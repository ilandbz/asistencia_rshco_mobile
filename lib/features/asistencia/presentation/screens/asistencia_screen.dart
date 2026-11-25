import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../../../core/theme/app_theme.dart';
import '../controllers/asistencia_controller.dart';
import '../../data/models/asistencia_model.dart';
import '../widgets/turno_badge.dart';

class AsistenciaScreen extends ConsumerWidget {
  const AsistenciaScreen({super.key});

  static const List<String> _meses = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Setiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(currentFilterProvider);
    final marcacionAsync = ref.watch(marcacionHoyProvider);
    final resumenAsync = ref.watch(faltasTardanzasProvider);
    final registrosAsync = ref.watch(misRegistrosProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Asistencia y Marcaciones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualizar',
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
                error: (_, __) => Card(
                  color: isDark ? const Color(0xFF450A0A) : AppColors.errorBg,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'No pudimos consultar tu marcación de hoy en este momento.',
                      style: TextStyle(color: isDark ? const Color(0xFFFCA5A5) : AppColors.error),
                    ),
                  ),
                ),
                data: (hoy) => _buildHoyCard(context, hoy),
              ),
              const SizedBox(height: 16),

              // 2. Selector de Mes y Año para el Historial y Resumen
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : AppColors.border,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.chevron_left_rounded,
                        color: isDark ? const Color(0xFFF8FAFC) : AppColors.primary,
                      ),
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
                          '${_meses[filter.mes - 1]} ${filter.anio}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark ? const Color(0xFF38BDF8) : AppColors.primary,
                          ),
                        ),
                        Text(
                          'Periodo consultado',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: AppColors.getTextSecondary(context),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.chevron_right_rounded,
                        color: isDark ? const Color(0xFFF8FAFC) : AppColors.primary,
                      ),
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
              const SizedBox(height: 16),

              // 3. Resumen de Faltas y Tardanzas
              resumenAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (resumen) => _buildResumenCard(context, resumen),
              ),
              const SizedBox(height: 20),

              // 4. Historial de Registros del Mes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Registros de Asistencia del Mes',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.getTextPrimary(context),
                    ),
                  ),
                  Text(
                    'Toca un día para ver detalle',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.getTextSecondary(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              registrosAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: SpinKitRing(color: AppColors.primary, size: 36),
                  ),
                ),
                error: (_, __) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      'No se pudieron obtener los registros de asistencia en este momento. Desliza hacia abajo para reintentar.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.getTextSecondary(context)),
                    ),
                  ),
                ),
                data: (registrosRaw) {
                  // Filtrar días no laborables sin actividad y ordenar de más reciente a más antiguo
                  final registros = registrosRaw
                      .where((item) => item.debeMostrarEnHistorial)
                      .toList()
                    ..sort((a, b) {
                      final dateA = DateTime.tryParse(a.fecha);
                      final dateB = DateTime.tryParse(b.fecha);
                      if (dateA != null && dateB != null) {
                        return dateB.compareTo(dateA);
                      }
                      return b.fecha.compareTo(a.fecha);
                    });

                  if (registros.isEmpty) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Center(
                          child: Text(
                            'No hay asistencias registradas aún para ${_meses[filter.mes - 1].toLowerCase()} ${filter.anio}.',
                            style: TextStyle(color: AppColors.getTextSecondary(context)),
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

  String _formatearFechaTitulo(String diaNombre, String fecha) {
    String fechaStr = fecha;
    final parts = fecha.split('-');
    if (parts.length == 3) {
      fechaStr = '${parts[2]}/${parts[1]}/${parts[0]}';
    }

    final hoy = DateTime.now();
    final hoyStr =
        '${hoy.year.toString().padLeft(4, '0')}-${hoy.month.toString().padLeft(2, '0')}-${hoy.day.toString().padLeft(2, '0')}';
    final esHoy = fecha == hoyStr;

    final dia = diaNombre.isNotEmpty ? diaNombre : '';
    if (dia.isNotEmpty) {
      return esHoy ? '$dia • $fechaStr (HOY)' : '$dia • $fechaStr';
    }
    return esHoy ? '$fechaStr (HOY)' : fechaStr;
  }

  ({Color color, String text}) _resolveEstadoVisual(String estado, bool isDark) {
    final estadoUpper = estado.toUpperCase();
    switch (estadoUpper) {
      case 'MARCADO':
      case 'ASISTIO':
        return (
          color: isDark ? const Color(0xFF4ADE80) : AppColors.success,
          text: 'ASISTIÓ',
        );
      case 'TARDANZA':
        return (
          color: isDark ? const Color(0xFFFBBF24) : AppColors.warning,
          text: 'TARDANZA',
        );
      case 'FALTA':
        return (
          color: isDark ? const Color(0xFFF87171) : AppColors.error,
          text: 'FALTA',
        );
      case 'PERMISO':
        return (
          color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
          text: 'PERMISO',
        );
      case 'FERIADO':
        return (
          color: isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0D9488),
          text: 'FERIADO',
        );
      case 'PENDIENTE':
        return (
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          text: 'PENDIENTE',
        );
      case 'SIN_HORARIO':
        return (
          color: isDark ? const Color(0xFF94A3B8) : AppColors.turnoDescanso,
          text: 'DESCANSO',
        );
      default:
        if (estadoUpper.startsWith('SIN_MARCACION')) {
          return (
            color: isDark ? const Color(0xFFFBBF24) : AppColors.warning,
            text: 'SIN MARCAR',
          );
        }
        return (
          color: isDark ? const Color(0xFF38BDF8) : AppColors.primary,
          text: estadoUpper,
        );
    }
  }

  Widget _buildHoyCard(BuildContext context, MarcacionHoy hoy) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final visual = _resolveEstadoVisual(hoy.estado, isDark);
    final estadoTexto =
        hoy.estado.toUpperCase() == 'PERMISO' ? 'CON PERMISO' : visual.text;

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
                      hoy.fecha.isNotEmpty ? 'Hoy: ${hoy.fecha}' : 'Marcación de Hoy',
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
                    color: visual.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: visual.color, width: 1),
                  ),
                  child: Text(
                    estadoTexto,
                    style: TextStyle(
                      color: visual.color,
                      fontSize: 11.5,
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
                      if (hoy.permisoDescripcion != null && hoy.permisoDescripcion!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2.0),
                          child: Text(
                            'Motivo: ${hoy.permisoDescripcion}',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                            ),
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

  Widget _buildResumenCard(BuildContext context, FaltasTardanzasResumen resumen) {
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
                    label: 'Días Asistidos',
                    value: '${resumen.diasAsistidos}',
                    color: isDark ? const Color(0xFF4ADE80) : AppColors.success,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricTile(
                    context: context,
                    label: 'Tardanzas',
                    value: resumen.minutosTardanzaTotal > 0
                        ? '${resumen.conteoTardanzas} (${resumen.minutosTardanzaTotal}m)'
                        : '${resumen.conteoTardanzas}',
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

  Widget _buildRegistroTile(BuildContext context, RegistroAsistenciaItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final estadoUpper = item.estado.toUpperCase();
    final visual = _resolveEstadoVisual(item.estado, isDark);

    String subtitulo;
    if (item.detalleTurnos != null && item.detalleTurnos!.isNotEmpty) {
      subtitulo = item.detalleTurnos!;
    } else if (item.entrada != null || item.salida != null) {
      subtitulo = 'Ingreso: ${item.entrada ?? "--:--"} | Salida: ${item.salida ?? "--:--"}';
    } else if (estadoUpper == 'PERMISO') {
      subtitulo = item.permisoNombre != null && item.permisoNombre!.isNotEmpty
          ? 'Permiso: ${item.permisoNombre}'
          : 'Con permiso autorizado';
    } else if (estadoUpper == 'FERIADO') {
      subtitulo = 'Día feriado calendario';
    } else if (estadoUpper == 'SIN_HORARIO') {
      subtitulo = 'Sin turno programado';
    } else if (estadoUpper == 'PENDIENTE') {
      subtitulo = 'Turno programado por cumplir';
    } else if (estadoUpper == 'FALTA') {
      subtitulo = 'Sin marcaciones registradas';
    } else {
      subtitulo = 'Ingreso: --:-- | Salida: --:--';
    }

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _mostrarDetalleRegistro(context, item),
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
                      _formatearFechaTitulo(item.diaNombre, item.fecha),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: isDark ? const Color(0xFFF8FAFC) : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitulo,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                      ),
                    ),
                    if (item.minutosTardanza > 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Tardanza acumulada: ${item.minutosTardanza} min',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFFFBBF24) : AppColors.warning,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: visual.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: visual.color.withOpacity(0.35), width: 0.8),
                ),
                child: Text(
                  visual.text,
                  style: TextStyle(
                    color: visual.color,
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: isDark ? const Color(0xFF64748B) : AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarDetalleRegistro(
      BuildContext context, RegistroAsistenciaItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final visual = _resolveEstadoVisual(item.estado, isDark);
    final estadoUpper = item.estado.toUpperCase();

    final tipoJornada = item.esGuardia
        ? 'Guardia'
        : (item.esFeriado
            ? 'Feriado'
            : (item.esLaborable ? 'Laborable' : 'Descanso'));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.72,
          minChildSize: 0.45,
          maxChildSize: 0.92,
          expand: false,
          builder: (_, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Barra de arrastre
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF475569) : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 1. Cabecera del día
                  Row(
                    children: [
                      TurnoBadge(sigla: item.turno, size: 44),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatearFechaTitulo(item.diaNombre, item.fecha),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? const Color(0xFFF8FAFC) : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.turnoNombre ??
                                  (estadoUpper == 'SIN_HORARIO'
                                      ? 'Día sin turno programado'
                                      : 'Jornada de asistencia'),
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: visual.color.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: visual.color.withOpacity(0.5)),
                        ),
                        child: Text(
                          visual.text,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: visual.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 2. Indicadores rápidos del día
                  Row(
                    children: [
                      Expanded(
                        child: _buildDetalleKpi(
                          isDark: isDark,
                          label: 'Horas prog.',
                          value: '${item.totalHoras} h',
                          color: isDark ? const Color(0xFF38BDF8) : AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildDetalleKpi(
                          isDark: isDark,
                          label: 'Tardanza',
                          value: '${item.minutosTardanza} min',
                          color: item.minutosTardanza > 0
                              ? (isDark ? const Color(0xFFFBBF24) : AppColors.warning)
                              : (isDark ? const Color(0xFF4ADE80) : AppColors.success),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildDetalleKpi(
                          isDark: isDark,
                          label: 'Jornada',
                          value: tipoJornada,
                          color: isDark ? const Color(0xFFF8FAFC) : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),

                  // 3. Aviso de falta o incidencia si corresponde
                  if (estadoUpper == 'FALTA' || item.faltasDia > 0 || item.tieneIncidencia) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF450A0A).withOpacity(0.5) : AppColors.errorBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? const Color(0xFFDC2626).withOpacity(0.5) : AppColors.error.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 20,
                            color: isDark ? const Color(0xFFF87171) : AppColors.error,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item.tieneIncidencia
                                  ? 'Este día presenta una incidencia registrada en control de asistencia.'
                                  : 'No se encontraron marcaciones registradas para cumplir el horario programado de este día.',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? const Color(0xFFFECACA) : AppColors.error,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // 4. Permiso / Licencia autorizada (si aplica)
                  if (item.permiso != null) ...[
                    const SizedBox(height: 16),
                    _buildPermisoDetalleBox(isDark, item.permiso!),
                  ],

                  const SizedBox(height: 18),
                  Divider(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200),
                  const SizedBox(height: 12),

                  // 5. Detalle por cada turno programado
                  Text(
                    'Turnos Programados del Día',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFFF8FAFC) : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),

                  if (item.turnosDetalle.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Text(
                        estadoUpper == 'FERIADO'
                            ? 'Día feriado no laborable según calendario oficial.'
                            : 'No tienes turnos laborales programados para esta fecha.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                        ),
                      ),
                    )
                  else
                    ...item.turnosDetalle.map(
                      (td) => _buildTurnoDetalleCard(isDark, td),
                    ),

                  const SizedBox(height: 18),

                  // 6. Todas las marcaciones registradas en reloj biométrico
                  Text(
                    'Marcaciones Registradas en Reloj (${item.marcaciones.length})',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFFF8FAFC) : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),

                  if (item.marcaciones.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Text(
                        'No se registraron marcaciones en el reloj biométrico para este día.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                        ),
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        children: List.generate(item.marcaciones.length, (i) {
                          final m = item.marcaciones[i];
                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.fingerprint_rounded,
                                      size: 18,
                                      color: isDark
                                          ? const Color(0xFF38BDF8)
                                          : AppColors.primary,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Registro ${i + 1}',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w500,
                                          color: isDark
                                              ? const Color(0xFFCBD5E1)
                                              : AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      m.hora,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? const Color(0xFFF8FAFC)
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (i < item.marcaciones.length - 1)
                                Divider(
                                  height: 1,
                                  color: isDark
                                      ? const Color(0xFF1E293B)
                                      : const Color(0xFFE2E8F0),
                                ),
                            ],
                          );
                        }),
                      ),
                    ),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isDark ? const Color(0xFF0284C7) : AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text(
                        'Cerrar',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetalleKpi({
    required bool isDark,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermisoDetalleBox(bool isDark, PermisoDiaResumen permiso) {
    final accentColor = isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7);
    final vigencia = (permiso.fechaDesde != null && permiso.fechaHasta != null)
        ? (permiso.fechaDesde == permiso.fechaHasta
            ? permiso.fechaDesde!
            : 'Del ${permiso.fechaDesde} al ${permiso.fechaHasta}')
        : null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0C4A6E).withOpacity(0.28) : const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF0284C7).withOpacity(0.5) : const Color(0xFFBAE6FD),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event_available_rounded, size: 18, color: accentColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  permiso.tipoPermiso,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFFF8FAFC) : AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  permiso.estado,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
          if (vigencia != null) ...[
            const SizedBox(height: 6),
            Text(
              'Vigencia: $vigencia${permiso.totalDias > 0 ? " (${permiso.totalDias} día(s))" : ""}',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? const Color(0xFFCBD5E1) : AppColors.textSecondary,
              ),
            ),
          ],
          if (permiso.motivo != null && permiso.motivo!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Motivo: ${permiso.motivo}',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? const Color(0xFFE2E8F0) : AppColors.textPrimary,
              ),
            ),
          ],
          if (permiso.numeroCertificado != null &&
              permiso.numeroCertificado!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'N° Certificado: ${permiso.numeroCertificado}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: accentColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTurnoDetalleCard(bool isDark, TurnoDetalleAsistencia td) {
    final visual = _resolveEstadoVisual(td.estado, isDark);
    final horarioProg = (td.horaProgEntrada != null && td.horaProgSalida != null)
        ? '${td.horaProgEntrada} a ${td.horaProgSalida}'
        : 'Horario no definido';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TurnoBadge(sigla: td.abreviatura, size: 30),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      td.nombre,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFFF8FAFC) : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Horario: $horarioProg',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: visual.color.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  visual.text,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: visual.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildMarcacionMini(
                  isDark: isDark,
                  titulo: 'Ingreso marcado',
                  valor: td.horaMarcEntrada ?? 'No registrado',
                  registrado: td.horaMarcEntrada != null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMarcacionMini(
                  isDark: isDark,
                  titulo: 'Salida marcada',
                  valor: td.horaMarcSalida ?? 'No registrado',
                  registrado: td.horaMarcSalida != null,
                ),
              ),
            ],
          ),
          if (td.toleranciaMinutos > 0 || td.minutosTardanza > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (td.toleranciaMinutos > 0)
                  Text(
                    'Tolerancia de ingreso: ${td.toleranciaMinutos} min',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                    ),
                  ),
                if (td.minutosTardanza > 0)
                  Text(
                    'Tardanza: ${td.minutosTardanza} min',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFFFBBF24) : AppColors.warning,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMarcacionMini({
    required bool isDark,
    required String titulo,
    required String valor,
    required bool registrado,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: TextStyle(
              fontSize: 10.5,
              color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            valor,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: registrado
                  ? (isDark ? const Color(0xFFF8FAFC) : AppColors.textPrimary)
                  : (isDark ? const Color(0xFF64748B) : AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
