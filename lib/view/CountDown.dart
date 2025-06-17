import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myadhan/controller/PrayerTimeController.dart';

class CountdownTimer extends StatefulWidget {
  @override
  _CountdownTimerState createState() => _CountdownTimerState();
}

final PrayerTimeController controller = PrayerTimeController();
final PrayerTimes = controller.getPrayerTimes();
Duration remaining = nextPrayerTimeDuration(getNextPrayer(prayerTimes));
Timer? timer;
final List<Map<String, String>> prayerTimes = [
  {"name": "الفجر", "time": "${DateFormat('HH:mm').format(PrayerTimes.fajer)}"},
  {"name": "الظهر", "time": "${DateFormat('HH:mm').format(PrayerTimes.dhuhr)}"},
  {"name": "العصر", "time": "${DateFormat('HH:mm').format(PrayerTimes.asr)}"},
  {
    "name": "المغرب",
    "time": "${DateFormat('HH:mm').format(PrayerTimes.maghrib)}",
  },
  {"name": "العشاء", "time": "${DateFormat('HH:mm').format(PrayerTimes.isha)}"},
];

int getNextPrayer(List<Map<String, String>> prayerTimes) {
  final timeNow = TimeOfDay.now();
  for (var i = 0; i < prayerTimes.length; i++) {
    final time = prayerTimes[i]['time']!;
    final hour = int.parse(time.split(":")[0]);
    final minute = int.parse(time.split(":")[1]);
    final prayerTime = TimeOfDay(hour: hour, minute: minute);

    if (prayerTime.hour > timeNow.hour ||
        (prayerTime.hour == timeNow.hour &&
            prayerTime.minute > timeNow.minute)) {
      return i;
    }
  }
  return 0;
}

Duration nextPrayerTimeDuration(int nextPrayer) {
  final time = prayerTimes[nextPrayer]['time'];
  final parts = time!.split(":");
  final hours = int.parse(parts[0]);
  final minutes = int.parse(parts[1]);
  // final seconds = int.parse(parts[3]);

  final now = TimeOfDay.now();
  final String timeNow = '${now.hour}:${now.minute}';
  final partsNow = timeNow.split(":");
  final hoursNow = int.parse(partsNow[0]);
  final minutesNow = int.parse(partsNow[1]);

  // final hourfinal = hours - hoursNow;
  // final minutefinal = minutes - minutesNow;

  final prayertime = Duration(hours: hours, minutes: minutes);
  final Duration n = Duration(hours: hoursNow, minutes: minutesNow);
  Duration lastDuration = prayertime - n;
  // Duration lastDuration = Duration(hours: hours, minutes: minutes);

  return lastDuration;
}

class _CountdownTimerState extends State<CountdownTimer> {
  late Timer timer;

  @override
  void initState() {
    super.initState();
    timerForTheNextPrayer();
  }

  void timerForTheNextPrayer() {
    const onSecond = const Duration(seconds: 1);

    timer = Timer.periodic(onSecond, (_) {
      setState(() {
        remaining = remaining - Duration(seconds: 1);
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
      "${formatDurationIntl(remaining)}",
      style: TextStyle(
        color: Color(0xffF0F8FF),
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    );
  }
}

String formatDurationIntl(Duration duration) {
  final format = DateFormat('HH:mm:ss');
  return format.format(
    DateTime(
      0,
      0,
      0,
      duration.inHours,
      duration.inMinutes.remainder(60),
      duration.inSeconds.remainder(60),
    ),
  );
}
