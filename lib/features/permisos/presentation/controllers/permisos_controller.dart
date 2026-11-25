import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/permiso_model.dart';
import '../../data/repositories/permisos_repository.dart';

final tiposPermisosProvider =
    FutureProvider.autoDispose<List<TipoPermiso>>((ref) async {
  final repo = ref.watch(permisosRepositoryProvider);
  return await repo.getTiposPermisos();
});

final resumenCitProvider = FutureProvider.autoDispose<ResumenCit>((ref) async {
  final repo = ref.watch(permisosRepositoryProvider);
  return await repo.getResumenCit();
});

final misPermisosProvider =
    FutureProvider.autoDispose<List<SolicitudPermisoItem>>((ref) async {
  final repo = ref.watch(permisosRepositoryProvider);
  return await repo.getMisPermisos();
});

class FormPermisoState {
  final bool isLoading;
  final bool isScanningOcr;
  final String tipoCertificado; // 'CITT' | 'PARTICULAR' | 'MINSA'
  final TipoPermiso? tipoSeleccionado;
  final String? nroCertificado;
  final String? cmp;
  final String? fechaInicio;
  final String? fechaFin;
  final int diasCalculados;
  final String? diagnostico;
  final String? filePath;
  final OcrCitScanResult? ocrResult;
  final String? errorMessage;
  final bool isSuccess;

  FormPermisoState({
    this.isLoading = false,
    this.isScanningOcr = false,
    this.tipoCertificado = 'CITT',
    this.tipoSeleccionado,
    this.nroCertificado,
    this.cmp,
    this.fechaInicio,
    this.fechaFin,
    this.diasCalculados = 0,
    this.diagnostico,
    this.filePath,
    this.ocrResult,
    this.errorMessage,
    this.isSuccess = false,
  });

  FormPermisoState copyWith({
    bool? isLoading,
    bool? isScanningOcr,
    String? tipoCertificado,
    TipoPermiso? tipoSeleccionado,
    String? nroCertificado,
    String? cmp,
    String? fechaInicio,
    String? fechaFin,
    int? diasCalculados,
    String? diagnostico,
    String? filePath,
    OcrCitScanResult? ocrResult,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return FormPermisoState(
      isLoading: isLoading ?? this.isLoading,
      isScanningOcr: isScanningOcr ?? this.isScanningOcr,
      tipoCertificado: tipoCertificado ?? this.tipoCertificado,
      tipoSeleccionado: tipoSeleccionado ?? this.tipoSeleccionado,
      nroCertificado: nroCertificado ?? this.nroCertificado,
      cmp: cmp ?? this.cmp,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      diasCalculados: diasCalculados ?? this.diasCalculados,
      diagnostico: diagnostico ?? this.diagnostico,
      filePath: filePath ?? this.filePath,
      ocrResult: ocrResult ?? this.ocrResult,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

final formPermisoControllerProvider =
    StateNotifierProvider.autoDispose<FormPermisoNotifier, FormPermisoState>(
        (ref) {
  final repo = ref.watch(permisosRepositoryProvider);
  return FormPermisoNotifier(repo: repo);
});

class FormPermisoNotifier extends StateNotifier<FormPermisoState> {
  final PermisosRepository repo;

  FormPermisoNotifier({required this.repo}) : super(FormPermisoState());

  void setTipoCertificado(String codigo) {
    state = state.copyWith(tipoCertificado: codigo);
  }

  void setTipo(TipoPermiso tipo) {
    state = state.copyWith(tipoSeleccionado: tipo);
  }

  void setFechas(String inicio, String fin, int dias) {
    state = state.copyWith(
      fechaInicio: inicio,
      fechaFin: fin,
      diasCalculados: dias,
    );
  }

  void setFilePath(String path) {
    state = state.copyWith(filePath: path);
  }

  void setDatosManuales({
    String? nroCertificado,
    String? cmp,
    String? diagnostico,
  }) {
    state = state.copyWith(
      nroCertificado: nroCertificado ?? state.nroCertificado,
      cmp: cmp ?? state.cmp,
      diagnostico: diagnostico ?? state.diagnostico,
    );
  }

  /// Envía la foto al backend para que Gemini realice el escaneo inteligente
  Future<OcrCitScanResult?> escanearOcr(String path) async {
    state =
        state.copyWith(isScanningOcr: true, filePath: path, errorMessage: null);
    try {
      final scan = await repo.escanearCitConOcr(path);

      // VALIDACIÓN: Si no detectó ningún dato médico válido (ej. foto aleatoria o selfie)
      if (!scan.esCertificadoValido) {
        state = state.copyWith(
          isScanningOcr: false,
          ocrResult: null,
          errorMessage: 'No se detectó un certificado médico válido en la imagen. Por favor suba una foto clara y enfocada de su CITT o descanso médico.',
        );
        return null;
      }

      // Determinar días
      int dias = scan.dias ?? 1;
      if (scan.fechaInicio != null && scan.fechaFin != null) {
        try {
          final dInicio = DateTime.parse(scan.fechaInicio!);
          final dFin = DateTime.parse(scan.fechaFin!);
          dias = dFin.difference(dInicio).inDays + 1;
        } catch (_) {}
      }

      // Sincronizar tipo de certificado según origen detectado
      String tipoOrigen = state.tipoCertificado;
      if (scan.tipoOrigen != null) {
        final origUpper = scan.tipoOrigen!.toUpperCase();
        if (origUpper.contains('PARTICULAR')) {
          tipoOrigen = 'PARTICULAR';
        } else if (origUpper.contains('MINSA') || origUpper.contains('30012')) {
          tipoOrigen = 'MINSA';
        } else {
          tipoOrigen = 'CITT';
        }
      }

      state = state.copyWith(
        isScanningOcr: false,
        ocrResult: scan,
        nroCertificado: scan.citt,
        cmp: scan.cmp,
        fechaInicio: scan.fechaInicio ?? state.fechaInicio,
        fechaFin: scan.fechaFin ?? state.fechaFin,
        diasCalculados: dias,
        diagnostico: scan.diagnostico,
        tipoCertificado: tipoOrigen,
        errorMessage: null,
      );
      return scan;
    } catch (e) {
      String msg = 'No se pudo procesar el certificado digital.';
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map) {
          final serverMsg = data['mensaje']?.toString() ?? data['message']?.toString();
          if (serverMsg != null && serverMsg.isNotEmpty) {
            if (serverMsg.contains('timed out') || serverMsg.contains('cURL error 28')) {
              msg = 'El servidor de lectura demoró en responder debido a saturación temporal de red. Por favor reintente en unos segundos.';
            } else if (serverMsg.contains('503') || serverMsg.contains('high demand') || serverMsg.contains('UNAVAILABLE')) {
              msg = 'El servicio de digitalización experimentó alta demanda en el servidor. Por favor presione "Reintentar Foto" o ingrese los datos manualmente.';
            } else {
              msg = serverMsg;
            }
          }
        } else if (e.type == DioExceptionType.receiveTimeout || e.type == DioExceptionType.connectionTimeout) {
          msg = 'Tiempo de espera agotado al conectar con el servidor. Verifique su conexión y vuelva a intentar.';
        }
      } else {
        final str = e.toString();
        if (str.contains('SocketException')) {
          msg = 'No se pudo conectar con el servidor. Verifique su conexión a internet.';
        }
      }
      state = state.copyWith(
        isScanningOcr: false,
        errorMessage: msg,
      );
      return null;
    }
  }

  /// Limpia el resultado del escáner para tomar otra foto
  void reiniciarEscaner() {
    state = state.copyWith(
      ocrResult: null,
      filePath: null,
      errorMessage: null,
    );
  }

  Future<bool> guardarPermiso({
    required String motivo,
    int? tipoPermisoId,
    String? nroCertificado,
    String? cmp,
  }) async {
    final fInicio = state.fechaInicio;
    final fFin = state.fechaFin;

    if (fInicio == null || fFin == null) {
      state =
          state.copyWith(errorMessage: 'Debe seleccionar el rango de fechas');
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      // Para descansos médicos el tipo_permiso_id es 8 (LICENCIA POR SALUD)
      final permisoId = tipoPermisoId ?? state.tipoSeleccionado?.id ?? 8;
      final detalle = state.tipoCertificado == 'CITT'
          ? 'ESSALUD'
          : (state.tipoCertificado == 'MINSA' ? 'LEY 30012' : 'PARTICULAR');

      await repo.guardarPermiso(
        tipoPermisoId: permisoId,
        fechaInicio: fInicio,
        fechaFin: fFin,
        motivo: motivo.isEmpty ? 'Descanso médico registrado' : motivo,
        cittNumero: nroCertificado ?? state.nroCertificado,
        filePath: state.filePath,
        detalleLicencia: detalle,
        colegiaturaMedico: cmp ?? state.cmp,
        diagnostico: state.diagnostico,
      );

      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al registrar permiso: ${e.toString()}',
      );
      return false;
    }
  }
}
