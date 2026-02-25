import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:myadhan/model/PrayerTimeModel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

/// Prayer Alarm Scheduler - Uses native Android AlarmManager for persistent alarms
/// These alarms show the full-screen Adhan even when the app is killed
class PrayerAlarmScheduler {
  static const MethodChannel _channel = MethodChannel('com.myadhan/notification');
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Schedule all prayer alarms using provided PrayerTimeModel data
  /// This is the Riverpod-friendly version that receives prayer times as parameter
  static Future<void> scheduleAllPrayersWithData(PrayerTimeModel data) async {
    // ⚠️ CRITICAL: Initialize the plugin before using it
    const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _notificationsPlugin.initialize(settings);
    
    // Cancel any existing alarms first
    await cancelAll();

    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();

    final prayers = [
      {'id': 1, 'name': 'الفجر', 'time': data.fajer},
      {'id': 2, 'name': 'الظهر', 'time': data.dhuhr},
      {'id': 3, 'name': 'العصر', 'time': data.asr},
      {'id': 4, 'name': 'المغرب', 'time': data.maghrib},
      {'id': 5, 'name': 'العشاء', 'time': data.isha},
    ];

    for (var prayer in prayers) {
      int id = prayer['id'] as int;
      String name = prayer['name'] as String;
      DateTime prayerTime = prayer['time'] as DateTime;
      String timeStr = DateFormat('HH:mm').format(prayerTime);

      // Check if adhan is enabled for this prayer
      bool isEnabled = prefs.getBool('adhan_enabled_$name') ?? true;
      if (!isEnabled) {
        print('⏭️ Skipping $name - adhan disabled');
        continue;
      }

      // Get selected sound for this prayer
      String soundName = prefs.getString('adhan_sound_$name') ?? 'adhan1';

      // Build scheduled DateTime for today
      var scheduledTime = DateTime(
        now.year,
        now.month,
        now.day,
        prayerTime.hour,
        prayerTime.minute,
      );

      // If prayer time has passed today, schedule for tomorrow
      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }

      // Store prayer info (native side reads these with 'flutter.' prefix)
      await prefs.setString('prayer_${id}_name', name);
      await prefs.setString('prayer_${id}_time', timeStr);
      await prefs.setString('adhan_sound_$name', soundName);

      // Schedule NATIVE alarm via AlarmManager → PrayerAlarmReceiver → AdhanAlarmService
      // This handles audio playback on ALARM stream (not interrupted by notifications)
      try {
        await _channel.invokeMethod('scheduleNativePrayerAlarm', {
          'prayerId': id,
          'triggerAtMillis': scheduledTime.millisecondsSinceEpoch,
        });
        print('✅ Native alarm scheduled for $name at $scheduledTime (sound: $soundName)');
      } catch (e) {
        print('⚠️ Native alarm failed for $name: $e — falling back to notification sound');
        // Fallback: schedule Flutter notification WITH sound
        await _scheduleLocalNotification(id, name, timeStr, scheduledTime, soundName, withSound: true);
      }
    }
  }

  /// Schedule a single local notification
  static Future<void> _scheduleLocalNotification(
    int id,
    String name,
    String timeStr,
    DateTime scheduledTime,
    String soundName, {
    bool withSound = false, // true = fallback when native alarm fails
  }) async {
    final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

    await _notificationsPlugin.zonedSchedule(
      id + 100, // Different ID to avoid conflict
      'حان وقت صلاة $name',
      'الوقت: $timeStr',
      tzScheduledTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          withSound ? 'adhan_sound_channel' : 'prayer_visual_channel',
          withSound ? 'Adhan Sound' : 'Prayer Reminders',
          channelDescription: withSound
              ? 'Adhan sound fallback'
              : 'Visual prayer time reminders',
          importance: Importance.max,
          priority: Priority.high,
          playSound: withSound,
          sound: withSound ? RawResourceAndroidNotificationSound(soundName) : null,
          actions: [const AndroidNotificationAction(
              'stop_audio_id', 
              'إلغاء',    
              cancelNotification: true, 
          ),]
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Request exact alarm permission (required for Android 12+)
  static Future<bool> requestExactAlarmPermission() async {
    try {
      final result = await _channel.invokeMethod('requestExactAlarmPermission');
      return result == true;
    } catch (e) {
      print('Error requesting exact alarm permission: $e');
      return false;
    }
  }

  /// Check if exact alarm permission is granted
  static Future<bool> checkExactAlarmPermission() async {
    try {
      final result = await _channel.invokeMethod('checkExactAlarmPermission');
      return result == true;
    } catch (e) {
      return false;
    }
  }

  /// Schedule a test alarm for 10 seconds from now
  static Future<void> testNativeAlarm() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Store dummy prayer info for test
      await prefs.setString('prayer_999_name', 'اختبار التنبيه');
      await prefs.setString('prayer_999_time', DateFormat('HH:mm').format(DateTime.now().add(const Duration(seconds: 10))));
      
      await _channel.invokeMethod('testNativeAlarm');
      print('Test native alarm requested');
    } catch (e) {
      print('Error requesting test alarm: $e');
    }
  }

  /// Cancel all scheduled alarms (both Flutter notifications and native alarms)
  static Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
    try {
      await _channel.invokeMethod('cancelAllNativeAlarms');
    } catch (e) {
      print('Error cancelling native alarms: $e');
    }
  }
}
