# 🏥 RSHCO Asistencia Móvil (Red de Salud Huánuco)

Aplicación móvil oficial de la **Red de Salud Huánuco (RSHCO)** para la gestión y control de asistencia, turnos y descansos médicos (CIT) del personal de salud (médicos, enfermeros, obstetras, técnicos y administrativos).

<p align="center">
  <img src="assets/images/logo_rshco.png" width="130" alt="Logo Red de Salud Huánuco" />
</p>

---

## 📱 Características Principales

### 1. 🕒 Consulta de Asistencia y Marcaciones en Tiempo Real
- **Estado de Hoy**: Consulta inmediata de turnos programados (`M`, `T`, `N`, `MT`, `GD`, `GN`), horario de entrada/salida y estado de marcación (`PENDIENTE`, `ASISTIO`, `TARDANZA`).
- **Resumen Mensual**: Métricas acumuladas de minutos de tardanza, número de tardanzas injustificadas y faltas.
- **Historial de Asistencia**: Detalle diario de horas de ingreso y salida del mes.

### 2. 📅 Rol de Turnos Mensual
- Calendario mensual en cuadrícula (*GridView*) con identificación cromática de siglas médicas institucionales.
- Detalle interactivo de guardias diurnas y nocturnas con horas programadas.
- Paginación dinámica por mes y año.

### 3. 🔄 Solicitud de Cambio de Turno (Permutas)
- **Control de Negocio Asistencial**: Solo permite permutar turnos futuros antes de su ejecución.
- Búsqueda en vivo de colegas por DNI dentro del mismo establecimiento de salud.
- **Pre-Validación**: Validación en tiempo real de topes de guardia, cruces de horario o bloqueos de 24h antes del envío.
- Seguimiento de solicitudes por estado: `SOLICITADO`, `APROBADO`, `RECHAZADO`, `EJECUTADO`.

### 4. 📋 Permisos y Descansos Médicos (CIT)
- **Control de Incapacidad Temporal (CIT)**:
  - Días 1 al 20 del año: Asumidos por el empleador (Red de Salud).
  - A partir del día 21: Subsidio obligatorio de EsSalud (requiere número de CITT).
- **Barra de Progreso Visual**: Control anual del consumo de días asumidos por la Red.
- **Cámara & Documentos**: Adjuntos sustentatorios mediante cámara o archivos PDF.
- **Soporte OCR con IA**: Extracción automática de CITT, CMP y fechas del descanso médico.

---

## 🛠️ Stack Tecnológico

- **Framework**: [Flutter](https://flutter.dev/) 3.24+ (Material 3 activo).
- **Lenguaje**: Dart 3.5+.
- **Gestión de Estado**: [Riverpod](https://riverpod.dev/) (`flutter_riverpod`).
- **Navegación**: [GoRouter](https://pub.dev/packages/go_router) con guards de sesión reactivos.
- **Cliente HTTP**: [Dio](https://pub.dev/packages/dio) con interceptores para inyección automática de Bearer Token, logging y captura centralizada de errores (401, 422, 500).
- **Almacenamiento Cifrado**: [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage) (Android Keystore / iOS Keychain).
- **Cámara & Archivos**: `image_picker` y `file_picker`.
- **Internacionalización**: `intl` configurado en español de Perú (`es_PE`).

---

## 🏗️ Arquitectura del Proyecto (Clean Architecture / Feature-First)

```text
lib/
├── main.dart
├── core/
│   ├── constants/           # Endpoints de API y Configuración de entornos
│   ├── errors/              # Excepciones personalizadas (ValidationException, etc.)
│   ├── network/             # Cliente Dio y AuthInterceptor (Bearer Token)
│   ├── routes/              # Configuración y Guards de GoRouter
│   ├── services/            # SecureStorageService cifrado
│   └── theme/               # Paleta institucional médica RSHCO (Material 3)
└── features/
    ├── auth/                # Login por DNI, Splash Screen y Perfil Laboral
    ├── asistencia/          # Marcaciones hoy, rol mensual e historial
    ├── cambio_turno/        # Permutas, validación de reglas y colega search
    └── permisos/            # Trámite de CIT, subsidios EsSalud y fotos
```

---

## ⚙️ Configuración e Instalación

### 1. Clonar el repositorio
```bash
git clone https://github.com/TU_USUARIO/asistencia_rshco_mobile.git
cd asistencia_rshco_mobile
```

### 2. Configurar la URL de la API
Edita el archivo `lib/core/constants/app_config.dart` según tu entorno:
```dart
static String get baseUrl => 'https://asistencia.macrocompany.net.pe/api';
```

### 3. Instalar dependencias
```bash
flutter pub get
```

### 4. Ejecutar en modo desarrollo
```bash
flutter run
```

### 5. Compilar APK para Producción (Release)
```bash
flutter build apk --release
```
El instalador generado se encontrará en:
`build/app/outputs/flutter-apk/app-release.apk`

---

## 🏢 Institución
**Red de Salud Huánuco (RSHCO)**  
*Oficina de Recursos Humanos y Tecnologías de la Información*  
Huánuco, Perú
