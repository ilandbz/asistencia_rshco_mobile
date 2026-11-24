import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final personal = authState.personal;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Red de Salud Huánuco'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Cerrar Sesión',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Cerrar Sesión'),
                  content: const Text('¿Está seguro de que desea salir de la aplicación?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Cerrar Sesión'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await ref.read(authControllerProvider.notifier).logout();
                if (context.mounted) {
                  context.go('/login');
                }
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tarjeta de Identificación del Trabajador
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: AppColors.primaryLight.withOpacity(0.15),
                          child: const Icon(
                            Icons.person_rounded,
                            size: 36,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                personal?.nombreCompleto.isNotEmpty == true
                                    ? personal!.nombreCompleto
                                    : 'Personal de Salud',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              if (personal?.dni != null && personal!.dni.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'DNI: ${personal.dni}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 4),
                              Text(
                                personal?.cargo ?? 'Cargo no asignado',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    // Metadatos: Establecimiento, Condición Laboral y Régimen
                    Row(
                      children: [
                        const Icon(Icons.business_rounded, size: 14, color: AppColors.accent),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            personal?.establecimiento ?? 'Red de Salud Huánuco',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.badge_outlined, size: 14, color: AppColors.turnoGuardia),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Condición: ${personal?.condicionLaboral ?? "Nombrado / Contratado"}'
                            '${personal?.regimen != null ? " (${personal!.regimen})" : ""}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Accesos Directos a Módulos
            const Text(
              'Módulos y Servicios',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
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
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
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
