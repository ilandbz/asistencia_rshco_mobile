import 'package:flutter/material.dart';

/// Transición en Cascada que desciende de arriba hacia abajo
/// al alternar entre modo claro y oscuro, sin gradientes y con tonos sólidos elegantes.
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
      duration: const Duration(milliseconds: 700),
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
        // Contenido de la aplicación con el tema actual
        widget.child,

        // Cascada animada que desciende de arriba hacia abajo
        if (_isAnimating)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _CascadeWaterfallPainter(
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

/// Pintor de la cascada escalonada (sin gradientes, colores sólidos elegantes)
class _CascadeWaterfallPainter extends CustomPainter {
  final double progress;
  final bool isDark;

  _CascadeWaterfallPainter({
    required this.progress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0) return;

    // Color de relleno sólido: Azul pizarra profundo (#0F172A) o Blanco institucional (#F8FAFC)
    final fillColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    // Borde frontal sólido de la cascada
    final frontColor = isDark ? const Color(0xFF00A3E0) : const Color(0xFF003876);

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final frontPaint = Paint()
      ..color = frontColor
      ..style = PaintingStyle.fill;

    // 6 columnas de cascada con desfase progresivo para crear el efecto de cascada natural
    const int columnCount = 6;
    final columnWidth = size.width / columnCount;
    const delays = [0.00, 0.06, 0.02, 0.10, 0.04, 0.08];

    // Desvanecimiento suave en el último 10% del recorrido
    double globalAlpha = 1.0;
    if (progress > 0.90) {
      globalAlpha = ((1.0 - progress) / 0.10).clamp(0.0, 1.0);
    }

    fillPaint.color = fillColor.withOpacity(globalAlpha);
    frontPaint.color = frontColor.withOpacity(globalAlpha);

    for (int i = 0; i < columnCount; i++) {
      final delay = delays[i % delays.length];
      // Tiempo local de cada columna
      final localProgress = ((progress - delay) / (1.0 - delay)).clamp(0.0, 1.0);
      final curved = Curves.easeInOutCubic.transform(localProgress);

      final colLeft = i * columnWidth;
      final currentHeight = size.height * curved;

      if (currentHeight > 0) {
        // 1. Relleno sólido de la columna
        canvas.drawRect(
          Rect.fromLTWH(colLeft, 0, columnWidth + 0.5, currentHeight),
          fillPaint,
        );

        // 2. Línea frontal de impacto de la cascada (4px de grosor)
        canvas.drawRect(
          Rect.fromLTWH(colLeft, currentHeight - 3, columnWidth + 0.5, 3),
          frontPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CascadeWaterfallPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isDark != isDark;
  }
}
