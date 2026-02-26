import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

/// Daily background updater for prayer times.
/// Uses WorkManager to run a task every day at midnight.
/// Fetches new prayer times from Aladhan API, saves trigger timestamps
/// to SharedPreferences, and triggers native alarm rescheduling.
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
        networkType: NetworkType.connected,
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
      
      // Save prayer times + trigger timestamps + Hijri date to SharedPreferences
      // The native BootReceiver/AlarmSchedulerHelper reads these to schedule alarms
      await _savePrayerTimesToPrefs(prayerTimes['prayers'] as Map<String, DateTime>, prefs);
      
      // Update cached Hijri date for the UI
      final hijriDate = prayerTimes['hijri'] as String?;
      if (hijriDate != null && hijriDate.isNotEmpty) {
        await prefs.setString('cached_hijri_date', hijriDate);
        print('📅 Hijri date updated: $hijriDate');
      }
      
      print('✅ Prayer times updated and saved for native rescheduling');
      return true;
    } catch (e) {
      print('❌ Background task error: $e');
      return true; // Return true to not retry immediately
    }
  });
}

/// Fetch prayer times from Aladhan API
Future<Map<String, dynamic>?> _fetchPrayerTimesFromApi(double lat, double lng) async {
  try {
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final uri = Uri.parse(
      'https://api.aladhan.com/v1/timings/$timestamp?latitude=$lat&longitude=$lng&method=1&school=0'
    );
    
    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    
    if (response.statusCode != 200) return null;
    
    final json = jsonDecode(response.body);
    final timings = json['data']['timings'] as Map<String, dynamic>;
    
    // Extract Hijri date
    final hijriData = json['data']['date']['hijri'];
    final hijriStr = '${hijriData['day']} ${hijriData['month']['ar']} ${hijriData['year']}';
    
    final now = DateTime.now();
    
    DateTime parseTime(String timeStr) {
      final clean = timeStr.split(' ').first;
      final parts = clean.split(':');
      return DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
    }
    
    return {
      'hijri': hijriStr,
      'prayers': {
        'Fajr': parseTime(timings['Fajr']),
        'Dhuhr': parseTime(timings['Dhuhr']),
        'Asr': parseTime(timings['Asr']),
        'Maghrib': parseTime(timings['Maghrib']),
        'Isha': parseTime(timings['Isha']),
      },
    };
  } catch (e) {
    print('API error: $e');
    return null;
  }
}

/// Save prayer times and trigger timestamps to SharedPreferences.
/// The native AlarmSchedulerHelper.rescheduleAllFromPrefs() reads these keys
/// to schedule AlarmManager.setAlarmClock() alarms directly from native code.
///
/// Keys saved (native reads with 'flutter.' prefix):
/// - prayer_{id}_name → Arabic prayer name
/// - prayer_{id}_time → display time "HH:mm"
/// - prayer_{id}_trigger_millis → epoch millis for next alarm trigger
Future<void> _savePrayerTimesToPrefs(
  Map<String, DateTime> prayerTimes,
  SharedPreferences prefs,
) async {
  final now = DateTime.now();
  
  final prayers = [
    {'id': 1, 'name': 'الفجر', 'apiKey': 'Fajr'},
    {'id': 2, 'name': 'الظهر', 'apiKey': 'Dhuhr'},
    {'id': 3, 'name': 'العصر', 'apiKey': 'Asr'},
    {'id': 4, 'name': 'المغرب', 'apiKey': 'Maghrib'},
    {'id': 5, 'name': 'العشاء', 'apiKey': 'Isha'},
  ];

  for (final prayer in prayers) {
    final id = prayer['id'] as int;
    final name = prayer['name'] as String;
    final apiKey = prayer['apiKey'] as String;
    
    // Check if adhan is enabled for this prayer
    final isEnabled = prefs.getBool('adhan_enabled_$name') ?? true;
    if (!isEnabled) {
      print('⏭️ Skipping $name - adhan disabled');
      continue;
    }

    var scheduledTime = prayerTimes[apiKey]!;
    final timeStr = DateFormat('HH:mm').format(scheduledTime);

    // If prayer time has passed today, schedule for tomorrow
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    // Save prayer info + trigger timestamp
    await prefs.setString('prayer_${id}_name', name);
    await prefs.setString('prayer_${id}_time', timeStr);
    await prefs.setInt('prayer_${id}_trigger_millis', scheduledTime.millisecondsSinceEpoch);

    print('💾 Saved $name: $timeStr → trigger at ${scheduledTime.millisecondsSinceEpoch}');
  }

  // Mark last update time
  await prefs.setString('last_prayer_update', now.toIso8601String());
  
  // Signal native side to reschedule by setting a flag
  // The native BootReceiver/AlarmSchedulerHelper checks this
  await prefs.setBool('needs_alarm_reschedule', true);
  
  print('✅ All prayer times saved to SharedPreferences for native scheduling');
}
