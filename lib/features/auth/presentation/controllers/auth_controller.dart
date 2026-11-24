import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/exceptions.dart';
import '../../data/repositories/auth_repository.dart';
import 'auth_state.dart';

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthController(authRepository: authRepository);
});

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;

  AuthController({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthState()) {
    checkAuthStatus();
  }

  /// Verifica el token al iniciar la app (Splash)
  Future<void> checkAuthStatus() async {
    state = state.copyWith(status: AuthStatus.checking);
    try {
      final isAuth = await _authRepository.isAuthenticated();
      if (isAuth) {
        final personalLocal = await _authRepository.getLocalPersonal();
        state = state.copyWith(
          status: AuthStatus.authenticated,
          personal: personalLocal,
        );
        // Sincronizar inmediatamente perfil desde la API y refrescar estado
        await _syncProfile();
      } else {
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    } catch (_) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> _syncProfile() async {
    try {
      final personal = await _authRepository.getPerfil();
      state = state.copyWith(personal: personal);
    } catch (_) {
      // Ignorar fallos de red en sincronización silenciosa
    }
  }

  /// Inicia sesión con DNI y Contraseña
  Future<bool> login({
    required String dni,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final response = await _authRepository.login(
        dni: dni,
        password: password,
      );

      state = state.copyWith(
        status: AuthStatus.authenticated,
        isLoading: false,
        personal: response.personal,
      );
      return true;
    } on ValidationException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.firstErrorMessage,
      );
      return false;
    } on AppException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error inesperado al iniciar sesión: ${e.toString()}',
      );
      return false;
    }
  }

  /// Cierre de sesión y limpieza de tokens
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    await _authRepository.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}
