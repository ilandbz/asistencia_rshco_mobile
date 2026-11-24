import 'package:equatable/equatable.dart';

class TipoPermiso extends Equatable {
  final int id;
  final String codigo;
  final String nombre;
  final bool conGoce;
  final bool requiereCit;
  final bool permiteAdjunto;

  const TipoPermiso({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.conGoce,
    this.requiereCit = false,
    this.permiteAdjunto = true,
  });

  factory TipoPermiso.fromJson(Map<String, dynamic> json) {
    return TipoPermiso(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      codigo: json['codigo']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? json['descripcion']?.toString() ?? '',
      conGoce: json['con_goce'] == true || json['con_goce'] == 1,
      requiereCit: json['requiere_cit'] == true || json['codigo'] == 'CIT',
      permiteAdjunto: json['permite_adjunto'] != false,
    );
  }

  @override
  List<Object?> get props => [id, codigo, nombre, conGoce, requiereCit, permiteAdjunto];
}

class ResumenCit extends Equatable {
  final int anio;
  final int diasAcumuladosRed; // Días 1 al 20 asumidos por la Red
  final int limiteRed; // 20 días
  final int diasSubsidioEssalud; // Días a partir del día 21
  final int totalDiasEnfermedadAnual;

  const ResumenCit({
    required this.anio,
    this.diasAcumuladosRed = 0,
    this.limiteRed = 20,
    this.diasSubsidioEssalud = 0,
    this.totalDiasEnfermedadAnual = 0,
  });

  bool get requiereSubsidioEssalud => diasAcumuladosRed >= limiteRed;

  double get porcentajeRed => (diasAcumuladosRed / limiteRed).clamp(0.0, 1.0);

  factory ResumenCit.fromJson(Map<String, dynamic> json) {
    final red = json['dias_acumulados_red'] is int
        ? json['dias_acumulados_red']
        : int.tryParse(json['dias_acumulados_red']?.toString() ?? '0') ?? 0;
    final essalud = json['dias_subsidio_essalud'] is int
        ? json['dias_subsidio_essalud']
        : int.tryParse(json['dias_subsidio_essalud']?.toString() ?? '0') ?? 0;

    return ResumenCit(
      anio: json['anio'] is int ? json['anio'] : 2026,
      diasAcumuladosRed: red,
      limiteRed: json['limite_red'] is int ? json['limite_red'] : 20,
      diasSubsidioEssalud: essalud,
      totalDiasEnfermedadAnual: json['total_dias_anual'] is int ? json['total_dias_anual'] : (red + essalud),
    );
  }

  @override
  List<Object?> get props => [
        anio,
        diasAcumuladosRed,
        limiteRed,
        diasSubsidioEssalud,
        totalDiasEnfermedadAnual,
      ];
}

class SolicitudPermisoItem extends Equatable {
  final int id;
  final String tipoNombre;
  final String fechaInicio;
  final String fechaFin;
  final int dias;
  final String motivo;
  final String estado; // PENDIENTE, APROBADO, RECHAZADO
  final String? cittNumero;
  final String? adjuntoUrl;

  const SolicitudPermisoItem({
    required this.id,
    required this.tipoNombre,
    required this.fechaInicio,
    required this.fechaFin,
    required this.dias,
    required this.motivo,
    required this.estado,
    this.cittNumero,
    this.adjuntoUrl,
  });

  factory SolicitudPermisoItem.fromJson(Map<String, dynamic> json) {
    return SolicitudPermisoItem(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      tipoNombre: json['tipo_nombre']?.toString() ?? json['tipo']?['nombre']?.toString() ?? 'Permiso',
      fechaInicio: json['fecha_inicio']?.toString() ?? '',
      fechaFin: json['fecha_fin']?.toString() ?? '',
      dias: json['dias'] is int ? json['dias'] : int.tryParse(json['dias']?.toString() ?? '1') ?? 1,
      motivo: json['motivo']?.toString() ?? '',
      estado: json['estado']?.toString() ?? 'PENDIENTE',
      cittNumero: json['citt_numero']?.toString() ?? json['citt']?.toString(),
      adjuntoUrl: json['adjunto_url']?.toString() ?? json['archivo']?.toString(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        tipoNombre,
        fechaInicio,
        fechaFin,
        dias,
        motivo,
        estado,
        cittNumero,
        adjuntoUrl,
      ];
}

class OcrCitScanResult extends Equatable {
  final String? citt;
  final String? cmp;
  final String? fechaInicio;
  final String? fechaFin;
  final int? dias;
  final String? diagnostico;

  const OcrCitScanResult({
    this.citt,
    this.cmp,
    this.fechaInicio,
    this.fechaFin,
    this.dias,
    this.diagnostico,
  });

  factory OcrCitScanResult.fromJson(Map<String, dynamic> json) {
    return OcrCitScanResult(
      citt: json['citt']?.toString(),
      cmp: json['cmp']?.toString(),
      fechaInicio: json['fecha_inicio']?.toString(),
      fechaFin: json['fecha_fin']?.toString(),
      dias: json['dias'] is int ? json['dias'] : int.tryParse(json['dias']?.toString() ?? ''),
      diagnostico: json['diagnostico']?.toString(),
    );
  }

  @override
  List<Object?> get props => [citt, cmp, fechaInicio, fechaFin, dias, diagnostico];
}
