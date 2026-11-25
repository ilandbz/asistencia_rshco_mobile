import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_cascade_transition.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class PerfilScreen extends ConsumerStatefulWidget {
  const PerfilScreen({super.key});

  @override
  ConsumerState<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends ConsumerState<PerfilScreen> {
  final _actualPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureActual = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _actualPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _guardarNuevaContrasena() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 24),
            SizedBox(width: 8),
            Text('Cambio de Contraseña', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'La actualización de credenciales desde el dispositivo móvil se habilitará en la siguiente actualización del sistema.\n\nPor el momento, puedes comunicarte con el área de Informática o soporte para gestionar tu clave.',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final personal = authState.personal;
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    final String nombres = personal?.nombres ?? 'Personal';
    final String apellidos = '${personal?.apellidoPaterno ?? ''} ${personal?.apellidoMaterno ?? ''}'.trim();
    final String nombreCompleto = personal?.nombreCompleto.isNotEmpty == true ? personal!.nombreCompleto : 'Personal de Salud';
    final String dni = personal?.dni ?? '--';
    final String cargo = personal?.cargo ?? 'Cargo no asignado';
    final String sede = personal?.establecimiento ?? 'SEDE RED SALUD HUÁNUCO';
    final String microred = personal?.microred ?? 'Sede Central';
    final String condicion = personal?.condicionLaboral ?? 'CONTRATADO - CAS';
    final String servicio = personal?.servicio ?? 'Área Asistencial / Administrativa';

    // Iniciales para avatar
    String iniciales = 'RH';
    if (nombres.isNotEmpty && apellidos.isNotEmpty) {
      iniciales = '${nombres[0]}${apellidos[0]}'.toUpperCase();
    } else if (nombres.isNotEmpty) {
      iniciales = nombres[0].toUpperCase();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        actions: const [
          // Botón Día y Noche (Theme Switch con Cascada)
          ThemeToggleButton(),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Column(
          children: [
            // 1. Tarjeta Principal de Identificación y Bienvenida
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: AppColors.primary.withOpacity(0.12),
                    child: Text(
                      iniciales,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    nombreCompleto,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    cargo,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF38BDF8) : AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.successBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.check_circle_rounded, size: 13, color: AppColors.success),
                        SizedBox(width: 4),
                        Text(
                          'TRABAJADOR HABILITADO',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Tarjeta de Datos Personales
            _buildCardSeccion(
              isDark: isDark,
              icono: Icons.person_outline_rounded,
              titulo: 'Información Personal',
              items: [
                _buildFilaInfo('Documento de Identidad (DNI)', dni, esResaltado: true),
                _buildFilaInfo('Nombres', nombres),
                _buildFilaInfo('Apellidos', apellidos),
                _buildFilaInfo('Correo Registrado', personal?.email ?? 'Sin registrar'),
                _buildFilaInfo('Teléfono de Contacto', personal?.celular ?? 'Sin registrar', esUltimo: true),
              ],
            ),
            const SizedBox(height: 16),

            // 3. Tarjeta de Datos Laborales
            _buildCardSeccion(
              isDark: isDark,
              icono: Icons.domain_rounded,
              titulo: 'Sede y Asignación Laboral',
              items: [
                _buildFilaInfo('Sede / Establecimiento', sede, esResaltado: true),
                _buildFilaInfo('Microred', microred),
                _buildFilaInfo('Condición Laboral', condicion),
                _buildFilaInfo('Servicio / Área', servicio),
                _buildFilaInfo('Régimen', personal?.regimen ?? 'Régimen Laboral de Salud', esUltimo: true),
              ],
            ),
            const SizedBox(height: 16),

            // 4. Tarjeta Visual: Cambiar Contraseña (Preview)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.lock_outline_rounded, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Seguridad de la Cuenta',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? const Color(0xFFF8FAFC) : AppColors.textPrimary),
                          ),
                          Text(
                            'Actualiza tu clave de acceso al sistema',
                            style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Campo Contraseña Actual
                  TextField(
                    controller: _actualPasswordController,
                    obscureText: _obscureActual,
                    decoration: InputDecoration(
                      labelText: 'Contraseña Actual',
                      hintText: 'Ingresa tu clave actual',
                      prefixIcon: const Icon(Icons.key_rounded, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureActual ? Icons.visibility_off : Icons.visibility, size: 20),
                        onPressed: () => setState(() => _obscureActual = !_obscureActual),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Campo Nueva Contraseña
                  TextField(
                    controller: _newPasswordController,
                    obscureText: _obscureNew,
                    decoration: InputDecoration(
                      labelText: 'Nueva Contraseña',
                      hintText: 'Mínimo 6 caracteres',
                      prefixIcon: const Icon(Icons.lock_reset_rounded, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility, size: 20),
                        onPressed: () => setState(() => _obscureNew = !_obscureNew),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Campo Confirmar Nueva Contraseña
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirm,
                    decoration: InputDecoration(
                      labelText: 'Confirmar Nueva Contraseña',
                      hintText: 'Vuelve a escribir la nueva clave',
                      prefixIcon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility, size: 20),
                        onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.save_rounded, size: 18),
                      label: const Text('Actualizar Contraseña'),
                      onPressed: _guardarNuevaContrasena,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 5. Botón de Cerrar Sesión
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 14),
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.logout_rounded, size: 20),
              label: const Text('Cerrar Sesión Segura'),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
                      ),
                    ),
                    contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.logout_rounded,
                            color: AppColors.error,
                            size: 30,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Cerrar Sesión',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? const Color(0xFFF8FAFC) : AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '¿Está seguro de que desea salir de su cuenta?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13.5,
                            color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // 1. Botón Grande Cerrar Sesión (Arriba)
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text(
                            'Cerrar Sesión',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // 2. Botón Grande Cancelar (Abajo, en el centro)
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark ? const Color(0xFFF8FAFC) : AppColors.textPrimary,
                            side: BorderSide(
                              color: isDark ? const Color(0xFF334155) : AppColors.border,
                              width: 1.5,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text(
                            'Cancelar',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                );

                if (confirm == true && context.mounted) {
                  await ref.read(authControllerProvider.notifier).logout();
                  if (context.mounted) {
                    context.go('/login');
                  }
                }
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCardSeccion({
    required bool isDark,
    required IconData icono,
    required String titulo,
    required List<Widget> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icono, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                titulo,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const Divider(height: 24),
          ...items,
        ],
      ),
    );
  }

  Widget _buildFilaInfo(String etiqueta, String valor, {bool esResaltado = false, bool esUltimo = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: esUltimo ? 0 : 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              etiqueta,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.getTextSecondary(context),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 6,
            child: Text(
              valor,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: esResaltado ? FontWeight.bold : FontWeight.w600,
                color: esResaltado
                    ? (Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF38BDF8)
                        : AppColors.primary)
                    : AppColors.getTextPrimary(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
