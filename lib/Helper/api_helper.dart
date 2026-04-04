import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_response.dart';
import 'app_constants.dart';
import 'storage_helper.dart';

class ApiHelper {
  ApiHelper({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    T Function(dynamic json)? fromData,
  }) async {
    final uri = Uri.parse('${AppConstants.baseUrl}$endpoint');
    final headers = await _buildHeaders();
    final response = await _client.post(
      uri,
      headers: headers,
      body: jsonEncode(body ?? <String, dynamic>{}),
    );

    final Map<String, dynamic> json = _decodeBody(response.body);
    return ApiResponse<T>.fromJson(json, fromData: fromData);
  }

  Future<Map<String, String>> _buildHeaders() async {
    final token = await StorageHelper.getAccessToken();
    final tokenType = await StorageHelper.getTokenType();

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = '${tokenType ?? 'Bearer'} $token';
    }

    return headers;
  }

  Map<String, dynamic> _decodeBody(String body) {
    if (body.trim().isEmpty) {
      return <String, dynamic>{
        'success': false,
        'message': 'Empty server response',
        'data': null,
        'meta': null,
        'errors': null,
      };
    }

    final dynamic decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    return <String, dynamic>{
      'success': false,
      'message': 'Invalid server response',
      'data': null,
      'meta': null,
      'errors': null,
    };
  }
}
