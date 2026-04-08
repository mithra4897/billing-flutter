class ApiException implements Exception {
  const ApiException(
    this.message, {
    this.statusCode,
    this.errors,
    this.isNetworkError = false,
    this.isTimeout = false,
  });

  final String message;
  final int? statusCode;
  final dynamic errors;
  final bool isNetworkError;
  final bool isTimeout;

  bool get isConnectivityIssue => isNetworkError || isTimeout;

  String get displayMessage {
    if (errors == null) {
      return message;
    }

    final details = _flattenErrors(errors);
    if (details.isEmpty) {
      return message;
    }

    return message == details ? message : '$message\n$details';
  }

  @override
  String toString() => displayMessage;

  static String _flattenErrors(dynamic value) {
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
}
