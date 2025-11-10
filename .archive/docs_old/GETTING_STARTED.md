# 🚀 TPay - Guía de Inicio Rápido

## ✅ Estado Actual del Proyecto

### ✨ Completado:
- ✅ Estructura Clean Architecture
- ✅ Modo Administrador completo con UI
- ✅ Simulador de préstamos (sin BD)
- ✅ Sistema de búsqueda de clientes mejorado
- ✅ CRUD de préstamos (UI)
- ✅ CRUD de clientes (UI)
- ✅ Menú lateral con navegación
- ✅ Tema personalizado
- ✅ Rutas configuradas
- ✅ Permisos de WiFi/Internet

### ⏳ Pendiente:
- ⚠️ Conexión con Supabase
- ⚠️ Sistema de autenticación
- ⚠️ Modo Cliente
- ⚠️ Verificación de email/teléfono

## 📱 Probar la Aplicación

### Opción 1: Ejecutar en modo debug
```bash
flutter run
```

### Opción 2: Ver dispositivos disponibles
```bash
flutter devices
```

### Opción 3: Ejecutar en un dispositivo específico
```bash
flutter run -d <device-id>
```

## 🔧 Configuración Pendiente

### 1. Configurar Supabase

#### Paso 1: Crear proyecto en Supabase
1. Ve a [supabase.com](https://supabase.com)
2. Crea una cuenta o inicia sesión
3. Crea un nuevo proyecto
4. Guarda la URL y la clave anónima

#### Paso 2: Ejecutar SQL de la Base de Datos
1. Ve a SQL Editor en tu proyecto de Supabase
2. Copia y pega el contenido de `supabase_bd_mejorada.sql`
3. Ejecuta el script

#### Paso 3: Configurar credenciales en la app
Edita el archivo: `lib/core/constants/supabase_constants.dart`

```dart
class SupabaseConstants {
  static const String supabaseUrl = 'TU_URL_DE_SUPABASE';
  static const String supabaseAnonKey = 'TU_CLAVE_ANONIMA';
  
  // ... resto del código
}
```

### 2. Agregar Logo de la App

Copia el logo a:
```
assets/images/tpay_logo.png
```

### 3. Configurar Iconos de la App (Opcional)

Para Android e iOS, puedes usar el paquete `flutter_launcher_icons`:

```bash
flutter pub add --dev flutter_launcher_icons
```

Luego crea el archivo `flutter_launcher_icons.yaml` y ejecuta:
```bash
flutter pub run flutter_launcher_icons
```

## 📂 Archivos Importantes

### Configuración
- `lib/core/constants/supabase_constants.dart` - Credenciales de Supabase
- `lib/config/theme/app_theme.dart` - Tema de la app
- `lib/config/routes/app_router.dart` - Rutas de navegación

### Páginas Principales del Admin
- `lib/features/admin/presentation/pages/admin_home_page.dart` - Página principal
- `lib/features/admin/presentation/pages/loan_simulator_page.dart` - Simulador
- `lib/features/admin/presentation/pages/create_loan_page.dart` - Registrar préstamo
- `lib/features/admin/presentation/pages/admin_loans_list_page.dart` - Lista de préstamos
- `lib/features/admin/presentation/pages/admin_clients_page.dart` - Gestión de clientes

### Widgets Compartidos
- `lib/features/admin/presentation/widgets/admin_drawer.dart` - Menú lateral

## 🎯 Funcionalidades por Explorar

### En el Simulador de Préstamo:
1. Ingresa un monto (ej: 10000)
2. Selecciona tasa de interés (3%, 5%, 10% o Manual)
3. Selecciona fechas
4. Presiona "Calcular Simulación"
5. Observa los resultados

### En Registro de Préstamo:
1. Selecciona buscar por "ID" o "Nombre"
2. Busca un cliente existente
3. Si no existe, completa el formulario
4. Solo el nombre es obligatorio
5. Ingresa datos del préstamo
6. Guarda

### En Lista de Préstamos:
1. Ve todos los préstamos
2. Filtra por estado (botón filtro en AppBar)
3. Edita un préstamo
4. Elimina un préstamo (con confirmación)

### En Clientes:
1. Busca clientes en tiempo real
2. Ve información de cada cliente
3. Edita datos del cliente
4. Elimina clientes (con confirmación)

## 🐛 Solución de Problemas

### Error: "No device found"
```bash
# Para Android
flutter emulators
flutter emulators --launch <emulator-id>

# O conecta un dispositivo físico con USB debugging
```

### Error: "Gradle build failed"
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

### Error: Dependencias no encontradas
```bash
flutter clean
flutter pub get
```

### La app no carga
1. Verifica que estés en el directorio correcto
2. Asegúrate de tener Flutter instalado correctamente:
```bash
flutter doctor
```

## 📚 Recursos

### Flutter
- [Documentación oficial](https://flutter.dev/docs)
- [Widget Catalog](https://flutter.dev/widgets)
- [Cookbook](https://flutter.dev/cookbook)

### Supabase
- [Documentación](https://supabase.com/docs)
- [Flutter Quick Start](https://supabase.com/docs/guides/getting-started/quickstarts/flutter)

### Paquetes Usados
- [flutter_bloc](https://pub.dev/packages/flutter_bloc) - State management
- [go_router](https://pub.dev/packages/go_router) - Routing
- [supabase_flutter](https://pub.dev/packages/supabase_flutter) - Backend

## 🎨 Colores del Diseño

Los colores están definidos en `lib/config/theme/app_theme.dart`:

- **Primary (Cyan):** `#00BCD4`
- **Secondary (Azul):** `#0277BD`
- **Accent:** `#40E0D0`
- **Success:** `#4CAF50`
- **Error:** `#D32F2F`
- **Warning:** `#FFA726`

## 📝 Notas de Desarrollo

### Datos Mock (Temporales)
Actualmente, todas las páginas usan datos simulados (hardcoded) para pruebas.
Estos están en cada página y deben reemplazarse con llamadas a Supabase.

Ejemplo en `admin_loans_list_page.dart`:
```dart
final List<Map<String, dynamic>> _prestamos = [
  // Datos de prueba
];
```

### Próximo Paso Crítico
Implementar los **DataSources** y **Repositories** para conectar con Supabase:

```
lib/features/admin/data/
├── datasources/
│   └── loan_remote_datasource.dart  ← Crear
├── repositories/
│   └── loan_repository_impl.dart    ← Crear
```

## 🔐 Seguridad

⚠️ **IMPORTANTE:** 
- No subas tus credenciales de Supabase a GitHub
- Agrega `lib/core/constants/supabase_constants.dart` al `.gitignore` si es necesario
- Usa variables de entorno en producción

## ✅ Checklist para Producción

- [ ] Configurar Supabase
- [ ] Implementar autenticación
- [ ] Conectar todas las páginas con BD
- [ ] Implementar modo cliente
- [ ] Agregar logo e iconos
- [ ] Probar en Android e iOS
- [ ] Implementar manejo de errores
- [ ] Agregar loading states
- [ ] Implementar verificación email/SMS
- [ ] Configurar políticas de seguridad en Supabase
- [ ] Testing
- [ ] Optimizar rendimiento

---

¡Disfruta desarrollando con TPay! 🚀💙
