import 'package:equatable/equatable.dart';

class User extends Equatable {
  final int id;
  final String dni;
  final String? name;
  final String? email;

  const User({
    required this.id,
    required this.dni,
    this.name,
    this.email,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      dni: json['dni']?.toString() ?? '',
      name: json['name']?.toString() ?? json['nombres']?.toString(),
      email: json['email']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'dni': dni,
        'name': name,
        'email': email,
      };

  @override
  List<Object?> get props => [id, dni, name, email];
}

class Personal extends Equatable {
  final int id;
  final String dni;
  final String nombres;
  final String apellidoPaterno;
  final String apellidoMaterno;
  final String? cargo;
  final String? establecimiento;
  final String? microred;
  final String? condicionLaboral;
  final String? regimen;
  final String? tipoTrabajador;
  final String? servicio;
  final String? direccion;
  final String? celular;
  final String? email;

  const Personal({
    required this.id,
    required this.dni,
    required this.nombres,
    required this.apellidoPaterno,
    required this.apellidoMaterno,
    this.cargo,
    this.establecimiento,
    this.microred,
    this.condicionLaboral,
    this.regimen,
    this.tipoTrabajador,
    this.servicio,
    this.direccion,
    this.celular,
    this.email,
  });

  String get nombreCompleto => '$nombres $apellidoPaterno $apellidoMaterno'.trim();

  factory Personal.fromJson(Map<String, dynamic> json) {
    // Si viene anidado en personal, data o trabajador
    final Map<String, dynamic> map = json['personal'] is Map<String, dynamic>
        ? json['personal']
        : (json['data'] is Map<String, dynamic> ? json['data'] : json);

    // Extraer establecimiento (puede venir como string, objeto establecimiento o dependencia)
    String? est;
    if (map['establecimiento'] is Map) {
      est = map['establecimiento']['nombre']?.toString() ??
          map['establecimiento']['descripcion']?.toString();
    } else {
      est = map['establecimiento']?.toString() ??
          map['nombre_establecimiento']?.toString() ??
          map['dependencia']?.toString() ??
          map['centro_salud']?.toString();
    }

    // Extraer cargo
    String? car;
    if (map['cargo'] is Map) {
      car = map['cargo']['nombre']?.toString() ?? map['cargo']['descripcion']?.toString();
    } else {
      car = map['cargo']?.toString() ??
          map['nombre_cargo']?.toString() ??
          map['puesto']?.toString();
    }

    // Extraer condición laboral
    String? cond;
    if (map['condicion_laboral'] is Map) {
      cond = map['condicion_laboral']['nombre']?.toString();
    } else {
      cond = map['condicion_laboral']?.toString() ??
          map['condicion']?.toString() ??
          map['modalidad']?.toString();
    }

    // Extraer régimen
    String? reg;
    if (map['regimen'] is Map) {
      reg = map['regimen']['nombre']?.toString();
    } else {
      reg = map['regimen']?.toString() ??
          map['regimen_laboral']?.toString() ??
          map['tipo_regimen']?.toString();
    }

    // Extraer microred
    String? mic;
    if (map['microred'] is Map) {
      mic = map['microred']['nombre']?.toString() ?? map['microred']['descripcion']?.toString();
    } else {
      mic = map['microred']?.toString() ?? map['nombre_microred']?.toString();
    }

    // Extraer servicio
    String? serv;
    if (map['servicio'] is Map) {
      serv = map['servicio']['nombre']?.toString();
    } else {
      serv = map['servicio']?.toString() ?? map['area']?.toString();
    }

    // Tipo trabajador y contacto
    final String? tipoTrab = map['tipo_trabajador']?.toString();
    final String? dir = map['direccion']?.toString();
    final String? cel = map['celular']?.toString() ?? map['telefono']?.toString();
    final String? mail = map['email']?.toString() ?? map['correo']?.toString() ?? json['email']?.toString();

    // Nombres y apellidos
    final String nom = map['nombres']?.toString() ?? map['nombre']?.toString() ?? '';
    final String pat = map['apellido_paterno']?.toString() ?? map['paterno']?.toString() ?? '';
    final String mat = map['apellido_materno']?.toString() ?? map['materno']?.toString() ?? '';

    return Personal(
      id: map['id'] is int ? map['id'] : int.tryParse(map['id']?.toString() ?? '0') ?? 0,
      dni: map['dni']?.toString() ?? map['numero_documento']?.toString() ?? map['documento']?.toString() ?? '',
      nombres: nom,
      apellidoPaterno: pat,
      apellidoMaterno: mat,
      cargo: car,
      establecimiento: est,
      microred: mic,
      condicionLaboral: cond,
      regimen: reg,
      tipoTrabajador: tipoTrab,
      servicio: serv,
      direccion: dir,
      celular: cel,
      email: mail,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'dni': dni,
        'nombres': nombres,
        'apellido_paterno': apellidoPaterno,
        'apellido_materno': apellidoMaterno,
        'cargo': cargo,
        'establecimiento': establecimiento,
        'microred': microred,
        'condicion_laboral': condicionLaboral,
        'regimen': regimen,
        'tipo_trabajador': tipoTrabajador,
        'servicio': servicio,
        'direccion': direccion,
        'celular': celular,
        'email': email,
      };

  @override
  List<Object?> get props => [
        id,
        dni,
        nombres,
        apellidoPaterno,
        apellidoMaterno,
        cargo,
        establecimiento,
        microred,
        condicionLaboral,
        regimen,
        tipoTrabajador,
        servicio,
        direccion,
        celular,
        email,
      ];
}

class AuthResponse extends Equatable {
  final String token;
  final User? user;
  final Personal? personal;

  const AuthResponse({
    required this.token,
    this.user,
    this.personal,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    // Si viene la data envuelta en 'data'
    final Map<String, dynamic> root = json['data'] is Map<String, dynamic> ? json['data'] : json;

    return AuthResponse(
      token: root['token']?.toString() ??
          root['access_token']?.toString() ??
          json['token']?.toString() ??
          '',
      user: root['user'] != null ? User.fromJson(root['user']) : null,
      personal: (root['personal'] != null || root['trabajador'] != null)
          ? Personal.fromJson((root['personal'] ?? root['trabajador']) as Map<String, dynamic>)
          : (json['personal'] != null
              ? Personal.fromJson(json['personal'] as Map<String, dynamic>)
              : null),
    );
  }

  @override
  List<Object?> get props => [token, user, personal];
}
