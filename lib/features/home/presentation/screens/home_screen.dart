import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _obtenerSaludo() {
    final hora = DateTime.now().hour;
    if (hora >= 5 && hora < 12) {
      return '¡Buenos días';
    } else if (hora >= 12 && hora < 19) {
      return '¡Buenas tardes';
    } else {
      return '¡Buenas noches';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final personal = authState.personal;
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    final String primerNombre = personal?.nombres.split(' ').first ?? 'Personal';
    final String nombreCompleto = personal?.nombreCompleto.isNotEmpty == true
        ? personal!.nombreCompleto
        : 'Personal de Salud';
    final String saludo = _obtenerSaludo();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Red de Salud Huánuco'),
        actions: [
          // Botón de Modo Día y Noche
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: isDark ? Colors.amberAccent : Colors.white,
            ),
            tooltip: isDark ? 'Cambiar a modo Día' : 'Cambiar a modo Noche',
            onPressed: () => ref.read(themeModeProvider.notifier).toggleTheme(),
          ),
          // Botón de Perfil
          IconButton(
            icon: const Icon(Icons.account_circle_rounded),
            tooltip: 'Mi Perfil',
            onPressed: () => context.push('/perfil'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Tarjeta Cálida de Bienvenida y Perfil (Interactiva)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                      : [AppColors.primary, AppColors.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => context.push('/perfil'),
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Saludo y Avatar
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              child: const Icon(
                                Icons.person_rounded,
                                size: 32,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$saludo, $primerNombre',
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    nombreCompleto,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: Colors.white.withOpacity(0.9),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (personal?.cargo != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      personal!.cargo!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: isDark ? const Color(0xFF38BDF8) : const Color(0xFFBAE6FD),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Barra inferior con Sede y link a perfil
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    const Icon(Icons.business_rounded, size: 14, color: Colors.white70),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        personal?.establecimiento ?? 'Sede Red de Salud Huánuco',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 11, color: Colors.white70),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Ver Perfil →',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Accesos Directos a Módulos
            Text(
              'Módulos y Servicios',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.getTextPrimary(context),
              ),
            ),
            const SizedBox(height: 12),

            _buildModuleCard(
              context: context,
              icon: Icons.fingerprint_rounded,
              color: AppColors.primary,
              title: 'Asistencia y Marcaciones',
              description: 'Estado de hoy, registro mensual de asistencia y récord de tardanzas.',
              onTap: () => context.push('/asistencia'),
            ),
            const SizedBox(height: 12),

            _buildModuleCard(
              context: context,
              icon: Icons.calendar_month_rounded,
              color: AppColors.turnoGuardia,
              title: 'Rol de Turnos Mensual',
              description: 'Calendario de turnos programados, guardias diurnas y nocturnas.',
              onTap: () => context.push('/rol-mes'),
            ),
            const SizedBox(height: 12),

            _buildModuleCard(
              context: context,
              icon: Icons.published_with_changes_rounded,
              color: AppColors.turnoTarde,
              title: 'Solicitud de Cambio de Turno',
              description: 'Permutas con colegas del servicio previas a la ejecución del rol.',
              onTap: () => context.push('/cambio-turno'),
            ),
            const SizedBox(height: 12),

            _buildModuleCard(
              context: context,
              icon: Icons.assignment_rounded,
              color: AppColors.success,
              title: 'Permisos & Descansos (CIT)',
              description: 'Trámite de CIT, subsidios EsSalud (>20 días), permisos particulares.',
              onTap: () => context.push('/permisos'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleCard({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.getTextPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.getTextSecondary(context),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
