import 'dart:convert';
import 'dart:async';
import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../app/constants/app_config.dart';
import '../error/api_exception.dart';
import '../models/api_response.dart';
import '../models/paginated_response.dart';
import '../navigation/app_route_state.dart';
import '../storage/session_storage.dart';
import 'api_cache_store.dart';
import '../../main.dart';
import '../../service/app/app_session_service.dart';
import 'api_endpoints.dart';

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
    ApiEndpoints.uoms,
    ApiEndpoints.taxCodes,
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
        ApiEndpoints.uoms: <String>{ApiEndpoints.uoms},
        ApiEndpoints.taxCodes: <String>{ApiEndpoints.taxCodes},
      };

  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic json)? fromData,
  }) async {
    final uri = _buildUri(endpoint, queryParameters);
    final response = await _getResponse(
      endpoint,
      queryParameters: queryParameters,
    );
    return _parseResponse(
      response,
      fromData: fromData,
      requestContext: _RequestDebugContext(method: 'GET', uri: uri),
    );
  }

  Future<PaginatedResponse<T>> getPaginated<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    required T Function(Map<String, dynamic> json) itemFromJson,
  }) async {
    final uri = _buildUri(endpoint, queryParameters);
    final response = await _getResponse(
      endpoint,
      queryParameters: queryParameters,
    );
    final json = _decodeBody(response.body);
    _throwIfHttpError(
      response.statusCode,
      json,
      requestContext: _RequestDebugContext(method: 'GET', uri: uri),
      responseBody: response.body,
    );
    return PaginatedResponse<T>.fromJson(json, itemFromJson: itemFromJson);
  }

  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    T Function(dynamic json)? fromData,
  }) async {
    final uri = _buildUri(endpoint);
    final response = await _guardRequest(
      requestContext: _RequestDebugContext(
        method: 'POST',
        uri: uri,
        requestBody: body,
      ),
      () async => _client.post(
        uri,
        headers: await _buildHeaders(),
        body: jsonEncode(body ?? <String, dynamic>{}),
      ),
    );
    _invalidateCacheForMutation(endpoint, response.statusCode);
    return _parseResponse(
      response,
      fromData: fromData,
      requestContext: _RequestDebugContext(
        method: 'POST',
        uri: uri,
        requestBody: body,
      ),
    );
  }

  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    T Function(dynamic json)? fromData,
  }) async {
    final uri = _buildUri(endpoint);
    final response = await _guardRequest(
      requestContext: _RequestDebugContext(
        method: 'PUT',
        uri: uri,
        requestBody: body,
      ),
      () async => _client.put(
        uri,
        headers: await _buildHeaders(),
        body: jsonEncode(body ?? <String, dynamic>{}),
      ),
    );
    _invalidateCacheForMutation(endpoint, response.statusCode);
    return _parseResponse(
      response,
      fromData: fromData,
      requestContext: _RequestDebugContext(
        method: 'PUT',
        uri: uri,
        requestBody: body,
      ),
    );
  }

  Future<ApiResponse<T>> patch<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    T Function(dynamic json)? fromData,
  }) async {
    final uri = _buildUri(endpoint);
    final response = await _guardRequest(
      requestContext: _RequestDebugContext(
        method: 'PATCH',
        uri: uri,
        requestBody: body,
      ),
      () async => _client.patch(
        uri,
        headers: await _buildHeaders(),
        body: jsonEncode(body ?? <String, dynamic>{}),
      ),
    );
    _invalidateCacheForMutation(endpoint, response.statusCode);
    return _parseResponse(
      response,
      fromData: fromData,
      requestContext: _RequestDebugContext(
        method: 'PATCH',
        uri: uri,
        requestBody: body,
      ),
    );
  }

  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    T Function(dynamic json)? fromData,
  }) async {
    final uri = _buildUri(endpoint);
    final response = await _guardRequest(
      requestContext: _RequestDebugContext(
        method: 'DELETE',
        uri: uri,
        requestBody: body,
      ),
      () async => _client.delete(
        uri,
        headers: await _buildHeaders(),
        body: body == null ? null : jsonEncode(body),
      ),
    );
    _invalidateCacheForMutation(endpoint, response.statusCode);
    return _parseResponse(
      response,
      fromData: fromData,
      requestContext: _RequestDebugContext(
        method: 'DELETE',
        uri: uri,
        requestBody: body,
      ),
    );
  }

  Future<ApiResponse<T>> upload<T>(
    String endpoint, {
    required String fileField,
    String? filePath,
    Uint8List? fileBytes,
    String? fileName,
    Map<String, String>? fields,
    T Function(dynamic json)? fromData,
  }) async {
    final uri = _buildUri(endpoint);
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(await _buildMultipartHeaders());

    if (fields != null) {
      request.fields.addAll(fields);
    }

    if (fileBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          fileField,
          fileBytes,
          filename: fileName ?? 'upload.bin',
        ),
      );
    } else if (filePath != null && filePath.trim().isNotEmpty) {
      request.files.add(await http.MultipartFile.fromPath(fileField, filePath));
    } else {
      throw ArgumentError(
        'Either filePath or fileBytes must be provided for upload.',
      );
    }

    final requestContext = _RequestDebugContext(
      method: 'POST',
      uri: uri,
      requestBody: <String, dynamic>{
        'multipart': true,
        'file_field': fileField,
        ...(filePath == null
            ? const <String, dynamic>{}
            : <String, dynamic>{'file_path': filePath}),
        ...(fileBytes == null
            ? const <String, dynamic>{}
            : <String, dynamic>{'file_bytes_length': fileBytes.length}),
        ...(fileName == null
            ? const <String, dynamic>{}
            : <String, dynamic>{'file_name': fileName}),
        'fields': fields ?? <String, String>{},
      },
    );

    final streamed = await _guardRequest(
      requestContext: requestContext,
      () => request.send(),
    );
    final response = await http.Response.fromStream(streamed);

    _invalidateCacheForMutation(endpoint, response.statusCode);
    return _parseResponse(
      response,
      fromData: fromData,
      requestContext: requestContext,
    );
  }

  Future<ApiResponse<T>> uploadBytes<T>(
    String endpoint, {
    required String fileField,
    required Uint8List fileBytes,
    required String fileName,
    Map<String, String>? fields,
    T Function(dynamic json)? fromData,
  }) async {
    final uri = _buildUri(endpoint);
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(await _buildMultipartHeaders());

    if (fields != null) {
      request.fields.addAll(fields);
    }

    MediaType? mediaType;
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'png': mediaType = MediaType('image', 'png'); break;
      case 'jpg':
      case 'jpeg': mediaType = MediaType('image', 'jpeg'); break;
      case 'webp': mediaType = MediaType('image', 'webp'); break;
      case 'gif': mediaType = MediaType('image', 'gif'); break;
      case 'pdf': mediaType = MediaType('application', 'pdf'); break;
      default: mediaType = MediaType('application', 'octet-stream');
    }

    final safeFileName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9.\-_]'), '_');

    request.files.add(
      http.MultipartFile.fromBytes(
        fileField, 
        fileBytes, 
        filename: safeFileName,
        contentType: mediaType,
      ),
    );

    final requestContext = _RequestDebugContext(
      method: 'POST',
      uri: uri,
      requestBody: <String, dynamic>{
        'multipart': true,
        'file_field': fileField,
        'file_name': fileName,
        'file_size': fileBytes.length,
        'fields': fields ?? <String, String>{},
      },
    );

    final streamed = await _guardRequest(
      requestContext: requestContext,
      () => request.send(),
    );
    final response = await http.Response.fromStream(streamed);

    _invalidateCacheForMutation(endpoint, response.statusCode);
    return _parseResponse(
      response,
      fromData: fromData,
      requestContext: requestContext,
    );
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
    _RequestDebugContext? requestContext,
  }) {
    final json = _decodeBody(response.body);
    _throwIfHttpError(
      response.statusCode,
      json,
      requestContext: requestContext,
      responseBody: response.body,
    );
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

  void _throwIfHttpError(
    int statusCode,
    Map<String, dynamic> json, {
    _RequestDebugContext? requestContext,
    String? responseBody,
  }) {
    if (statusCode >= 200 && statusCode < 300) {
      return;
    }

    _logFailedRequest(
      requestContext,
      statusCode: statusCode,
      responseJson: json,
      responseBody: responseBody,
    );

    if (statusCode == 401 || statusCode == 403) {
      _handleUnauthorized();
    }

    final message = _resolveErrorMessage(json);

    throw ApiException(message, statusCode: statusCode, errors: json['errors']);
  }

  Future<T> _guardRequest<T>(
    Future<T> Function() request, {
    _RequestDebugContext? requestContext,
  }) async {
    try {
      return await request().timeout(_requestTimeout);
    } on TimeoutException catch (error, stackTrace) {
      _logFailedRequest(requestContext, error: error, stackTrace: stackTrace);
      throw const ApiException(
        'The server is taking too long to respond. Please try again.',
        isTimeout: true,
      );
    } on http.ClientException catch (error, stackTrace) {
      _logFailedRequest(requestContext, error: error, stackTrace: stackTrace);
      throw const ApiException(
        'Server is unreachable. Please check the connection and try again.',
        isNetworkError: true,
      );
    } on FormatException catch (error, stackTrace) {
      _logFailedRequest(requestContext, error: error, stackTrace: stackTrace);
      throw const ApiException('Invalid response received from server.');
    }
  }

  void _logFailedRequest(
    _RequestDebugContext? context, {
    int? statusCode,
    Map<String, dynamic>? responseJson,
    String? responseBody,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (context == null) {
      return;
    }

    final buffer = StringBuffer()
      ..writeln('[API ERROR]')
      ..writeln('${context.method} ${context.uri}');

    if (context.requestBody != null) {
      buffer.writeln('Request Body: ${_prettyJson(context.requestBody)}');
    }

    if (statusCode != null) {
      buffer.writeln('Status: $statusCode');
    }

    if (responseJson != null) {
      buffer.writeln('Response JSON: ${_prettyJson(responseJson)}');
    } else if (responseBody != null && responseBody.trim().isNotEmpty) {
      buffer.writeln('Response Body: $responseBody');
    }

    if (error != null) {
      buffer.writeln('Error: $error');
    }

    developer.log(
      buffer.toString().trimRight(),
      name: 'ApiClient',
      error: error,
      stackTrace: stackTrace,
    );
  }

  String _prettyJson(dynamic value) {
    try {
      return const JsonEncoder.withIndent('  ').convert(value);
    } catch (_) {
      return value.toString();
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

  String _resolveErrorMessage(Map<String, dynamic> json) {
    final message = json['message']?.toString().trim();
    final details = _flattenErrors(json['errors']);

    if ((message == null || message.isEmpty) && details.isNotEmpty) {
      return details;
    }

    if (message == null || message.isEmpty) {
      return 'Request failed';
    }

    if (details.isEmpty || message.contains(details)) {
      return message;
    }

    return '$message\n$details';
  }

  String _flattenErrors(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .join('\n');
    }

    if (value is Map) {
      return value.values
          .map(_flattenErrors)
          .where((item) => item.trim().isNotEmpty)
          .join('\n');
    }

    return value?.toString().trim() ?? '';
  }

  void _handleUnauthorized() {
    if (AppRouteState.redirectingToLogin) {
      return;
    }

    AppRouteState.setRedirectingToLogin(true);
    final currentRoute = AppRouteState.currentRoute;

    Future<void>(() async {
      await AppSessionService.instance.clearSession();
      final navigator = appNavigatorKey.currentState;
      if (navigator == null) {
        AppRouteState.setRedirectingToLogin(false);
        return;
      }

      final redirectTo = currentRoute.startsWith('/login')
          ? '/dashboard'
          : currentRoute;
      final loginRoute = Uri(
        path: '/login',
        queryParameters: <String, String>{'redirect': redirectTo},
      ).toString();
      navigator.pushNamedAndRemoveUntil(loginRoute, (_) => false);
      AppRouteState.update(loginRoute);
      AppRouteState.setRedirectingToLogin(false);
    });
  }
}

class _RequestDebugContext {
  const _RequestDebugContext({
    required this.method,
    required this.uri,
    this.requestBody,
  });

  final String method;
  final Uri uri;
  final dynamic requestBody;
}
