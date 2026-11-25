import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../../../core/theme/app_theme.dart';
import '../controllers/asistencia_controller.dart';
import '../widgets/turno_badge.dart';

class AsistenciaScreen extends ConsumerWidget {
  const AsistenciaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final marcacionAsync = ref.watch(marcacionHoyProvider);
    final resumenAsync = ref.watch(faltasTardanzasProvider);
    final registrosAsync = ref.watch(misRegistrosProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Asistencia y Marcaciones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.invalidate(marcacionHoyProvider);
              ref.invalidate(faltasTardanzasProvider);
              ref.invalidate(misRegistrosProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(marcacionHoyProvider);
          ref.invalidate(faltasTardanzasProvider);
          ref.invalidate(misRegistrosProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Tarjeta Marcación de Hoy
              marcacionAsync.when(
                loading: () => const Card(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(child: SpinKitRing(color: AppColors.primary, size: 36)),
                  ),
                ),
                error: (err, _) => Card(
                  color: AppColors.errorBg,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Error al cargar marcación de hoy: $err',
                        style: const TextStyle(color: AppColors.error)),
                  ),
                ),
                data: (hoy) => _buildHoyCard(context, hoy),
              ),
              const SizedBox(height: 20),

              // 2. Resumen de Faltas y Tardanzas
              resumenAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (resumen) => _buildResumenCard(context, resumen),
              ),
              const SizedBox(height: 20),

              // 3. Historial de Registros del Mes
              Text(
                'Registros de Asistencia del Mes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getTextPrimary(context),
                ),
              ),
              const SizedBox(height: 12),

              registrosAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: SpinKitRing(color: AppColors.primary, size: 36),
                  ),
                ),
                error: (err, _) => Center(
                  child: Text('No se pudieron obtener registros: $err'),
                ),
                data: (registros) {
                  if (registros.isEmpty) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Center(
                          child: Text(
                            'No hay registros procesados para este período.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: registros.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = registros[index];
                      return _buildRegistroTile(context, item);
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

  Widget _buildHoyCard(BuildContext context, dynamic hoy) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final estadoColor = hoy.estado == 'MARCADO' || hoy.estado == 'ASISTIO'
        ? (isDark ? const Color(0xFF4ADE80) : AppColors.success)
        : (hoy.estado == 'TARDANZA'
            ? (isDark ? const Color(0xFFFBBF24) : AppColors.warning)
            : (isDark ? const Color(0xFF38BDF8) : AppColors.primary));

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.access_time_filled_rounded,
                      color: isDark ? const Color(0xFF38BDF8) : AppColors.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      hoy.fecha.isNotEmpty ? 'Fecha: ${hoy.fecha}' : 'Marcación de Hoy',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isDark ? const Color(0xFFF8FAFC) : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: estadoColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: estadoColor, width: 1),
                  ),
                  child: Text(
                    hoy.estado,
                    style: TextStyle(
                      color: estadoColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                if (hoy.turnoProgramado != null) ...[
                  TurnoBadge(sigla: hoy.turnoProgramado!, size: 40),
                  const SizedBox(width: 14),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hoy.turnoNombre != null && hoy.turnoNombre!.isNotEmpty
                            ? 'Turno: ${hoy.turnoNombre}'
                            : (hoy.turnoProgramado != null
                                ? 'Turno: ${hoy.turnoProgramado}'
                                : 'Turno: Sin programar'),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: isDark ? const Color(0xFFF8FAFC) : AppColors.textPrimary,
                        ),
                      ),
                      if (hoy.horaEntradaProgramada != null && hoy.horaSalidaProgramada != null)
                        Text(
                          'Horario: ${hoy.horaEntradaProgramada} - ${hoy.horaSalidaProgramada}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTimeBox(
                  context: context,
                  label: 'Primer Ingreso',
                  time: hoy.primerIngreso ?? '--:--',
                  icon: Icons.login_rounded,
                  color: isDark ? const Color(0xFF4ADE80) : AppColors.success,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: isDark ? const Color(0xFF334155) : AppColors.border,
                ),
                _buildTimeBox(
                  context: context,
                  label: 'Último Egreso',
                  time: hoy.ultimoEgreso ?? '--:--',
                  icon: Icons.logout_rounded,
                  color: isDark ? const Color(0xFF38BDF8) : AppColors.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeBox({
    required BuildContext context,
    required String label,
    required String time,
    required IconData icon,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          time,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: time == '--:--'
                ? (isDark ? const Color(0xFF64748B) : AppColors.textMuted)
                : AppColors.getTextPrimary(context),
          ),
        ),
      ],
    );
  }

  Widget _buildResumenCard(BuildContext context, dynamic resumen) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 1,
      color: isDark ? const Color(0xFF1E293B) : AppColors.surfaceVariant.withOpacity(0.5),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen Mensual de Asistencia',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.getTextPrimary(context),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    context: context,
                    label: 'Minutos Tardanza',
                    value: '${resumen.minutosTardanzaTotal} min',
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricTile(
                    context: context,
                    label: 'N° Tardanzas',
                    value: '${resumen.conteoTardanzas}',
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricTile(
                    context: context,
                    label: 'Faltas',
                    value: '${resumen.faltasTotal}',
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required BuildContext context,
    required String label,
    required String value,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegistroTile(BuildContext context, dynamic item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color badgeColor = AppColors.turnoDescanso;
    if (item.estado == 'ASISTIO') badgeColor = isDark ? const Color(0xFF4ADE80) : AppColors.success;
    if (item.estado == 'TARDANZA') badgeColor = isDark ? const Color(0xFFFBBF24) : AppColors.warning;
    if (item.estado == 'FALTA') badgeColor = isDark ? const Color(0xFFF87171) : AppColors.error;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
        child: Row(
          children: [
            TurnoBadge(sigla: item.turno, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${item.diaNombre} ${item.fecha}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: isDark ? const Color(0xFFF8FAFC) : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Ingreso: ${item.entrada ?? "--:--"} | Salida: ${item.salida ?? "--:--"}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                item.estado,
                style: TextStyle(color: badgeColor, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
