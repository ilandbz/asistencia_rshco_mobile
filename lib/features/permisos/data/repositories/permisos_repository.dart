import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/permiso_model.dart';

final permisosRepositoryProvider = Provider<PermisosRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return PermisosRepositoryImpl(dioClient: dioClient);
});

abstract class PermisosRepository {
  Future<List<TipoPermiso>> getTiposPermisos();
  Future<ResumenCit> getResumenCit();
  Future<List<SolicitudPermisoItem>> getMisPermisos();
  Future<OcrCitScanResult> escanearCitConOcr(String filePath);
  Future<void> guardarPermiso({
    required int tipoPermisoId,
    required String fechaInicio,
    required String fechaFin,
    required String motivo,
    String? cittNumero,
    String? filePath,
    String? detalleLicencia,
    String? colegiaturaMedico,
    String? diagnostico,
  });
}

class PermisosRepositoryImpl implements PermisosRepository {
  final DioClient dioClient;

  PermisosRepositoryImpl({required this.dioClient});

  @override
  Future<List<TipoPermiso>> getTiposPermisos() async {
    final response = await dioClient.get(ApiEndpoints.tiposPermisos);
    final data = response.data;
    List list = [];
    if (data is Map<String, dynamic>) {
      list = data['tipos'] ?? data['data'] ?? [];
    } else if (data is List) {
      list = data;
    }
    return list.map((item) => TipoPermiso.fromJson(item as Map<String, dynamic>)).toList();
  }

  @override
  Future<ResumenCit> getResumenCit() async {
    final response = await dioClient.get(ApiEndpoints.resumenCit);
    final data = response.data is Map<String, dynamic> ? response.data : {};
    final content = data['resumen'] ?? data['data'] ?? data;
    return ResumenCit.fromJson(content as Map<String, dynamic>);
  }

  @override
  Future<List<SolicitudPermisoItem>> getMisPermisos() async {
    final response = await dioClient.get(ApiEndpoints.listarPermisos);
    final data = response.data;
    List list = [];
    if (data is Map<String, dynamic>) {
      list = data['permisos'] ?? data['data'] ?? [];
    } else if (data is List) {
      list = data;
    }
    return list.map((item) => SolicitudPermisoItem.fromJson(item as Map<String, dynamic>)).toList();
  }

  @override
  Future<OcrCitScanResult> escanearCitConOcr(String filePath) async {
    final formData = FormData.fromMap({
      'archivo': await MultipartFile.fromFile(filePath, filename: 'cit_scan.jpg'),
    });

    final response = await dioClient.post(
      ApiEndpoints.ocrEscanear,
      data: formData,
      options: Options(
        sendTimeout: const Duration(seconds: 90),
        receiveTimeout: const Duration(seconds: 90),
      ),
    );
    final data = response.data is Map<String, dynamic> ? response.data : {};
    return OcrCitScanResult.fromJson(data);
  }

  @override
  Future<void> guardarPermiso({
    required int tipoPermisoId,
    required String fechaInicio,
    required String fechaFin,
    required String motivo,
    String? cittNumero,
    String? filePath,
    String? detalleLicencia,
    String? colegiaturaMedico,
    String? diagnostico,
  }) async {
    final map = <String, dynamic>{
      'tipo_permiso_id': tipoPermisoId,
      'fecha_desde': fechaInicio,
      'fecha_hasta': fechaFin,
      'fecha_inicio': fechaInicio,
      'fecha_fin': fechaFin,
      'motivo': motivo,
    };

    if (detalleLicencia != null && detalleLicencia.isNotEmpty) {
      map['detalle_licencia'] = detalleLicencia;
    }

    if (colegiaturaMedico != null && colegiaturaMedico.isNotEmpty) {
      map['colegiatura_medico'] = colegiaturaMedico;
      map['cmp'] = colegiaturaMedico;
    }

    if (cittNumero != null && cittNumero.isNotEmpty) {
      map['numero_certificado'] = cittNumero;
      map['citt_numero'] = cittNumero;
    }

    if (diagnostico != null && diagnostico.isNotEmpty) {
      map['diagnostico'] = diagnostico;
    }

    if (filePath != null && filePath.isNotEmpty) {
      final fileName = filePath.split(RegExp(r'[/\\]')).last;
      map['archivo'] = await MultipartFile.fromFile(filePath, filename: fileName);
    }

    final formData = FormData.fromMap(map);

    await dioClient.post(
      ApiEndpoints.guardarPermiso,
      data: formData,
    );
  }
}
