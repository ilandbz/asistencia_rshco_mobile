import 'package:dio/dio.dart';
import '../services/secure_storage_service.dart';

typedef OnUnauthorizedCallback = void Function();

class AuthInterceptor extends Interceptor {
  final SecureStorageService _storageService;
  final OnUnauthorizedCallback? onUnauthorized;

  AuthInterceptor({
    required SecureStorageService storageService,
    this.onUnauthorized,
  }) : _storageService = storageService;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Headers globales obligatorios
    options.headers['Accept'] = 'application/json';

    // Inyectar Token Bearer si existe en el almacenamiento seguro
    final token = await _storageService.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Limpiar sesión local ante expiración o token revocado
      await _storageService.clearAll();
      if (onUnauthorized != null) {
        onUnauthorized!();
      }
    }
    return handler.next(err);
  }
}
