import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/cambio_turno_model.dart';

final cambioTurnoRepositoryProvider = Provider<CambioTurnoRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return CambioTurnoRepositoryImpl(dioClient: dioClient);
});

abstract class CambioTurnoRepository {
  Future<List<SolicitudCambioTurno>> getMisCambios({String? estado});
  Future<ColegaSearchResult> buscarColegaPorDni(String dni);
  Future<String> getTurnoColegaPorFecha({required String dni, required String fecha});
  Future<ValidacionCambioTurnoResult> validarCambioTurno({
    required String fechaMiTurno,
    required String colegaDni,
    required String fechaTurnoColega,
    required String motivo,
  });
  Future<void> storeCambioTurno({
    required String fechaMiTurno,
    required String colegaDni,
    required String fechaTurnoColega,
    required String motivo,
  });
}

class CambioTurnoRepositoryImpl implements CambioTurnoRepository {
  final DioClient dioClient;

  CambioTurnoRepositoryImpl({required this.dioClient});

  @override
  Future<List<SolicitudCambioTurno>> getMisCambios({String? estado}) async {
    final response = await dioClient.get(
      ApiEndpoints.misCambiosTurno,
      queryParameters: estado != null ? {'estado': estado} : null,
    );
    final data = response.data;
    List list = [];
    if (data is Map<String, dynamic>) {
      list = data['cambios'] ?? data['data'] ?? [];
    } else if (data is List) {
      list = data;
    }
    return list.map((item) => SolicitudCambioTurno.fromJson(item as Map<String, dynamic>)).toList();
  }

  @override
  Future<ColegaSearchResult> buscarColegaPorDni(String dni) async {
    final response = await dioClient.post(
      ApiEndpoints.obtenerPersonalPorDni,
      data: {'dni': dni.trim()},
    );
    final data = response.data is Map<String, dynamic> ? response.data : {};
    final personalData = data['personal'] ?? data['data'] ?? data;
    return ColegaSearchResult.fromJson(personalData as Map<String, dynamic>);
  }

  @override
  Future<String> getTurnoColegaPorFecha({required String dni, required String fecha}) async {
    final response = await dioClient.post(
      ApiEndpoints.turnoPorFechaPersonal,
      data: {'dni': dni.trim(), 'fecha': fecha},
    );
    final data = response.data is Map<String, dynamic> ? response.data : {};
    return data['sigla']?.toString() ?? data['turno']?.toString() ?? 'D';
  }

  @override
  Future<ValidacionCambioTurnoResult> validarCambioTurno({
    required String fechaMiTurno,
    required String colegaDni,
    required String fechaTurnoColega,
    required String motivo,
  }) async {
    final response = await dioClient.post(
      ApiEndpoints.validarCambioTurno,
      data: {
        'fecha_mi_turno': fechaMiTurno,
        'colega_dni': colegaDni,
        'fecha_turno_colega': fechaTurnoColega,
        'motivo': motivo,
      },
    );
    return ValidacionCambioTurnoResult.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> storeCambioTurno({
    required String fechaMiTurno,
    required String colegaDni,
    required String fechaTurnoColega,
    required String motivo,
  }) async {
    await dioClient.post(
      ApiEndpoints.storeCambioTurno,
      data: {
        'fecha_mi_turno': fechaMiTurno,
        'colega_dni': colegaDni,
        'fecha_turno_colega': fechaTurnoColega,
        'motivo': motivo,
      },
    );
  }
}
