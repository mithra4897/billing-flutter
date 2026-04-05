import 'pagination_meta.dart';

class ApiResponse<T> {
  const ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.meta,
    this.errors,
  });

  final bool success;
  final String message;
  final T? data;
  final PaginationMeta? meta;
  final dynamic errors;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json, {
    T Function(dynamic json)? fromData,
  }) {
    return ApiResponse<T>(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      data: fromData != null ? fromData(json['data']) : json['data'] as T?,
      meta: json['meta'] is Map<String, dynamic>
          ? PaginationMeta.fromJson(json['meta'] as Map<String, dynamic>)
          : null,
      errors: json['errors'],
    );
  }
}
