import 'package:flutter/material.dart';

/// Transición de Cascada Fluida y Uniforme
/// Desciende de manera homogénea en toda la pantalla en un lapso de 1.5 segundos,
/// tiñendo progresivamente la interfaz entre modo claro y modo oscuro,
/// sin cortes agresivos ni rectángulos escalonados.
class ThemeCascadeTransition extends StatefulWidget {
  final ThemeMode themeMode;
  final Widget child;

  const ThemeCascadeTransition({
    super.key,
    required this.themeMode,
    required this.child,
  });

  @override
  State<ThemeCascadeTransition> createState() => _ThemeCascadeTransitionState();
}

class _ThemeCascadeTransitionState extends State<ThemeCascadeTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isAnimating = false;
  bool _targetIsDark = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          setState(() {
            _isAnimating = false;
          });
        }
      }
    });
  }

  @override
  void didUpdateWidget(covariant ThemeCascadeTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.themeMode != widget.themeMode) {
      _targetIsDark = widget.themeMode == ThemeMode.dark;
      _isAnimating = true;
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Contenido de la aplicación
        widget.child,

        // Velo fluido de cascada que desciende de manera uniforme
        if (_isAnimating)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _SmoothCascadePainter(
                      progress: _controller.value,
                      isDark: _targetIsDark,
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

/// Pintor de la cascada suave y uniforme (100% homogénea a lo ancho)
class _SmoothCascadePainter extends CustomPainter {
  final double progress;
  final bool isDark;

  _SmoothCascadePainter({
    required this.progress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0 || progress >= 1.0) return;

    // Tono institucional sólido elegante: Pizarra profunda (#0F172A) o Blanco institucional (#F8FAFC)
    final Color baseColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    // Borde frontal sutil que guía la cascada
    final Color frontColor = isDark ? const Color(0xFF38BDF8) : const Color(0xFF003876);

    // Curva de aceleración y desaceleración orgánica
    final double curved = Curves.easeInOutCubic.transform(progress);
    final double currentHeight = size.height * curved;

    // Desvanecimiento suave en el tramo final para un cierre sedoso
    double alpha = 0.90;
    if (progress > 0.80) {
      final double fadeOut = ((1.0 - progress) / 0.20).clamp(0.0, 1.0);
      alpha = 0.90 * fadeOut;
    }

    final fillPaint = Paint()
      ..color = baseColor.withOpacity(alpha)
      ..style = PaintingStyle.fill;

    // 1. Manto uniforme que cubre el ancho completo de la pantalla
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, currentHeight),
      fillPaint,
    );

    // 2. Línea frontal sutil de contacto de 2.0px de grosor
    final frontPaint = Paint()
      ..color = frontColor.withOpacity(alpha * 0.7)
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(0, currentHeight - 2.0, size.width, 2.0),
      frontPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _SmoothCascadePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isDark != isDark;
  }
}
