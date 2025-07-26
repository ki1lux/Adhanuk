import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myadhan/controller/PrayerTimeController.dart';

class CountdownTimer extends StatefulWidget {
  final VoidCallback onFinish;

  const CountdownTimer({required this.onFinish, Key? key}) : super(key: key);

  @override
  _CountdownTimerState createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  late Timer timer;
  Duration remaining = Duration.zero;
  Duration countUp = Duration.zero;
  bool isAdhanPhase = true;
  String? lastPlayedPrayer;
  final Duration iqamaDelay = Duration(minutes: 1);
  final PrayerTimeController controller = PrayerTimeController();

  @override
  void initState() {
    super.initState();
    loadPrayerTimesAndStartCountdown();
  }

  Future<void> loadPrayerTimesAndStartCountdown() async {
    final prayerTimesData = await controller.getPrayerTimes();
    final now = DateTime.now();

    final prayerTimes = <Map<String, String>>[
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

    int nextIndex = getNextPrayerIndex(prayerTimes, now);
    String nextPrayerName = prayerTimes[nextIndex]['name']!;
    DateTime nextPrayerTime = getNextPrayerDateTime(
      prayerTimes,
      nextIndex,
      now,
    );

    isAdhanPhase = true;
    countUp = Duration.zero;
    remaining = nextPrayerTime.difference(now);

    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        if (isAdhanPhase) {
          remaining -= const Duration(seconds: 1);
          if (remaining.inSeconds <= 0 && lastPlayedPrayer != nextPrayerName) {
            isAdhanPhase = false;
            lastPlayedPrayer = nextPrayerName;
            controller.callNativeAdhanNow(nextPrayerName);
            countUp = Duration.zero;
          }
        } else {
          countUp += const Duration(seconds: 1);
          if (countUp >= iqamaDelay) {
            timer.cancel();
            widget.onFinish();
            loadPrayerTimesAndStartCountdown();
          }
        }
      });
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      isAdhanPhase ? formatDuration(remaining) : formatDuration(countUp),
      style: TextStyle(
        color: isAdhanPhase ? const Color(0xffF0F8FF) : Colors.red,
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    );
  }

  // Gets the index of the next upcoming prayer
  int getNextPrayerIndex(List<Map<String, String>> prayerTimes, DateTime now) {
    for (int i = 0; i < prayerTimes.length; i++) {
      final time = prayerTimes[i]['time']!;
      final parts = time.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final prayerTime = DateTime(now.year, now.month, now.day, hour, minute);

      if (prayerTime.isAfter(now)) {
        return i;
      }
    }
    return 0; // Next is Fajr of tomorrow
  }

  // Gets the DateTime of the next prayer, even if it's tomorrow
  DateTime getNextPrayerDateTime(
    List<Map<String, String>> prayerTimes,
    int index,
    DateTime now,
  ) {
    final parts = prayerTimes[index]['time']!.split(':');
    int hour = int.parse(parts[0]);
    int minute = int.parse(parts[1]);

    DateTime candidate = DateTime(now.year, now.month, now.day, hour, minute);
    if (candidate.isBefore(now)) {
      // If time already passed, prayer is tomorrow
      candidate = candidate.add(Duration(days: 1));
    }
    return candidate;
  }

  // Format duration into HH:mm:ss
  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(duration.inHours)}:"
        "${twoDigits(duration.inMinutes.remainder(60))}:"
        "${twoDigits(duration.inSeconds.remainder(60))}";
  }
}
