class AppException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? validationErrors;

  AppException({
    required this.message,
    this.statusCode,
    this.validationErrors,
  });

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  NetworkException({String message = 'Sin conexión a Internet. Verifique su red móvil o Wi-Fi.'})
      : super(message: message, statusCode: 0);
}

class UnauthorizedException extends AppException {
  UnauthorizedException({String message = 'Su sesión ha expirado o las credenciales son inválidas.'})
      : super(message: message, statusCode: 401);
}

class ValidationException extends AppException {
  ValidationException({
    required String message,
    Map<String, dynamic>? errors,
  }) : super(message: message, statusCode: 422, validationErrors: errors);

  /// Obtiene el primer mensaje de error para mostrar en toasts o banners rápidos
  String get firstErrorMessage {
    if (validationErrors == null || validationErrors!.isEmpty) return message;
    final firstEntry = validationErrors!.values.first;
    if (firstEntry is List && firstEntry.isNotEmpty) {
      return firstEntry.first.toString();
    }
    return firstEntry.toString();
  }
}

class ServerException extends AppException {
  ServerException({String message = 'Error interno en los servidores de RSHCO. Intente más tarde.'})
      : super(message: message, statusCode: 500);
}

class UnknownException extends AppException {
  UnknownException({String message = 'Ocurrió un error inesperado al procesar la solicitud.'})
      : super(message: message);
}
