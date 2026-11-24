import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/asistencia/presentation/screens/asistencia_screen.dart';
import '../../features/asistencia/presentation/screens/rol_mes_screen.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/controllers/auth_state.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/cambio_turno/presentation/screens/mis_cambios_turno_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/permisos/presentation/screens/mis_permisos_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (BuildContext context, GoRouterState state) {
      final isChecking = authState.status == AuthStatus.checking || authState.status == AuthStatus.initial;
      final isAuthenticated = authState.status == AuthStatus.authenticated;
      final isGoingToLogin = state.matchedLocation == '/login';
      final isGoingToSplash = state.matchedLocation == '/splash';

      if (isChecking) {
        return isGoingToSplash ? null : '/splash';
      }

      if (!isAuthenticated) {
        return isGoingToLogin ? null : '/login';
      }

      if (isAuthenticated && (isGoingToLogin || isGoingToSplash)) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/asistencia',
        builder: (context, state) => const AsistenciaScreen(),
      ),
      GoRoute(
        path: '/rol-mes',
        builder: (context, state) => const RolMesScreen(),
      ),
      GoRoute(
        path: '/cambio-turno',
        builder: (context, state) => const MisCambiosTurnoScreen(),
      ),
      GoRoute(
        path: '/permisos',
        builder: (context, state) => const MisPermisosScreen(),
      ),
    ],
  );
});
