# Guía de Integración de Notificaciones

## ✅ Completado

### 1. NotificationService Mejorado
Se ha mejorado el servicio de notificaciones con los siguientes métodos:

- ✅ `initialize()` - Inicializa el servicio con permisos de Android/iOS
- ✅ `schedulePaymentReminder()` - Recordatorio 1 semana antes del vencimiento
- ✅ `schedulePaymentDue()` - Notificación el día del vencimiento
- ✅ `scheduleOverdueNotification()` - Alerta de mora 3 días después
- ✅ `notifyPaymentReceived()` - Notificación instantánea al recibir pago
- ✅ `notifyLoanPaidOff()` - Notificación de préstamo completado
- ✅ `cancelLoanNotifications()` - Cancela todas las notificaciones de un préstamo
- ✅ `showInstantNotification()` - Notificación instantánea genérica

### 2. Integración en LoanActionButtons
Se han agregado notificaciones automáticas en:

✅ **Marcar como Pagado** (`_marcarComoPagado`):
```dart
// Cancela notificaciones pendientes
await NotificationService().cancelLoanNotifications(prestamo.id);

// Notifica al admin
await NotificationService().notifyLoanPaidOff(
  loanId: prestamo.id,
  clientName: prestamo.nombreCliente ?? 'Cliente',
  isAdmin: true,
);
```

✅ **Agregar Abono** (`_agregarAbono`):
```dart
// Notifica sobre pago recibido
await NotificationService().notifyPaymentReceived(
  loanId: prestamo.id,
  clientName: prestamo.nombreCliente ?? 'Cliente',
  amount: monto,
  remainingDebt: nuevaDeuda,
);

// Si se pagó todo, notifica y cancela pendientes
if (nuevaDeuda <= 0) {
  await NotificationService().cancelLoanNotifications(prestamo.id);
  await NotificationService().notifyLoanPaidOff(
    loanId: prestamo.id,
    clientName: prestamo.nombreCliente ?? 'Cliente',
    isAdmin: true,
  );
}
```

### 3. Inicialización en main.dart
✅ Se agregó inicialización automática al iniciar la app:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await SupabaseService().initialize();
  await NotificationService().initialize(); // ✅ AGREGADO
  
  runApp(const MyApp());
}
```

## 🔄 Pendiente: Integración al Crear Préstamos

### Dónde integrar
Cuando implementes la función `_guardarPrestamo()` en `create_loan_page.dart`, después de crear exitosamente el préstamo en Supabase, agrega:

```dart
void _guardarPrestamo() async {
  if (_formKey.currentState!.validate()) {
    try {
      // 1. Crear préstamo en Supabase
      final resultado = await MovimientoRepository().crearPrestamo(
        idCliente: clienteId,
        monto: monto,
        interes: interes,
        fechaInicio: DateTime.now(),
        fechaPago: _fechaVencimiento!,
      );
      
      final prestamoId = resultado['id'] as int;
      final nombreCliente = resultado['cliente_nombre'] as String;
      final montoTotal = monto + interes;
      
      // 2. Programar notificaciones
      // Recordatorio 1 semana antes
      await NotificationService().schedulePaymentReminder(
        loanId: prestamoId,
        clientName: nombreCliente,
        paymentDate: _fechaVencimiento!,
        debtAmount: montoTotal,
        isAdmin: true, // true para admin, false para cliente
      );
      
      // Notificación el día del vencimiento
      await NotificationService().schedulePaymentDue(
        loanId: prestamoId,
        clientName: nombreCliente,
        paymentDate: _fechaVencimiento!,
        debtAmount: montoTotal,
        isAdmin: true,
      );
      
      // Notificación de mora (3 días después)
      await NotificationService().scheduleOverdueNotification(
        loanId: prestamoId,
        clientName: nombreCliente,
        paymentDate: _fechaVencimiento!,
        debtAmount: montoTotal,
        isAdmin: true,
      );
      
      // 3. Mostrar confirmación
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Préstamo registrado y notificaciones programadas'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
```

## 📋 Configuración de Permisos

### Android (android/app/src/main/AndroidManifest.xml)
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Agregar estos permisos -->
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
    <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
    <uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
    
    <application>
        <!-- Agregar este receiver -->
        <receiver 
            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver"
            android:exported="false"/>
        <receiver 
            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver"
            android:exported="false">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
            </intent-filter>
        </receiver>
    </application>
</manifest>
```

### iOS (ios/Runner/Info.plist)
```xml
<dict>
    <!-- Agregar esta entrada -->
    <key>UIBackgroundModes</key>
    <array>
        <string>remote-notification</string>
    </array>
</dict>
```

## 🧪 Pruebas Recomendadas

### 1. Probar Notificaciones Instantáneas
```dart
// En cualquier parte de la app
await NotificationService().showInstantNotification(
  id: 999,
  title: 'Prueba',
  body: 'Esta es una notificación de prueba',
);
```

### 2. Probar Notificación Programada (1 minuto)
```dart
final fechaPrueba = DateTime.now().add(Duration(minutes: 1));
await NotificationService().schedulePaymentReminder(
  loanId: 1,
  clientName: 'Juan Pérez',
  paymentDate: fechaPrueba,
  debtAmount: 1000.0,
  isAdmin: true,
);
```

### 3. Verificar Cancelación
```dart
// Cancela todas las notificaciones de un préstamo
await NotificationService().cancelLoanNotifications(1);
```

## 📊 Tipos de Notificaciones Implementadas

| Tipo | ID Base | Cuándo se Envía | Color |
|------|---------|-----------------|-------|
| Recordatorio | `loanId` | 1 semana antes | Cyan (#00BCD4) |
| Vencimiento | `300000 + loanId` | Día del pago | Rojo (#F44336) |
| Mora | `400000 + loanId` | 3 días después | Rojo oscuro (#D32F2F) |
| Pago Recibido | `100000 + loanId` | Al registrar abono | Instantánea |
| Completado | `200000 + loanId` | Al pagar todo | Instantánea |

## 🎯 Casos de Uso Cubiertos

### ✅ Admin recibe notificación cuando:
1. ✅ Un cliente registra un abono (notifyPaymentReceived)
2. ✅ Un préstamo es completado (notifyLoanPaidOff)
3. ✅ Se acerca fecha de pago (schedulePaymentReminder)
4. ✅ Hoy vence un pago (schedulePaymentDue)
5. ✅ Un cliente está en mora (scheduleOverdueNotification)

### 🔄 Cliente recibe notificación cuando:
- Se programe al crear préstamo (cambiar `isAdmin: false`)
- Le recuerden su pago próximo
- Su pago venza hoy
- Esté en mora
- Complete su préstamo

## 🔧 Personalización

### Cambiar tiempo de recordatorio
En `schedulePaymentReminder()`, modifica:
```dart
final notificationDate = paymentDate.subtract(const Duration(days: 7));
// Cambiar a 3 días antes:
// final notificationDate = paymentDate.subtract(const Duration(days: 3));
```

### Cambiar tiempo de mora
En `scheduleOverdueNotification()`, modifica:
```dart
final notificationDate = paymentDate.add(const Duration(days: 3));
// Cambiar a 1 día después:
// final notificationDate = paymentDate.add(const Duration(days: 1));
```

### Agregar sonido personalizado
```dart
AndroidNotificationDetails(
  'channel_id',
  'Channel Name',
  sound: RawResourceAndroidNotificationSound('notification_sound'),
  // Coloca el archivo en android/app/src/main/res/raw/notification_sound.mp3
)
```

## 📝 Notas Importantes

1. ⚠️ **Permisos**: En Android 13+ se solicitan automáticamente en `initialize()`
2. ⚠️ **Timezone**: Configurado para 'America/Mexico_City', cambiar en `initialize()` si es necesario
3. ⚠️ **IDs únicos**: Cada tipo de notificación usa base diferente para evitar conflictos
4. ⚠️ **Background**: Las notificaciones programadas funcionan aunque la app esté cerrada
5. ⚠️ **Exactitud**: Se usa `AndroidScheduleMode.exactAllowWhileIdle` para máxima precisión

## 🚀 Próximos Pasos

1. ✅ Implementar `_guardarPrestamo()` en create_loan_page.dart con integración de notificaciones
2. ✅ Agregar toggle en perfil de admin para habilitar/deshabilitar notificaciones
3. ✅ Agregar vista de historial de notificaciones enviadas
4. ✅ Implementar notificaciones push remotas (Firebase Cloud Messaging)
5. ✅ Agregar configuración personalizada de tiempos de recordatorio

---
**Última actualización**: Completado por GitHub Copilot
**Estado**: ✅ Funcional - Listo para usar en registro de abonos y marcar como pagado
**Pendiente**: Integrar al crear préstamos nuevos
