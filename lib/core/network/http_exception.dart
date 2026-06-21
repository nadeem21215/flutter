class HttpException implements Exception {
  final String message;
  final int?   statusCode;
  const HttpException({required this.message, this.statusCode});
  @override
  String toString() => message;
}
