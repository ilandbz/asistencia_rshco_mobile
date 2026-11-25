import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/permiso_model.dart';

class BarraProgresoCitWidget extends StatelessWidget {
  final ResumenCit resumen;

  const BarraProgresoCitWidget({super.key, required this.resumen});

  @override
  Widget build(BuildContext context) {
    final diasRed = resumen.diasAcumuladosRed;
    final limite = resumen.limiteRed > 0 ? resumen.limiteRed : 20;
    final saldo = resumen.saldoRedDisponible;
    final diasEssalud = resumen.diasSubsidioEssalud;
    final esSubsidio = resumen.requiereSubsidioEssalud;
    final porcentaje = resumen.porcentajeRed;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Cabecera con Título y Año
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0284C7).withOpacity(0.2)
                          : AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.health_and_safety_rounded,
                      color: isDark ? const Color(0xFF38BDF8) : AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Días de Descanso Médico',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isDark ? const Color(0xFFF8FAFC) : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Periodo Anual ${resumen.anio}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: esSubsidio
                      ? (isDark ? const Color(0xFF78350F).withOpacity(0.4) : AppColors.warningBg)
                      : (isDark ? const Color(0xFF064E3B).withOpacity(0.4) : AppColors.successBg),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  esSubsidio ? 'EN SUBSIDIO' : 'COBERTURA ACTIVA',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: esSubsidio
                        ? (isDark ? const Color(0xFFFBBF24) : AppColors.warning)
                        : (isDark ? const Color(0xFF4ADE80) : AppColors.success),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 2. Tres Tarjetas de Resumen Numérico (Fácil de entender)
          Row(
            children: [
              Expanded(
                child: _buildTarjetaContador(
                  isDark: isDark,
                  titulo: 'Usados este año',
                  valor: '$diasRed',
                  subtitulo: 'de $limite días',
                  color: diasRed > 0
                      ? (isDark ? const Color(0xFF38BDF8) : AppColors.primary)
                      : (isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary),
                  bgColor: isDark ? const Color(0xFF0F172A) : AppColors.primary.withOpacity(0.06),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTarjetaContador(
                  isDark: isDark,
                  titulo: 'Te quedan',
                  valor: '$saldo',
                  subtitulo: 'asumidos por la Red',
                  color: saldo > 0
                      ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A))
                      : (isDark ? const Color(0xFF64748B) : Colors.grey),
                  bgColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF0FDF4),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTarjetaContador(
                  isDark: isDark,
                  titulo: 'En EsSalud',
                  valor: '$diasEssalud',
                  subtitulo: 'en subsidio',
                  color: diasEssalud > 0
                      ? (isDark ? const Color(0xFFFBBF24) : AppColors.warning)
                      : (isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary),
                  bgColor: isDark ? const Color(0xFF0F172A) : (diasEssalud > 0 ? AppColors.warningBg : Colors.grey.shade50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 3. Barra de Progreso Visual
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Consumo de los 20 días que cubre la Red:',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '${(porcentaje * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: esSubsidio
                          ? AppColors.error
                          : (isDark ? const Color(0xFF38BDF8) : AppColors.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: porcentaje,
                  minHeight: 8,
                  backgroundColor: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    esSubsidio
                        ? AppColors.error
                        : (isDark ? const Color(0xFF38BDF8) : AppColors.primary),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 4. Mensaje Informativo en Lenguaje Humano y Cálido
          if (esSubsidio)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF78350F).withOpacity(0.35) : const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isDark ? const Color(0xFFB45309) : const Color(0xFFFCD34D)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Has completado los 20 primeros días que cubre la Red de Salud. A partir de ahora, todo descanso médico debe ser obligatoriamente CITT emitido por EsSalud para gestionar tu subsidio por incapacidad temporal.',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (diasRed == 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF064E3B).withOpacity(0.35) : const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isDark ? const Color(0xFF059669) : const Color(0xFFBBF7D0)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Cuentas con tus 20 días completos de descanso médico pagados al 100% por la institución.',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? const Color(0xFFA7F3D0) : const Color(0xFF166534),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0C4A6E).withOpacity(0.35) : AppColors.primary.withOpacity(0.04),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isDark ? const Color(0xFF0284C7) : const Color(0xFFBAE6FD)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: isDark ? const Color(0xFF38BDF8) : AppColors.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Aún te quedan $saldo días cubiertos con goce de haber directo por la Red de Salud Huánuco.',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? const Color(0xFFBAE6FD) : AppColors.primaryDark,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTarjetaContador({
    required bool isDark,
    required String titulo,
    required String valor,
    required String subtitulo,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(isDark ? 0.35 : 0.18)),
      ),
      child: Column(
        children: [
          Text(
            titulo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9.5,
              color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            valor,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
          Text(
            subtitulo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 8.5,
              color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
