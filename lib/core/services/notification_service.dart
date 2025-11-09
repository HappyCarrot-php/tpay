import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';
import 'dart:io';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Inicializa el servicio de notificaciones
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Inicializar timezone
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Mexico_City'));

    // Configuración de Android
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configuración de iOS
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Solicitar permisos en Android 13+
    if (Platform.isAndroid) {
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }

    _isInitialized = true;
  }

  /// Maneja el tap en notificación
  void _onNotificationTapped(NotificationResponse response) {
    // Aquí puedes manejar la navegación cuando el usuario toca la notificación
    debugPrint('Notificación tocada: ${response.payload}');
  }

  /// Programa notificación de recordatorio de pago (1 semana antes)
  Future<void> schedulePaymentReminder({
    required int loanId,
    required String clientName,
    required DateTime paymentDate,
    required double debtAmount,
    required bool isAdmin,
  }) async {
    if (!_isInitialized) await initialize();

    // Calcular fecha de notificación (1 semana antes)
    final notificationDate = paymentDate.subtract(const Duration(days: 7));
    
    // No programar si la fecha ya pasó
    if (notificationDate.isBefore(DateTime.now())) {
      return;
    }

    final tz.TZDateTime scheduledDate = tz.TZDateTime.from(
      notificationDate,
      tz.local,
    );

    // Mensaje diferente para admin y cliente
    final String title;
    final String body;

    if (isAdmin) {
      title = 'Recordatorio de Pago - Cliente';
      body = '$clientName tiene una deuda de \$${debtAmount.toStringAsFixed(2)} '
          'con fecha de pago el ${_formatDate(paymentDate)}';
    } else {
      title = 'Recordatorio de Pago';
      body = 'Recuerde que debe pagar \$${debtAmount.toStringAsFixed(2)} '
          'antes del ${_formatDate(paymentDate)}';
    }

    await _notificationsPlugin.zonedSchedule(
      loanId, // ID único por préstamo
      title,
      body,
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'payment_reminders',
          'Recordatorios de Pago',
          channelDescription: 'Notificaciones de recordatorio de pago de préstamos',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF00BCD4),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'loan_$loanId',
    );
  }

  /// Cancela notificación específica
  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  /// Cancela todas las notificaciones
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  /// Muestra notificación inmediata
  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) await initialize();

    await _notificationsPlugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'instant_notifications',
          'Notificaciones Instantáneas',
          channelDescription: 'Notificaciones inmediatas de la app',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  /// Notifica sobre pago recibido (para admin)
  Future<void> notifyPaymentReceived({
    required int loanId,
    required String clientName,
    required double amount,
    required double remainingDebt,
  }) async {
    await showInstantNotification(
      id: 100000 + loanId, // ID diferente para evitar conflictos
      title: 'Pago Recibido',
      body: '$clientName realizó un pago de \$${amount.toStringAsFixed(2)}. '
          'Deuda restante: \$${remainingDebt.toStringAsFixed(2)}',
      payload: 'payment_$loanId',
    );
  }

  /// Notifica sobre préstamo completamente pagado
  Future<void> notifyLoanPaidOff({
    required int loanId,
    required String clientName,
    required bool isAdmin,
  }) async {
    final String title;
    final String body;

    if (isAdmin) {
      title = 'Préstamo Completado';
      body = '$clientName ha completado el pago de su préstamo #$loanId';
    } else {
      title = '¡Felicidades!';
      body = 'Has completado el pago de tu préstamo #$loanId';
    }

    await showInstantNotification(
      id: 200000 + loanId,
      title: title,
      body: body,
      payload: 'loan_complete_$loanId',
    );
  }

  /// Programa notificación de vencimiento (día del pago)
  Future<void> schedulePaymentDue({
    required int loanId,
    required String clientName,
    required DateTime paymentDate,
    required double debtAmount,
    required bool isAdmin,
  }) async {
    if (!_isInitialized) await initialize();

    // No programar si la fecha ya pasó
    if (paymentDate.isBefore(DateTime.now())) {
      return;
    }

    final tz.TZDateTime scheduledDate = tz.TZDateTime.from(
      paymentDate,
      tz.local,
    );

    final String title;
    final String body;

    if (isAdmin) {
      title = 'Pago Vencido Hoy - Cliente';
      body = '$clientName debe pagar \$${debtAmount.toStringAsFixed(2)} hoy';
    } else {
      title = '¡Pago Vencido Hoy!';
      body = 'Su pago de \$${debtAmount.toStringAsFixed(2)} vence hoy';
    }

    await _notificationsPlugin.zonedSchedule(
      300000 + loanId, // ID diferente para notificación de vencimiento
      title,
      body,
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'payment_due',
          'Pagos Vencidos',
          channelDescription: 'Notificaciones de pagos que vencen hoy',
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFFF44336),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'due_$loanId',
    );
  }

  /// Programa notificación de mora (3 días después del vencimiento)
  Future<void> scheduleOverdueNotification({
    required int loanId,
    required String clientName,
    required DateTime paymentDate,
    required double debtAmount,
    required bool isAdmin,
  }) async {
    if (!_isInitialized) await initialize();

    // Calcular fecha de notificación (3 días después del vencimiento)
    final notificationDate = paymentDate.add(const Duration(days: 3));
    
    // No programar si la fecha ya pasó
    if (notificationDate.isBefore(DateTime.now())) {
      return;
    }

    final tz.TZDateTime scheduledDate = tz.TZDateTime.from(
      notificationDate,
      tz.local,
    );

    final String title;
    final String body;

    if (isAdmin) {
      title = 'Cliente en Mora';
      body = '$clientName tiene un pago atrasado de \$${debtAmount.toStringAsFixed(2)} '
          'desde el ${_formatDate(paymentDate)}';
    } else {
      title = 'Pago Atrasado';
      body = 'Su pago de \$${debtAmount.toStringAsFixed(2)} está atrasado desde el '
          '${_formatDate(paymentDate)}. Por favor contacte con nosotros.';
    }

    await _notificationsPlugin.zonedSchedule(
      400000 + loanId, // ID diferente para notificación de mora
      title,
      body,
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'payment_overdue',
          'Pagos en Mora',
          channelDescription: 'Notificaciones de pagos atrasados',
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFFD32F2F),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'overdue_$loanId',
    );
  }

  /// Cancela todas las notificaciones de un préstamo específico
  Future<void> cancelLoanNotifications(int loanId) async {
    await _notificationsPlugin.cancel(loanId); // Recordatorio
    await _notificationsPlugin.cancel(100000 + loanId); // Pago recibido
    await _notificationsPlugin.cancel(200000 + loanId); // Completado
    await _notificationsPlugin.cancel(300000 + loanId); // Vencimiento
    await _notificationsPlugin.cancel(400000 + loanId); // Mora
  }

  String _formatDate(DateTime date) {
    final months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return '${date.day} de ${months[date.month - 1]} de ${date.year}';
  }
}
