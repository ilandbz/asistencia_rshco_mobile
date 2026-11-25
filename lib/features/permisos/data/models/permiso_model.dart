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
  final int saldoRedDisponible; // Días restantes (ej: 20 - diasAcumuladosRed)
  final int totalDiasEnfermedadAnual;
  final int totalEssalud;
  final int totalParticular;
  final int totalLey30012;
  final bool superaTope;

  const ResumenCit({
    required this.anio,
    this.diasAcumuladosRed = 0,
    this.limiteRed = 20,
    this.diasSubsidioEssalud = 0,
    this.saldoRedDisponible = 20,
    this.totalDiasEnfermedadAnual = 0,
    this.totalEssalud = 0,
    this.totalParticular = 0,
    this.totalLey30012 = 0,
    this.superaTope = false,
  });

  bool get requiereSubsidioEssalud => superaTope || diasAcumuladosRed >= limiteRed;

  double get porcentajeRed => (diasAcumuladosRed / (limiteRed > 0 ? limiteRed : 20)).clamp(0.0, 1.0);

  factory ResumenCit.fromJson(Map<String, dynamic> json) {
    // Si la API responde anidado en 'kpis' o en la raíz
    final kpis = json['kpis'] is Map<String, dynamic>
        ? json['kpis'] as Map<String, dynamic>
        : (json['resumen'] is Map<String, dynamic> ? json['resumen'] as Map<String, dynamic> : json);

    final limite = kpis['tope_dias_empleador'] is int
        ? kpis['tope_dias_empleador']
        : int.tryParse(kpis['tope_dias_empleador']?.toString() ?? '20') ?? 20;

    final red = kpis['dias_red'] is int
        ? kpis['dias_red']
        : (kpis['dias_acumulados_red'] is int
            ? kpis['dias_acumulados_red']
            : int.tryParse(kpis['dias_red']?.toString() ?? kpis['dias_acumulados_red']?.toString() ?? '0') ?? 0);

    final essalud = kpis['dias_subsidio'] is int
        ? kpis['dias_subsidio']
        : (kpis['dias_subsidio_essalud'] is int
            ? kpis['dias_subsidio_essalud']
            : int.tryParse(kpis['dias_subsidio']?.toString() ?? kpis['dias_subsidio_essalud']?.toString() ?? '0') ?? 0);

    final saldo = kpis['saldo_red_disponible'] is int
        ? kpis['saldo_red_disponible']
        : (limite - red).clamp(0, limite);

    final total = kpis['total_dias'] is int
        ? kpis['total_dias']
        : (kpis['total_dias_anual'] is int
            ? kpis['total_dias_anual']
            : (red + essalud));

    return ResumenCit(
      anio: json['anho'] is int
          ? json['anho']
          : (json['anio'] is int
              ? json['anio']
              : int.tryParse(json['anho']?.toString() ?? json['anio']?.toString() ?? '2026') ?? 2026),
      diasAcumuladosRed: red,
      limiteRed: limite,
      diasSubsidioEssalud: essalud,
      saldoRedDisponible: saldo,
      totalDiasEnfermedadAnual: total,
      totalEssalud: kpis['total_essalud'] is int ? kpis['total_essalud'] : 0,
      totalParticular: kpis['total_particular'] is int ? kpis['total_particular'] : 0,
      totalLey30012: kpis['total_ley30012'] is int ? kpis['total_ley30012'] : 0,
      superaTope: kpis['supera_tope'] == true || red >= limite,
    );
  }

  @override
  List<Object?> get props => [
        anio,
        diasAcumuladosRed,
        limiteRed,
        diasSubsidioEssalud,
        saldoRedDisponible,
        totalDiasEnfermedadAnual,
        totalEssalud,
        totalParticular,
        totalLey30012,
        superaTope,
      ];
}

class SolicitudPermisoItem extends Equatable {
  final int id;
  final int? tipoPermisoId;
  final String tipoNombre;
  final String fechaInicio;
  final String fechaFin;
  final int dias;
  final int horas;
  final String motivo;
  final String estado; // PENDIENTE, APROBADO 1, APROBADO 2, RECHAZADO
  final String? cittNumero;
  final String? adjuntoUrl;
  final String? diagnostico;

  const SolicitudPermisoItem({
    required this.id,
    this.tipoPermisoId,
    required this.tipoNombre,
    required this.fechaInicio,
    required this.fechaFin,
    required this.dias,
    this.horas = 0,
    required this.motivo,
    required this.estado,
    this.cittNumero,
    this.adjuntoUrl,
    this.diagnostico,
  });

  /// Determina si este registro corresponde a un descanso médico / CITT
  bool get esDescansoMedico {
    if (cittNumero != null && cittNumero!.trim().isNotEmpty) return true;
    if (tipoPermisoId == 8 || tipoPermisoId == 67 || tipoPermisoId == 32) return true;
    final t = tipoNombre.toUpperCase();
    return t.contains('SALUD') ||
        t.contains('CITT') ||
        t.contains('MEDIC') ||
        t.contains('ENFERM') ||
        t.contains('MATERN');
  }

  factory SolicitudPermisoItem.fromJson(Map<String, dynamic> json) {
    final tipoNom = json['tipopermiso']?['nombre']?.toString() ??
        json['tipo_nombre']?.toString() ??
        json['tipo']?['nombre']?.toString() ??
        'Permiso';

    final fInicio = json['fecha_desde']?.toString() ??
        json['fecha_inicio']?.toString() ??
        json['desde']?.toString() ??
        '';

    final fFin = json['fecha_hasta']?.toString() ??
        json['fecha_fin']?.toString() ??
        json['hasta']?.toString() ??
        fInicio;

    final nroCert = json['numero_certificado']?.toString() ??
        json['citt_numero']?.toString() ??
        json['citt']?.toString();

    final diag = json['diagnostico']?.toString();

    return SolicitudPermisoItem(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      tipoPermisoId: json['tipo_permiso_id'] is int
          ? json['tipo_permiso_id']
          : int.tryParse(json['tipo_permiso_id']?.toString() ?? ''),
      tipoNombre: tipoNom,
      fechaInicio: fInicio,
      fechaFin: fFin,
      dias: json['total_dias'] is int
          ? json['total_dias']
          : (json['dias'] is int
              ? json['dias']
              : int.tryParse(json['total_dias']?.toString() ?? json['dias']?.toString() ?? '1') ?? 1),
      horas: json['total_horas'] is int
          ? json['total_horas']
          : int.tryParse(json['total_horas']?.toString() ?? '0') ?? 0,
      motivo: json['motivo']?.toString() ?? '',
      estado: json['estado']?.toString() ?? 'PENDIENTE',
      cittNumero: nroCert,
      adjuntoUrl: json['adjunto_url']?.toString() ?? json['archivo']?.toString(),
      diagnostico: diag,
    );
  }

  @override
  List<Object?> get props => [
        id,
        tipoPermisoId,
        tipoNombre,
        fechaInicio,
        fechaFin,
        dias,
        horas,
        motivo,
        estado,
        cittNumero,
        adjuntoUrl,
        diagnostico,
      ];
}

class OcrCitScanResult extends Equatable {
  final String? citt;
  final String? cmp;
  final String? fechaInicio;
  final String? fechaFin;
  final int? dias;
  final String? diagnostico;
  final String? servidorNombre;
  final String? servidorDni;
  final bool servidorIdentificado;
  final String? medicoTratante;
  final String? tipoOrigen; // CITT EsSalud, Particular (CMP), MINSA
  final String? contingencia;
  final String? alertaContingencia;

  const OcrCitScanResult({
    this.citt,
    this.cmp,
    this.fechaInicio,
    this.fechaFin,
    this.dias,
    this.diagnostico,
    this.servidorNombre,
    this.servidorDni,
    this.servidorIdentificado = false,
    this.medicoTratante,
    this.tipoOrigen,
    this.contingencia,
    this.alertaContingencia,
  });

  factory OcrCitScanResult.fromJson(Map<String, dynamic> json) {
    // El backend de producción responde con: { ok: 1, datos_ocr: { ... }, advertencia_dni: "...", personal: { ... } }
    final Map<String, dynamic> map = json['datos_ocr'] is Map<String, dynamic>
        ? json['datos_ocr'] as Map<String, dynamic>
        : (json['data'] is Map<String, dynamic>
            ? json['data'] as Map<String, dynamic>
            : (json['ocr'] is Map<String, dynamic> ? json['ocr'] as Map<String, dynamic> : json));

    // Servidor / Paciente identificado
    String? sNombre;
    String? sDni;
    bool sIdentificado = false;

    if (map['paciente_nombre'] != null) {
      sNombre = map['paciente_nombre']?.toString();
      sDni = map['numero_dni']?.toString();
      sIdentificado = true;
    } else if (json['personal'] is Map) {
      sNombre = json['personal']['apenom']?.toString() ?? json['personal']['nombre']?.toString();
      sDni = json['personal']['numero_dni']?.toString() ?? json['personal']['dni']?.toString();
      sIdentificado = true;
    } else if (map['servidor'] is Map) {
      sNombre = map['servidor']['nombre']?.toString() ?? map['servidor']['nombre_completo']?.toString();
      sDni = map['servidor']['dni']?.toString();
      sIdentificado = true;
    } else {
      sNombre = map['servidor_nombre']?.toString() ?? map['nombre_servidor']?.toString() ?? map['trabajador']?.toString();
      sDni = map['servidor_dni']?.toString() ?? map['dni']?.toString() ?? map['numero_dni']?.toString();
      sIdentificado = map['servidor_identificado'] == true || map['identificado'] == true || (sNombre != null && sNombre.isNotEmpty);
    }

    // Advertencia de contingencia o discrepancia de DNI
    final alerta = json['advertencia_dni']?.toString() ??
        map['alerta_contingencia']?.toString() ??
        map['alerta']?.toString();

    // Tipo origen
    String? origen = map['origen_certificado']?.toString() ??
        map['tipo_origen']?.toString() ??
        map['tipo']?.toString() ??
        map['origen']?.toString();
    if (origen != null) {
      if (origen.toUpperCase().contains('PARTICULAR')) {
        origen = 'Particular (CMP)';
      } else if (origen.toUpperCase().contains('CITT') || origen.toUpperCase().contains('ESSALUD')) {
        origen = 'EsSalud CITT';
      } else if (origen.toUpperCase().contains('MINSA') || origen.toUpperCase().contains('30012')) {
        origen = 'MINSA (Ley Nº 30012)';
      }
    }

    // Extracción exhaustiva y limpia del diagnóstico
    String? extraerDiagnostico() {
      final keys = [
        'diagnostico',
        'diagnostico_cie10',
        'diagnostico_medico',
        'cie10',
        'codigo_cie10',
        'cie_10',
        'tipo_licencia',
        'contingencia',
        'tipo_contingencia',
        'motivo',
        'descripcion',
        'observacion',
        'observaciones',
      ];
      for (final k in keys) {
        final valMap = map[k]?.toString().trim();
        if (valMap != null &&
            valMap.isNotEmpty &&
            valMap.toLowerCase() != 'null' &&
            valMap != 'No detectado') {
          return valMap;
        }
        final valJson = json[k]?.toString().trim();
        if (valJson != null &&
            valJson.isNotEmpty &&
            valJson.toLowerCase() != 'null' &&
            valJson != 'No detectado') {
          return valJson;
        }
      }
      return null;
    }

    final diagDetectado = extraerDiagnostico();
    final diagFinal = (diagDetectado != null && diagDetectado.isNotEmpty)
        ? diagDetectado
        : (origen != null && origen.toUpperCase().contains('CITT')
            ? 'Incapacidad Temporal para el Trabajo (CITT)'
            : (origen != null && origen.toUpperCase().contains('MINSA')
                ? 'Licencia por Familiar Grave o Terminal (Ley 30012)'
                : 'Descanso médico institucional'));

    return OcrCitScanResult(
      citt: map['numero_certificado']?.toString() ??
          map['citt']?.toString() ??
          map['certificado']?.toString() ??
          map['nro_certificado']?.toString(),
      cmp: map['colegiatura_medico']?.toString() ??
          map['cmp']?.toString() ??
          map['colegiatura']?.toString() ??
          map['colegiatura_cmp']?.toString(),
      fechaInicio: map['fecha_desde']?.toString() ??
          map['fecha_inicio']?.toString() ??
          map['desde']?.toString(),
      fechaFin: map['fecha_hasta']?.toString() ??
          map['fecha_fin']?.toString() ??
          map['hasta']?.toString(),
      dias: map['total_dias'] is int
          ? map['total_dias']
          : (map['dias'] is int
              ? map['dias']
              : int.tryParse(map['total_dias']?.toString() ??
                  map['dias']?.toString() ??
                  map['dias_otorgados']?.toString() ??
                  '')),
      diagnostico: diagFinal,
      servidorNombre: sNombre,
      servidorDni: sDni,
      servidorIdentificado: sIdentificado,
      medicoTratante: map['medico_nombre']?.toString() ??
          map['medico_tratante']?.toString() ??
          map['medico']?.toString() ??
          map['nombre_medico']?.toString(),
      tipoOrigen: origen,
      contingencia: map['tipo_licencia']?.toString() ?? map['contingencia']?.toString() ?? map['tipo_contingencia']?.toString(),
      alertaContingencia: alerta,
    );
  }

  /// Valida si la imagen procesada realmente corresponde a un descanso médico
  /// y no a una foto aleatoria, selfie o documento no médico
  bool get esCertificadoValido {
    final tieneCitt = citt != null && citt!.trim().isNotEmpty && citt != 'No detectado';
    final tieneCmp = cmp != null && cmp!.trim().isNotEmpty && cmp != 'No detectado';
    final tieneFechas = (fechaInicio != null && fechaInicio!.trim().isNotEmpty && fechaInicio != '--') ||
        (fechaFin != null && fechaFin!.trim().isNotEmpty && fechaFin != '--');
    final tieneDiagnostico = diagnostico != null && diagnostico!.trim().isNotEmpty && diagnostico != 'No detectado';
    final tieneMedico = medicoTratante != null && medicoTratante!.trim().isNotEmpty && medicoTratante != 'No detectado';

    return tieneCitt || tieneCmp || tieneFechas || tieneDiagnostico || tieneMedico;
  }

  @override
  List<Object?> get props => [
        citt,
        cmp,
        fechaInicio,
        fechaFin,
        dias,
        diagnostico,
        servidorNombre,
        servidorDni,
        servidorIdentificado,
        medicoTratante,
        tipoOrigen,
        contingencia,
        alertaContingencia,
      ];
}
