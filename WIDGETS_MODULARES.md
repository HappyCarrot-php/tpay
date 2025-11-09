# 📋 Widgets Modulares - TPay App

## 🎯 Resumen de Widgets Creados

Se han creado 5 widgets modulares reutilizables para mejorar la modularidad y mantenibilidad del código de la aplicación TPay. Estos widgets siguen el principio de Clean Architecture y están diseñados para ser usados en múltiples páginas.

---

## 1️⃣ InterestRateSelector

**Ubicación:** `lib/features/admin/presentation/widgets/interest_rate_selector.dart`

### Propósito
Widget para seleccionar la tasa de interés de un préstamo con opciones predefinidas (3%, 5%, 10%) o entrada manual.

### Características
- ✅ Chips seleccionables (ChoiceChips) para 3%, 5%, y 10% mensual
- ✅ Opción "Manual" para ingresar tasa personalizada
- ✅ Campo de texto que aparece automáticamente al seleccionar "Manual"
- ✅ Validación de entrada numérica
- ✅ Diseño responsivo con scroll horizontal

### Parámetros
```dart
InterestRateSelector({
  required String selectedRate,           // Tasa seleccionada: '3', '5', '10', o 'manual'
  required Function(String) onRateChanged, // Callback cuando cambia la selección
  TextEditingController? manualController, // Controller para entrada manual
  bool showManualField = true,            // Mostrar campo manual
})
```

### Uso en Páginas
- ✅ **loan_simulator_page.dart** - Actualizado para usar este widget
- ⏳ **create_loan_page.dart** - Pendiente de actualizar

### Ejemplo de Uso
```dart
InterestRateSelector(
  selectedRate: _selectedInterestRate,
  manualController: _manualInterestController,
  onRateChanged: (rate) {
    setState(() {
      _selectedInterestRate = rate;
    });
  },
)
```

---

## 2️⃣ PasswordConfirmationDialog

**Ubicación:** `lib/features/admin/presentation/widgets/password_confirmation_dialog.dart`

### Propósito
Diálogo de confirmación de dos pasos para operaciones críticas (eliminar, editar). Requiere contraseña del administrador.

### Características
- ✅ Confirmación en dos pasos (Sí/No → Contraseña)
- ✅ Campo de contraseña con visibilidad togglable
- ✅ Manejo de errores con contador de intentos
- ✅ Mensaje personalizable
- ✅ Validación de contraseña del administrador

### Parámetros
```dart
PasswordConfirmationDialog.show({
  required BuildContext context,
  required String adminPassword,      // Contraseña correcta del admin
  required String title,              // Título del diálogo
  required String message,            // Mensaje de confirmación
  String confirmButtonText = 'Confirmar',
})
```

### Uso en Páginas
- ⏳ **admin_loans_list_page.dart** - Pendiente (botones eliminar/editar)
- ⏳ **admin_clients_page.dart** - Pendiente (botones eliminar/editar)

### Ejemplo de Uso
```dart
final confirmed = await PasswordConfirmationDialog.show(
  context: context,
  adminPassword: 'admin123', // TODO: Obtener de Supabase
  title: 'Eliminar Préstamo',
  message: '¿Está seguro de eliminar el préstamo #12345?',
);

if (confirmed == true) {
  // Realizar la operación de eliminación
}
```

---

## 3️⃣ LoanInfoCard

**Ubicación:** `lib/features/admin/presentation/widgets/loan_info_card.dart`

### Propósito
Tarjeta para mostrar la información financiera de un préstamo con cálculos correctos.

### Características
- ✅ Muestra: Monto, Interés, Total a Pagar, Abonos, Deuda Actual
- ✅ Cálculos automáticos correctos:
  - **Total a Pagar** = Monto + Interés
  - **Deuda Actual** = Total a Pagar - Abonos
- ✅ Colores semánticos (verde para pagado, rojo para deuda)
- ✅ Modo detallado y compacto
- ✅ Formato de moneda mexicana

### Parámetros
```dart
LoanInfoCard({
  required double loanAmount,        // Monto del préstamo
  required double interestRate,      // Tasa de interés (%)
  required double totalPayments,     // Total de abonos realizados
  bool isCompact = false,            // Modo compacto
})
```

### Uso en Páginas
- ⏳ **admin_loans_list_page.dart** - Pendiente de actualizar
- ⏳ **create_loan_page.dart** - Pendiente para vista previa

### Ejemplo de Uso
```dart
LoanInfoCard(
  loanAmount: 10000.0,
  interestRate: 5.0,
  totalPayments: 3000.0,
  isCompact: false,
)

// Resultado mostrado:
// Monto: $10,000.00
// Interés (5%): $500.00
// Total a Pagar: $10,500.00
// Abonos: $3,000.00
// Deuda Actual: $7,500.00
```

---

## 4️⃣ LoanSearchSelector

**Ubicación:** `lib/features/admin/presentation/widgets/loan_search_selector.dart`

### Propósito
Widget de búsqueda avanzada de préstamos con tres modos de búsqueda.

### Características
- ✅ **Tres modos de búsqueda:**
  1. Por número de préstamo
  2. Por ID de cliente
  3. Por nombre de cliente
- ✅ Búsqueda con autocompletado (DropdownSearch)
- ✅ Tarjeta de resultado con información del préstamo
- ✅ Muestra deuda total del cliente
- ✅ Diseño con Chips para seleccionar modo

### Parámetros
```dart
LoanSearchSelector({
  required LoanSearchType searchType,                    // Tipo de búsqueda
  required Function(LoanSearchType) onSearchTypeChanged, // Cambio de tipo
  required Function(Map<String, dynamic>?) onLoanSelected, // Préstamo seleccionado
  List<Map<String, dynamic>> mockLoans = const [],       // Datos de préstamos
  List<Map<String, dynamic>> mockClients = const [],     // Datos de clientes
})
```

### Uso en Páginas
- ⏳ **admin_loans_list_page.dart** - Pendiente de integrar
- ⏳ Puede usarse en página de pagos/abonos

### Ejemplo de Uso
```dart
LoanSearchSelector(
  searchType: _currentSearchType,
  onSearchTypeChanged: (type) {
    setState(() {
      _currentSearchType = type;
      _selectedLoan = null;
    });
  },
  onLoanSelected: (loan) {
    setState(() {
      _selectedLoan = loan;
    });
  },
  mockLoans: _prestamos,
  mockClients: _clientes,
)
```

---

## 5️⃣ ReceiptImageGenerator

**Ubicación:** `lib/features/admin/presentation/widgets/receipt_image_generator.dart`

### Propósito
Generador de recibos de pago en formato imagen PNG que se pueden guardar en el dispositivo.

### Características
- ✅ Genera recibo visual con toda la información del pago
- ✅ Guarda imagen en carpeta Download/TPay (Android) o Documents (iOS)
- ✅ Vista previa del recibo antes de guardar
- ✅ Formato profesional con logo, firma, etc.
- ✅ Incluye: Monto pagado, Total abonado, Deuda restante

### Métodos Principales
```dart
// 1. Construir widget de recibo
Widget buildReceiptWidget({
  required String receiptNumber,
  required String loanNumber,
  required String clientName,
  required String clientId,
  required double paymentAmount,
  required DateTime paymentDate,
  required String adminName,
  required double remainingDebt,
  required double totalPaid,
})

// 2. Capturar y guardar imagen
Future<String?> captureAndSaveReceipt({
  required GlobalKey key,
  required String fileName,
})

// 3. Mostrar diálogo con preview y botón guardar
Future<void> showReceiptDialog({
  required BuildContext context,
  // ... parámetros del recibo
})
```

### Uso en Páginas
- ⏳ Página de registro de pagos/abonos (pendiente de crear)
- ⏳ Vista de detalles de préstamo

### Ejemplo de Uso
```dart
// Mostrar recibo después de registrar un pago
await ReceiptImageGenerator.showReceiptDialog(
  context: context,
  receiptNumber: 'REC-001',
  loanNumber: 'L-12345',
  clientName: 'Juan Pérez',
  clientId: 'CLI-001',
  paymentAmount: 1000.0,
  paymentDate: DateTime.now(),
  adminName: 'Admin Usuario',
  remainingDebt: 9500.0,
  totalPaid: 1000.0,
);
```

---

## 📦 Dependencias Añadidas

### path_provider (^2.1.4)
Para guardar las imágenes de recibos en el almacenamiento del dispositivo.

```yaml
dependencies:
  path_provider: ^2.1.4
```

### Permisos Android
Se agregaron permisos de almacenamiento en `AndroidManifest.xml`:

```xml
<!-- Permisos de almacenamiento para guardar recibos -->
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
    android:maxSdkVersion="32" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
    android:maxSdkVersion="32" />
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
```

---

## 🎨 Tema Actualizado

El tema de la app se actualizó a un diseño minimalista moderno:

### Colores Principales
- **Primary Color:** `#00BCD4` (Turquesa)
- **Primary Light:** `#B2EBF2`
- **Primary Dark:** `#0097A7`
- **Accent Color:** `#FF5722` (Naranja)
- **Success:** `#4CAF50` (Verde)
- **Error:** `#F44336` (Rojo)

### Estilo Minimalista
- ✅ AppBar blanca sin elevación
- ✅ Tarjetas con bordes sutiles en lugar de sombras fuertes
- ✅ Botones planos sin elevación
- ✅ Espaciado generoso
- ✅ Tipografía clara y legible

---

## ✅ Estado Actual de Integración

| Página | Widgets Integrados | Estado |
|--------|-------------------|--------|
| **loan_simulator_page.dart** | InterestRateSelector | ✅ Completado |
| **create_loan_page.dart** | InterestRateSelector, PasswordConfirmationDialog | ⏳ Pendiente |
| **admin_loans_list_page.dart** | LoanInfoCard, LoanSearchSelector, PasswordConfirmationDialog | ⏳ Pendiente |
| **admin_clients_page.dart** | PasswordConfirmationDialog | ⏳ Pendiente |
| **Página de Pagos** | ReceiptImageGenerator, LoanSearchSelector | ⏳ Pendiente crear |

---

## 🚀 Próximos Pasos Sugeridos

### Alta Prioridad
1. ✅ Actualizar `create_loan_page.dart` para usar `InterestRateSelector`
2. ✅ Actualizar `admin_loans_list_page.dart` para usar:
   - `LoanInfoCard` en lugar de código inline
   - `LoanSearchSelector` para búsqueda
   - `PasswordConfirmationDialog` para eliminar/editar
3. ✅ Actualizar `admin_clients_page.dart` para usar `PasswordConfirmationDialog`

### Media Prioridad
4. ✅ Crear página de registro de pagos/abonos
5. ✅ Integrar `ReceiptImageGenerator` en registro de pagos
6. ✅ Agregar validaciones de contraseña real (conectar con Supabase)

### Baja Prioridad
7. ✅ Crear más widgets modulares según necesidad
8. ✅ Agregar tests unitarios para cada widget
9. ✅ Documentar casos de uso adicionales

---

## 📖 Notas de Desarrollo

- Todos los widgets siguen el patrón **StatelessWidget** cuando es posible
- Se usa **callback pattern** para comunicación con páginas padre
- Los widgets son **independientes** y no tienen dependencias entre sí
- Los cálculos financieros están **centralizados** en los widgets
- El formato de moneda usa **locale mexicano** (es_MX)

---

## 🐛 Problemas Conocidos

1. **Datos Mock:** Actualmente todos los widgets usan datos hardcodeados. Necesitan conectarse a Supabase.
2. **Contraseña Admin:** La contraseña del administrador está hardcodeada. Debe obtenerse de la sesión de Supabase.
3. **Permisos iOS:** Puede requerir configuración adicional en Info.plist para guardar imágenes.

---

**Fecha de Actualización:** ${DateTime.now().toString().split(' ')[0]}
**Versión:** 1.0.0
**Autor:** Copilot AI Assistant
