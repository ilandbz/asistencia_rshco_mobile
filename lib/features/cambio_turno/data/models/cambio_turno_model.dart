import 'package:equatable/equatable.dart';

class SolicitudCambioTurno extends Equatable {
  final int id;
  final String fechaSolicitud;
  final String fechaMiTurno;
  final String miTurnoSigla;
  final String colegaDni;
  final String colegaNombre;
  final String fechaTurnoColega;
  final String colegaTurnoSigla;
  final String motivo;
  final String estado; // SOLICITADO, APROBADO, RECHAZADO, EJECUTADO
  final String? motivoRechazo;

  const SolicitudCambioTurno({
    required this.id,
    required this.fechaSolicitud,
    required this.fechaMiTurno,
    required this.miTurnoSigla,
    required this.colegaDni,
    required this.colegaNombre,
    required this.fechaTurnoColega,
    required this.colegaTurnoSigla,
    required this.motivo,
    required this.estado,
    this.motivoRechazo,
  });

  factory SolicitudCambioTurno.fromJson(Map<String, dynamic> json) {
    return SolicitudCambioTurno(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      fechaSolicitud: json['fecha_solicitud']?.toString() ?? '',
      fechaMiTurno: json['fecha_mi_turno']?.toString() ?? json['fecha_turno_origen']?.toString() ?? '',
      miTurnoSigla: json['mi_turno_sigla']?.toString() ?? json['turno_origen']?.toString() ?? '',
      colegaDni: json['colega_dni']?.toString() ?? '',
      colegaNombre: json['colega_nombre']?.toString() ?? json['nombre_colega']?.toString() ?? '',
      fechaTurnoColega: json['fecha_turno_colega']?.toString() ?? json['fecha_turno_destino']?.toString() ?? '',
      colegaTurnoSigla: json['colega_turno_sigla']?.toString() ?? json['turno_destino']?.toString() ?? '',
      motivo: json['motivo']?.toString() ?? '',
      estado: json['estado']?.toString() ?? 'SOLICITADO',
      motivoRechazo: json['motivo_rechazo']?.toString(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        fechaSolicitud,
        fechaMiTurno,
        miTurnoSigla,
        colegaDni,
        colegaNombre,
        fechaTurnoColega,
        colegaTurnoSigla,
        motivo,
        estado,
        motivoRechazo,
      ];
}

class ColegaSearchResult extends Equatable {
  final int id;
  final String dni;
  final String nombreCompleto;
  final String? cargo;
  final String? establecimiento;

  const ColegaSearchResult({
    required this.id,
    required this.dni,
    required this.nombreCompleto,
    this.cargo,
    this.establecimiento,
  });

  factory ColegaSearchResult.fromJson(Map<String, dynamic> json) {
    return ColegaSearchResult(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      dni: json['dni']?.toString() ?? json['numero_documento']?.toString() ?? '',
      nombreCompleto: json['nombre_completo']?.toString() ??
          '${json['nombres'] ?? ''} ${json['apellido_paterno'] ?? ''}'.trim(),
      cargo: json['cargo']?.toString(),
      establecimiento: json['establecimiento']?.toString(),
    );
  }

  @override
  List<Object?> get props => [id, dni, nombreCompleto, cargo, establecimiento];
}

class ValidacionCambioTurnoResult extends Equatable {
  final bool esValido;
  final String mensaje;
  final List<String> advertencias;

  const ValidacionCambioTurnoResult({
    required this.esValido,
    required this.mensaje,
    this.advertencias = const [],
  });

  factory ValidacionCambioTurnoResult.fromJson(Map<String, dynamic> json) {
    final list = json['advertencias'] is List ? (json['advertencias'] as List).map((e) => e.toString()).toList() : <String>[];
    return ValidacionCambioTurnoResult(
      esValido: json['es_valido'] == true || json['valido'] == true || json['status'] == 'success',
      mensaje: json['message']?.toString() ?? json['mensaje']?.toString() ?? 'Validación completada',
      advertencias: list,
    );
  }

  @override
  List<Object?> get props => [esValido, mensaje, advertencias];
}
