import 'dart:async';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:intl/intl.dart';
import 'package:myadhan/controller/PrayerTimeController.dart';

Future<bool> onStart(ServiceInstance service) async {
  final controller = PrayerTimeController();

  Timer.periodic(const Duration(seconds: 1), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        final prayerTimesData = await controller.getPrayerTimes();
        final now = DateTime.now();

        final prayerTimes = [
          {
            "name": "الفجر",
            "time": DateFormat('HH:mm').format(prayerTimesData.fajer),
          },
          {
            "name": "الظهر",
            "time": DateFormat('HH:mm').format(prayerTimesData.dhuhr),
          },
          {
            "name": "العصر",
            "time": DateFormat('HH:mm').format(prayerTimesData.asr),
          },
          {
            "name": "المغرب",
            "time": DateFormat('HH:mm').format(prayerTimesData.maghrib),
          },
          {
            "name": "العشاء",
            "time": DateFormat('HH:mm').format(prayerTimesData.isha),
          },
        ];

        int nextIndex = _getNextPrayerIndex(prayerTimes, now);
        String nextPrayerName = prayerTimes[nextIndex]['name']!;
        String prayerTime = prayerTimes[nextIndex]['time']!;
        DateTime nextPrayerTime = _getNextPrayerDateTime(
          prayerTimes,
          nextIndex,
          now,
        );

        if (now.isAfter(nextPrayerTime)) {
          controller.callNativeAdhanNow(nextPrayerName, prayerTime);
        }
      }
    }
  });
  return true;
}

int _getNextPrayerIndex(List<Map<String, String>> prayerTimes, DateTime now) {
  for (int i = 0; i < prayerTimes.length; i++) {
    final time = prayerTimes[i]['time']!;
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final prayerTime = DateTime(now.year, now.month, now.day, hour, minute);
    if (prayerTime.isAfter(now)) return i;
  }
  return 0;
}

DateTime _getNextPrayerDateTime(
  List<Map<String, String>> prayerTimes,
  int index,
  DateTime now,
) {
  final parts = prayerTimes[index]['time']!.split(':');
  int hour = int.parse(parts[0]);
  int minute = int.parse(parts[1]);
  DateTime candidate = DateTime(now.year, now.month, now.day, hour, minute);
  if (candidate.isBefore(now)) {
    candidate = candidate.add(Duration(days: 1));
  }
  return candidate;
}
