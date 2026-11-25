enum Environment { dev, staging, prod }

class AppConfig {
  static Environment currentEnvironment = Environment.prod;

  /// Base URLs según el entorno
  /// Prod: https://asistencia.macrocompany.net.pe/api
  static String get baseUrl {
    switch (currentEnvironment) {
      case Environment.dev:
        return 'https://asistencia.macrocompany.net.pe/api';
      case Environment.staging:
        return 'https://asistencia.macrocompany.net.pe/api';
      case Environment.prod:
        return 'https://asistencia.macrocompany.net.pe/api';
    }
  }

  static const String appName = 'RSHCO Asistencia';
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 90);

  // Claves de Storage
  static const String keyAuthToken = 'auth_token';
  static const String keyUserData = 'auth_user_data';
  static const String keyPersonalData = 'auth_personal_data';
  static const String keyDeviceName = 'device_name';
}
