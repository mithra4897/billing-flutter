import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../app/constants/app_config.dart';
import '../error/api_exception.dart';
import '../models/api_response.dart';
import '../models/paginated_response.dart';
import '../storage/session_storage.dart';

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic json)? fromData,
  }) async {
    final response = await _client.get(
      _buildUri(endpoint, queryParameters),
      headers: await _buildHeaders(),
    );

    return _parseResponse(response, fromData: fromData);
  }

  Future<PaginatedResponse<T>> getPaginated<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    required T Function(Map<String, dynamic> json) itemFromJson,
  }) async {
    final response = await _client.get(
      _buildUri(endpoint, queryParameters),
      headers: await _buildHeaders(),
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
    final response = await _client.post(
      _buildUri(endpoint),
      headers: await _buildHeaders(),
      body: jsonEncode(body ?? <String, dynamic>{}),
    );

    return _parseResponse(response, fromData: fromData);
  }

  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    T Function(dynamic json)? fromData,
  }) async {
    final response = await _client.put(
      _buildUri(endpoint),
      headers: await _buildHeaders(),
      body: jsonEncode(body ?? <String, dynamic>{}),
    );

    return _parseResponse(response, fromData: fromData);
  }

  Future<ApiResponse<T>> patch<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    T Function(dynamic json)? fromData,
  }) async {
    final response = await _client.patch(
      _buildUri(endpoint),
      headers: await _buildHeaders(),
      body: jsonEncode(body ?? <String, dynamic>{}),
    );

    return _parseResponse(response, fromData: fromData);
  }

  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    T Function(dynamic json)? fromData,
  }) async {
    final response = await _client.delete(
      _buildUri(endpoint),
      headers: await _buildHeaders(),
      body: body == null ? null : jsonEncode(body),
    );

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

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    return _parseResponse(response, fromData: fromData);
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
}
