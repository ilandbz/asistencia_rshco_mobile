import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../constants/app_config.dart';
import '../errors/exceptions.dart';
import '../services/secure_storage_service.dart';
import 'auth_interceptor.dart';

final dioClientProvider = Provider<DioClient>((ref) {
  final storageService = ref.watch(secureStorageServiceProvider);
  return DioClient(storageService: storageService);
});

class DioClient {
  late final Dio dio;
  final SecureStorageService storageService;

  DioClient({
    required this.storageService,
    OnUnauthorizedCallback? onUnauthorized,
  }) {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        headers: {
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.addAll([
      AuthInterceptor(
        storageService: storageService,
        onUnauthorized: onUnauthorized,
      ),
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        compact: true,
      ),
    ]);
  }

  /// Wrapper seguro para peticiones GET
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Wrapper seguro para peticiones POST
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Transforma DioException en excepciones de dominio limpias
  AppException _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return NetworkException();

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final responseData = error.response?.data;

        String serverMessage = 'Ocurrió un problema en la solicitud';
        Map<String, dynamic>? validationErrors;

        if (responseData is Map<String, dynamic>) {
          serverMessage = responseData['message'] ??
              responseData['error'] ??
              serverMessage;
          if (responseData['errors'] is Map<String, dynamic>) {
            validationErrors = responseData['errors'] as Map<String, dynamic>;
          }
        }

        if (statusCode == 401) {
          return UnauthorizedException(message: serverMessage);
        } else if (statusCode == 422) {
          return ValidationException(
            message: serverMessage,
            errors: validationErrors,
          );
        } else if (statusCode != null && statusCode >= 500) {
          return ServerException(message: serverMessage);
        }

        return AppException(message: serverMessage, statusCode: statusCode);

      case DioExceptionType.cancel:
        return AppException(message: 'La solicitud fue cancelada.');

      default:
        return UnknownException(
          message: error.message ?? 'Error inesperado de comunicación.',
        );
    }
  }
}
