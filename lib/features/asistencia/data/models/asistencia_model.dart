import 'package:equatable/equatable.dart';

int _parseAsInt(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

String? _formatHoraCorta(dynamic value) {
  if (value == null) return null;
  final str = value.toString().trim();
  if (str.isEmpty || str == 'null') return null;
  if (str.length >= 5 && str[2] == ':') {
    return str.substring(0, 5);
  }
  return str;
}

String? _cleanHoraExacta(dynamic value) {
  if (value == null) return null;
  final str = value.toString().trim();
  if (str.isEmpty || str == 'null') return null;
  return str;
}

class MarcacionHoy extends Equatable {
  final String fecha;
  final String? turnoProgramado;
  final String? turnoNombre;
  final String? horaEntradaProgramada;
  final String? horaSalidaProgramada;
  final String? primerIngreso;
  final String? ultimoEgreso;
  final String estado; // ASISTIO, TARDANZA, FALTA, PERMISO, FERIADO, PENDIENTE
  final int minutosTardanza;
  final String? permisoDescripcion;

  const MarcacionHoy({
    required this.fecha,
    this.turnoProgramado,
    this.turnoNombre,
    this.horaEntradaProgramada,
    this.horaSalidaProgramada,
    this.primerIngreso,
    this.ultimoEgreso,
    this.estado = 'PENDIENTE',
    this.minutosTardanza = 0,
    this.permisoDescripcion,
  });

  factory MarcacionHoy.fromJson(Map<String, dynamic> json) {
    // El backend envía turno_programado como objeto { abreviatura: "MT", nombre: "MAÑANA Y TARDE", ... }
    String? turnoProg;
    String? turnoDesc;
    final rawTurno = json['turno_programado'] ?? json['sigla_turno'] ?? json['turno'];
    if (rawTurno is Map<String, dynamic>) {
      turnoProg = rawTurno['abreviatura']?.toString() ??
          rawTurno['sigla']?.toString() ??
          rawTurno['codigo']?.toString() ??
          rawTurno['nombre']?.toString();
      turnoDesc = rawTurno['nombre']?.toString() ?? rawTurno['descripcion']?.toString();
    } else if (rawTurno != null) {
      turnoProg = rawTurno.toString();
    }

    final resumenHoy = json['resumen_hoy'] is Map<String, dynamic>
        ? json['resumen_hoy'] as Map<String, dynamic>
        : <String, dynamic>{};

    final turnosDetalle = json['turnos_detalle'] is List
        ? (json['turnos_detalle'] as List).whereType<Map<String, dynamic>>().toList()
        : <Map<String, dynamic>>[];

    // Horario programado de entrada/salida (directo o deducido de turnos_detalle)
    String? horaEntProg = _formatHoraCorta(
        json['hora_entrada_programada'] ?? json['hora_inicio']);
    String? horaSalProg = _formatHoraCorta(
        json['hora_salida_programada'] ?? json['hora_fin']);

    if (turnosDetalle.isNotEmpty) {
      horaEntProg ??= _formatHoraCorta(turnosDetalle.first['hora_prog_entrada']);
      horaSalProg ??= _formatHoraCorta(turnosDetalle.last['hora_prog_salida']);
    }

    // Extracción tolerante de horas marcadas de entrada / salida
    String? primerIng = _formatHoraCorta(
      json['primer_ingreso'] ??
          json['hora_entrada'] ??
          json['entrada'] ??
          json['hora_ingreso'] ??
          json['primer_marcado'],
    );
    String? ultimoEg = _formatHoraCorta(
      json['ultimo_egreso'] ??
          json['hora_salida'] ??
          json['salida'] ??
          json['hora_egreso'] ??
          json['ultimo_marcado'],
    );

    if (turnosDetalle.isNotEmpty) {
      for (final td in turnosDetalle) {
        primerIng ??= _formatHoraCorta(td['hora_marc_entrada']);
        final sal = _formatHoraCorta(td['hora_marc_salida']);
        if (sal != null) ultimoEg = sal;
      }
    }

    if ((primerIng == null || primerIng.isEmpty) &&
        json['marcaciones'] is List &&
        (json['marcaciones'] as List).isNotEmpty) {
      final list = json['marcaciones'] as List;
      final first = list.first;
      final last = list.last;
      if (first is Map) {
        primerIng = _formatHoraCorta(
            first['hora'] ?? first['hora_marcado'] ?? first['created_at']);
      }
      if (last is Map && list.length > 1) {
        ultimoEg ??= _formatHoraCorta(
            last['hora'] ?? last['hora_marcado'] ?? last['created_at']);
      }
    }

    final estadoFinal = resumenHoy['estado_dia']?.toString() ??
        json['estado']?.toString() ??
        (primerIng != null && primerIng.isNotEmpty ? 'ASISTIO' : 'PENDIENTE');

    final permisoObj = resumenHoy['permiso'] is Map<String, dynamic>
        ? resumenHoy['permiso'] as Map<String, dynamic>
        : null;
    final permisoDesc = permisoObj?['tipo_permiso']?.toString();

    return MarcacionHoy(
      fecha: json['fecha']?.toString() ?? '',
      turnoProgramado: turnoProg,
      turnoNombre: turnoDesc,
      horaEntradaProgramada: horaEntProg,
      horaSalidaProgramada: horaSalProg,
      primerIngreso: primerIng,
      ultimoEgreso: ultimoEg,
      estado: estadoFinal,
      minutosTardanza: _parseAsInt(
          resumenHoy['minutos_tardanza_hoy'] ?? json['minutos_tardanza']),
      permisoDescripcion: permisoDesc,
    );
  }

  @override
  List<Object?> get props => [
        fecha,
        turnoProgramado,
        turnoNombre,
        horaEntradaProgramada,
        horaSalidaProgramada,
        primerIngreso,
        ultimoEgreso,
        estado,
        minutosTardanza,
        permisoDescripcion,
      ];
}

class TurnoDiaRol extends Equatable {
  final int dia;
  final String fecha;
  final String sigla; // MT, M, T, N, D, GD, GN, L, VAC, F
  final String? descripcion;
  final String? horario;
  final String? nombreDia;
  final int totalHoras;
  final bool esGuardia;
  final bool programado;

  const TurnoDiaRol({
    required this.dia,
    required this.fecha,
    required this.sigla,
    this.descripcion,
    this.horario,
    this.nombreDia,
    this.totalHoras = 0,
    this.esGuardia = false,
    this.programado = true,
  });

  factory TurnoDiaRol.fromJson(Map<String, dynamic> json) {
    String sig = json['abreviatura']?.toString() ??
        json['sigla']?.toString() ??
        json['turno']?.toString() ??
        '';
    if (sig.isEmpty || sig == 'null') {
      sig = 'D';
    }

    String? hor;
    final ent = _formatHoraCorta(json['hora_entrada']);
    final sal = _formatHoraCorta(json['hora_salida']);
    if (ent != null && sal != null) {
      hor = '$ent a $sal';
    } else if (json['horario'] != null) {
      hor = json['horario'].toString();
    }

    return TurnoDiaRol(
      dia: _parseAsInt(json['dia'], 1),
      fecha: json['fecha']?.toString() ?? '',
      sigla: sig,
      descripcion: json['turno_nombre']?.toString() ?? json['descripcion']?.toString(),
      horario: hor,
      nombreDia: json['nombre_dia']?.toString(),
      totalHoras: _parseAsInt(json['total_horas']),
      esGuardia: json['es_guardia'] == true || sig == 'GD' || sig == 'GN',
      programado: json['programado'] != false,
    );
  }

  @override
  List<Object?> get props => [dia, fecha, sigla, descripcion, horario, nombreDia, totalHoras, esGuardia, programado];
}

class RolMensual extends Equatable {
  final int mes;
  final int anio;
  final List<TurnoDiaRol> turnos;
  final int totalHoras;
  final int totalGuardias;
  final int diasProgramados;
  final int diasDelMes;
  final int topeHorasMes;
  final int turnosMt;
  final String estadoRol; // 'cerrado', 'abierto'
  final bool rolCerrado;

  const RolMensual({
    required this.mes,
    required this.anio,
    required this.turnos,
    this.totalHoras = 0,
    this.totalGuardias = 0,
    this.diasProgramados = 0,
    this.diasDelMes = 30,
    this.topeHorasMes = 150,
    this.turnosMt = 0,
    this.estadoRol = 'abierto',
    this.rolCerrado = false,
  });

  factory RolMensual.fromJson(Map<String, dynamic> json) {
    final rawList = json['dias'] ?? json['turnos'] ?? json['data'];
    final list = rawList is List ? rawList : [];

    final resumen = json['resumen_rol'] is Map<String, dynamic>
        ? json['resumen_rol'] as Map<String, dynamic>
        : <String, dynamic>{};

    return RolMensual(
      mes: _parseAsInt(json['mes'], 1),
      anio: _parseAsInt(json['anho'] ?? json['anio'], 2026),
      turnos: list.map((item) => TurnoDiaRol.fromJson(item as Map<String, dynamic>)).toList(),
      totalHoras: _parseAsInt(resumen['total_horas_mes'] ?? json['total_horas']),
      totalGuardias: _parseAsInt(resumen['total_guardias_mes'] ?? json['total_guardias']),
      diasProgramados: _parseAsInt(resumen['dias_programados']),
      diasDelMes: _parseAsInt(resumen['dias_del_mes'], list.length),
      topeHorasMes: _parseAsInt(resumen['tope_horas_mes'], 150),
      turnosMt: _parseAsInt(resumen['total_turnos_mt']),
      estadoRol: json['estado_rol']?.toString() ?? 'abierto',
      rolCerrado: json['rol_cerrado'] == true,
    );
  }

  @override
  List<Object?> get props => [
        mes,
        anio,
        turnos,
        totalHoras,
        totalGuardias,
        diasProgramados,
        diasDelMes,
        topeHorasMes,
        turnosMt,
        estadoRol,
        rolCerrado,
      ];
}

class FaltasTardanzasResumen extends Equatable {
  final int mes;
  final int anio;
  final int minutosTardanzaTotal;
  final int conteoTardanzas;
  final int tardanzasInjustificadas;
  final int faltasTotal;
  final int permisosConGoce;
  final int permisosSinGoce;
  final int diasAsistidos;

  const FaltasTardanzasResumen({
    required this.mes,
    required this.anio,
    this.minutosTardanzaTotal = 0,
    this.conteoTardanzas = 0,
    this.tardanzasInjustificadas = 0,
    this.faltasTotal = 0,
    this.permisosConGoce = 0,
    this.permisosSinGoce = 0,
    this.diasAsistidos = 0,
  });

  factory FaltasTardanzasResumen.fromJson(Map<String, dynamic> json) {
    final periodo = json['periodo'] is Map<String, dynamic>
        ? json['periodo'] as Map<String, dynamic>
        : json;
    final resumen = json['resumen'] is Map<String, dynamic>
        ? json['resumen'] as Map<String, dynamic>
        : json;

    return FaltasTardanzasResumen(
      mes: _parseAsInt(periodo['mes'] ?? json['mes'], 1),
      anio: _parseAsInt(
          periodo['anho'] ?? periodo['anio'] ?? json['anho'] ?? json['anio'],
          DateTime.now().year),
      minutosTardanzaTotal: _parseAsInt(
          resumen['total_minutos_tardanza'] ?? json['minutos_tardanza_total']),
      conteoTardanzas: _parseAsInt(resumen['dias_con_tardanza'] ??
          resumen['turnos_con_tardanza'] ??
          json['conteo_tardanzas']),
      tardanzasInjustificadas: _parseAsInt(
          resumen['turnos_con_tardanza'] ?? json['tardanzas_injustificadas']),
      faltasTotal: _parseAsInt(resumen['dias_con_falta'] ??
          resumen['total_faltas_turnos'] ??
          json['faltas_total']),
      permisosConGoce: _parseAsInt(
          resumen['dias_permiso_justificado'] ?? json['permisos_con_goce']),
      permisosSinGoce: _parseAsInt(json['permisos_sin_goce']),
      diasAsistidos: _parseAsInt(resumen['dias_asistidos']),
    );
  }

  @override
  List<Object?> get props => [
        mes,
        anio,
        minutosTardanzaTotal,
        conteoTardanzas,
        tardanzasInjustificadas,
        faltasTotal,
        permisosConGoce,
        permisosSinGoce,
        diasAsistidos,
      ];
}

class TurnoDetalleAsistencia extends Equatable {
  final String abreviatura;
  final String nombre;
  final String? horaProgEntrada;
  final String? horaProgSalida;
  final String? ventanaEntradaInicio;
  final String? ventanaEntradaFin;
  final int toleranciaMinutos;
  final String? horaMarcEntrada;
  final String? horaMarcSalida;
  final int minutosTardanza;
  final bool tienePermiso;
  final String? permisoEstado;
  final bool tieneIncidencia;
  final bool esGuardia;
  final bool esNocturno;
  final String estado;

  const TurnoDetalleAsistencia({
    required this.abreviatura,
    required this.nombre,
    this.horaProgEntrada,
    this.horaProgSalida,
    this.ventanaEntradaInicio,
    this.ventanaEntradaFin,
    this.toleranciaMinutos = 0,
    this.horaMarcEntrada,
    this.horaMarcSalida,
    this.minutosTardanza = 0,
    this.tienePermiso = false,
    this.permisoEstado,
    this.tieneIncidencia = false,
    this.esGuardia = false,
    this.esNocturno = false,
    required this.estado,
  });

  factory TurnoDetalleAsistencia.fromJson(Map<String, dynamic> json) {
    return TurnoDetalleAsistencia(
      abreviatura: json['abreviatura']?.toString() ?? 'T',
      nombre: json['turno_nombre']?.toString() ?? 'Turno programado',
      horaProgEntrada: _formatHoraCorta(json['hora_prog_entrada']),
      horaProgSalida: _formatHoraCorta(json['hora_prog_salida']),
      ventanaEntradaInicio: _formatHoraCorta(json['ventana_entrada_inicio']),
      ventanaEntradaFin: _formatHoraCorta(json['ventana_entrada_fin']),
      toleranciaMinutos: _parseAsInt(json['tolerancia_minutos']),
      horaMarcEntrada: _cleanHoraExacta(json['hora_marc_entrada']),
      horaMarcSalida: _cleanHoraExacta(json['hora_marc_salida']),
      minutosTardanza: _parseAsInt(json['minutos_tardanza']),
      tienePermiso: json['tiene_permiso'] == true,
      permisoEstado: _cleanHoraExacta(json['permiso_estado']),
      tieneIncidencia: json['tiene_incidencia'] == true,
      esGuardia: json['es_guardia'] == true,
      esNocturno: json['es_nocturno'] == true,
      estado: json['estado']?.toString() ?? 'PENDIENTE',
    );
  }

  @override
  List<Object?> get props => [
        abreviatura,
        nombre,
        horaProgEntrada,
        horaProgSalida,
        ventanaEntradaInicio,
        ventanaEntradaFin,
        toleranciaMinutos,
        horaMarcEntrada,
        horaMarcSalida,
        minutosTardanza,
        tienePermiso,
        permisoEstado,
        tieneIncidencia,
        esGuardia,
        esNocturno,
        estado,
      ];
}

class MarcacionRelojItem extends Equatable {
  final String fecha;
  final String hora;
  final String tipo;

  const MarcacionRelojItem({
    required this.fecha,
    required this.hora,
    required this.tipo,
  });

  factory MarcacionRelojItem.fromJson(Map<String, dynamic> json) {
    return MarcacionRelojItem(
      fecha: json['fecha']?.toString() ?? '',
      hora: _cleanHoraExacta(json['hora'] ?? json['hora_marcado']) ?? '--:--',
      tipo: json['tipo']?.toString() ?? 'MARCACIÓN',
    );
  }

  @override
  List<Object?> get props => [fecha, hora, tipo];
}

class PermisoDiaResumen extends Equatable {
  final String tipoPermiso;
  final String estado;
  final String? motivo;
  final String? fechaDesde;
  final String? fechaHasta;
  final String? horaInicio;
  final String? horaHasta;
  final int totalDias;
  final int totalHoras;
  final String? numeroCertificado;
  final String? detalleLicencia;

  const PermisoDiaResumen({
    required this.tipoPermiso,
    required this.estado,
    this.motivo,
    this.fechaDesde,
    this.fechaHasta,
    this.horaInicio,
    this.horaHasta,
    this.totalDias = 0,
    this.totalHoras = 0,
    this.numeroCertificado,
    this.detalleLicencia,
  });

  factory PermisoDiaResumen.fromJson(Map<String, dynamic> json) {
    return PermisoDiaResumen(
      tipoPermiso: json['tipo_permiso']?.toString() ?? 'Permiso / Licencia',
      estado: json['estado']?.toString() ?? 'AUTORIZADO',
      motivo: _cleanHoraExacta(json['motivo']),
      fechaDesde: _cleanHoraExacta(json['fecha_desde']),
      fechaHasta: _cleanHoraExacta(json['fecha_hasta']),
      horaInicio: _formatHoraCorta(json['hora_inicio']),
      horaHasta: _formatHoraCorta(json['hora_hasta']),
      totalDias: _parseAsInt(json['total_dias']),
      totalHoras: _parseAsInt(json['total_horas']),
      numeroCertificado: _cleanHoraExacta(json['numero_certificado']),
      detalleLicencia: _cleanHoraExacta(json['detalle_licencia']),
    );
  }

  @override
  List<Object?> get props => [
        tipoPermiso,
        estado,
        motivo,
        fechaDesde,
        fechaHasta,
        horaInicio,
        horaHasta,
        totalDias,
        totalHoras,
        numeroCertificado,
        detalleLicencia,
      ];
}

class RegistroAsistenciaItem extends Equatable {
  final String fecha;
  final String diaNombre;
  final String turno;
  final String? turnoNombre;
  final int totalHoras;
  final bool esGuardia;
  final bool esLaborable;
  final bool esFeriado;
  final bool tieneIncidencia;
  final String? entrada;
  final String? salida;
  final String? detalleTurnos;
  final String? permisoNombre;
  final int minutosTardanza;
  final int faltasDia;
  final String estado; // ASISTIO, FALTA, TARDANZA, PERMISO, FERIADO, PENDIENTE, SIN_HORARIO
  final List<TurnoDetalleAsistencia> turnosDetalle;
  final List<MarcacionRelojItem> marcaciones;
  final PermisoDiaResumen? permiso;

  const RegistroAsistenciaItem({
    required this.fecha,
    required this.diaNombre,
    required this.turno,
    this.turnoNombre,
    this.totalHoras = 0,
    this.esGuardia = false,
    this.esLaborable = true,
    this.esFeriado = false,
    this.tieneIncidencia = false,
    this.entrada,
    this.salida,
    this.detalleTurnos,
    this.permisoNombre,
    this.minutosTardanza = 0,
    this.faltasDia = 0,
    required this.estado,
    this.turnosDetalle = const [],
    this.marcaciones = const [],
    this.permiso,
  });

  factory RegistroAsistenciaItem.fromJson(Map<String, dynamic> json) {
    String t = '';
    final rawTurno = json['turno_abreviatura'] ??
        json['turno'] ??
        json['sigla'] ??
        json['sigla_turno'];
    if (rawTurno is Map) {
      t = rawTurno['abreviatura']?.toString() ??
          rawTurno['sigla']?.toString() ??
          '';
    } else if (rawTurno != null) {
      t = rawTurno.toString();
    }
    if (t.isEmpty || t == 'null') {
      t = 'D';
    }

    // Extraer entradas/salidas desde turnos_detalle y marcaciones
    String? ent = _formatHoraCorta(
        json['entrada'] ?? json['hora_entrada'] ?? json['primer_ingreso']);
    String? sal = _formatHoraCorta(
        json['salida'] ?? json['hora_salida'] ?? json['ultimo_egreso']);

    final rawTurnosDetalle = json['turnos_detalle'] is List
        ? (json['turnos_detalle'] as List).whereType<Map<String, dynamic>>().toList()
        : <Map<String, dynamic>>[];

    final turnosDetalleParsed = rawTurnosDetalle
        .map((td) => TurnoDetalleAsistencia.fromJson(td))
        .toList();

    final List<String> segmentos = [];
    for (final td in turnosDetalleParsed) {
      final abrev = td.abreviatura;
      final mEnt = _formatHoraCorta(td.horaMarcEntrada);
      final mSal = _formatHoraCorta(td.horaMarcSalida);

      if (mEnt != null) ent ??= mEnt;
      if (mSal != null) sal = mSal;

      if (mEnt != null || mSal != null) {
        final label = abrev.isNotEmpty ? '$abrev: ' : '';
        segmentos.add('$label${mEnt ?? "--:--"} - ${mSal ?? "--:--"}');
      } else if (td.estado.startsWith('SIN_MARCACION')) {
        segmentos.add('${abrev.isNotEmpty ? "$abrev: " : ""}Sin marcar');
      }
    }

    final rawMarcaciones = json['marcaciones'] is List
        ? (json['marcaciones'] as List).whereType<Map<String, dynamic>>().toList()
        : <Map<String, dynamic>>[];

    final marcacionesParsed =
        rawMarcaciones.map((m) => MarcacionRelojItem.fromJson(m)).toList();

    if ((ent == null || sal == null) && marcacionesParsed.isNotEmpty) {
      ent ??= _formatHoraCorta(marcacionesParsed.first.hora);
      if (marcacionesParsed.length > 1) {
        sal ??= _formatHoraCorta(marcacionesParsed.last.hora);
      }
    }

    final permisoObj = json['permiso'] is Map<String, dynamic>
        ? PermisoDiaResumen.fromJson(json['permiso'] as Map<String, dynamic>)
        : null;

    return RegistroAsistenciaItem(
      fecha: json['fecha']?.toString() ?? json['dia']?.toString() ?? '',
      diaNombre: json['nombre_dia']?.toString() ?? json['dia_nombre']?.toString() ?? '',
      turno: t,
      turnoNombre: _cleanHoraExacta(json['turno_nombre']),
      totalHoras: _parseAsInt(json['total_horas']),
      esGuardia: json['es_guardia'] == true,
      esLaborable: json['es_laborable'] != false,
      esFeriado: json['es_feriado'] == true,
      tieneIncidencia: json['tiene_incidencia'] == true,
      entrada: ent,
      salida: sal,
      detalleTurnos: segmentos.isNotEmpty ? segmentos.join('  |  ') : null,
      permisoNombre: permisoObj?.tipoPermiso,
      minutosTardanza: _parseAsInt(
          json['minutos_tardanza_dia'] ?? json['minutos_tardanza']),
      faltasDia: _parseAsInt(json['faltas_dia']),
      estado: json['estado_dia']?.toString() ??
          json['estado']?.toString() ??
          'SIN_HORARIO',
      turnosDetalle: turnosDetalleParsed,
      marcaciones: marcacionesParsed,
      permiso: permisoObj,
    );
  }

  @override
  List<Object?> get props => [
        fecha,
        diaNombre,
        turno,
        turnoNombre,
        totalHoras,
        esGuardia,
        esLaborable,
        esFeriado,
        tieneIncidencia,
        entrada,
        salida,
        detalleTurnos,
        permisoNombre,
        minutosTardanza,
        faltasDia,
        estado,
        turnosDetalle,
        marcaciones,
        permiso,
      ];
}
