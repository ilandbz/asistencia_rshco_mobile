import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../../../core/theme/app_theme.dart';
import '../controllers/asistencia_controller.dart';
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
      ),
      body: Column(
        children: [
          // Selector de Mes y Año
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: () {
                    final prevMes = filter.mes == 1 ? 12 : filter.mes - 1;
                    final prevAnio = filter.mes == 1 ? filter.anio - 1 : filter.anio;
                    ref.read(currentFilterProvider.notifier).state =
                        MonthYearFilter(mes: prevMes, anio: prevAnio);
                  },
                ),
                Text(
                  '${meses[filter.mes - 1]} ${filter.anio}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
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

          // Leyenda de Siglas
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.surfaceVariant.withOpacity(0.5),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: const [
                  _LeyendaItem(sigla: 'M', nombre: 'Mañana'),
                  SizedBox(width: 12),
                  _LeyendaItem(sigla: 'T', nombre: 'Tarde'),
                  SizedBox(width: 12),
                  _LeyendaItem(sigla: 'N', nombre: 'Noche'),
                  SizedBox(width: 12),
                  _LeyendaItem(sigla: 'GD', nombre: 'Guardia D.'),
                  SizedBox(width: 12),
                  _LeyendaItem(sigla: 'GN', nombre: 'Guardia N.'),
                  SizedBox(width: 12),
                  _LeyendaItem(sigla: 'D', nombre: 'Descanso'),
                ],
              ),
            ),
          ),

          // Calendario Grid
          Expanded(
            child: rolAsync.when(
              loading: () => const Center(
                child: SpinKitRing(color: AppColors.primary, size: 36),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text('Error al cargar rol mensual: $err'),
                ),
              ),
              data: (rol) {
                if (rol.turnos.isEmpty) {
                  return const Center(
                    child: Text('No hay turnos programados en este mes.'),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: rol.turnos.length,
                  itemBuilder: (context, index) {
                    final turno = rol.turnos[index];
                    return Card(
                      elevation: 1,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          _showTurnoDetails(context, turno);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Día ${turno.dia}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TurnoBadge(sigla: turno.sigla, size: 36),
                              const SizedBox(height: 4),
                              if (turno.esGuardia)
                                const Text(
                                  'GUARDIA',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.turnoGuardia,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showTurnoDetails(BuildContext context, dynamic turno) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  TurnoBadge(sigla: turno.sigla, size: 40),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Turno: ${turno.sigla}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Fecha: ${turno.fecha}',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (turno.horario != null)
                Text('Horario de programación: ${turno.horario}'),
              if (turno.descripcion != null)
                Text('Detalle: ${turno.descripcion}'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        );
      },
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
