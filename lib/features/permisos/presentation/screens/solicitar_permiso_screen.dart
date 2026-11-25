import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/permisos_controller.dart';

class SolicitarPermisoScreen extends ConsumerStatefulWidget {
  const SolicitarPermisoScreen({super.key});

  @override
  ConsumerState<SolicitarPermisoScreen> createState() =>
      _SolicitarPermisoScreenState();
}

class _SolicitarPermisoScreenState extends ConsumerState<SolicitarPermisoScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _laserController;
  late Animation<double> _laserAnimation;

  final _formKey = GlobalKey<FormState>();

  // Controladores de texto del formulario
  final _nroCertificadoController = TextEditingController();
  final _cmpController = TextEditingController();
  final _diagnosticoController = TextEditingController();
  final _motivoController = TextEditingController();

  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  File? _archivoAdjunto;

  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  final ImagePicker _picker = ImagePicker();

  // Temporizador de 5 segundos para bloqueo obligatorio de revisión
  Timer? _countdownTimer;
  int _countdownSeconds = 5;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _laserAnimation = CurvedAnimation(
      parent: _laserController,
      curve: Curves.easeInOut,
    );
    _verificarFotoRecuperada();
  }

  Future<void> _verificarFotoRecuperada() async {
    try {
      final LostDataResponse response = await _picker.retrieveLostData();
      if (response.isEmpty || response.file == null) return;
      final file = response.file!;
      if (!mounted) return;
      setState(() => _archivoAdjunto = File(file.path));
      ref.read(formPermisoControllerProvider.notifier).setFilePath(file.path);
      await _procesarConOcr(file.path);
    } catch (_) {}
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _laserController.dispose();
    _tabController.dispose();
    _nroCertificadoController.dispose();
    _cmpController.dispose();
    _diagnosticoController.dispose();
    _motivoController.dispose();
    super.dispose();
  }

  void _iniciarCuentaRegresiva() {
    _countdownTimer?.cancel();
    setState(() => _countdownSeconds = 5);

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownSeconds > 1) {
        setState(() => _countdownSeconds--);
      } else {
        setState(() => _countdownSeconds = 0);
        timer.cancel();
      }
    });
  }

  // Cálculo automático de días de descanso otorgados
  int get _diasOtorgados {
    if (_fechaInicio == null || _fechaFin == null) return 0;
    return _fechaFin!.difference(_fechaInicio!).inDays + 1;
  }

  Future<void> _seleccionarFechaInicio() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaInicio ?? now,
      firstDate: now.subtract(const Duration(days: 60)),
      lastDate: now.add(const Duration(days: 90)),
      helpText: 'SELECCIONAR PRIMER DÍA',
    );

    if (picked != null) {
      setState(() {
        _fechaInicio = picked;
        if (_fechaFin != null && _fechaFin!.isBefore(picked)) {
          _fechaFin = picked;
        }
      });
      _actualizarFechasEnController();
    }
  }

  Future<void> _seleccionarFechaFin() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaFin ?? (_fechaInicio ?? now),
      firstDate: _fechaInicio ?? now.subtract(const Duration(days: 60)),
      lastDate: now.add(const Duration(days: 90)),
      helpText: 'SELECCIONAR ÚLTIMO DÍA',
    );

    if (picked != null) {
      setState(() => _fechaFin = picked);
      _actualizarFechasEnController();
    }
  }

  void _actualizarFechasEnController() {
    if (_fechaInicio != null && _fechaFin != null) {
      ref.read(formPermisoControllerProvider.notifier).setFechas(
            _dateFormat.format(_fechaInicio!),
            _dateFormat.format(_fechaFin!),
            _diasOtorgados,
          );
    }
  }

  Future<void> _tomarFoto({bool dispararOcr = false}) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
        requestFullMetadata: false,
      );

      if (photo != null) {
        setState(() => _archivoAdjunto = File(photo.path));
        ref.read(formPermisoControllerProvider.notifier).setFilePath(photo.path);

        if (dispararOcr) {
          await _procesarConOcr(photo.path);
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo acceder a la cámara: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _seleccionarDeGaleria({bool dispararOcr = false}) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
        requestFullMetadata: false,
      );

      if (photo != null) {
        setState(() => _archivoAdjunto = File(photo.path));
        ref.read(formPermisoControllerProvider.notifier).setFilePath(photo.path);

        if (dispararOcr) {
          await _procesarConOcr(photo.path);
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo abrir la galería: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _seleccionarArchivoPdf() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (files.isNotEmpty && files.first.path != null) {
      final path = files.first.path!;
      setState(() => _archivoAdjunto = File(path));
      ref.read(formPermisoControllerProvider.notifier).setFilePath(path);
    }
  }

  Future<void> _procesarConOcr(String path) async {
    final scan = await ref
        .read(formPermisoControllerProvider.notifier)
        .escanearOcr(path);

    if (!mounted) return;

    if (scan != null) {
      _iniciarCuentaRegresiva();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Certificado digitalizado y reconocido con éxito'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      final errorMsg = ref.read(formPermisoControllerProvider).errorMessage ??
          'No se pudo leer la información del certificado médico.';

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.info_outline_rounded,
                  color: AppColors.primary, size: 24),
              SizedBox(width: 8),
              Expanded(
                child: Text('Verificación del Documento',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                errorMsg,
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 12),
              const Text(
                '• Asegúrate de que el documento esté bien iluminado y nítido.\n• Si prefieres, también puedes ingresar los datos directamente en "Registro Manual".',
                style: TextStyle(
                    fontSize: 12, color: AppColors.textSecondary, height: 1.4),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _tabController.animateTo(0);
              },
              child: const Text('Ingresar Manualmente'),
            ),
            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () {
                Navigator.pop(ctx);
                _tomarFoto(dispararOcr: true);
              },
              child: const Text('Tomar Otra Foto'),
            ),
          ],
        ),
      );
    }
  }

  // Pasa los datos extraídos de la IA a los campos del formulario manual y cambia a la pestaña 1
  void _pasarAlFormularioManual() {
    final formState = ref.read(formPermisoControllerProvider);
    final ocr = formState.ocrResult;

    if (ocr != null) {
      if (ocr.citt != null) _nroCertificadoController.text = ocr.citt!;
      if (ocr.cmp != null) _cmpController.text = ocr.cmp!;
      if (ocr.diagnostico != null && ocr.diagnostico!.trim().isNotEmpty) {
        _diagnosticoController.text = ocr.diagnostico!;
      } else {
        _diagnosticoController.text = 'Descanso médico institucional';
      }

      if (ocr.tipoOrigen != null) {
        if (ocr.tipoOrigen!.toUpperCase().contains('CITT')) {
          ref
              .read(formPermisoControllerProvider.notifier)
              .setTipoCertificado('CITT');
        } else if (ocr.tipoOrigen!.toUpperCase().contains('MINSA')) {
          ref
              .read(formPermisoControllerProvider.notifier)
              .setTipoCertificado('MINSA');
        } else {
          ref
              .read(formPermisoControllerProvider.notifier)
              .setTipoCertificado('PARTICULAR');
        }
      }

      if (ocr.fechaInicio != null) {
        try {
          _fechaInicio = DateTime.parse(ocr.fechaInicio!);
        } catch (_) {}
      }
      if (ocr.fechaFin != null) {
        try {
          _fechaFin = DateTime.parse(ocr.fechaFin!);
        } catch (_) {}
      }
      setState(() {});
      _actualizarFechasEnController();
    }

    // Cambiar a la pestaña de Registro Manual
    _tabController.animateTo(0);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'Datos del certificado transferidos al formulario. Verifique y presione Registrar Licencia.'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _enviarFormulario() async {
    if (!_formKey.currentState!.validate()) return;

    if (_fechaInicio == null || _fechaFin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Por favor seleccione las fechas de inicio y fin')),
      );
      return;
    }

    final notifier = ref.read(formPermisoControllerProvider.notifier);
    final success = await notifier.guardarPermiso(
      motivo: _diagnosticoController.text.isNotEmpty
          ? _diagnosticoController.text
          : 'Descanso médico registrado',
      nroCertificado: _nroCertificadoController.text.trim(),
      cmp: _cmpController.text.trim(),
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Licencia registrada y enviada a Bienestar Social / RRHH'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } else if (mounted) {
      final error = ref.read(formPermisoControllerProvider).errorMessage ??
          'Error al registrar la licencia';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(formPermisoControllerProvider);
    final authState = ref.watch(authControllerProvider);
    final personal = authState.personal;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        title: const Text('REGISTRAR DESCANSO MÉDICO'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Cerrar',
            onPressed: () => Navigator.pop(context),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12),
              border: isDark ? Border.all(color: const Color(0xFF334155)) : null,
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: isDark
                    ? Border.all(color: const Color(0xFF38BDF8).withOpacity(0.4))
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: isDark ? const Color(0xFF38BDF8) : AppColors.primary,
              unselectedLabelColor:
                  isDark ? const Color(0xFF94A3B8) : Colors.white.withOpacity(0.85),
              labelStyle:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: const [
                Tab(
                  icon: Icon(Icons.description_rounded, size: 18),
                  text: 'Registro Manual',
                ),
                Tab(
                  icon: Icon(Icons.document_scanner_rounded, size: 18),
                  text: 'Escanear',
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // PESTAÑA 1: REGISTRO MANUAL
          _buildPestanaManual(formState),

          // PESTAÑA 2: ESCÁNER INTELIGENTE CITT (GEMINI OCR)
          _buildPestanaEscaner(formState, personal),
        ],
      ),
    );
  }

  // ==========================================
  // PESTAÑA 1: FORMULARIO DE REGISTRO MANUAL
  // ==========================================
  Widget _buildPestanaManual(FormPermisoState formState) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? const Color(0xFFF8FAFC) : AppColors.textPrimary;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Selector de Tipo de Certificado (Radio Cards)
            _buildTipoCertificadoSelector(formState),
            const SizedBox(height: 20),

            // 2. Número de Certificado
            Text(
              'Número de Certificado',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: labelColor),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nroCertificadoController,
              decoration: InputDecoration(
                hintText: 'Ej. A-12345678',
                prefixIcon: Icon(Icons.badge_outlined,
                    color: isDark ? const Color(0xFF38BDF8) : AppColors.primary),
              ),
              validator: (v) {
                if (formState.tipoCertificado == 'CITT' &&
                    (v == null || v.trim().isEmpty)) {
                  return 'El número de CITT es obligatorio';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 3. Colegiatura Médica (CMP)
            Text(
              'Colegiatura Médica (CMP)',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: labelColor),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _cmpController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Ej. 094296',
                prefixIcon: Icon(Icons.medical_services_outlined,
                    color: isDark ? const Color(0xFF38BDF8) : AppColors.primary),
              ),
            ),
            const SizedBox(height: 16),

            // 4. Fechas (Desde y Hasta)
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Fecha de Inicio (Desde)',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: labelColor)),
                          Text('Primer día',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: isDark ? const Color(0xFF38BDF8) : AppColors.accent)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: _seleccionarFechaInicio,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 14),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: isDark ? const Color(0xFF334155) : AppColors.border),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _fechaInicio != null
                                    ? _dateFormat.format(_fechaInicio!)
                                    : 'Seleccionar',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _fechaInicio != null
                                      ? (isDark ? const Color(0xFFF8FAFC) : AppColors.textPrimary)
                                      : (isDark ? const Color(0xFF94A3B8) : AppColors.textMuted),
                                  fontWeight: _fechaInicio != null
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                              Icon(Icons.calendar_today_rounded,
                                  size: 16,
                                  color: isDark ? const Color(0xFF38BDF8) : AppColors.primary),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Fecha de Fin (Hasta)',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: labelColor)),
                          Text('Último día',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: isDark ? const Color(0xFF38BDF8) : AppColors.accent)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: _seleccionarFechaFin,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 14),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: isDark ? const Color(0xFF334155) : AppColors.border),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _fechaFin != null
                                    ? _dateFormat.format(_fechaFin!)
                                    : 'Seleccionar',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _fechaFin != null
                                      ? (isDark ? const Color(0xFFF8FAFC) : AppColors.textPrimary)
                                      : (isDark ? const Color(0xFF94A3B8) : AppColors.textMuted),
                                  fontWeight: _fechaFin != null
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                              Icon(Icons.calendar_today_rounded,
                                  size: 16,
                                  color: isDark ? const Color(0xFF38BDF8) : AppColors.primary),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 5. Días de Descanso Otorgados (Cálculo Automático)
            Text(
              'Días de Descanso Otorgados',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: labelColor),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : AppColors.surfaceVariant.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: isDark ? const Color(0xFF334155) : AppColors.border),
              ),
              child: Text(
                _diasOtorgados > 0
                    ? '$_diasOtorgados día(s) de descanso'
                    : 'Esperando fechas...',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      _diasOtorgados > 0 ? FontWeight.bold : FontWeight.normal,
                  color: _diasOtorgados > 0
                      ? (isDark ? const Color(0xFF38BDF8) : AppColors.primary)
                      : (isDark ? const Color(0xFF94A3B8) : AppColors.textMuted),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 6. Diagnóstico / Código CIE-10
            Text(
              'Diagnóstico / Código CIE-10',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: labelColor),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _diagnosticoController,
              decoration: InputDecoration(
                hintText: 'Ej. Contusión en zona lumbosacro (S30.0)',
                prefixIcon: Icon(Icons.healing_rounded,
                    color: isDark ? const Color(0xFF38BDF8) : AppColors.primary),
              ),
            ),
            const SizedBox(height: 20),

            // 7. Evidencia del Descanso (Obligatorio)
            Row(
              children: [
                Text('Evidencia del Descanso',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: labelColor)),
                const SizedBox(width: 6),
                const Text('(Obligatorio)',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: AppColors.error)),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(
                          color: isDark ? const Color(0xFF38BDF8) : AppColors.primary),
                      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: Icon(Icons.camera_alt_rounded,
                        size: 18,
                        color: isDark ? const Color(0xFF38BDF8) : AppColors.primary),
                    label: Text('Tomar Foto',
                        style: TextStyle(
                            fontSize: 12,
                            color: isDark ? const Color(0xFF38BDF8) : AppColors.primary)),
                    onPressed: () => _tomarFoto(dispararOcr: false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(
                          color: isDark ? const Color(0xFF38BDF8) : AppColors.primary),
                      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: Icon(Icons.upload_file_rounded,
                        size: 18,
                        color: isDark ? const Color(0xFF38BDF8) : AppColors.primary),
                    label: Text('Subir Archivo / PDF',
                        style: TextStyle(
                            fontSize: 12,
                            color: isDark ? const Color(0xFF38BDF8) : AppColors.primary)),
                    onPressed: _seleccionarArchivoPdf,
                  ),
                ),
              ],
            ),

            if (_archivoAdjunto != null) ...[
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF064E3B).withOpacity(0.3) : AppColors.successBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: isDark ? const Color(0xFF059669) : AppColors.success.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: AppColors.success, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _archivoAdjunto!.path.split(RegExp(r'[/\\]')).last,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark ? const Color(0xFF34D399) : AppColors.success),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded,
                          size: 18,
                          color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary),
                      onPressed: () => setState(() => _archivoAdjunto = null),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 28),

            // Botones Cancelar y Registrar Licencia
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancelar',
                        style: TextStyle(
                            color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? const Color(0xFF0284C7) : AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: formState.isLoading
                        ? const SizedBox.shrink()
                        : const Icon(Icons.check_circle_outline_rounded,
                            color: Colors.white, size: 18),
                    label: formState.isLoading
                        ? const SpinKitThreeBounce(
                            color: Colors.white, size: 18)
                        : const Text('Registrar Licencia',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                    onPressed: formState.isLoading ? null : _enviarFormulario,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Selector de Tarjetas de Tipo de Certificado (CITT EsSalud, Particular, MINSA)
  Widget _buildTipoCertificadoSelector(FormPermisoState formState) {
    return Column(
      children: [
        _buildRadioOptionCard(
          codigo: 'CITT',
          titulo: 'CITT EsSalud',
          subtitulo: 'Descanso médico institucional',
          seleccionado: formState.tipoCertificado == 'CITT',
        ),
        const SizedBox(height: 8),
        _buildRadioOptionCard(
          codigo: 'PARTICULAR',
          titulo: 'Particular (CMP)',
          subtitulo: 'Especie valorada o clínica',
          seleccionado: formState.tipoCertificado == 'PARTICULAR',
        ),
        const SizedBox(height: 8),
        _buildRadioOptionCard(
          codigo: 'MINSA',
          titulo: 'MINSA (Ley Nº 30012)',
          subtitulo: 'Familiar grave o terminal',
          seleccionado: formState.tipoCertificado == 'MINSA',
        ),
      ],
    );
  }

  Widget _buildRadioOptionCard({
    required String codigo,
    required String titulo,
    required String subtitulo,
    required bool seleccionado,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () {
        ref
            .read(formPermisoControllerProvider.notifier)
            .setTipoCertificado(codigo);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: seleccionado
              ? (isDark ? const Color(0xFF0284C7).withOpacity(0.15) : AppColors.primary.withOpacity(0.04))
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: seleccionado
                ? (isDark ? const Color(0xFF38BDF8) : AppColors.primary)
                : (isDark ? const Color(0xFF334155) : AppColors.border),
            width: seleccionado ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              seleccionado
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: seleccionado
                  ? (isDark ? const Color(0xFF38BDF8) : AppColors.primary)
                  : (isDark ? const Color(0xFF64748B) : AppColors.textMuted),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: seleccionado
                          ? (isDark ? const Color(0xFF38BDF8) : AppColors.primary)
                          : (isDark ? const Color(0xFFF8FAFC) : AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitulo,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // PESTAÑA 2: ESCÁNER INTELIGENTE CON IA
  // ==========================================
  Widget _buildPestanaEscaner(FormPermisoState formState, dynamic personal) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (formState.isScanningOcr) {
      return _buildScanningOverlay(isDark);
    }

    // Si ya hay resultado de OCR, mostramos la pre-visualización idéntica a la web
    if (formState.ocrResult != null) {
      return _buildResultadoEscanerCard(formState, personal, isDark);
    }

    // Pantalla Inicial: Invitar a Escanear
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0284C7).withOpacity(0.18)
                    : AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.document_scanner_rounded,
                size: 64,
                color: isDark ? const Color(0xFF38BDF8) : AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Escáner Digital CITT',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFFF8FAFC) : AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Toma una foto clara a tu certificado médico de EsSalud o clínica para digitalizar y completar todos los datos automáticamente.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13,
                  color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                  height: 1.4),
            ),
            const SizedBox(height: 28),

            // Botón Principal de Cámara
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? const Color(0xFF0284C7) : AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.camera_alt_rounded, color: Colors.white),
              label: const Text('Tomar Foto del Certificado',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              onPressed: () => _tomarFoto(dispararOcr: true),
            ),
            const SizedBox(height: 12),

            // Botón Galería
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                side: BorderSide(
                    color: isDark ? const Color(0xFF38BDF8) : AppColors.primary),
                backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: Icon(Icons.photo_library_rounded,
                  color: isDark ? const Color(0xFF38BDF8) : AppColors.primary),
              label: Text('Seleccionar Foto de la Galería',
                  style: TextStyle(
                      color: isDark ? const Color(0xFF38BDF8) : AppColors.primary,
                      fontWeight: FontWeight.w600)),
              onPressed: () => _seleccionarDeGaleria(dispararOcr: true),
            ),
          ],
        ),
      ),
    );
  }

  // Vista de Simulación de Escáner Láser con la Imagen Real del Usuario
  Widget _buildScanningOverlay(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          // Badge superior de estado
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.radar_rounded, color: AppColors.primary, size: 15),
                SizedBox(width: 8),
                Text(
                  'ESCANEANDO DOCUMENTO...',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Marco del Documento con Láser Animado (Más compacto y estilizado)
          Container(
            height: 270,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.cyan.withOpacity(0.2),
                  blurRadius: 14,
                  spreadRadius: 1,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Imagen real que el usuario tomó
                  if (_archivoAdjunto != null)
                    Image.file(
                      _archivoAdjunto!,
                      fit: BoxFit.cover,
                      cacheWidth: 800,
                    )
                  else
                    Container(
                      color: const Color(0xFF1E293B),
                      child: const Center(
                        child: Icon(Icons.document_scanner_rounded,
                            size: 64, color: Colors.white24),
                      ),
                    ),

                  // Overlay oscuro translúcido para alto contraste
                  Container(
                    color: Colors.black.withOpacity(0.25),
                  ),

                  // 4 Esquinas HUD / Brackets de Escáner
                  _buildHudCorner(top: 12, left: 12, isTop: true, isLeft: true),
                  _buildHudCorner(top: 12, right: 12, isTop: true, isLeft: false),
                  _buildHudCorner(bottom: 12, left: 12, isTop: false, isLeft: true),
                  _buildHudCorner(bottom: 12, right: 12, isTop: false, isLeft: false),

                  // Línea Láser Animada que sube y baja
                  AnimatedBuilder(
                    animation: _laserAnimation,
                    builder: (context, child) {
                      final double laserPos =
                          _laserAnimation.value * (270 - 45);
                      return Positioned(
                        top: laserPos,
                        left: 0,
                        right: 0,
                        child: Column(
                          children: [
                            // Haz de luz brillante degradado
                            Container(
                              height: 34,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.cyanAccent.withOpacity(0.0),
                                    Colors.cyanAccent.withOpacity(0.35),
                                  ],
                                ),
                              ),
                            ),
                            // Línea de corte láser horizontal
                            Container(
                              height: 3,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Colors.cyanAccent,
                                    Colors.white,
                                    Colors.cyanAccent,
                                    Colors.transparent,
                                  ],
                                  stops: [0.0, 0.2, 0.5, 0.8, 1.0],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.cyanAccent.withOpacity(0.9),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  // Badge institucional en la esquina inferior del visor
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Colors.cyanAccent.withOpacity(0.6)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.qr_code_scanner_rounded,
                              color: Colors.cyanAccent, size: 13),
                          SizedBox(width: 5),
                          Text(
                            'DOCUMENTO EN LECTURA',
                            style: TextStyle(
                              color: Colors.cyanAccent,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Indicador de Progreso y Textos
          SpinKitThreeBounce(
              color: isDark ? const Color(0xFF38BDF8) : AppColors.primary,
              size: 20),
          const SizedBox(height: 12),
          Text(
            'Procesando Certificado Médico...',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFFF8FAFC) : AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'Extrayendo N° de documento, colegiatura CMP, fechas de reposo y diagnóstico...',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 11,
                color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                height: 1.35),
          ),
        ],
      ),
    );
  }

  Widget _buildHudCorner({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required bool isTop,
    required bool isLeft,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          border: Border(
            top: isTop
                ? const BorderSide(color: Colors.cyanAccent, width: 3)
                : BorderSide.none,
            bottom: !isTop
                ? const BorderSide(color: Colors.cyanAccent, width: 3)
                : BorderSide.none,
            left: isLeft
                ? const BorderSide(color: Colors.cyanAccent, width: 3)
                : BorderSide.none,
            right: !isLeft
                ? const BorderSide(color: Colors.cyanAccent, width: 3)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }

  // Vista de Resultados del Escáner (Diseño Limpio, Compacto y Profesional)
  Widget _buildResultadoEscanerCard(
      FormPermisoState formState, dynamic personal, bool isDark) {
    final ocr = formState.ocrResult!;
    final sNombre = ocr.servidorNombre ??
        personal?.nombreCompleto ??
        'PERSONAL DE LA RED';
    final sDni = ocr.servidorDni ?? personal?.dni ?? '';
    final estaBloqueado = _countdownSeconds > 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Barra de Estado Superior: Certificado Reconocido
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF064E3B).withOpacity(0.3) : AppColors.successBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: isDark ? const Color(0xFF059669) : AppColors.success.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: AppColors.success, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Certificado Médico Reconocido',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: isDark ? const Color(0xFF34D399) : AppColors.success),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () => _tomarFoto(dispararOcr: true),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Row(
                      children: [
                        Icon(Icons.refresh_rounded,
                            size: 15,
                            color: isDark ? const Color(0xFF38BDF8) : AppColors.primary),
                        const SizedBox(width: 4),
                        Text('Reescanear',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDark ? const Color(0xFF38BDF8) : AppColors.primary)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 2. Tarjeta Horizontal Compacta de la Evidencia Adjuntada
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: isDark ? const Color(0xFF334155) : Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.25 : 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Miniatura de la foto escaneada
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 54,
                    height: 54,
                    color: isDark ? const Color(0xFF0F172A) : Colors.grey.shade100,
                    child: _archivoAdjunto != null
                        ? Image.file(
                            _archivoAdjunto!,
                            fit: BoxFit.cover,
                            cacheWidth: 150,
                          )
                        : Icon(Icons.description_outlined,
                            size: 28,
                            color: isDark ? const Color(0xFF38BDF8) : AppColors.primary),
                  ),
                ),
                const SizedBox(width: 12),
                // Información del documento adjunto
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF064E3B).withOpacity(0.4)
                                  : AppColors.successBg,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_rounded,
                                    size: 11, color: AppColors.success),
                                const SizedBox(width: 3),
                                Text(
                                  'Evidencia Adjuntada',
                                  style: TextStyle(
                                      color: isDark ? const Color(0xFF34D399) : AppColors.success,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Foto del Descanso Médico',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFFF8FAFC) : AppColors.textPrimary),
                      ),
                      Text(
                        _archivoAdjunto != null
                            ? _archivoAdjunto!.path.split(RegExp(r'[/\\]')).last
                            : 'Documento CITT',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 10,
                            color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                // Botón cambiar foto
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    side: BorderSide(
                        color: isDark
                            ? const Color(0xFF38BDF8).withOpacity(0.5)
                            : Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _tomarFoto(dispararOcr: true),
                  child: Text('Cambiar',
                      style: TextStyle(
                          fontSize: 11,
                          color: isDark ? const Color(0xFF38BDF8) : AppColors.primary)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 3. Titular Identificado (Compacto)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E293B)
                  : AppColors.primary.withOpacity(0.04),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : AppColors.primary.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                Icon(Icons.badge_outlined,
                    color: isDark ? const Color(0xFF38BDF8) : AppColors.primary,
                    size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sNombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: isDark ? const Color(0xFFF8FAFC) : AppColors.textPrimary),
                      ),
                      Text(
                        sDni.isNotEmpty
                            ? 'DNI $sDni • Servidor Titular'
                            : 'Servidor Titular',
                        style: TextStyle(
                            fontSize: 10,
                            color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'TITULAR',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Alerta de DNI / Contingencia si la lectura detectó alguna discrepancia
          if (ocr.alertaContingencia != null &&
              ocr.alertaContingencia!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF164E63).withOpacity(0.4) : const Color(0xFFE0F7FA),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: isDark ? const Color(0xFF0891B2) : const Color(0xFF80DEEA)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF00838F),
                      size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ocr.alertaContingencia!,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? const Color(0xFFE0F2FE) : const Color(0xFF006064),
                        height: 1.3,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          // 4. Panel de Datos Extraídos en Formato Dashboard (2 Columnas)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: isDark ? const Color(0xFF334155) : Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fila 1: N° Certificado & Tipo / Origen
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 6,
                      child: _buildItemResumen(
                        label: 'N° CERTIFICADO',
                        valor: ocr.citt ?? 'Sin número',
                        esResaltado: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 5,
                      child: _buildItemResumen(
                        label: 'TIPO / DESTINO',
                        valor: ocr.tipoOrigen ?? 'Particular / MINSA',
                        chipColor: isDark
                            ? const Color(0xFF0284C7).withOpacity(0.25)
                            : AppColors.primary.withOpacity(0.08),
                        chipTextColor: isDark
                            ? const Color(0xFF38BDF8)
                            : AppColors.primary,
                      ),
                    ),
                  ],
                ),
                Divider(
                    height: 16,
                    color: isDark ? const Color(0xFF334155) : null),

                // Fila 2: Periodo de Descanso & Días Otorgados
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 6,
                      child: _buildItemResumen(
                        label: 'PERIODO AUTORIZADO',
                        valor:
                            '${ocr.fechaInicio ?? "--"} al ${ocr.fechaFin ?? "--"}',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 5,
                      child: _buildItemResumen(
                        label: 'DÍAS OTORGADOS',
                        valor: '${ocr.dias ?? formState.diasCalculados} día(s)',
                        chipColor: isDark
                            ? const Color(0xFF064E3B)
                            : AppColors.successBg,
                        chipTextColor: isDark
                            ? const Color(0xFF34D399)
                            : AppColors.success,
                        esResaltado: true,
                      ),
                    ),
                  ],
                ),

                // Fila 3: Médico Tratante & CMP (si existen)
                if (ocr.medicoTratante != null || ocr.cmp != null) ...[
                  Divider(
                      height: 16,
                      color: isDark ? const Color(0xFF334155) : null),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 6,
                        child: _buildItemResumen(
                          label: 'MÉDICO TRATANTE',
                          valor: ocr.medicoTratante ?? 'No especificado',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 5,
                        child: _buildItemResumen(
                          label: 'COLEGIATURA',
                          valor: ocr.cmp != null ? 'CMP ${ocr.cmp}' : '--',
                          chipColor: isDark
                              ? const Color(0xFF0284C7).withOpacity(0.25)
                              : AppColors.primary.withOpacity(0.08),
                          chipTextColor: isDark
                              ? const Color(0xFF38BDF8)
                              : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],

                // Fila 4: Diagnóstico CIE-10 (Siempre visible)
                Divider(
                    height: 16,
                    color: isDark ? const Color(0xFF334155) : null),
                _buildItemResumen(
                  label: 'DIAGNÓSTICO / CIE-10',
                  valor: (ocr.diagnostico != null &&
                          ocr.diagnostico!.trim().isNotEmpty)
                      ? ocr.diagnostico!
                      : 'Descanso médico institucional',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 5. Temporizador de 5 segundos para revisión de datos
          if (estaBloqueado)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF78350F).withOpacity(0.4)
                    : AppColors.warningBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: isDark
                        ? const Color(0xFFB45309)
                        : AppColors.warning.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  Icon(Icons.timer_outlined,
                      color: isDark ? const Color(0xFFFBBF24) : AppColors.warning,
                      size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Verifique los datos extraídos antes de continuar ($_countdownSeconds s)...',
                      style: TextStyle(
                          fontSize: 11,
                          color: isDark ? const Color(0xFFFEF3C7) : AppColors.primaryDark,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),

          // 6. Botón Único de Acción: Continuar al Formulario
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: estaBloqueado
                  ? (isDark ? const Color(0xFF334155) : Colors.grey.shade400)
                  : (isDark ? const Color(0xFF0284C7) : AppColors.primary),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: estaBloqueado ? null : _pasarAlFormularioManual,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!estaBloqueado) ...[
                  const Icon(Icons.check_circle_outline_rounded, size: 18),
                  const SizedBox(width: 8),
                ],
                Text(
                  estaBloqueado
                      ? 'Revisando información ($_countdownSeconds s)...'
                      : 'Continuar al Formulario y Guardar',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Botón Cancelar / Descartar
          TextButton(
            onPressed: () {
              _countdownTimer?.cancel();
              ref
                  .read(formPermisoControllerProvider.notifier)
                  .reiniciarEscaner();
            },
            child: Text('Descartar y volver',
                style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  Widget _buildItemResumen({
    required String label,
    required String valor,
    bool esResaltado = false,
    Color? chipColor,
    Color? chipTextColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color: AppColors.getTextSecondary(context),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 3),
        if (chipColor != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: chipColor,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              valor,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: chipTextColor ?? AppColors.getTextPrimary(context),
              ),
            ),
          )
        else
          Text(
            valor,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: esResaltado ? FontWeight.bold : FontWeight.w500,
              color: AppColors.getTextPrimary(context),
            ),
          ),
      ],
    );
  }
}
