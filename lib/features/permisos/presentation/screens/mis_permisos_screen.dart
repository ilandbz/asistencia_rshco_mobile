import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../../../core/theme/app_theme.dart';
import '../controllers/permisos_controller.dart';
import '../../data/models/permiso_model.dart';
import '../widgets/barra_progreso_cit_widget.dart';
import 'solicitar_permiso_screen.dart';

class MisPermisosScreen extends ConsumerStatefulWidget {
  const MisPermisosScreen({super.key});

  @override
  ConsumerState<MisPermisosScreen> createState() => _MisPermisosScreenState();
}

class _MisPermisosScreenState extends ConsumerState<MisPermisosScreen> {
  // 0: Descansos Médicos & CITT, 1: Todos los Permisos del Personal
  int _filtroIndex = 0;

  void _abrirRegistroDescanso() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SolicitarPermisoScreen()),
    ).then((_) {
      ref.invalidate(resumenCitProvider);
      ref.invalidate(misPermisosProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final resumenCitAsync = ref.watch(resumenCitProvider);
    final permisosAsync = ref.watch(misPermisosProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        title: const Text('Descansos Médicos & CITT'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualizar',
            onPressed: () {
              ref.invalidate(resumenCitProvider);
              ref.invalidate(misPermisosProvider);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        elevation: 3,
        icon: const Icon(Icons.document_scanner_rounded, color: Colors.white, size: 20),
        label: const Text(
          'Registrar CITT / Licencia',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
        ),
        onPressed: _abrirRegistroDescanso,
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
              // 1. Resumen de Días CIT y Regla de los 20 Días del Empleador
              resumenCitAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: SpinKitRing(color: AppColors.primary, size: 26),
                  ),
                ),
                error: (err, _) => const SizedBox.shrink(),
                data: (resumen) => BarraProgresoCitWidget(resumen: resumen),
              ),
              const SizedBox(height: 20),

              // 2. Selector de Filtro: Descansos Médicos vs Todos los Permisos
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(9),
                        onTap: () => setState(() => _filtroIndex = 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _filtroIndex == 0 ? AppColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Center(
                            child: Text(
                              'Descansos Médicos (CITT)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _filtroIndex == 0
                                    ? Colors.white
                                    : (isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(9),
                        onTap: () => setState(() => _filtroIndex = 1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _filtroIndex == 1 ? AppColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Center(
                            child: Text(
                              'Todos los Permisos',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _filtroIndex == 1
                                    ? Colors.white
                                    : (isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 3. Encabezado de la Sección
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _filtroIndex == 0 ? 'Descansos Médicos Registrados' : 'Historial de Permisos del Servidor',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.getTextPrimary(context),
                    ),
                  ),
                  Text(
                    'Control Asistencia',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.getTextMuted(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // 4. Lista de Registros Filtrados
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
                    child: Text(
                      'Error al cargar el historial de registros',
                      style: TextStyle(color: AppColors.error, fontSize: 13),
                    ),
                  ),
                ),
                data: (permisos) {
                  final items = _filtroIndex == 0
                      ? permisos.where((p) => p.esDescansoMedico).toList()
                      : permisos;

                  if (items.isEmpty) {
                    if (_filtroIndex == 0) {
                      return Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.health_and_safety_rounded,
                                  size: 40,
                                  color: AppColors.success,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'No registra descansos médicos en 2026',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.5,
                                  color: isDark ? const Color(0xFFF8FAFC) : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Sus 20 días asumidos por la Red de Salud Huánuco están 100% disponibles. Para reportar una licencia médica, utilice el botón inferior.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.assignment_outlined, size: 36, color: AppColors.primary),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Sin permisos registrados',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: isDark ? const Color(0xFFF8FAFC) : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _buildPermisoTile(item, isDark);
                    },
                  );
                },
              ),
              const SizedBox(height: 70), // Espacio para no tapar con el botón flotante
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermisoTile(SolicitudPermisoItem item, bool isDark) {
    Color estadoColor = AppColors.warning;
    final est = item.estado.toUpperCase();
    if (est.contains('APROBADO')) estadoColor = AppColors.success;
    if (est.contains('RECHAZADO')) estadoColor = AppColors.error;

    // Icono según la naturaleza del permiso
    IconData iconData = Icons.description_outlined;
    Color iconColor = AppColors.primary;
    if (item.esDescansoMedico) {
      iconData = Icons.medical_services_rounded;
      iconColor = const Color(0xFF0284C7);
    } else if (item.tipoNombre.toUpperCase().contains('ONOMASTICO')) {
      iconData = Icons.cake_outlined;
      iconColor = Colors.amber.shade700;
    } else if (item.tipoNombre.toUpperCase().contains('MEMORANDUM')) {
      iconData = Icons.assignment_outlined;
      iconColor = Colors.indigo;
    } else if (item.tipoNombre.toUpperCase().contains('HORAS')) {
      iconData = Icons.schedule_outlined;
      iconColor = Colors.teal;
    }

    // Formateo de fechas
    String periodoTexto;
    if (item.fechaInicio.isNotEmpty && item.fechaFin.isNotEmpty) {
      if (item.fechaInicio == item.fechaFin) {
        periodoTexto = 'Fecha: ${item.fechaInicio}';
      } else {
        periodoTexto = 'Período: ${item.fechaInicio} al ${item.fechaFin}';
      }
    } else if (item.fechaInicio.isNotEmpty) {
      periodoTexto = 'Fecha: ${item.fechaInicio}';
    } else {
      periodoTexto = 'Fecha en trámite';
    }

    // Tiempo otorgado (días u horas)
    final duracionTexto = item.dias > 0
        ? '${item.dias} día(s)'
        : (item.horas > 0 ? '${item.horas} hora(s)' : '${item.dias} día(s)');

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isDark ? const Color(0xFF334155) : AppColors.border,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _mostrarDetallePermiso(context, item, isDark),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(iconData, size: 17, color: iconColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.tipoNombre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: isDark ? const Color(0xFFF8FAFC) : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: estadoColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: estadoColor.withOpacity(0.4), width: 1),
                    ),
                    child: Text(
                      item.estado,
                      style: TextStyle(color: estadoColor, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const Divider(height: 18),

              // Período y Duración
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    periodoTexto,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(6),
                      border: isDark ? Border.all(color: const Color(0xFF334155)) : null,
                    ),
                    child: Text(
                      duracionTexto,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFF38BDF8) : AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),

              // N° de CITT si existe
              if (item.cittNumero != null && item.cittNumero!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.badge_outlined,
                        size: 14,
                        color: isDark ? const Color(0xFF38BDF8) : AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      'N° CITT: ${item.cittNumero}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFF38BDF8) : AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],

              // Diagnóstico o Motivo
              if (item.diagnostico != null && item.diagnostico!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'Diagnóstico: ${item.diagnostico}',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFFCBD5E1) : AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ] else if (item.motivo.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  item.esDescansoMedico ? 'Motivo / Diagnóstico: ${item.motivo}' : 'Motivo: ${item.motivo}',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Ver detalle y documento',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF38BDF8) : AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 11,
                    color: isDark ? const Color(0xFF38BDF8) : AppColors.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarDetallePermiso(
    BuildContext context,
    SolicitudPermisoItem item,
    bool isDark,
  ) {
    Color estadoColor = AppColors.warning;
    final est = item.estado.toUpperCase();
    if (est.contains('APROBADO')) estadoColor = AppColors.success;
    if (est.contains('RECHAZADO')) estadoColor = AppColors.error;

    // Formateo de fechas
    String periodoTexto;
    if (item.fechaInicio.isNotEmpty && item.fechaFin.isNotEmpty) {
      if (item.fechaInicio == item.fechaFin) {
        periodoTexto = item.fechaInicio;
      } else {
        periodoTexto = '${item.fechaInicio} al ${item.fechaFin}';
      }
    } else if (item.fechaInicio.isNotEmpty) {
      periodoTexto = item.fechaInicio;
    } else {
      periodoTexto = 'Fecha en trámite';
    }

    final duracionTexto = item.dias > 0
        ? '${item.dias} día(s)'
        : (item.horas > 0 ? '${item.horas} hora(s)' : '${item.dias} día(s)');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        bool desplegado = false;
        return StatefulBuilder(
          builder: (ctx, setModalState) {
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
                      // Barra pequeña de arrastre
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

                      // Cabecera con Icono, Nombre y Estado
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: item.esDescansoMedico
                                  ? (isDark
                                      ? const Color(0xFF0284C7).withOpacity(0.2)
                                      : const Color(0xFF0284C7).withOpacity(0.1))
                                  : (isDark
                                      ? const Color(0xFF0F172A)
                                      : AppColors.primary.withOpacity(0.08)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              item.esDescansoMedico
                                  ? Icons.medical_services_rounded
                                  : Icons.assignment_outlined,
                              size: 26,
                              color: item.esDescansoMedico
                                  ? const Color(0xFF0284C7)
                                  : (isDark ? const Color(0xFF38BDF8) : AppColors.primary),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.tipoNombre,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? const Color(0xFFF8FAFC) : AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.esDescansoMedico
                                      ? 'Registro de Descanso Médico / CITT'
                                      : 'Papeleta de Permiso Administrativo',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: estadoColor.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: estadoColor.withOpacity(0.5)),
                            ),
                            child: Text(
                              item.estado,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: estadoColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Divider(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200),
                      const SizedBox(height: 8),

                      // Tarjeta con información detallada
                      _buildDetalleFila(
                        isDark: isDark,
                        icon: Icons.date_range_rounded,
                        titulo: 'Período Otorgado',
                        valor: periodoTexto,
                      ),
                      _buildDetalleFila(
                        isDark: isDark,
                        icon: Icons.timer_outlined,
                        titulo: 'Duración',
                        valor: duracionTexto,
                      ),
                      if (item.cittNumero != null && item.cittNumero!.isNotEmpty)
                        _buildDetalleFila(
                          isDark: isDark,
                          icon: Icons.badge_outlined,
                          titulo: 'Número de Certificado / CITT',
                          valor: item.cittNumero!,
                          destacado: true,
                        ),
                      if (item.diagnostico != null && item.diagnostico!.isNotEmpty)
                        _buildDetalleFila(
                          isDark: isDark,
                          icon: Icons.healing_outlined,
                          titulo: 'Diagnóstico (CIE-10)',
                          valor: item.diagnostico!,
                        ),
                      if (item.motivo.isNotEmpty)
                        _buildDetalleFila(
                          isDark: isDark,
                          icon: Icons.notes_rounded,
                          titulo: 'Motivo / Justificación',
                          valor: item.motivo,
                        ),

                      const SizedBox(height: 12),

                      // APARTADO DESPLEGABLE: Evidencia (Imagen o Documento)
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Column(
                          children: [
                            InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () {
                                setModalState(() {
                                  desplegado = !desplegado;
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.photo_library_outlined,
                                      size: 20,
                                      color: isDark ? const Color(0xFF38BDF8) : AppColors.primary,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Evidencia Adjunta / Documento CITT',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: isDark ? const Color(0xFFF8FAFC) : AppColors.textPrimary,
                                            ),
                                          ),
                                          Text(
                                            item.adjuntoUrl != null && item.adjuntoUrl!.isNotEmpty
                                                ? 'Toque para ${desplegado ? "ocultar" : "ver"} el certificado'
                                                : 'No registra imagen adjunta',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      desplegado
                                          ? Icons.keyboard_arrow_up_rounded
                                          : Icons.keyboard_arrow_down_rounded,
                                      color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Contenido desplegable
                            if (desplegado)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                                child: _buildContenidoEvidencia(
                                  context: ctx,
                                  urlOrPath: item.adjuntoUrl,
                                  titulo: item.tipoNombre,
                                  isDark: isDark,
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Botón Cerrar
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? const Color(0xFF38BDF8) : AppColors.primary,
                            foregroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text(
                            'Cerrar',
                            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
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
      },
    );
  }

  Widget _buildDetalleFila({
    required bool isDark,
    required IconData icon,
    required String titulo,
    required String valor,
    bool destacado = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: destacado
                ? (isDark ? const Color(0xFF38BDF8) : AppColors.primary)
                : (isDark ? const Color(0xFF64748B) : AppColors.textMuted),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  valor,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: destacado ? FontWeight.bold : FontWeight.w600,
                    color: destacado
                        ? (isDark ? const Color(0xFF38BDF8) : AppColors.primary)
                        : (isDark ? const Color(0xFFF8FAFC) : AppColors.textPrimary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContenidoEvidencia({
    required BuildContext context,
    required String? urlOrPath,
    required String titulo,
    required bool isDark,
  }) {
    if (urlOrPath == null || urlOrPath.trim().isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(Icons.image_not_supported_outlined,
                size: 36, color: isDark ? const Color(0xFF64748B) : AppColors.textMuted),
            const SizedBox(height: 8),
            Text(
              'No se adjuntó comprobante en este trámite',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    final String fullUrl = _resolverUrlCompleta(urlOrPath);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _abrirVisorImagenCompleta(context, fullUrl, titulo, isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 200,
              width: double.infinity,
              color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    fullUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;
                      return const Center(
                        child: SpinKitRing(color: AppColors.primary, size: 28),
                      );
                    },
                    errorBuilder: (_, __, ___) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.picture_as_pdf_rounded, size: 36, color: AppColors.error),
                            const SizedBox(height: 6),
                            Text(
                              'Documento en formato PDF o no previsualizable',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.zoom_in_rounded, size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Ver completa',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Presiona la imagen para ampliar en pantalla completa',
            style: TextStyle(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _resolverUrlCompleta(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    if (path.startsWith('/storage/')) {
      return 'https://asistencia.macrocompany.net.pe$path';
    }
    if (path.startsWith('storage/')) {
      return 'https://asistencia.macrocompany.net.pe/$path';
    }
    return 'https://asistencia.macrocompany.net.pe/storage/$path';
  }

  void _abrirVisorImagenCompleta(
    BuildContext context,
    String url,
    String titulo,
    bool isDark,
  ) {
    showDialog(
      context: context,
      useSafeArea: false,
      builder: (ctx) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: Text(
            titulo,
            style: const TextStyle(fontSize: 15, color: Colors.white),
          ),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, size: 26),
            onPressed: () => Navigator.pop(ctx),
          ),
        ),
        body: Center(
          child: InteractiveViewer(
            panEnabled: true,
            boundaryMargin: const EdgeInsets.all(20),
            minScale: 0.5,
            maxScale: 4.0,
            child: Image.network(
              url,
              fit: BoxFit.contain,
              loadingBuilder: (_, child, progress) {
                if (progress == null) return child;
                return const Center(
                  child: SpinKitRing(color: Colors.white, size: 36),
                );
              },
              errorBuilder: (_, __, ___) {
                return const Center(
                  child: Text(
                    'No se pudo cargar la imagen en alta resolución.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
