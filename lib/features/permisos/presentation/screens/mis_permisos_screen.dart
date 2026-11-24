import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../../../core/theme/app_theme.dart';
import '../controllers/permisos_controller.dart';
import '../widgets/barra_progreso_cit_widget.dart';
import 'solicitar_permiso_screen.dart';

class MisPermisosScreen extends ConsumerWidget {
  const MisPermisosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resumenCitAsync = ref.watch(resumenCitProvider);
    final permisosAsync = ref.watch(misPermisosProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Permisos & Descansos Médicos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.invalidate(resumenCitProvider);
              ref.invalidate(misPermisosProvider);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.note_add_rounded, color: Colors.white),
        label: const Text('Solicitar Permiso / CIT', style: TextStyle(color: Colors.white)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SolicitarPermisoScreen()),
          ).then((_) {
            ref.invalidate(resumenCitProvider);
            ref.invalidate(misPermisosProvider);
          });
        },
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(resumenCitProvider);
          ref.invalidate(misPermisosProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Resumen de Días CIT y Regla de 20 Días
              resumenCitAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: SpinKitRing(color: AppColors.primary, size: 30),
                  ),
                ),
                error: (err, _) => const SizedBox.shrink(),
                data: (resumen) => BarraProgresoCitWidget(resumen: resumen),
              ),
              const SizedBox(height: 20),

              // 2. Historial de Permisos Registrados
              const Text(
                'Mis Solicitudes de Permiso',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              permisosAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: SpinKitRing(color: AppColors.primary, size: 36),
                  ),
                ),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Error al cargar historial: $err'),
                  ),
                ),
                data: (permisos) {
                  if (permisos.isEmpty) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Center(
                          child: Text(
                            'No tienes solicitudes de permisos registradas.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: permisos.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = permisos[index];
                      return _buildPermisoTile(item);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermisoTile(dynamic item) {
    Color estadoColor = AppColors.warning;
    if (item.estado == 'APROBADO') estadoColor = AppColors.success;
    if (item.estado == 'RECHAZADO') estadoColor = AppColors.error;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item.tipoNombre,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            const SizedBox(height: 6),
            Text(
              'Período: ${item.fechaInicio} al ${item.fechaFin} (${item.dias} días)',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            if (item.cittNumero != null && item.cittNumero!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'N° CITT EsSalud: ${item.cittNumero}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
              ),
            ],
            if (item.motivo.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Motivo: ${item.motivo}',
                style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textMuted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
