class ApiOfflineException implements Exception {
  final String message;
  final int? statusCode;

  const ApiOfflineException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}
