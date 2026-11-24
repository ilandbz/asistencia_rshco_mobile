import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../models/auth_model.dart';
import 'dart:convert';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  final storageService = ref.watch(secureStorageServiceProvider);
  return AuthRepositoryImpl(
    dioClient: dioClient,
    storageService: storageService,
  );
});

abstract class AuthRepository {
  Future<AuthResponse> login({
    required String dni,
    required String password,
    String? deviceName,
  });
  Future<Personal> getPerfil();
  Future<void> logout();
  Future<bool> isAuthenticated();
  Future<Personal?> getLocalPersonal();
}

class AuthRepositoryImpl implements AuthRepository {
  final DioClient dioClient;
  final SecureStorageService storageService;

  AuthRepositoryImpl({
    required this.dioClient,
    required this.storageService,
  });

  @override
  Future<AuthResponse> login({
    required String dni,
    required String password,
    String? deviceName,
  }) async {
    final dniTrim = dni.trim();
    final response = await dioClient.post(
      ApiEndpoints.login,
      data: {
        'name': dniTrim,
        'dni': dniTrim,
        'username': dniTrim,
        'password': password,
        'device_name': deviceName ?? 'Flutter Mobile (Android/iOS)',
      },
    );

    final authResponse = AuthResponse.fromJson(response.data);

    // Guardar token en secure storage
    await storageService.saveToken(authResponse.token);

    if (authResponse.user != null) {
      await storageService.saveUserData(jsonEncode(authResponse.user!.toJson()));
    }
    if (authResponse.personal != null) {
      await storageService.savePersonalData(jsonEncode(authResponse.personal!.toJson()));
    }

    // Consultar inmediatamente el endpoint /perfil para garantizar datos frescos del trabajador
    Personal? personalActualizado = authResponse.personal;
    try {
      final perfilResponse = await dioClient.get(ApiEndpoints.perfil);
      final perfilData = perfilResponse.data;
      final perfilMap = (perfilData is Map<String, dynamic> && perfilData['personal'] != null)
          ? perfilData['personal']
          : (perfilData is Map<String, dynamic> && perfilData['data'] != null
              ? perfilData['data']
              : perfilData);
      personalActualizado = Personal.fromJson(perfilMap as Map<String, dynamic>);
      await storageService.savePersonalData(jsonEncode(personalActualizado.toJson()));
    } catch (_) {
      // Si falla /perfil, se mantiene authResponse.personal
    }

    return AuthResponse(
      token: authResponse.token,
      user: authResponse.user,
      personal: personalActualizado,
    );
  }

  @override
  Future<Personal> getPerfil() async {
    final response = await dioClient.get(ApiEndpoints.perfil);
    final data = response.data;
    final personalMap = (data is Map<String, dynamic> && data['personal'] != null)
        ? data['personal']
        : (data is Map<String, dynamic> && data['data'] != null ? data['data'] : data);
    final personal = Personal.fromJson(personalMap as Map<String, dynamic>);

    await storageService.savePersonalData(jsonEncode(personal.toJson()));
    return personal;
  }

  @override
  Future<void> logout() async {
    try {
      await dioClient.post(ApiEndpoints.logout);
    } catch (_) {
      // Ignorar errores de red en logout para forzar limpieza local
    } finally {
      await storageService.clearAll();
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    return await storageService.hasToken();
  }

  @override
  Future<Personal?> getLocalPersonal() async {
    final raw = await storageService.getPersonalData();
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return Personal.fromJson(json);
    } catch (_) {
      return null;
    }
  }
}
