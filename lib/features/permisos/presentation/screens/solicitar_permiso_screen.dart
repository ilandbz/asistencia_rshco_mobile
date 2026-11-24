import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/permiso_model.dart';
import '../controllers/permisos_controller.dart';

class SolicitarPermisoScreen extends ConsumerStatefulWidget {
  const SolicitarPermisoScreen({super.key});

  @override
  ConsumerState<SolicitarPermisoScreen> createState() => _SolicitarPermisoScreenState();
}

class _SolicitarPermisoScreenState extends ConsumerState<SolicitarPermisoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _motivoController = TextEditingController();
  final _cittController = TextEditingController();
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  DateTimeRange? _selectedDateRange;
  File? _selectedFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _motivoController.dispose();
    _cittController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarRangoFechas() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 90)),
      initialDateRange: _selectedDateRange ??
          DateTimeRange(start: now, end: now.add(const Duration(days: 1))),
    );

    if (picked != null) {
      setState(() => _selectedDateRange = picked);
      final inicio = _dateFormat.format(picked.start);
      final fin = _dateFormat.format(picked.end);
      ref.read(formPermisoControllerProvider.notifier).setFechas(inicio, fin);
    }
  }

  Future<void> _tomarFotoConCamara() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (photo != null) {
      setState(() => _selectedFile = File(photo.path));
      ref.read(formPermisoControllerProvider.notifier).setFilePath(photo.path);

      // Si es descanso médico o CIT, lanzar OCR inteligente
      final tipo = ref.read(formPermisoControllerProvider).tipoSeleccionado;
      if (tipo != null && tipo.requiereCit) {
        _escanearConOcr(photo.path);
      }
    }
  }

  Future<void> _seleccionarArchivo() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (files.isNotEmpty && files.first.path != null) {
      final path = files.first.path!;
      setState(() => _selectedFile = File(path));
      ref.read(formPermisoControllerProvider.notifier).setFilePath(path);
    }
  }

  Future<void> _escanearConOcr(String path) async {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
      const SnackBar(content: Text('Analizando documento CIT mediante OCR con IA...')),
    );

    final ocrResult = await ref.read(formPermisoControllerProvider.notifier).escanearOcr(path);
    if (ocrResult != null && mounted) {
      if (ocrResult.citt != null) {
        _cittController.text = ocrResult.citt!;
      }
      scaffold.showSnackBar(
        const SnackBar(
          content: Text('Lectura OCR completada. Verifique los datos extraídos.'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _enviarPermiso() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDateRange == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione el rango de fechas')),
      );
      return;
    }

    final formNotifier = ref.read(formPermisoControllerProvider.notifier);
    final success = await formNotifier.guardarPermiso(
      motivo: _motivoController.text.trim(),
      citt: _cittController.text.trim(),
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solicitud de permiso enviada satisfactoriamente'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tiposAsync = ref.watch(tiposPermisosProvider);
    final formState = ref.watch(formPermisoControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Solicitud de Permiso'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Selector de Tipo de Permiso
              const Text(
                '1. Tipo de Licencia o Permiso',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),

              tiposAsync.when(
                loading: () => const Center(child: SpinKitThreeBounce(color: AppColors.primary, size: 20)),
                error: (e, _) => Text('Error al cargar tipos: $e'),
                data: (tipos) {
                  return DropdownButtonFormField<TipoPermiso>(
                    value: formState.tipoSeleccionado,
                    hint: const Text('Seleccionar tipo de permiso'),
                    items: tipos.map((t) {
                      return DropdownMenuItem<TipoPermiso>(
                        value: t,
                        child: Text(t.nombre, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(formPermisoControllerProvider.notifier).setTipo(val);
                      }
                    },
                    validator: (v) => v == null ? 'Seleccione un tipo de permiso' : null,
                  );
                },
              ),
              const SizedBox(height: 20),

              // 2. Rango de Fechas
              const Text(
                '2. Período de Ausencia',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),

              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.border),
                ),
                tileColor: Colors.white,
                leading: const Icon(Icons.date_range_rounded, color: AppColors.primary),
                title: Text(
                  _selectedDateRange != null
                      ? '${_dateFormat.format(_selectedDateRange!.start)} hasta ${_dateFormat.format(_selectedDateRange!.end)} (${_selectedDateRange!.duration.inDays + 1} días)'
                      : 'Seleccionar fechas de inicio y fin',
                  style: TextStyle(
                    color: _selectedDateRange != null ? AppColors.textPrimary : AppColors.textMuted,
                    fontWeight: _selectedDateRange != null ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
                trailing: const Icon(Icons.arrow_drop_down_rounded),
                onTap: _seleccionarRangoFechas,
              ),
              const SizedBox(height: 20),

              // 3. Campo CITT (si aplica a CIT o Enfermedad)
              if (formState.tipoSeleccionado?.requiereCit == true) ...[
                const Text(
                  '3. Datos del Certificado (EsSalud / Médico)',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _cittController,
                  decoration: const InputDecoration(
                    labelText: 'N° de CITT o Colegiatura CMP',
                    hintText: 'Ej. C-12345678-2026',
                    prefixIcon: Icon(Icons.badge_rounded, color: AppColors.primary),
                  ),
                  validator: (v) {
                    if (formState.tipoSeleccionado?.requiereCit == true && (v == null || v.trim().isEmpty)) {
                      return 'El número de CITT / CMP es requerido para este permiso';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
              ],

              // 4. Adjuntar Documento o Foto OCR
              const Text(
                '4. Documento Sustentatorio / Foto',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
                      label: const Text('Tomar Foto'),
                      onPressed: _tomarFotoConCamara,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.attach_file_rounded, color: AppColors.primary),
                      label: const Text('PDF / Archivo'),
                      onPressed: _seleccionarArchivo,
                    ),
                  ),
                ],
              ),
              if (_selectedFile != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedFile!.path.split(RegExp(r'[/\\]')).last,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          setState(() => _selectedFile = null);
                          ref.read(formPermisoControllerProvider.notifier).setFilePath('');
                        },
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // 5. Motivo
              const Text(
                '5. Motivo o Justificación',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),

              TextFormField(
                controller: _motivoController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Explique detalladamente la justificación del permiso...',
                ),
                validator: (v) => (v == null || v.trim().length < 4) ? 'Ingrese una justificación válida' : null,
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

              // Botón Guardar
              ElevatedButton(
                onPressed: formState.isLoading ? null : _enviarPermiso,
                child: formState.isLoading
                    ? const SpinKitThreeBounce(color: Colors.white, size: 20)
                    : const Text('ENVIAR SOLICITUD DE PERMISO'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
