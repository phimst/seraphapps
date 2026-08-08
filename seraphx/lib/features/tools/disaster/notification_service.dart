import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class DisasterNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidInit);
    await _plugin.initialize(settings);

    // Minta izin notifikasi (wajib di Android 13+)
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  static Future<void> showAlert({
    required String title,
    required String body,
  }) async {
    await init();
    const androidDetails = AndroidNotificationDetails(
      'disaster_alert_channel',
      'Peringatan Bencana',
      channelDescription: 'Notifikasi peringatan gempa & aktivitas gunung api',
      importance: Importance.max,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }
}
