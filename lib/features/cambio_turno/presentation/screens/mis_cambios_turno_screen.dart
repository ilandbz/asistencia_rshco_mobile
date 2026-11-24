import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../../../core/theme/app_theme.dart';
import '../controllers/cambio_turno_controller.dart';
import 'solicitar_cambio_turno_screen.dart';

class MisCambiosTurnoScreen extends ConsumerWidget {
  const MisCambiosTurnoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final solicitudesAsync = ref.watch(misCambiosTurnoProvider);
    final filtro = ref.watch(filtroEstadoCambioProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cambios de Turno'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(misCambiosTurnoProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Nueva Solicitud', style: TextStyle(color: Colors.white)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SolicitarCambioTurnoScreen()),
          ).then((_) => ref.invalidate(misCambiosTurnoProvider));
        },
      ),
      body: Column(
        children: [
          // Barra de Filtros por Estado
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildFilterChip(context, ref, label: 'Todos', value: null, selected: filtro == null),
                const SizedBox(width: 8),
                _buildFilterChip(context, ref, label: 'Solicitados', value: 'SOLICITADO', selected: filtro == 'SOLICITADO'),
                const SizedBox(width: 8),
                _buildFilterChip(context, ref, label: 'Aprobados', value: 'APROBADO', selected: filtro == 'APROBADO'),
                const SizedBox(width: 8),
                _buildFilterChip(context, ref, label: 'Rechazados', value: 'RECHAZADO', selected: filtro == 'RECHAZADO'),
                const SizedBox(width: 8),
                _buildFilterChip(context, ref, label: 'Ejecutados', value: 'EJECUTADO', selected: filtro == 'EJECUTADO'),
              ],
            ),
          ),
          const Divider(height: 1),

          // Lista de Solicitudes
          Expanded(
            child: solicitudesAsync.when(
              loading: () => const Center(child: SpinKitRing(color: AppColors.primary, size: 36)),
              error: (err, _) => Center(child: Text('Error al obtener solicitudes: $err')),
              data: (solicitudes) {
                if (solicitudes.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text(
                        'No tienes solicitudes de cambio de turno registradas.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: solicitudes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = solicitudes[index];
                    return _buildSolicitudCard(item);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    WidgetRef ref, {
    required String label,
    required String? value,
    required bool selected,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: AppColors.primary.withOpacity(0.15),
      labelStyle: TextStyle(
        color: selected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (_) {
        ref.read(filtroEstadoCambioProvider.notifier).state = value;
      },
    );
  }

  Widget _buildSolicitudCard(dynamic item) {
    Color estadoColor = AppColors.info;
    if (item.estado == 'APROBADO') estadoColor = AppColors.success;
    if (item.estado == 'RECHAZADO') estadoColor = AppColors.error;
    if (item.estado == 'EJECUTADO') estadoColor = Colors.teal;

    return Card(
      elevation: 1.5,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Solicitud #${item.id}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: estadoColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: estadoColor, width: 1),
                  ),
                  child: Text(
                    item.estado,
                    style: TextStyle(color: estadoColor, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Mi turno a ceder:', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      const SizedBox(height: 2),
                      Text(
                        '${item.fechaMiTurno} (${item.miTurnoSigla})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.sync_alt_rounded, color: AppColors.primary, size: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Turno de colega:', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      const SizedBox(height: 2),
                      Text(
                        '${item.fechaTurnoColega} (${item.colegaTurnoSigla})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.person_outline_rounded, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Colega: ${item.colegaNombre} (DNI ${item.colegaDni})',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
            if (item.motivo.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Motivo: ${item.motivo}',
                style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textSecondary),
              ),
            ],
            if (item.motivoRechazo != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.errorBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Observación: ${item.motivoRechazo}',
                  style: const TextStyle(fontSize: 11, color: AppColors.error),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
