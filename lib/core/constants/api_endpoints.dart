class ApiEndpoints {
  // Autenticación & Perfil
  static const String login = '/login';
  static const String logout = '/logout';
  static const String perfil = '/perfil';

  // Asistencia & Turnos
  static const String asistenciaHoy = '/asistencia/hoy';
  static const String misRegistros = '/asistencia/mis-registros';
  static const String miRolMes = '/asistencia/mi-rol-mes';
  static const String faltasTardanzas = '/asistencia/faltas-tardanzas';

  // Cambio de Turno
  static const String datosParaCambioTurno = '/datos-para-cambio-turno';
  static const String obtenerPersonalPorDni = '/obtener-personal-por-dni';
  static const String turnoPorFechaPersonal = '/cambio-turno/turno-por-fecha-personal';
  static const String validarCambioTurno = '/cambio-turno/validar';
  static const String storeCambioTurno = '/cambio-turno/store';
  static const String misCambiosTurno = '/cambio-turno/mis-cambios';

  // Permisos & CIT
  static const String tiposPermisos = '/tipos-permisos';
  static const String resumenCit = '/permisos/resumen-cit';
  static const String disponibilidadParticulares = '/permisos/disponibilidad-particulares';
  static const String ocrEscanear = '/permisos/ocr-escanear';
  static const String guardarPermiso = '/guardar-permiso';
  static const String listarPermisos = '/permisos';
}
