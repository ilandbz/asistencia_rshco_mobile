# 📱 Bitácora Completa de Desarrollo: RSHCO Asistencia Móvil (Red de Salud Huánuco)

---

## 📌 1. Información General del Proyecto
- **Entidad**: Red de Salud Huánuco (RSHCO).
- **Objetivo**: Aplicación móvil oficial para el personal asistencial y administrativo (médicos, enfermeros, obstetras, técnicos y administrativos) orientada a la gestión de asistencia, consulta de rol mensual de turnos, permutas de turnos y descansos médicos (CIT / subsidios EsSalud).
- **Backend / API**: Laravel con Sanctum (`https://asistencia.macrocompany.net.pe/api`).
- **Plataformas**: Android (APK release generado) e iOS (preparado y adaptado).

---

## 🛠️ 2. Stack Tecnológico & Arquitectura
- **Framework**: Flutter 3.24+ (Material 3 activo).
- **Lenguaje**: Dart 3.5+.
- **Gestión de Estado**: Flutter Riverpod (`flutter_riverpod: ^2.6.1`).
- **Navegación**: GoRouter (`go_router: ^14.8.1`) con guards basados en el estado de autenticación.
- **Cliente HTTP**: Dio (`dio: ^5.7.0`) con `AuthInterceptor` para inyección de `Bearer Token` y refresco de sesión.
- **Almacenamiento Seguro**: `flutter_secure_storage: ^11.2.0` (Android Keystore / iOS Keychain).
- **Archivos & Multimedia**: `file_picker: ^13.4.1`, `image_picker: ^1.1.2`.
- **Diseño**: Clean Architecture con organización modular **Feature-First**:
  - `core/`: Configuración, constantes de API, excepciones HTTP tipadas, interceptores de red, rutas y temas.
  - `features/auth/`: Login, Splash y Perfil del Trabajador.
  - `features/asistencia/`: Marcación de hoy, resumen de tardanzas/faltas e historial del mes.
  - `features/cambio_turno/`: Búsqueda de colegas por DNI, pre-validación de topes de guardia y registro de permutas.
  - `features/permisos/`: Trámite de licencias, indicador de regla 1-20 días vs subsidio EsSalud y soporte OCR para CIT.

---

## 🚀 3. Historial de Fases y Soluciones Implementadas

### Fase 1: Creación del Proyecto & Arquitectura Base
1. Se estructuró el proyecto bajo Clean Architecture (Data, Domain, Presentation).
2. Se configuraron las dependencias en `pubspec.yaml`.
3. Se implementó `DioClient` con manejo de errores para códigos `401 (Unauthorized)`, `422 (Validation)`, `500 (Server)`.
4. Se creó el sistema de persistencia cifrada para tokens y datos del trabajador con `SecureStorageService`.
5. Se configuraron los permisos de red, almacenamiento y cámara en `AndroidManifest.xml` e `Info.plist` de iOS.

---

### Fase 2: Módulos de Asistencia, Turnos, Permutas y Permisos (CIT)
1. **Asistencia & Turnos**:
   - `MarcacionHoy`: Visualización de hora de ingreso, salida, estado y turno programado.
   - `RolMensual`: Calendario mensual con códigos de colores por turno (`M`, `T`, `N`, `MT`, `GD`, `GN`, `D`).
   - `FaltasTardanzasResumen`: Conteo de minutos acumulados y faltas del mes.
2. **Cambio de Turnos (Permutas)**:
   - Control de negocio: solo permite solicitar permutas para turnos futuros.
   - Búsqueda en vivo de colegas por DNI del mismo establecimiento.
   - Pre-validación ante el servidor antes de asentar el estado `SOLICITADO`.
3. **Permisos y Descansos Médicos (CIT)**:
   - Visualización del límite anual de 20 días asumidos por el empleador (Red de Salud) vs subsidio de EsSalud (día 21 en adelante con CITT obligatorio).
   - Carga de imágenes/PDF sustentatorios y compatibilidad con escaneo OCR asistido por IA.

---

### Fase 3: Resolución de Errores de Compilación (Gradle & Android SDK)
1. **Error de importaciones relativas**:
   - Se ajustaron los imports en controladores que requerían subir dos niveles (`../../data/...`).
2. **Error de API `CardTheme` vs `CardThemeData`**:
   - En Flutter 3.24+, `ThemeData.cardTheme` requería la clase `CardThemeData`.
3. **Conflicto `checkReleaseAarMetadata` (Android compileSdk 36)**:
   - `file_picker` requería Android API 36+. Se actualizaron `file_picker` a `^13.4.1` y `flutter_secure_storage` a `^11.2.0`, configurando `compileSdk = 36` en `build.gradle.kts`.
4. **Espacio en disco insuficiente en `C:`**:
   - Se detectó que el disco local estaba lleno impidiendo la ejecución de `MergeNativeLibsTaskWorkAction`. Tras liberar espacio en la carpeta `Downloads`, la compilación se completó con éxito.

---

### Fase 4: Ajustes de Negocio en Producción
1. **Error *"El campo name es obligatorio"***:
   - El backend de Laravel requería el parámetro `name` en la petición de autenticación. Se ajustó el payload de `login` para enviar `name: dni` garantizando compatibilidad total.
2. **Logo Oficial de la RSHCO**:
   - Se incorporó el logotipo oficial circular en `assets/images/logo_rshco.png`, mostrándose en el Splash y Login.
   - Se actualizaron todos los iconos nativos de Android (`res/mipmap-*/ic_launcher.png`) para que la app tenga el logo de la Red en la pantalla de inicio del teléfono.
3. **Caché y datos del trabajador (Establecimiento, Cargo, Condición, Régimen)**:
   - Se rediseñó la tarjeta de perfil en el Home para reflejar DNI, cargo en azul institucional, establecimiento, condición laboral y régimen.
   - Se implementó sincronización forzada con `/api/perfil` al momento del login para evitar datos vacíos o de sesiones previas.
4. **Limpieza de Metadatos en Marcaciones**:
   - El endpoint retornaba el turno como un objeto anidado `{ abreviatura: "MT", nombre: "MAÑANA Y TARDE", ... }`. Se adaptó el modelo para extraer la sigla limpia y el nombre legible del turno.
   - Se flexibilizó el parser de horas de marcación de hoy para reconocer `hora_ingreso`, `primer_marcado`, `entrada` o listas de eventos `marcaciones`.
5. **Documentación del Repositorio**:
   - Se redactó el archivo `README.md` completo para publicación en GitHub.

---

## 📦 4. Entregables Generados

- **APK de Producción**:
  `build\app\outputs\flutter-apk\app-release.apk` (55.8 MB)
- **Documentación de Repositorio**:
  `README.md`
- **Logo Institucional**:
  `assets/images/logo_rshco.png`
- **Iconos del Dispositivo**:
  `android/app/src/main/res/mipmap-*/ic_launcher.png`
- **Entorno Configurado**:
  `https://asistencia.macrocompany.net.pe/api`
