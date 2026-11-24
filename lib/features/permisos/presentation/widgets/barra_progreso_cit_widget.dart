import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/permiso_model.dart';

class BarraProgresoCitWidget extends StatelessWidget {
  final ResumenCit resumen;

  const BarraProgresoCitWidget({super.key, required this.resumen});

  @override
  Widget build(BuildContext context) {
    final diasRed = resumen.diasAcumuladosRed;
    final limite = resumen.limiteRed;
    final esSubsidio = resumen.requiereSubsidioEssalud;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.medical_services_rounded, color: AppColors.primary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Control Anual de Descansos (CIT)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
                Text(
                  '${resumen.anio}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Barra de Progreso
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: resumen.porcentajeRed,
                minHeight: 12,
                backgroundColor: AppColors.surfaceVariant,
                valueColor: AlwaysStoppedAnimation<Color>(
                  diasRed >= limite ? AppColors.error : AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Días Red de Salud: $diasRed / $limite días',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                Text(
                  '${(resumen.porcentajeRed * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: diasRed >= limite ? AppColors.error : AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Alerta si sobrepasó los 20 días
            if (esSubsidio)
              Container(
                margin: const EdgeInsets.only(top: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.warningBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.warning.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Has superado los 20 días asumidos por el empleador (${resumen.diasSubsidioEssalud} días en subsidio). Es obligatorio adjuntar el CITT de EsSalud.',
                        style: const TextStyle(fontSize: 11, color: AppColors.primaryDark),
                      ),
                    ),
                  ],
                ),
              )
            else
              Text(
                'Te restan ${limite - diasRed} días asumidos por la Red de Salud antes de ingresar a subsidio de EsSalud.',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
          ],
        ),
      ),
    );
  }
}
