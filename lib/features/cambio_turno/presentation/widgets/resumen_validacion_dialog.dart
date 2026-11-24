import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/cambio_turno_model.dart';

class ResumenValidacionDialog extends StatelessWidget {
  final ValidacionCambioTurnoResult validacion;

  const ResumenValidacionDialog({super.key, required this.validacion});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(
            validacion.esValido ? Icons.check_circle_rounded : Icons.warning_rounded,
            color: validacion.esValido ? AppColors.success : AppColors.warning,
          ),
          const SizedBox(width: 8),
          const Text('Pre-Validación RSHCO', style: TextStyle(fontSize: 16)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            validacion.mensaje,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          if (validacion.advertencias.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Advertencias y Reglas de Control:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.warning),
            ),
            const SizedBox(height: 4),
            ...validacion.advertencias.map(
              (adv) => Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(color: AppColors.warning)),
                    Expanded(child: Text(adv, style: const TextStyle(fontSize: 12))),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Modificar'),
        ),
        if (validacion.esValido)
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar Envío'),
          ),
      ],
    );
  }
}
