import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/permiso_model.dart';
import '../../data/repositories/permisos_repository.dart';

final tiposPermisosProvider = FutureProvider.autoDispose<List<TipoPermiso>>((ref) async {
  final repo = ref.watch(permisosRepositoryProvider);
  return await repo.getTiposPermisos();
});

final resumenCitProvider = FutureProvider.autoDispose<ResumenCit>((ref) async {
  final repo = ref.watch(permisosRepositoryProvider);
  return await repo.getResumenCit();
});

final misPermisosProvider = FutureProvider.autoDispose<List<SolicitudPermisoItem>>((ref) async {
  final repo = ref.watch(permisosRepositoryProvider);
  return await repo.getMisPermisos();
});

class FormPermisoState {
  final bool isLoading;
  final bool isScanningOcr;
  final TipoPermiso? tipoSeleccionado;
  final String? fechaInicio;
  final String? fechaFin;
  final String? cittNumero;
  final String? filePath;
  final String? errorMessage;
  final bool isSuccess;

  FormPermisoState({
    this.isLoading = false,
    this.isScanningOcr = false,
    this.tipoSeleccionado,
    this.fechaInicio,
    this.fechaFin,
    this.cittNumero,
    this.filePath,
    this.errorMessage,
    this.isSuccess = false,
  });

  FormPermisoState copyWith({
    bool? isLoading,
    bool? isScanningOcr,
    TipoPermiso? tipoSeleccionado,
    String? fechaInicio,
    String? fechaFin,
    String? cittNumero,
    String? filePath,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return FormPermisoState(
      isLoading: isLoading ?? this.isLoading,
      isScanningOcr: isScanningOcr ?? this.isScanningOcr,
      tipoSeleccionado: tipoSeleccionado ?? this.tipoSeleccionado,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      cittNumero: cittNumero ?? this.cittNumero,
      filePath: filePath ?? this.filePath,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

final formPermisoControllerProvider =
    StateNotifierProvider.autoDispose<FormPermisoNotifier, FormPermisoState>((ref) {
  final repo = ref.watch(permisosRepositoryProvider);
  return FormPermisoNotifier(repo: repo);
});

class FormPermisoNotifier extends StateNotifier<FormPermisoState> {
  final PermisosRepository repo;

  FormPermisoNotifier({required this.repo}) : super(FormPermisoState());

  void setTipo(TipoPermiso tipo) {
    state = state.copyWith(tipoSeleccionado: tipo);
  }

  void setFechas(String inicio, String fin) {
    state = state.copyWith(fechaInicio: inicio, fechaFin: fin);
  }

  void setFilePath(String path) {
    state = state.copyWith(filePath: path);
  }

  Future<OcrCitScanResult?> escanearOcr(String path) async {
    state = state.copyWith(isScanningOcr: true, filePath: path, errorMessage: null);
    try {
      final scan = await repo.escanearCitConOcr(path);
      state = state.copyWith(
        isScanningOcr: false,
        cittNumero: scan.citt,
        fechaInicio: scan.fechaInicio ?? state.fechaInicio,
        fechaFin: scan.fechaFin ?? state.fechaFin,
      );
      return scan;
    } catch (e) {
      state = state.copyWith(
        isScanningOcr: false,
        errorMessage: 'El escaneo OCR falló. Por favor complete los datos manualmente.',
      );
      return null;
    }
  }

  Future<bool> guardarPermiso({
    required String motivo,
    String? citt,
  }) async {
    if (state.tipoSeleccionado == null || state.fechaInicio == null || state.fechaFin == null) {
      state = state.copyWith(errorMessage: 'Seleccione el tipo y rango de fechas');
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await repo.guardarPermiso(
        tipoPermisoId: state.tipoSeleccionado!.id,
        fechaInicio: state.fechaInicio!,
        fechaFin: state.fechaFin!,
        motivo: motivo,
        cittNumero: citt ?? state.cittNumero,
        filePath: state.filePath,
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
