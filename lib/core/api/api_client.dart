import 'dart:convert';
import 'dart:async';

import 'package:http/http.dart' as http;

import '../../app/constants/app_config.dart';
import '../error/api_exception.dart';
import '../models/api_response.dart';
import '../models/paginated_response.dart';
import '../storage/session_storage.dart';
import 'api_cache_store.dart';

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const Duration _requestTimeout = Duration(seconds: 20);
  static final Map<String, Future<http.Response>> _inFlightGetRequests =
      <String, Future<http.Response>>{};
  static const Set<String> _cacheableGetPrefixes = <String>{
    '/masters/companies',
    '/masters/branches',
    '/masters/business-locations',
    '/masters/warehouses',
    '/masters/financial-years',
    '/masters/document-series',
    '/masters/party-types',
    '/inventory/uoms',
    '/inventory/tax-codes',
  };
  static const Map<String, Set<String>> _cacheInvalidationMap =
      <String, Set<String>>{
        '/masters/companies': <String>{
          '/masters/companies',
          '/masters/branches',
          '/masters/business-locations',
          '/masters/warehouses',
        },
        '/masters/branches': <String>{
          '/masters/branches',
          '/masters/business-locations',
          '/masters/warehouses',
        },
        '/masters/business-locations': <String>{
          '/masters/business-locations',
          '/masters/warehouses',
        },
        '/masters/warehouses': <String>{'/masters/warehouses'},
        '/masters/financial-years': <String>{'/masters/financial-years'},
        '/masters/document-series': <String>{'/masters/document-series'},
        '/masters/party-types': <String>{'/masters/party-types'},
        '/inventory/uoms': <String>{'/inventory/uoms'},
        '/inventory/tax-codes': <String>{'/inventory/tax-codes'},
      };

  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic json)? fromData,
  }) async {
    final response = await _getResponse(
      endpoint,
      queryParameters: queryParameters,
    );

    return _parseResponse(response, fromData: fromData);
  }

  Future<PaginatedResponse<T>> getPaginated<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    required T Function(Map<String, dynamic> json) itemFromJson,
  }) async {
    final response = await _getResponse(
      endpoint,
      queryParameters: queryParameters,
    );

    final json = _decodeBody(response.body);
    _throwIfHttpError(response.statusCode, json);
    return PaginatedResponse<T>.fromJson(json, itemFromJson: itemFromJson);
  }

  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    T Function(dynamic json)? fromData,
  }) async {
    final response = await _guardRequest(
      () async => _client.post(
        _buildUri(endpoint),
        headers: await _buildHeaders(),
        body: jsonEncode(body ?? <String, dynamic>{}),
      ),
    );

    _invalidateCacheForMutation(endpoint, response.statusCode);
    return _parseResponse(response, fromData: fromData);
  }

  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    T Function(dynamic json)? fromData,
  }) async {
    final response = await _guardRequest(
      () async => _client.put(
        _buildUri(endpoint),
        headers: await _buildHeaders(),
        body: jsonEncode(body ?? <String, dynamic>{}),
      ),
    );

    _invalidateCacheForMutation(endpoint, response.statusCode);
    return _parseResponse(response, fromData: fromData);
  }

  Future<ApiResponse<T>> patch<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    T Function(dynamic json)? fromData,
  }) async {
    final response = await _guardRequest(
      () async => _client.patch(
        _buildUri(endpoint),
        headers: await _buildHeaders(),
        body: jsonEncode(body ?? <String, dynamic>{}),
      ),
    );

    _invalidateCacheForMutation(endpoint, response.statusCode);
    return _parseResponse(response, fromData: fromData);
  }

  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    T Function(dynamic json)? fromData,
  }) async {
    final response = await _guardRequest(
      () async => _client.delete(
        _buildUri(endpoint),
        headers: await _buildHeaders(),
        body: body == null ? null : jsonEncode(body),
      ),
    );

    _invalidateCacheForMutation(endpoint, response.statusCode);
    return _parseResponse(response, fromData: fromData);
  }

  Future<ApiResponse<T>> upload<T>(
    String endpoint, {
    required String fileField,
    required String filePath,
    Map<String, String>? fields,
    T Function(dynamic json)? fromData,
  }) async {
    final request = http.MultipartRequest('POST', _buildUri(endpoint));
    request.headers.addAll(await _buildMultipartHeaders());

    if (fields != null) {
      request.fields.addAll(fields);
    }

    request.files.add(await http.MultipartFile.fromPath(fileField, filePath));

    final streamed = await _guardRequest(() => request.send());
    final response = await http.Response.fromStream(streamed);

    _invalidateCacheForMutation(endpoint, response.statusCode);
    return _parseResponse(response, fromData: fromData);
  }

  Future<http.Response> _getResponse(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final uri = _buildUri(endpoint, queryParameters);
    final headers = await _buildHeaders();
    final path = _normalizePath(uri.path);

    if (!_isCacheableGetPath(path)) {
      return _guardRequest(() => _client.get(uri, headers: headers));
    }

    final cacheKey = _buildCacheKey(uri, headers);
    final inFlight = _inFlightGetRequests[cacheKey];
    if (inFlight != null) {
      return inFlight;
    }

    final future = _performCacheableGet(
      uri,
      headers: headers,
      cacheKey: cacheKey,
    );
    _inFlightGetRequests[cacheKey] = future;

    try {
      return await future;
    } finally {
      if (identical(_inFlightGetRequests[cacheKey], future)) {
        _inFlightGetRequests.remove(cacheKey);
      }
    }
  }

  Uri _buildUri(String endpoint, [Map<String, dynamic>? queryParameters]) {
    final normalizedEndpoint = endpoint.startsWith('/')
        ? endpoint
        : '/$endpoint';
    final uri = Uri.parse('${AppConfig.apiBaseUrl}$normalizedEndpoint');

    if (queryParameters == null || queryParameters.isEmpty) {
      return uri;
    }

    final filtered = queryParameters.map(
      (key, value) => MapEntry(key, value?.toString() ?? ''),
    )..removeWhere((_, value) => value.isEmpty);

    return uri.replace(queryParameters: filtered);
  }

  Future<http.Response> _performCacheableGet(
    Uri uri, {
    required Map<String, String> headers,
    required String cacheKey,
  }) async {
    final cachedEntry = ApiCacheStore.read(cacheKey);
    final requestHeaders = Map<String, String>.from(headers);

    if (cachedEntry?.etag != null && cachedEntry!.etag!.isNotEmpty) {
      requestHeaders['If-None-Match'] = cachedEntry.etag!;
    }

    final response = await _guardRequest(
      () => _client.get(uri, headers: requestHeaders),
    );

    if (response.statusCode == 304) {
      if (cachedEntry == null) {
        return _guardRequest(() => _client.get(uri, headers: headers));
      }

      return http.Response(
        cachedEntry.body,
        200,
        headers: response.headers,
        request: response.request,
        reasonPhrase: response.reasonPhrase,
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      ApiCacheStore.write(
        cacheKey,
        body: response.body,
        etag: response.headers['etag'],
      );
    } else {
      ApiCacheStore.remove(cacheKey);
    }

    return response;
  }

  Future<Map<String, String>> _buildHeaders() async {
    final token = await SessionStorage.getAuthToken();
    final tokenType = await SessionStorage.getTokenType();

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = '${tokenType ?? 'Bearer'} $token';
    }

    return headers;
  }

  Future<Map<String, String>> _buildMultipartHeaders() async {
    final token = await SessionStorage.getAuthToken();
    final tokenType = await SessionStorage.getTokenType();
    final headers = <String, String>{'Accept': 'application/json'};

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = '${tokenType ?? 'Bearer'} $token';
    }

    return headers;
  }

  ApiResponse<T> _parseResponse<T>(
    http.Response response, {
    T Function(dynamic json)? fromData,
  }) {
    final json = _decodeBody(response.body);
    _throwIfHttpError(response.statusCode, json);
    return ApiResponse<T>.fromJson(json, fromData: fromData);
  }

  Map<String, dynamic> _decodeBody(String body) {
    if (body.trim().isEmpty) {
      return <String, dynamic>{
        'success': false,
        'message': 'Empty server response',
      };
    }

    final decoded = jsonDecode(body);
    return decoded is Map<String, dynamic>
        ? decoded
        : <String, dynamic>{
            'success': false,
            'message': 'Invalid server response',
          };
  }

  void _throwIfHttpError(int statusCode, Map<String, dynamic> json) {
    if (statusCode >= 200 && statusCode < 300) {
      return;
    }

    throw ApiException(
      json['message']?.toString() ?? 'Request failed',
      statusCode: statusCode,
      errors: json['errors'],
    );
  }

  Future<T> _guardRequest<T>(Future<T> Function() request) async {
    try {
      return await request().timeout(_requestTimeout);
    } on TimeoutException {
      throw const ApiException(
        'The server is taking too long to respond. Please try again.',
        isTimeout: true,
      );
    } on http.ClientException {
      throw const ApiException(
        'Server is unreachable. Please check the connection and try again.',
        isNetworkError: true,
      );
    } on FormatException {
      throw const ApiException('Invalid response received from server.');
    }
  }

  bool _isCacheableGetPath(String path) =>
      _cacheableGetPrefixes.any((prefix) => path.startsWith(prefix));

  String _buildCacheKey(Uri uri, Map<String, String> headers) {
    final authorization = headers['Authorization'] ?? '';
    final normalizedPath = _normalizePath(uri.path);
    final query = uri.query;
    return 'GET|$authorization|$normalizedPath|$query';
  }

  void _invalidateCacheForMutation(String endpoint, int statusCode) {
    if (statusCode < 200 || statusCode >= 300) {
      return;
    }

    final path = _normalizePath(_buildUri(endpoint).path);
    final matchedPrefix = _cacheInvalidationMap.keys.firstWhere(
      (prefix) => path.startsWith(prefix),
      orElse: () => '',
    );

    if (matchedPrefix.isEmpty) {
      return;
    }

    final families = _cacheInvalidationMap[matchedPrefix] ?? <String>{};
    ApiCacheStore.removeWhere(
      (key, _) => families.any((family) => key.contains('|$family|')),
    );
  }

  String _normalizePath(String path) {
    if (path.isEmpty) {
      return '/';
    }

    return path.endsWith('/') && path.length > 1
        ? path.substring(0, path.length - 1)
        : path;
  }
}
