import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/cambio_turno_model.dart';
import '../../data/repositories/cambio_turno_repository.dart';

// Filtro de Estado para Listado de Solicitudes
final filtroEstadoCambioProvider = StateProvider<String?>((ref) => null);

final misCambiosTurnoProvider = FutureProvider.autoDispose<List<SolicitudCambioTurno>>((ref) async {
  final repo = ref.watch(cambioTurnoRepositoryProvider);
  final estado = ref.watch(filtroEstadoCambioProvider);
  return await repo.getMisCambios(estado: estado);
});

// Estado para el formulario de Creación de Solicitud de Cambio de Turno
class FormCambioTurnoState {
  final bool isLoading;
  final bool isValidating;
  final ColegaSearchResult? colega;
  final String? miFechaSeleccionada;
  final String? fechaTurnoColega;
  final String? colegaTurnoSigla;
  final ValidacionCambioTurnoResult? validacion;
  final String? errorMessage;
  final bool isSuccess;

  FormCambioTurnoState({
    this.isLoading = false,
    this.isValidating = false,
    this.colega,
    this.miFechaSeleccionada,
    this.fechaTurnoColega,
    this.colegaTurnoSigla,
    this.validacion,
    this.errorMessage,
    this.isSuccess = false,
  });

  FormCambioTurnoState copyWith({
    bool? isLoading,
    bool? isValidating,
    ColegaSearchResult? colega,
    String? miFechaSeleccionada,
    String? fechaTurnoColega,
    String? colegaTurnoSigla,
    ValidacionCambioTurnoResult? validacion,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return FormCambioTurnoState(
      isLoading: isLoading ?? this.isLoading,
      isValidating: isValidating ?? this.isValidating,
      colega: colega ?? this.colega,
      miFechaSeleccionada: miFechaSeleccionada ?? this.miFechaSeleccionada,
      fechaTurnoColega: fechaTurnoColega ?? this.fechaTurnoColega,
      colegaTurnoSigla: colegaTurnoSigla ?? this.colegaTurnoSigla,
      validacion: validacion ?? this.validacion,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

final formCambioTurnoControllerProvider =
    StateNotifierProvider.autoDispose<FormCambioTurnoNotifier, FormCambioTurnoState>((ref) {
  final repo = ref.watch(cambioTurnoRepositoryProvider);
  return FormCambioTurnoNotifier(repo: repo);
});

class FormCambioTurnoNotifier extends StateNotifier<FormCambioTurnoState> {
  final CambioTurnoRepository repo;

  FormCambioTurnoNotifier({required this.repo}) : super(FormCambioTurnoState());

  void setMiFecha(String fecha) {
    state = state.copyWith(miFechaSeleccionada: fecha);
  }

  Future<void> buscarColega(String dni) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final colega = await repo.buscarColegaPorDni(dni);
      state = state.copyWith(colega: colega, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'No se encontró al colega con DNI $dni en el establecimiento.',
      );
    }
  }

  Future<void> setFechaColega(String fecha) async {
    if (state.colega == null) return;
    state = state.copyWith(fechaTurnoColega: fecha);
    try {
      final turnoSigla = await repo.getTurnoColegaPorFecha(
        dni: state.colega!.dni,
        fecha: fecha,
      );
      state = state.copyWith(colegaTurnoSigla: turnoSigla);
    } catch (_) {
      state = state.copyWith(colegaTurnoSigla: 'D');
    }
  }

  Future<bool> prevalidar({required String motivo}) async {
    if (state.miFechaSeleccionada == null ||
        state.colega == null ||
        state.fechaTurnoColega == null) {
      state = state.copyWith(errorMessage: 'Por favor complete todos los campos requeridos.');
      return false;
    }

    state = state.copyWith(isValidating: true, errorMessage: null);
    try {
      final validacion = await repo.validarCambioTurno(
        fechaMiTurno: state.miFechaSeleccionada!,
        colegaDni: state.colega!.dni,
        fechaTurnoColega: state.fechaTurnoColega!,
        motivo: motivo,
      );

      state = state.copyWith(isValidating: false, validacion: validacion);
      return validacion.esValido;
    } catch (e) {
      state = state.copyWith(
        isValidating: false,
        errorMessage: 'Error en la validación: ${e.toString()}',
      );
      return false;
    }
  }

  Future<bool> enviarSolicitud({required String motivo}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await repo.storeCambioTurno(
        fechaMiTurno: state.miFechaSeleccionada!,
        colegaDni: state.colega!.dni,
        fechaTurnoColega: state.fechaTurnoColega!,
        motivo: motivo,
      );

      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al enviar solicitud: ${e.toString()}',
      );
      return false;
    }
  }
}
