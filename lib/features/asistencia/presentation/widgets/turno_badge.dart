import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class TurnoBadge extends StatelessWidget {
  final String sigla;
  final double size;

  const TurnoBadge({
    super.key,
    required this.sigla,
    this.size = 32.0,
  });

  static Color getColorForSigla(String sigla) {
    switch (sigla.toUpperCase()) {
      case 'MT':
        return const Color(0xFF1E40AF); // Azul institucional intenso
      case 'M':
        return AppColors.turnoManana;
      case 'T':
        return AppColors.turnoTarde;
      case 'N':
        return AppColors.turnoNoche;
      case 'GD':
      case 'GN':
        return AppColors.turnoGuardia;
      case 'D':
        return const Color(0xFF64748B); // Slate neutral para descanso
      case 'F':
        return const Color(0xFF0D9488); // Teal para feriados
      case 'VAC':
        return const Color(0xFF16A34A); // Verde para vacaciones
      case 'L':
      case 'CIT':
        return AppColors.warning;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = getColorForSigla(sigla);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(size * 0.25),
        border: Border.all(color: color, width: 1.2),
      ),
      child: Center(
        child: Text(
          sigla,
          style: TextStyle(
            color: color,
            fontSize: size * 0.38,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
