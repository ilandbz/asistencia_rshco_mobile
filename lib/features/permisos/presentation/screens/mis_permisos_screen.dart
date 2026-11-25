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
          ],
        ),
      ),
    );
  }
}
