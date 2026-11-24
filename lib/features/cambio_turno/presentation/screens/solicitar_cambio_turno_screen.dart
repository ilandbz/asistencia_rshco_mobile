import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../controllers/cambio_turno_controller.dart';
import '../widgets/resumen_validacion_dialog.dart';

class SolicitarCambioTurnoScreen extends ConsumerStatefulWidget {
  const SolicitarCambioTurnoScreen({super.key});

  @override
  ConsumerState<SolicitarCambioTurnoScreen> createState() => _SolicitarCambioTurnoScreenState();
}

class _SolicitarCambioTurnoScreenState extends ConsumerState<SolicitarCambioTurnoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _colegaDniController = TextEditingController();
  final _motivoController = TextEditingController();
  DateTime? _miFecha;
  DateTime? _colegaFecha;

  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  @override
  void dispose() {
    _colegaDniController.dispose();
    _motivoController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarMiFecha() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now, // Regla de negocio: No se permiten fechas pasadas
      lastDate: now.add(const Duration(days: 60)),
    );

    if (picked != null) {
      setState(() => _miFecha = picked);
      final formatted = _dateFormat.format(picked);
      ref.read(formCambioTurnoControllerProvider.notifier).setMiFecha(formatted);
    }
  }

  Future<void> _seleccionarFechaColega() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
    );

    if (picked != null) {
      setState(() => _colegaFecha = picked);
      final formatted = _dateFormat.format(picked);
      await ref.read(formCambioTurnoControllerProvider.notifier).setFechaColega(formatted);
    }
  }

  void _validarYEnviar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_miFecha == null || _colegaFecha == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione las fechas de ambos turnos')),
      );
      return;
    }

    final notifier = ref.read(formCambioTurnoControllerProvider.notifier);
    await notifier.prevalidar(motivo: _motivoController.text.trim());

    if (!mounted) return;

    final formState = ref.read(formCambioTurnoControllerProvider);
    if (formState.validacion != null) {
      final proceder = await showDialog<bool>(
        context: context,
        builder: (_) => ResumenValidacionDialog(validacion: formState.validacion!),
      );

      if (proceder == true && mounted) {
        final success = await notifier.enviarSolicitud(motivo: _motivoController.text.trim());
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Solicitud registrada correctamente en estado SOLICITADO'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(formCambioTurnoControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitar Cambio de Turno'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Alerta Informativa de Regla de Negocio
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.infoBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.info.withOpacity(0.3)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.info_outline_rounded, color: AppColors.info, size: 22),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Los cambios deben solicitarse antes de la fecha programada. La solicitud nace en estado SOLICITADO sujeta a visto bueno de jefatura y RRHH.',
                        style: TextStyle(fontSize: 12, color: AppColors.primaryDark),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Paso 1: Seleccionar Turno Propio
              const Text(
                '1. Mi Turno a Permutar',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.border),
                ),
                tileColor: Colors.white,
                leading: const Icon(Icons.calendar_today_rounded, color: AppColors.primary),
                title: Text(
                  _miFecha != null ? _dateFormat.format(_miFecha!) : 'Seleccionar fecha de mi turno',
                  style: TextStyle(
                    color: _miFecha != null ? AppColors.textPrimary : AppColors.textMuted,
                    fontWeight: _miFecha != null ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                trailing: const Icon(Icons.arrow_drop_down_rounded),
                onTap: _seleccionarMiFecha,
              ),
              const SizedBox(height: 20),

              // Paso 2: Buscar Colega por DNI
              const Text(
                '2. Colega de Reemplazo (Mismo Servicio)',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _colegaDniController,
                      keyboardType: TextInputType.number,
                      maxLength: 8,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'DNI del Colega',
                        hintText: '8 dígitos',
                        counterText: '',
                        prefixIcon: Icon(Icons.badge_outlined, color: AppColors.primary),
                      ),
                      validator: (v) => (v == null || v.trim().length != 8) ? 'DNI inválido' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(minimumSize: const Size(80, 50)),
                    onPressed: formState.isLoading
                        ? null
                        : () {
                            if (_colegaDniController.text.trim().length == 8) {
                              ref
                                  .read(formCambioTurnoControllerProvider.notifier)
                                  .buscarColega(_colegaDniController.text.trim());
                            }
                          },
                    child: formState.isLoading
                        ? const SpinKitRing(color: Colors.white, size: 20)
                        : const Text('Buscar'),
                  ),
                ],
              ),
              if (formState.colega != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.successBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.success.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline_rounded, color: AppColors.success),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formState.colega!.nombreCompleto,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              formState.colega!.cargo ?? 'Personal Asistencial',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // Paso 3: Turno del Colega
              const Text(
                '3. Fecha y Turno a Cubrir del Colega',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.border),
                ),
                tileColor: Colors.white,
                leading: const Icon(Icons.event_available_rounded, color: AppColors.turnoGuardia),
                title: Text(
                  _colegaFecha != null
                      ? '${_dateFormat.format(_colegaFecha!)} (Turno: ${formState.colegaTurnoSigla ?? "Consultando..."})'
                      : 'Seleccionar fecha del colega',
                  style: TextStyle(
                    color: _colegaFecha != null ? AppColors.textPrimary : AppColors.textMuted,
                    fontWeight: _colegaFecha != null ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                trailing: const Icon(Icons.arrow_drop_down_rounded),
                onTap: formState.colega != null ? _seleccionarFechaColega : null,
              ),
              const SizedBox(height: 20),

              // Paso 4: Motivo
              const Text(
                '4. Sustento / Motivo de la Permuta',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _motivoController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Explique detalladamente el motivo de la permuta...',
                ),
                validator: (v) => (v == null || v.trim().length < 5) ? 'Ingrese un motivo claro' : null,
              ),
              const SizedBox(height: 24),

              // Mensaje de Error
              if (formState.errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.errorBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    formState.errorMessage!,
                    style: const TextStyle(color: AppColors.error, fontSize: 13),
                  ),
                ),

              // Botón de Prevalidación y Envío
              ElevatedButton(
                onPressed: (formState.isLoading || formState.isValidating) ? null : _validarYEnviar,
                child: (formState.isValidating || formState.isLoading)
                    ? const SpinKitThreeBounce(color: Colors.white, size: 20)
                    : const Text('VALIDAR Y ENVIAR SOLICITUD'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
