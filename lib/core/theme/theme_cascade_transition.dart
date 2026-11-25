import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_theme.dart';

/// Transición de Cascada Orgánica con Revelado Real de Tema
/// Captura el fotograma del tema actual antes de cambiar y desciende una onda
/// líquida continua que va pintando progresivamente cada tarjeta, texto e ícono
/// en su camino, acompañada de crestas translúcidas y destellos cristalinos.
class ThemeCascadeTransition extends StatefulWidget {
  final ThemeMode themeMode;
  final Widget child;

  const ThemeCascadeTransition({
    super.key,
    required this.themeMode,
    required this.child,
  });

  /// Captura la pantalla actual y dispara el cambio de tema con efecto cascada.
  static Future<void> toggleThemeWithCascade(
    BuildContext context,
    WidgetRef ref, {
    Offset? origin,
  }) async {
    final state =
        context.findAncestorStateOfType<_ThemeCascadeTransitionState>();
    if (state != null) {
      await state.prepareCapture(origin: origin);
    }
    if (context.mounted) {
      ref.read(themeModeProvider.notifier).toggleTheme();
    } else {
      state?._discardPreparedScreenshot();
    }
  }

  @override
  State<ThemeCascadeTransition> createState() => _ThemeCascadeTransitionState();
}

class _ThemeCascadeTransitionState extends State<ThemeCascadeTransition>
    with SingleTickerProviderStateMixin {
  final GlobalKey _captureKey = GlobalKey();
  late AnimationController _controller;

  bool _isAnimating = false;
  bool _isCapturing = false;
  bool _targetIsDark = false;

  ui.Image? _preparedScreenshot;
  ui.Image? _oldScreenshot;
  Offset? _originOffset;

  @override
  void initState() {
    super.initState();
    _targetIsDark = widget.themeMode == ThemeMode.dark;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1650),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        final completedImg = _oldScreenshot;
        setState(() {
          _isAnimating = false;
          _oldScreenshot = null;
        });
        if (completedImg != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            completedImg.dispose();
          });
        }
      }
    });
  }

  Future<void> prepareCapture({Offset? origin}) async {
    if (_isCapturing || !mounted) return;
    _isCapturing = true;
    _originOffset = origin;

    try {
      final renderObject = _captureKey.currentContext?.findRenderObject();
      if (renderObject is RenderRepaintBoundary) {
        if (renderObject.debugNeedsPaint) {
          await WidgetsBinding.instance.endOfFrame;
          if (!mounted || renderObject.debugNeedsPaint) return;
        }
        final pixelRatio =
            MediaQuery.maybeOf(context)?.devicePixelRatio ?? 2.0;
        final ui.Image snapshot = await renderObject.toImage(
          pixelRatio: pixelRatio.clamp(1.0, 3.0),
        );
        if (!mounted) {
          snapshot.dispose();
          return;
        }
        _preparedScreenshot?.dispose();
        _preparedScreenshot = snapshot;
      }
    } catch (_) {
      // Respaldo seguro en caso la vista se encuentre en transición simultánea
    } finally {
      _isCapturing = false;
    }
  }

  void _discardPreparedScreenshot() {
    _preparedScreenshot?.dispose();
    _preparedScreenshot = null;
  }

  @override
  void didUpdateWidget(covariant ThemeCascadeTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.themeMode != widget.themeMode) {
      _targetIsDark = widget.themeMode == ThemeMode.dark;
      if (_preparedScreenshot != null) {
        final prevImg = _oldScreenshot;
        _oldScreenshot = _preparedScreenshot;
        _preparedScreenshot = null;
        if (prevImg != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            prevImg.dispose();
          });
        }
      } else if (!_isAnimating) {
        _oldScreenshot = null;
      }
      _isAnimating = true;
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _oldScreenshot?.dispose();
    _preparedScreenshot?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Capa base + Capa revelada envueltas juntas para permitir capturas en cualquier instante
        RepaintBoundary(
          key: _captureKey,
          child: Stack(
            children: [
              // 1. Captura del tema anterior visible por delante de la ola
              if (_isAnimating && _oldScreenshot != null)
                Positioned.fill(
                  child: IgnorePointer(
                    child: RawImage(
                      image: _oldScreenshot,
                      fit: BoxFit.fill,
                    ),
                  ),
                )
              else
                const SizedBox.shrink(),

              // 2. Interfaz real en el nuevo tema, revelada progresivamente por la cascada
              AnimatedBuilder(
                animation: _controller,
                child: widget.child,
                builder: (context, child) {
                  final activeClip = _isAnimating && _oldScreenshot != null;
                  return ClipPath(
                    clipBehavior: activeClip ? Clip.antiAlias : Clip.none,
                    clipper: activeClip
                        ? _OrganicCascadeClipper(
                            progress: _controller.value,
                            origin: _originOffset,
                          )
                        : null,
                    child: child,
                  );
                },
              ),
            ],
          ),
        ),

        // 3. Efecto artístico de cascada sobre el frente de onda (crestas y gotas)
        if (_isAnimating)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _CascadeEffectsPainter(
                      progress: _controller.value,
                      isDark: _targetIsDark,
                      origin: _originOffset,
                      hasSnapshot: _oldScreenshot != null,
                    ),
                  );
                },
              ),
            ),
          )
        else
          const SizedBox.shrink(),
      ],
    );
  }
}

/// Botón Día / Noche con animación de rotación y transición de cascada integrada.
class ThemeToggleButton extends ConsumerWidget {
  final Color? lightColor;
  final Color? darkColor;

  const ThemeToggleButton({
    super.key,
    this.lightColor,
    this.darkColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

    return Builder(
      builder: (btnContext) => IconButton(
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (child, anim) => RotationTransition(
            turns: Tween<double>(begin: 0.78, end: 1.0).animate(anim),
            child: ScaleTransition(scale: anim, child: child),
          ),
          child: Icon(
            isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            key: ValueKey<bool>(isDark),
            color: isDark
                ? (darkColor ?? Colors.amberAccent)
                : (lightColor ?? Colors.white),
          ),
        ),
        tooltip: isDark ? 'Cambiar a modo Día' : 'Cambiar a modo Noche',
        onPressed: () {
          Offset? origin;
          final renderObject = btnContext.findRenderObject();
          if (renderObject is RenderBox && renderObject.hasSize) {
            origin = renderObject.localToGlobal(
              renderObject.size.center(Offset.zero),
            );
          }
          ThemeCascadeTransition.toggleThemeWithCascade(
            btnContext,
            ref,
            origin: origin,
          );
        },
      ),
    );
  }
}

/// Geometría compartida para que el recorte y los efectos visuales coincidan al píxel.
double _computeCascadeY({
  required double x,
  required Size size,
  required double t,
  Offset? origin,
}) {
  final double w = size.width;
  final double h = size.height;
  final double ease = Curves.easeInOutSine.transform(t);
  final double envelope = math.sin(math.pi * t).clamp(0.0, 1.0);

  // Inicia levemente por encima de y=0 y termina levemente por debajo de y=h
  final double baseY = -2.0 + (h + 6.0) * ease;
  final double u = w > 0 ? x / w : 0.0;

  // Doble armónico orgánico para un movimiento sedoso continuo
  final double w1 =
      math.sin(u * math.pi * 2.2 + t * math.pi * 2.4) * (20.0 * envelope);
  final double w2 =
      math.sin(u * math.pi * 4.0 - t * math.pi * 3.0) * (9.0 * envelope);

  // Curvatura suave inicial desde el punto donde se presionó el ícono
  double originSwell = 0.0;
  if (origin != null && w > 0) {
    final double originFade =
        math.sin(math.pi * (t / 0.65).clamp(0.0, 1.0)).clamp(0.0, 1.0);
    final double dx = (x - origin.dx) / (w * 0.42);
    originSwell = 28.0 * originFade * math.exp(-dx * dx);
  }

  return baseY + w1 + w2 + originSwell;
}

List<Offset> _sampleCascadePoints(Size size, double t, Offset? origin) {
  const int steps = 48;
  final double stepW = size.width / steps;
  return List<Offset>.generate(steps + 1, (i) {
    final double x = i * stepW;
    return Offset(
      x,
      _computeCascadeY(x: x, size: size, t: t, origin: origin),
    );
  });
}

void _appendSmoothWaveCurve(Path path, List<Offset> points,
    {bool reverse = false}) {
  if (points.isEmpty) return;
  if (!reverse) {
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      path.quadraticBezierTo(
        p0.dx,
        p0.dy,
        (p0.dx + p1.dx) * 0.5,
        (p0.dy + p1.dy) * 0.5,
      );
    }
    path.lineTo(points.last.dx, points.last.dy);
  } else {
    for (int i = points.length - 1; i > 0; i--) {
      final p0 = points[i];
      final p1 = points[i - 1];
      path.quadraticBezierTo(
        p0.dx,
        p0.dy,
        (p0.dx + p1.dx) * 0.5,
        (p0.dy + p1.dy) * 0.5,
      );
    }
    path.lineTo(points.first.dx, points.first.dy);
  }
}

/// Recorte orgánico que revela el nuevo tema conforme desciende la cascada.
class _OrganicCascadeClipper extends CustomClipper<Path> {
  final double progress;
  final Offset? origin;

  _OrganicCascadeClipper({
    required this.progress,
    this.origin,
  });

  @override
  Path getClip(Size size) {
    final double t = progress.clamp(0.0, 1.0);
    if (t <= 0.0) return Path();
    if (t >= 1.0) {
      return Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    }

    final points = _sampleCascadePoints(size, t, origin);
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(0, points.first.dy);
    _appendSmoothWaveCurve(path, points);
    path
      ..lineTo(size.width, 0)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant _OrganicCascadeClipper oldClipper) {
    return oldClipper.progress != progress || oldClipper.origin != origin;
  }
}

class _CascadeParticle {
  final double xFrac;
  final double trailDist;
  final double radius;
  final double swayAmp;
  final double swayFreq;
  final double phase;
  final bool isRing;
  final int colorIndex;

  const _CascadeParticle({
    required this.xFrac,
    required this.trailDist,
    required this.radius,
    required this.swayAmp,
    required this.swayFreq,
    required this.phase,
    required this.isRing,
    required this.colorIndex,
  });
}

/// Pintor de las ondas translúcidas, destello de cresta y partículas de la cascada
/// (tonos sólidos cristalinos con transparencias limpias, sin gradientes).
class _CascadeEffectsPainter extends CustomPainter {
  final double progress;
  final bool isDark;
  final Offset? origin;
  final bool hasSnapshot;

  _CascadeEffectsPainter({
    required this.progress,
    required this.isDark,
    required this.origin,
    required this.hasSnapshot,
  });

  static const List<_CascadeParticle> _particles = [
    _CascadeParticle(xFrac: 0.06, trailDist: 18, radius: 2.0, swayAmp: 6, swayFreq: 2.0, phase: 0.4, isRing: false, colorIndex: 0),
    _CascadeParticle(xFrac: 0.11, trailDist: 44, radius: 3.4, swayAmp: 9, swayFreq: 2.4, phase: 1.2, isRing: true, colorIndex: 1),
    _CascadeParticle(xFrac: 0.15, trailDist: 12, radius: 1.8, swayAmp: 5, swayFreq: 3.0, phase: 2.1, isRing: false, colorIndex: 2),
    _CascadeParticle(xFrac: 0.21, trailDist: 66, radius: 2.4, swayAmp: 10, swayFreq: 1.8, phase: 0.8, isRing: false, colorIndex: 1),
    _CascadeParticle(xFrac: 0.26, trailDist: 28, radius: 4.0, swayAmp: 7, swayFreq: 2.5, phase: 3.3, isRing: true, colorIndex: 0),
    _CascadeParticle(xFrac: 0.31, trailDist: 52, radius: 1.6, swayAmp: 8, swayFreq: 3.2, phase: 1.7, isRing: false, colorIndex: 2),
    _CascadeParticle(xFrac: 0.37, trailDist: 16, radius: 2.5, swayAmp: 6, swayFreq: 2.1, phase: 4.5, isRing: false, colorIndex: 0),
    _CascadeParticle(xFrac: 0.42, trailDist: 78, radius: 3.6, swayAmp: 11, swayFreq: 1.6, phase: 2.6, isRing: true, colorIndex: 2),
    _CascadeParticle(xFrac: 0.48, trailDist: 34, radius: 2.1, swayAmp: 7, swayFreq: 2.8, phase: 0.2, isRing: false, colorIndex: 1),
    _CascadeParticle(xFrac: 0.53, trailDist: 14, radius: 1.7, swayAmp: 5, swayFreq: 3.4, phase: 5.1, isRing: false, colorIndex: 0),
    _CascadeParticle(xFrac: 0.58, trailDist: 60, radius: 4.2, swayAmp: 9, swayFreq: 1.9, phase: 3.9, isRing: true, colorIndex: 1),
    _CascadeParticle(xFrac: 0.63, trailDist: 24, radius: 2.6, swayAmp: 8, swayFreq: 2.6, phase: 1.1, isRing: false, colorIndex: 2),
    _CascadeParticle(xFrac: 0.69, trailDist: 86, radius: 2.0, swayAmp: 12, swayFreq: 1.7, phase: 4.2, isRing: false, colorIndex: 0),
    _CascadeParticle(xFrac: 0.74, trailDist: 40, radius: 3.5, swayAmp: 7, swayFreq: 2.3, phase: 2.9, isRing: true, colorIndex: 2),
    _CascadeParticle(xFrac: 0.79, trailDist: 15, radius: 2.2, swayAmp: 6, swayFreq: 3.1, phase: 0.7, isRing: false, colorIndex: 1),
    _CascadeParticle(xFrac: 0.84, trailDist: 56, radius: 1.8, swayAmp: 9, swayFreq: 2.2, phase: 5.6, isRing: false, colorIndex: 0),
    _CascadeParticle(xFrac: 0.89, trailDist: 30, radius: 4.1, swayAmp: 8, swayFreq: 2.7, phase: 1.9, isRing: true, colorIndex: 0),
    _CascadeParticle(xFrac: 0.94, trailDist: 70, radius: 2.3, swayAmp: 10, swayFreq: 1.9, phase: 3.4, isRing: false, colorIndex: 2),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final double t = progress.clamp(0.0, 1.0);
    if (t <= 0.0 || t >= 1.0) return;

    final double envelope = math.sin(math.pi * t).clamp(0.0, 1.0);
    final double fadeIn = (t / 0.10).clamp(0.0, 1.0);
    final double fadeOut = ((1.0 - t) / 0.18).clamp(0.0, 1.0);
    final double globalFade = fadeIn * fadeOut;

    final mainPoints = _sampleCascadePoints(size, t, origin);

    // 1. Respaldo suave si por alguna razón no existiera captura previa
    if (!hasSnapshot) {
      final fallbackPath = Path()
        ..moveTo(0, 0)
        ..lineTo(0, mainPoints.first.dy);
      _appendSmoothWaveCurve(fallbackPath, mainPoints);
      fallbackPath
        ..lineTo(size.width, 0)
        ..close();

      final fallbackColor =
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
      canvas.drawPath(
        fallbackPath,
        Paint()..color = fallbackColor.withOpacity(0.45 * fadeOut),
      );
    }

    // 2. Pulso de expansión inicial desde el botón Día/Noche
    if (origin != null && t < 0.34) {
      final double ringT = (t / 0.34).clamp(0.0, 1.0);
      final double ringEase = Curves.easeOutCubic.transform(ringT);
      final Color ringColor =
          isDark ? const Color(0xFF38BDF8) : const Color(0xFFFBBF24);

      canvas.drawCircle(
        origin!,
        12.0 + 78.0 * ringEase,
        Paint()
          ..color = ringColor.withOpacity(0.55 * (1.0 - ringEase))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2 * (1.0 - ringEase * 0.6),
      );

      if (ringT > 0.15) {
        final double innerT = ((ringT - 0.15) / 0.85).clamp(0.0, 1.0);
        final double innerEase = Curves.easeOutCubic.transform(innerT);
        canvas.drawCircle(
          origin!,
          8.0 + 46.0 * innerEase,
          Paint()
            ..color = ringColor.withOpacity(0.40 * (1.0 - innerEase))
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6,
        );
      }
    }

    // 3. Bandas líquidas paralelas detrás del filo (sin gradientes, transparencias sólidas)
    final double w = size.width;
    final List<Offset> outerTrailPoints = List<Offset>.generate(
      mainPoints.length,
      (i) {
        final p = mainPoints[i];
        final u = w > 0 ? p.dx / w : 0.0;
        final double thickness = (24.0 +
                11.0 * math.cos(u * math.pi * 3.0 - t * math.pi * 4.2)) *
            envelope;
        return Offset(p.dx, p.dy - thickness);
      },
    );

    final List<Offset> innerTrailPoints = List<Offset>.generate(
      mainPoints.length,
      (i) {
        final p = mainPoints[i];
        final u = w > 0 ? p.dx / w : 0.0;
        final double thickness = (10.0 +
                5.0 * math.sin(u * math.pi * 4.6 + t * math.pi * 3.4)) *
            envelope;
        return Offset(p.dx, p.dy - thickness);
      },
    );

    final ribbon1Path = Path()
      ..moveTo(mainPoints.first.dx, mainPoints.first.dy);
    _appendSmoothWaveCurve(ribbon1Path, mainPoints);
    ribbon1Path.lineTo(outerTrailPoints.last.dx, outerTrailPoints.last.dy);
    _appendSmoothWaveCurve(ribbon1Path, outerTrailPoints, reverse: true);
    ribbon1Path.close();

    final ribbon2Path = Path()
      ..moveTo(mainPoints.first.dx, mainPoints.first.dy);
    _appendSmoothWaveCurve(ribbon2Path, mainPoints);
    ribbon2Path.lineTo(innerTrailPoints.last.dx, innerTrailPoints.last.dy);
    _appendSmoothWaveCurve(ribbon2Path, innerTrailPoints, reverse: true);
    ribbon2Path.close();

    final Color ribbon1Color =
        isDark ? const Color(0xFF0284C7) : const Color(0xFF00A3E0);
    final Color ribbon2Color =
        isDark ? const Color(0xFF38BDF8) : const Color(0xFF7DD3FC);

    canvas.drawPath(
      ribbon1Path,
      Paint()
        ..color = ribbon1Color.withOpacity(0.18 * globalFade)
        ..style = PaintingStyle.fill,
    );

    canvas.drawPath(
      ribbon2Path,
      Paint()
        ..color = ribbon2Color.withOpacity(0.24 * globalFade)
        ..style = PaintingStyle.fill,
    );

    // 4. Cresta luminosa principal que define el borde de pintado
    final crestPath = Path()
      ..moveTo(mainPoints.first.dx, mainPoints.first.dy);
    _appendSmoothWaveCurve(crestPath, mainPoints);

    final Color glowColor =
        isDark ? const Color(0xFF38BDF8) : const Color(0xFF0EA5E9);
    final Color coreColor =
        isDark ? const Color(0xFFBAE6FD) : const Color(0xFFFFFFFF);

    canvas.drawPath(
      crestPath,
      Paint()
        ..color = glowColor.withOpacity(0.45 * globalFade)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.5),
    );

    canvas.drawPath(
      crestPath,
      Paint()
        ..color = coreColor.withOpacity(0.90 * globalFade)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round,
    );

    // 5. Gotitas y destellos cristalinos en la estela de la cascada
    final List<Color> particlePalette = isDark
        ? const [
            Color(0xFF38BDF8),
            Color(0xFF7DD3FC),
            Color(0xFFE0F2FE),
          ]
        : const [
            Color(0xFFFFFFFF),
            Color(0xFF38BDF8),
            Color(0xFFFBBF24),
          ];

    for (final p in _particles) {
      final double baseX = p.xFrac * size.width;
      final double sway =
          math.sin(t * math.pi * p.swayFreq + p.phase) * p.swayAmp;
      final double px = (baseX + sway).clamp(4.0, size.width - 4.0);
      final double waveY =
          _computeCascadeY(x: px, size: size, t: t, origin: origin);
      final double py = waveY - p.trailDist * (0.35 + 0.65 * envelope);

      if (py <= 0.0 || py >= size.height) continue;

      final double distFade = (1.0 - (p.trailDist / 100.0)).clamp(0.25, 1.0);
      final Color pColor = particlePalette[p.colorIndex % particlePalette.length];
      final double pAlpha = (p.isRing ? 0.55 : 0.78) * distFade * globalFade;

      if (p.isRing) {
        canvas.drawCircle(
          Offset(px, py),
          p.radius * (0.85 + 0.35 * envelope),
          Paint()
            ..color = pColor.withOpacity(pAlpha)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.1,
        );
      } else {
        canvas.drawCircle(
          Offset(px, py),
          p.radius,
          Paint()
            ..color = pColor.withOpacity(pAlpha)
            ..style = PaintingStyle.fill,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CascadeEffectsPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isDark != isDark ||
        oldDelegate.origin != origin ||
        oldDelegate.hasSnapshot != hasSnapshot;
  }
}
