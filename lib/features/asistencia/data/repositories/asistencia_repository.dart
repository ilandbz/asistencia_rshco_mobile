import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/asistencia_model.dart';

final asistenciaRepositoryProvider = Provider<AsistenciaRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return AsistenciaRepositoryImpl(dioClient: dioClient);
});

abstract class AsistenciaRepository {
  Future<MarcacionHoy> getMarcacionHoy();
  Future<RolMensual> getRolMensual({required int mes, required int anio});
  Future<FaltasTardanzasResumen> getResumenFaltasTardanzas({required int mes, required int anio});
  Future<List<RegistroAsistenciaItem>> getMisRegistros({required int mes, required int anio});
}

class AsistenciaRepositoryImpl implements AsistenciaRepository {
  final DioClient dioClient;

  AsistenciaRepositoryImpl({required this.dioClient});

  @override
  Future<MarcacionHoy> getMarcacionHoy() async {
    final response = await dioClient.get(ApiEndpoints.asistenciaHoy);
    final data = response.data is Map<String, dynamic> ? response.data : {};
    final content = data['data'] ?? data;
    return MarcacionHoy.fromJson(content as Map<String, dynamic>);
  }

  @override
  Future<RolMensual> getRolMensual({required int mes, required int anio}) async {
    final response = await dioClient.get(
      ApiEndpoints.miRolMes,
      queryParameters: {'mes': mes, 'anio': anio},
    );
    final data = response.data is Map<String, dynamic> ? response.data : {};
    final content = data['data'] ?? data;
    return RolMensual.fromJson(content as Map<String, dynamic>);
  }

  @override
  Future<FaltasTardanzasResumen> getResumenFaltasTardanzas({required int mes, required int anio}) async {
    final response = await dioClient.get(
      ApiEndpoints.faltasTardanzas,
      queryParameters: {'mes': mes, 'anio': anio},
    );
    final data = response.data is Map<String, dynamic> ? response.data : {};
    final content = data['data'] ?? data;
    return FaltasTardanzasResumen.fromJson(content as Map<String, dynamic>);
  }

  @override
  Future<List<RegistroAsistenciaItem>> getMisRegistros({required int mes, required int anio}) async {
    final response = await dioClient.get(
      ApiEndpoints.misRegistros,
      queryParameters: {'mes': mes, 'anio': anio},
    );
    final data = response.data;
    List list = [];
    if (data is Map<String, dynamic>) {
      list = data['detalle_dias'] ??
          data['registros'] ??
          data['asistencias'] ??
          data['historial'] ??
          data['data'] ??
          [];
    } else if (data is List) {
      list = data;
    }
    final parsed = list
        .map((item) => RegistroAsistenciaItem.fromJson(item as Map<String, dynamic>))
        .where((item) => item.debeMostrarEnHistorial)
        .toList();

    // Ordenar de más reciente (hoy / día 25) a más antiguo (día 1)
    parsed.sort((a, b) {
      final dateA = DateTime.tryParse(a.fecha);
      final dateB = DateTime.tryParse(b.fecha);
      if (dateA != null && dateB != null) {
        return dateB.compareTo(dateA);
      }
      return b.fecha.compareTo(a.fecha);
    });

    return parsed;
  }
}
