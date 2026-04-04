class ApiResponse<T> {
  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.meta,
    this.errors,
  });

  final bool success;
  final String message;
  final T? data;
  final dynamic meta;
  final dynamic errors;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json, {
    T Function(dynamic json)? fromData,
  }) {
    return ApiResponse<T>(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      data: fromData != null ? fromData(json['data']) : json['data'] as T?,
      meta: json['meta'],
      errors: json['errors'],
    );
  }
}
