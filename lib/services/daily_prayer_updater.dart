import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:workmanager/workmanager.dart';

/// Daily background updater for prayer times
/// Uses WorkManager to run a task every day at midnight
class DailyPrayerUpdater {
  static const String _taskName = 'daily_prayer_update';
  static const String _taskTag = 'prayer_notifications_daily';

  /// Initialize and register the daily background task
  static Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
    );

    // Register periodic task - runs approximately every 24 hours
    await Workmanager().registerPeriodicTask(
      _taskName,
      _taskTag,
      frequency: const Duration(hours: 24),
      initialDelay: _calculateDelayUntilMidnight(),
      constraints: Constraints(
        networkType: NetworkType.connected, // Requires internet
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
    );
    
    print('📅 Daily prayer updater registered');
  }

  /// Calculate delay until next midnight (00:05)
  static Duration _calculateDelayUntilMidnight() {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1, 0, 5);
    return midnight.difference(now);
  }
}

/// Top-level callback function - MUST be outside any class
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    print('🔄 Background task started: $taskName');
    
    try {
      // Initialize timezone
      tz_data.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Africa/Algiers'));
      
      // Get stored location
      final prefs = await SharedPreferences.getInstance();
      final lat = prefs.getDouble('last_latitude');
      final lng = prefs.getDouble('last_longitude');
      
      if (lat == null || lng == null) {
        print('❌ No stored location, skipping update');
        return true;
      }
      
      // Fetch prayer times from API
      final prayerTimes = await _fetchPrayerTimesFromApi(lat, lng);
      if (prayerTimes == null) {
        print('❌ Failed to fetch prayer times');
        return true;
      }
      
      // Schedule notifications
      await _scheduleNotifications(prayerTimes);
      
      print('✅ Prayer times updated successfully');
      return true;
    } catch (e) {
      print('❌ Background task error: $e');
      return true; // Return true to not retry immediately
    }
  });
}

/// Fetch prayer times from Aladhan API
Future<Map<String, DateTime>?> _fetchPrayerTimesFromApi(double lat, double lng) async {
  try {
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final uri = Uri.parse(
      'https://api.aladhan.com/v1/timings/$timestamp?latitude=$lat&longitude=$lng&method=1&school=0'
    );
    
    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    
    if (response.statusCode != 200) return null;
    
    final json = jsonDecode(response.body);
    final timings = json['data']['timings'] as Map<String, dynamic>;
    
    final now = DateTime.now();
    
    DateTime parseTime(String timeStr) {
      final clean = timeStr.split(' ').first;
      final parts = clean.split(':');
      return DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
    }
    
    return {
      'Fajr': parseTime(timings['Fajr']),
      'Dhuhr': parseTime(timings['Dhuhr']),
      'Asr': parseTime(timings['Asr']),
      'Maghrib': parseTime(timings['Maghrib']),
      'Isha': parseTime(timings['Isha']),
    };
  } catch (e) {
    print('API error: $e');
    return null;
  }
}

/// Schedule notifications for all prayers
Future<void> _scheduleNotifications(Map<String, DateTime> prayerTimes) async {
  final plugin = FlutterLocalNotificationsPlugin();
  final prefs = await SharedPreferences.getInstance();
  
  // Initialize plugin
  const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
  const settings = InitializationSettings(android: androidSettings);
  await plugin.initialize(settings);
  
  // Cancel old notifications
  await plugin.cancelAll();
  
  final now = DateTime.now();
  final prayers = [
    {'id': 101, 'name': 'الفجر', 'time': prayerTimes['Fajr']!},
    {'id': 102, 'name': 'الظهر', 'time': prayerTimes['Dhuhr']!},
    {'id': 103, 'name': 'العصر', 'time': prayerTimes['Asr']!},
    {'id': 104, 'name': 'المغرب', 'time': prayerTimes['Maghrib']!},
    {'id': 105, 'name': 'العشاء', 'time': prayerTimes['Isha']!},
  ];
  
  for (final prayer in prayers) {
    final name = prayer['name'] as String;
    
    // Check if adhan is enabled for this prayer
    final isEnabled = prefs.getBool('adhan_enabled_$name') ?? true;
    if (!isEnabled) {
      print('⏭️ Skipping $name - adhan disabled');
      continue;
    }
    
    // Get selected sound for this prayer
    final soundName = prefs.getString('adhan_sound_$name') ?? 'adhan1';
    
    var scheduledTime = prayer['time'] as DateTime;
    
    // If time passed, schedule for tomorrow
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }
    
    final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);
    final timeStr = DateFormat('HH:mm').format(scheduledTime);
    
    await plugin.zonedSchedule(
      prayer['id'] as int,
      'حان وقت صلاة $name',
      'الوقت: $timeStr',
      tzTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'prayer_notification_channel',
          'Prayer Notifications',
          channelDescription: 'Notifications for Islamic prayer times',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          sound: RawResourceAndroidNotificationSound(soundName),
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
    
    print('📿 Scheduled $name at $tzTime (sound: $soundName)');
  }
}
