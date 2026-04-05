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

  @override
  String toString() => message;
}
