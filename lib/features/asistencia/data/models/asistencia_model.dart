import 'package:equatable/equatable.dart';

class MarcacionHoy extends Equatable {
  final String fecha;
  final String? turnoProgramado;
  final String? turnoNombre;
  final String? horaEntradaProgramada;
  final String? horaSalidaProgramada;
  final String? primerIngreso;
  final String? ultimoEgreso;
  final String estado; // EN_TURNO, DESCANSO, MARCADO, PENDIENTE
  final int minutosTardanza;

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
  });

  factory MarcacionHoy.fromJson(Map<String, dynamic> json) {
    // El backend puede enviar turno_programado como objeto o Map:
    // { abreviatura: "T", nombre: "TARDE ASISTENCIAL", total_horas: 6, es_guardia: false, ... }
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

    // Extracción tolerante de horas de entrada / salida
    String? primerIng = json['primer_ingreso']?.toString() ??
        json['hora_entrada']?.toString() ??
        json['entrada']?.toString() ??
        json['hora_ingreso']?.toString() ??
        json['primer_marcado']?.toString();

    String? ultimoEg = json['ultimo_egreso']?.toString() ??
        json['hora_salida']?.toString() ??
        json['salida']?.toString() ??
        json['hora_egreso']?.toString() ??
        json['ultimo_marcado']?.toString();

    // Si vienen dentro de una lista de "marcaciones" de hoy
    if ((primerIng == null || primerIng.isEmpty) && json['marcaciones'] is List && (json['marcaciones'] as List).isNotEmpty) {
      final list = json['marcaciones'] as List;
      final first = list.first;
      final last = list.last;
      if (first is Map) {
        primerIng = first['hora']?.toString() ?? first['hora_marcado']?.toString() ?? first['created_at']?.toString();
      }
      if (last is Map && list.length > 1) {
        ultimoEg = last['hora']?.toString() ?? last['hora_marcado']?.toString() ?? last['created_at']?.toString();
      }
    }

    return MarcacionHoy(
      fecha: json['fecha']?.toString() ?? '',
      turnoProgramado: turnoProg,
      turnoNombre: turnoDesc,
      horaEntradaProgramada: json['hora_entrada_programada']?.toString() ?? json['hora_inicio']?.toString(),
      horaSalidaProgramada: json['hora_salida_programada']?.toString() ?? json['hora_fin']?.toString(),
      primerIngreso: primerIng,
      ultimoEgreso: ultimoEg,
      estado: json['estado']?.toString() ?? (primerIng != null && primerIng.isNotEmpty ? 'ASISTIO' : 'PENDIENTE'),
      minutosTardanza: json['minutos_tardanza'] is int
          ? json['minutos_tardanza']
          : int.tryParse(json['minutos_tardanza']?.toString() ?? '0') ?? 0,
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
    // Si no está programado o no tiene abreviatura, es descanso (D)
    String sig = json['abreviatura']?.toString() ??
        json['sigla']?.toString() ??
        json['turno']?.toString() ??
        '';
    if (sig.isEmpty || sig == 'null') {
      sig = json['programado'] == false ? 'D' : 'D';
    }

    String? hor;
    final hEnt = json['hora_entrada']?.toString();
    final hSal = json['hora_salida']?.toString();
    if (hEnt != null && hSal != null && hEnt != 'null' && hSal != 'null') {
      final ent = hEnt.length >= 5 ? hEnt.substring(0, 5) : hEnt;
      final sal = hSal.length >= 5 ? hSal.substring(0, 5) : hSal;
      hor = '$ent a $sal';
    } else if (json['horario'] != null) {
      hor = json['horario'].toString();
    }

    return TurnoDiaRol(
      dia: json['dia'] is int
          ? json['dia']
          : int.tryParse(json['dia']?.toString() ?? '1') ?? 1,
      fecha: json['fecha']?.toString() ?? '',
      sigla: sig,
      descripcion: json['turno_nombre']?.toString() ?? json['descripcion']?.toString(),
      horario: hor,
      nombreDia: json['nombre_dia']?.toString(),
      totalHoras: json['total_horas'] is int
          ? json['total_horas']
          : int.tryParse(json['total_horas']?.toString() ?? '0') ?? 0,
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
    // El backend envía la lista en 'dias' o 'turnos'
    final rawList = json['dias'] ?? json['turnos'] ?? json['data'];
    final list = rawList is List ? rawList : [];

    final resumen = json['resumen_rol'] is Map<String, dynamic>
        ? json['resumen_rol'] as Map<String, dynamic>
        : <String, dynamic>{};

    return RolMensual(
      mes: json['mes'] is int
          ? json['mes']
          : int.tryParse(json['mes']?.toString() ?? '1') ?? 1,
      anio: json['anho'] is int
          ? json['anho']
          : (json['anio'] is int
              ? json['anio']
              : int.tryParse(json['anho']?.toString() ?? json['anio']?.toString() ?? '2026') ?? 2026),
      turnos: list.map((item) => TurnoDiaRol.fromJson(item as Map<String, dynamic>)).toList(),
      totalHoras: resumen['total_horas_mes'] is int
          ? resumen['total_horas_mes']
          : (json['total_horas'] is int ? json['total_horas'] : 0),
      totalGuardias: resumen['total_guardias_mes'] is int
          ? resumen['total_guardias_mes']
          : (json['total_guardias'] is int ? json['total_guardias'] : 0),
      diasProgramados: resumen['dias_programados'] is int ? resumen['dias_programados'] : 0,
      diasDelMes: resumen['dias_del_mes'] is int ? resumen['dias_del_mes'] : list.length,
      topeHorasMes: resumen['tope_horas_mes'] is int ? resumen['tope_horas_mes'] : 150,
      turnosMt: resumen['total_turnos_mt'] is int ? resumen['total_turnos_mt'] : 0,
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

  const FaltasTardanzasResumen({
    required this.mes,
    required this.anio,
    this.minutosTardanzaTotal = 0,
    this.conteoTardanzas = 0,
    this.tardanzasInjustificadas = 0,
    this.faltasTotal = 0,
    this.permisosConGoce = 0,
    this.permisosSinGoce = 0,
  });

  factory FaltasTardanzasResumen.fromJson(Map<String, dynamic> json) {
    return FaltasTardanzasResumen(
      mes: json['mes'] is int ? json['mes'] : int.tryParse(json['mes']?.toString() ?? '1') ?? 1,
      anio: json['anio'] is int ? json['anio'] : int.tryParse(json['anio']?.toString() ?? '2026') ?? 2026,
      minutosTardanzaTotal: json['minutos_tardanza_total'] is int ? json['minutos_tardanza_total'] : 0,
      conteoTardanzas: json['conteo_tardanzas'] is int ? json['conteo_tardanzas'] : 0,
      tardanzasInjustificadas: json['tardanzas_injustificadas'] is int ? json['tardanzas_injustificadas'] : 0,
      faltasTotal: json['faltas_total'] is int ? json['faltas_total'] : 0,
      permisosConGoce: json['permisos_con_goce'] is int ? json['permisos_con_goce'] : 0,
      permisosSinGoce: json['permisos_sin_goce'] is int ? json['permisos_sin_goce'] : 0,
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
      ];
}

class RegistroAsistenciaItem extends Equatable {
  final String fecha;
  final String diaNombre;
  final String turno;
  final String? entrada;
  final String? salida;
  final int minutosTardanza;
  final String estado; // ASISTIO, FALTA, TARDANZA, PERMISO, DESCANSO

  const RegistroAsistenciaItem({
    required this.fecha,
    required this.diaNombre,
    required this.turno,
    this.entrada,
    this.salida,
    this.minutosTardanza = 0,
    required this.estado,
  });

  factory RegistroAsistenciaItem.fromJson(Map<String, dynamic> json) {
    String t = 'D';
    final rawTurno = json['turno'] ?? json['sigla'] ?? json['sigla_turno'];
    if (rawTurno is Map) {
      t = rawTurno['abreviatura']?.toString() ?? rawTurno['sigla']?.toString() ?? 'D';
    } else if (rawTurno != null) {
      t = rawTurno.toString();
    }

    return RegistroAsistenciaItem(
      fecha: json['fecha']?.toString() ?? json['dia']?.toString() ?? '',
      diaNombre: json['dia_nombre']?.toString() ?? json['nombre_dia']?.toString() ?? '',
      turno: t,
      entrada: json['entrada']?.toString() ?? json['hora_entrada']?.toString() ?? json['primer_ingreso']?.toString(),
      salida: json['salida']?.toString() ?? json['hora_salida']?.toString() ?? json['ultimo_egreso']?.toString(),
      minutosTardanza: json['minutos_tardanza'] is int
          ? json['minutos_tardanza']
          : int.tryParse(json['minutos_tardanza']?.toString() ?? '0') ?? 0,
      estado: json['estado']?.toString() ?? 'DESCANSO',
    );
  }

  @override
  List<Object?> get props => [fecha, diaNombre, turno, entrada, salida, minutosTardanza, estado];
}
