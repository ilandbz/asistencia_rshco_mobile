import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_config.dart';

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  Future<void> saveToken(String token) async {
    await _storage.write(key: AppConfig.keyAuthToken, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: AppConfig.keyAuthToken);
  }

  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> saveUserData(String jsonUserData) async {
    await _storage.write(key: AppConfig.keyUserData, value: jsonUserData);
  }

  Future<String?> getUserData() async {
    return await _storage.read(key: AppConfig.keyUserData);
  }

  Future<void> savePersonalData(String jsonPersonalData) async {
    await _storage.write(key: AppConfig.keyPersonalData, value: jsonPersonalData);
  }

  Future<String?> getPersonalData() async {
    return await _storage.read(key: AppConfig.keyPersonalData);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
