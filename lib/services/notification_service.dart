import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

class NotificationService {
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(settings);
  }

  Future<void> showTimerComplete({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'timer_channel',
      '计时器通知',
      channelDescription: '计时器完成通知',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(0, title, body, details);
  }

  Future<void> showBreakComplete() async {
    await showTimerComplete(
      title: '休息结束',
      body: '准备好继续学习了吗？',
    );
  }

  Future<void> showPomodoroComplete() async {
    await showTimerComplete(
      title: '番茄钟完成',
      body: '休息一下吧！',
    );
  }

  Future<void> showCountdownComplete() async {
    await showTimerComplete(
      title: '倒计时结束',
      body: '学习时段已完成！',
    );
  }

  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}
