import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _fln = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _upcomingDose = AndroidNotificationChannel(
    'upcoming_dose', 'Upcoming Dose',
    description: 'Reminders for upcoming doses', importance: Importance.high,
  );
  static const AndroidNotificationChannel _lowStock = AndroidNotificationChannel(
    'low_stock', 'Low Stock',
    description: 'Alerts for low medication stock', importance: Importance.defaultImportance,
  );
  static const AndroidNotificationChannel _expiry = AndroidNotificationChannel(
    'expiry', 'Expiry',
    description: 'Alerts for medication expiry', importance: Importance.defaultImportance,
  );

  static Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _fln.initialize(initSettings);

    final android = _fln.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.createNotificationChannel(_upcomingDose);
      await android.createNotificationChannel(_lowStock);
      await android.createNotificationChannel(_expiry);
    }

    // Request notifications permission on Android 13+
    await Permission.notification.request();
  }

  static Future<void> showTest() async {
    const details = NotificationDetails(android: AndroidNotificationDetails('upcoming_dose', 'Upcoming Dose'));
    await _fln.show(1, 'Dosifi v5', 'Notifications initialized', details);
  }
}

