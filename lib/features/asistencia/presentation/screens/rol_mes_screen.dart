import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../../../core/theme/app_theme.dart';
import '../controllers/asistencia_controller.dart';
import '../../data/models/asistencia_model.dart';
import '../widgets/turno_badge.dart';

class RolMesScreen extends ConsumerWidget {
  const RolMesScreen({super.key});

  static const List<String> meses = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Setiembre', 'Octubre', 'Noviembre', 'Diciembre'
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(currentFilterProvider);
    final rolAsync = ref.watch(rolMensualProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rol de Turnos Mensual'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualizar rol',
            onPressed: () => ref.invalidate(rolMensualProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Selector de Mes y Año
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, size: 28),
                  onPressed: () {
                    final prevMes = filter.mes == 1 ? 12 : filter.mes - 1;
                    final prevAnio = filter.mes == 1 ? filter.anio - 1 : filter.anio;
                    ref.read(currentFilterProvider.notifier).state =
                        MonthYearFilter(mes: prevMes, anio: prevAnio);
                  },
                ),
                Column(
                  children: [
                    Text(
                      '${meses[filter.mes - 1]} ${filter.anio}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Programación de turnos del personal',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded, size: 28),
                  onPressed: () {
                    final nextMes = filter.mes == 12 ? 1 : filter.mes + 1;
                    final nextAnio = filter.mes == 12 ? filter.anio + 1 : filter.anio;
                    ref.read(currentFilterProvider.notifier).state =
                        MonthYearFilter(mes: nextMes, anio: nextAnio);
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // 2. Leyenda de Siglas de Turnos
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: AppColors.surfaceVariant.withOpacity(0.4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: const [
                  _LeyendaItem(sigla: 'MT', nombre: 'Mañana y Tarde'),
                  SizedBox(width: 10),
                  _LeyendaItem(sigla: 'M', nombre: 'Mañana'),
                  SizedBox(width: 10),
                  _LeyendaItem(sigla: 'T', nombre: 'Tarde'),
                  SizedBox(width: 10),
                  _LeyendaItem(sigla: 'N', nombre: 'Noche'),
                  SizedBox(width: 10),
                  _LeyendaItem(sigla: 'GD', nombre: 'Guardia Diurna'),
                  SizedBox(width: 10),
                  _LeyendaItem(sigla: 'GN', nombre: 'Guardia Nocturna'),
                  SizedBox(width: 10),
                  _LeyendaItem(sigla: 'F', nombre: 'Feriado'),
                  SizedBox(width: 10),
                  _LeyendaItem(sigla: 'D', nombre: 'Descanso'),
                ],
              ),
            ),
          ),

          // 3. Contenido Principal: Resumen + Calendario Grid
          Expanded(
            child: rolAsync.when(
              loading: () => const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SpinKitRing(color: AppColors.primary, size: 36),
                    SizedBox(height: 16),
                    Text(
                      'Consultando tu rol de turnos...',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(28.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.errorBg,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.cloud_off_rounded, size: 36, color: AppColors.error),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'No pudimos cargar el rol de turnos',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Por favor revisa tu conexión a internet o intenta nuevamente en unos momentos.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Reintentar'),
                        onPressed: () => ref.invalidate(rolMensualProvider),
                      ),
                    ],
                  ),
                ),
              ),
              data: (rol) {
                if (rol.turnos.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.event_available_rounded, size: 40, color: AppColors.primary),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'No hay turnos registrados en este mes',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Aún no se ha publicado la programación de turnos de este periodo para tu establecimiento.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: [
                    // Tarjeta de Resumen Mensual (Limpia y amigable)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildKpiTurno(
                              icon: Icons.calendar_month_outlined,
                              titulo: 'Laborables',
                              valor: '${rol.diasProgramados} días',
                              color: AppColors.primary,
                            ),
                            Container(width: 1, height: 30, color: Colors.grey.shade200),
                            _buildKpiTurno(
                              icon: Icons.schedule_outlined,
                              titulo: 'Horas Mes',
                              valor: '${rol.totalHoras} h',
                              color: const Color(0xFF0D9488),
                            ),
                            Container(width: 1, height: 30, color: Colors.grey.shade200),
                            _buildKpiTurno(
                              icon: rol.rolCerrado ? Icons.verified_rounded : Icons.pending_actions_rounded,
                              titulo: 'Estado',
                              valor: rol.rolCerrado ? 'Aprobado' : 'Borrador',
                              color: rol.rolCerrado ? AppColors.success : AppColors.warning,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Grid de Días del Mes
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 0.9,
                        ),
                        itemCount: rol.turnos.length,
                        itemBuilder: (context, index) {
                          final turno = rol.turnos[index];
                          final diaSemana = turno.nombreDia != null && turno.nombreDia!.isNotEmpty
                              ? (turno.nombreDia!.length >= 3 ? turno.nombreDia!.substring(0, 3) : turno.nombreDia!)
                              : '';

                          return Card(
                            elevation: 0.8,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: turno.sigla == 'D' ? Colors.grey.shade200 : AppColors.primary.withOpacity(0.2),
                              ),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () => _showTurnoDetails(context, turno, rol),
                              child: Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      diaSemana.isNotEmpty ? '$diaSemana ${turno.dia}' : 'Día ${turno.dia}',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                        color: turno.sigla == 'D' ? AppColors.textSecondary : AppColors.primaryDark,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    TurnoBadge(sigla: turno.sigla, size: 30),
                                    const SizedBox(height: 3),
                                    Text(
                                      turno.totalHoras > 0 ? '${turno.totalHoras}h' : (turno.sigla == 'D' ? 'Libre' : turno.sigla),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                        color: turno.totalHoras > 0 ? AppColors.textPrimary : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiTurno({
    required IconData icon,
    required String titulo,
    required String valor,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            Text(valor, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ],
    );
  }

  void _showTurnoDetails(BuildContext context, TurnoDiaRol turno, RolMensual rol) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Barra de cabecera
              Row(
                children: [
                  TurnoBadge(sigla: turno.sigla, size: 44),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          turno.nombreDia != null ? '${turno.nombreDia} ${turno.dia}' : 'Día ${turno.dia}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.getTextPrimary(ctx),
                          ),
                        ),
                        Text(
                          turno.fecha,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.getTextSecondary(ctx),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: rol.rolCerrado ? AppColors.successBg : AppColors.warningBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      rol.rolCerrado ? 'OFICIAL' : 'BORRADOR',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: rol.rolCerrado ? AppColors.success : AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Detalle del Turno
              _buildFilaDetalle(
                context: ctx,
                icono: Icons.label_outline_rounded,
                titulo: 'Turno Asignado',
                contenido: turno.descripcion ?? (turno.sigla == 'D' ? 'Día de Descanso / Libre' : turno.sigla),
              ),
              const SizedBox(height: 12),

              _buildFilaDetalle(
                context: ctx,
                icono: Icons.schedule_rounded,
                titulo: 'Horario Programado',
                contenido: turno.horario != null && turno.horario!.isNotEmpty
                    ? '${turno.horario} (${turno.totalHoras} horas)'
                    : (turno.totalHoras > 0 ? '${turno.totalHoras} horas' : 'Sin horario de ingreso (No laborable)'),
              ),
              const SizedBox(height: 12),

              _buildFilaDetalle(
                context: ctx,
                icono: Icons.verified_user_outlined,
                titulo: 'Programación',
                contenido: turno.sigla == 'D'
                    ? 'Día libre programado según rol de turnos'
                    : 'Turno programado por la jefatura de tu establecimiento',
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Entendido'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilaDetalle({
    required BuildContext context,
    required IconData icono,
    required String titulo,
    required String contenido,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo, style: TextStyle(fontSize: 11, color: AppColors.getTextSecondary(context), fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(contenido, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.getTextPrimary(context))),
            ],
          ),
        ),
      ],
    );
  }
}

class _LeyendaItem extends StatelessWidget {
  final String sigla;
  final String nombre;

  const _LeyendaItem({required this.sigla, required this.nombre});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TurnoBadge(sigla: sigla, size: 20),
        const SizedBox(width: 4),
        Text(nombre, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}
