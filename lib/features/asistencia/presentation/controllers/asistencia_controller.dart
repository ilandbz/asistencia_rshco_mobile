import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/asistencia_model.dart';
import '../../data/repositories/asistencia_repository.dart';

// Proveedor para Marcación de Hoy
final marcacionHoyProvider = FutureProvider.autoDispose<MarcacionHoy>((ref) async {
  final repo = ref.watch(asistenciaRepositoryProvider);
  return await repo.getMarcacionHoy();
});

// Proveedor para Mes y Año seleccionados
class MonthYearFilter {
  final int mes;
  final int anio;
  MonthYearFilter({required this.mes, required this.anio});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MonthYearFilter && runtimeType == other.runtimeType && mes == other.mes && anio == other.anio;

  @override
  int get hashCode => mes.hashCode ^ anio.hashCode;
}

final currentFilterProvider = StateProvider<MonthYearFilter>((ref) {
  final now = DateTime.now();
  return MonthYearFilter(mes: now.month, anio: now.year);
});

// Proveedor para Rol Mensual
final rolMensualProvider = FutureProvider.autoDispose<RolMensual>((ref) async {
  final repo = ref.watch(asistenciaRepositoryProvider);
  final filter = ref.watch(currentFilterProvider);
  return await repo.getRolMensual(mes: filter.mes, anio: filter.anio);
});

// Proveedor para Resumen de Faltas y Tardanzas
final faltasTardanzasProvider = FutureProvider.autoDispose<FaltasTardanzasResumen>((ref) async {
  final repo = ref.watch(asistenciaRepositoryProvider);
  final filter = ref.watch(currentFilterProvider);
  return await repo.getResumenFaltasTardanzas(mes: filter.mes, anio: filter.anio);
});

// Proveedor para Historial de Registros
final misRegistrosProvider = FutureProvider.autoDispose<List<RegistroAsistenciaItem>>((ref) async {
  final repo = ref.watch(asistenciaRepositoryProvider);
  final filter = ref.watch(currentFilterProvider);
  return await repo.getMisRegistros(mes: filter.mes, anio: filter.anio);
});
