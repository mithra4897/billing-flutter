import 'api_response.dart';

class PaginatedResponse<T> extends ApiResponse<List<T>> {
  const PaginatedResponse({
    required super.success,
    required super.message,
    super.data,
    super.meta,
    super.errors,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json, {
    required T Function(Map<String, dynamic> json) itemFromJson,
  }) {
    final rawData = json['data'];
    final items = rawData is List
        ? rawData
              .whereType<Map<String, dynamic>>()
              .map(itemFromJson)
              .toList(growable: false)
        : <T>[];

    final response = ApiResponse<List<T>>.fromJson(
      json,
      fromData: (_) => items,
    );

    return PaginatedResponse<T>(
      success: response.success,
      message: response.message,
      data: response.data,
      meta: response.meta,
      errors: response.errors,
    );
  }
}
