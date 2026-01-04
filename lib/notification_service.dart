// import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/timezone.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// دالة لتجديد إشعارات الصلاة
Future<void> schedulePrayerNotifications() async {
  // هنا تحسب مواقيت الصلاة من API أو من مكتبة عندك
  // حاليا سنضع أوقات تجريبية (يجب تعويضها بوقتك الحقيقي)

  int id = 2;
  final now = DateTime.now();
  final prayerTimesList = [
    {"name": "الفجر", "time": "05:00"},
    {"name": "الظهر", "time": "12:30"},
    {"name": "العصر", "time": "15:27"},
    {"name": "المغرب", "time": "18:20"},
    {"name": "العشاء", "time": "20:00"},
  ];

  for (var prayer in prayerTimesList) {
    String name = prayer['name']!;
    String time = prayer['time']!;

    final parts = time.split(':');
    final scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );

    // final notificationTime =
    //     scheduledTime.isBefore(now)
    //         ? scheduledTime.add(Duration(days: 1))
    //         : scheduledTime;

    _showScheduledNotification(
      id: id,
      title: name,
      body: name,
      time: scheduledTime,
    );
  }
}

Future<void> _showScheduledNotification({
  required int id,
  required String title,
  required String body,
  DateTime? time,
}) async {
  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  // TZDateTime now = TZDateTime.now(local);
  TZDateTime salat = tz.TZDateTime.from(time!, tz.local);
  TZDateTime scheduledDate = salat;
  await notificationsPlugin.zonedSchedule(
    id,
    title,
    body,
    scheduledDate,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_reminder_channel_id',
        'Daily Reminders',
        channelDescription: 'Reminder to complete daily habits',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    ),
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
  );
}

// دالة لجدولة الإشعار
// Future<void> _showScheduledNotification(
//   String title,
//   String body,
//   DateTime scheduledTime,
// ) async {
//   var androidDetails = const AndroidNotificationDetails(
//     'prayer_channel',
//     'Prayer Notifications',
//     channelDescription: 'إشعارات مواقيت الصلاة',
//     importance: Importance.max,
//     priority: Priority.high,
//   );

//   var details = NotificationDetails(android: androidDetails);

//   await flutterLocalNotificationsPlugin.zonedSchedule(
//     0,
//     title,
//     body,
//     tz.TZDateTime.from(scheduledTime, tz.local),
//     const NotificationDetails(
//       android: AndroidNotificationDetails(
//         'your_channel_id',
//         'your_channel_name',
//         channelDescription: 'your_channel_description',
//         importance: Importance.max,
//         priority: Priority.high,
//       ),
//       iOS: DarwinNotificationDetails(),
//     ),
//     androidScheduleMode:
//         AndroidScheduleMode.exactAllowWhileIdle, // بديل androidAllowWhileIdle
//     matchDateTimeComponents: DateTimeComponents.time,
//   );
// }
