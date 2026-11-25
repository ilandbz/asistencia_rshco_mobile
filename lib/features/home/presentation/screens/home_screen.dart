import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_cascade_transition.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _obtenerSaludo() {
    final hora = DateTime.now().hour;
    if (hora >= 5 && hora < 12) {
      return '¡Buenos días';
    } else if (hora >= 12 && hora < 19) {
      return '¡Buenas tardes';
    } else {
      return '¡Buenas noches';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final personal = authState.personal;
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    final String primerNombre = personal?.nombres.split(' ').first ?? 'Personal';
    final String nombreCompleto = personal?.nombreCompleto.isNotEmpty == true
        ? personal!.nombreCompleto
        : 'Personal de Salud';
    final String saludo = _obtenerSaludo();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Red de Salud Huánuco'),
        actions: [
          // Botón de Modo Día y Noche con efecto cascada
          const ThemeToggleButton(),
          // Botón de Perfil
          IconButton(
            icon: const Icon(Icons.account_circle_rounded),
            tooltip: 'Mi Perfil',
            onPressed: () => context.push('/perfil'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Banner de Bienvenida y Perfil (Asimétrico: borde leve en A y D, redondeado amplio en B y C)
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFF2B6CB0),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(28),
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(8),
                ),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : Colors.transparent,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(28),
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(8),
                  ),
                  onTap: () => context.push('/perfil'),
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Saludo y Avatar
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.white.withOpacity(0.24),
                              child: const Icon(
                                Icons.person_rounded,
                                size: 32,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          '$saludo, $primerNombre',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const _AnimatedGreetingWave(),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    nombreCompleto,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (personal?.cargo != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      personal!.cargo!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: isDark
                                            ? const Color(0xFF38BDF8)
                                            : const Color(0xFFFEF08A),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.22),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Barra inferior con Sede y link a perfil
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    const Icon(Icons.business_rounded, size: 14, color: Colors.white),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        personal?.establecimiento ?? 'Sede Red de Salud Huánuco',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Ver Perfil →',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Accesos Directos a Módulos en Cuadrícula 2x2
            Text(
              'Módulos y Servicios',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.getTextPrimary(context),
              ),
            ),
            const SizedBox(height: 12),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.24,
              children: [
                _buildSquareModuleCard(
                  context: context,
                  icon: Icons.fingerprint_rounded,
                  color: AppColors.primary,
                  lightBg: const Color(0xFFEFF6FF),
                  lightBorder: const Color(0xFFBFDBFE),
                  darkBg: const Color(0xFF132338),
                  darkBorder: const Color(0xFF1E3A8A),
                  title: 'Asistencia y Marcaciones',
                  description: 'Registro de hoy y récord',
                  onTap: () => context.push('/asistencia'),
                ),
                _buildSquareModuleCard(
                  context: context,
                  icon: Icons.calendar_month_rounded,
                  color: AppColors.turnoGuardia,
                  lightBg: const Color(0xFFF5F3FF),
                  lightBorder: const Color(0xFFDDD6FE),
                  darkBg: const Color(0xFF201836),
                  darkBorder: const Color(0xFF5B21B6),
                  title: 'Rol de Turnos Mensual',
                  description: 'Calendario y turnos',
                  onTap: () => context.push('/rol-mes'),
                ),
                _buildSquareModuleCard(
                  context: context,
                  icon: Icons.published_with_changes_rounded,
                  color: AppColors.turnoTarde,
                  lightBg: const Color(0xFFFFF7ED),
                  lightBorder: const Color(0xFFFED7AA),
                  darkBg: const Color(0xFF2B1D16),
                  darkBorder: const Color(0xFF9A3412),
                  title: 'Cambio de Turno',
                  description: 'Permutas entre colegas',
                  onTap: () => context.push('/cambio-turno'),
                ),
                _buildSquareModuleCard(
                  context: context,
                  icon: Icons.assignment_rounded,
                  color: AppColors.success,
                  lightBg: const Color(0xFFF0FDF4),
                  lightBorder: const Color(0xFFBBF7D0),
                  darkBg: const Color(0xFF12281D),
                  darkBorder: const Color(0xFF065F46),
                  title: 'Descansos y CITT',
                  description: 'Licencias y subsidios',
                  onTap: () => context.push('/permisos'),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSquareModuleCard({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required Color lightBg,
    required Color lightBorder,
    required Color darkBg,
    required Color darkBorder,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveColor = isDark
        ? (color == AppColors.primary
            ? const Color(0xFF38BDF8)
            : (color == AppColors.turnoGuardia
                ? const Color(0xFFA78BFA)
                : (color == AppColors.turnoTarde
                    ? const Color(0xFFFB923C)
                    : const Color(0xFF4ADE80))))
        : color;

    final backgroundColor = isDark ? darkBg : lightBg;
    final borderColor = isDark ? darkBorder.withOpacity(0.55) : lightBorder;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Ícono distintivo centrado
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: effectiveColor.withOpacity(isDark ? 0.25 : 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: effectiveColor,
                    size: 27,
                  ),
                ),
                const SizedBox(height: 6),

                // Título centrado
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 2),

                // Subtítulo descriptivo centrado
                Text(
                  description,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedGreetingWave extends StatefulWidget {
  const _AnimatedGreetingWave();

  @override
  State<_AnimatedGreetingWave> createState() => _AnimatedGreetingWaveState();
}

class _AnimatedGreetingWaveState extends State<_AnimatedGreetingWave>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _angle;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..repeat(reverse: true);
    _angle = Tween<double>(begin: -0.18, end: 0.24).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _angle,
      builder: (context, child) {
        return Transform.rotate(
          angle: _angle.value,
          alignment: const Alignment(0.5, 0.7),
          child: child,
        );
      },
      child: const Text(
        '👋',
        style: TextStyle(fontSize: 20),
      ),
    );
  }
}
