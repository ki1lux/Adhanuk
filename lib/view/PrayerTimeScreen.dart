import 'dart:async';
import 'dart:ui';

// import 'package:adhan/adhan.dart';
import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:myadhan/controller/PrayerTimeController.dart';

class PrayerTimeScreen extends StatefulWidget {
  @override
  _PrayerTimeState createState() => _PrayerTimeState();
}

final PrayerTimeController controller = PrayerTimeController();
final PrayerTimes = controller.getPrayerTimes();
Duration remaining =  ;
Timer? timer;

class _PrayerTimeState extends State<PrayerTimeScreen> {
  final List<Map<String, String>> prayerTimes = [
    {
      "name": "الفجر",
      "time": "${DateFormat('HH:mm').format(PrayerTimes.fajer)}",
    },
    {
      "name": "الظهر",
      "time": "${DateFormat('HH:mm').format(PrayerTimes.dhuhr)}",
    },
    {"name": "العصر", "time": "${DateFormat('HH:mm').format(PrayerTimes.asr)}"},
    {
      "name": "المغرب",
      "time": "${DateFormat('HH:mm').format(PrayerTimes.maghrib)}",
    },
    {
      "name": "العشاء",
      "time": "${DateFormat('HH:mm').format(PrayerTimes.isha)}",
    },
  ];

  

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    timerForTheNextPrayer();
  }

  void timerForTheNextPrayer() {
    const onSecond = const Duration(seconds: 1);

    timer = Timer.periodic(onSecond, (_) {
      // final second = 1;
      setState(() {
        remaining = remaining - Duration(seconds: 1);
        // if (remaining.isNegative) {
        //   getNextPrayer(prayerTimes);
        // }
        // final seconds = remaining.inSeconds - second;
        // remaining = Duration(seconds: seconds);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    int nextIndex = getNextPrayer(prayerTimes);

    // TODO: implement build
    return Scaffold(
      body: Stack(
        children: [
          Container(color: Color(0xff0A2239)),
          SvgPicture.asset(
            'assets/Vector.svg',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          Column(
            children: [
              Padding(
                padding: EdgeInsets.only(right: 16, top: 89),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,

                      children: [
                        Text(
                          "الموقع",
                          style: TextStyle(
                            color: Color(0xffF0F8FF),
                            fontFamily: 'Cairo',
                            fontSize: 38,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        Text(
                          "الجزائر",
                          style: TextStyle(
                            color: Color(0xffF0F8FF),
                            fontFamily: 'Cairo',
                            fontSize: 24,
                            fontWeight: FontWeight.w100,
                          ),
                        ),
                      ],
                    ),
                    Icon(Icons.location_on, color: Color(0xffF0F8FF), size: 42),
                  ],
                ),
              ),
              SizedBox(height: 64),
              Column(
                children:
                    prayerTimes.asMap().entries.map((entry) {
                      int i = entry.key;
                      var prayer = entry.value;
                      return prayerCard(
                        prayer["name"]!,
                        prayer["time"]!,
                        i == nextIndex,
                      );
                    }).toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget prayerCard(String name, String time, bool isNext) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18, right: 12, left: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(36),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
          child: Container(
            height: 76,
            // padding: EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(36),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(Icons.volume_up, color: Color(0xffF0F8FF)),

                  //there where i want to add countDownTimer just at the next prayer
                  isNext
                      ? Text(
                        // textAlign: TextAlign.left,
                        "${formatDurationIntl(remaining)}",
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          color: Color(0xffF0F8FF),
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      )
                      : Text(""),
                  SizedBox(width: 32),

                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "$name",
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            color: Color(0xffF0F8FF),
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "$time",
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            color: Color(0xffF0F8FF),
                            fontWeight: FontWeight.w100,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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
    return -1;
  }

  Duration nextPrayerTimeDuration(int nextPrayer, TimeOfDay timeNow) {
    final time = prayerTimes[nextPrayer]['time'];
    final parts = time!.split(":");
    final hours = int.parse(parts[0]);
    final minutes = int.parse(parts[1]);
    final seconds = int.parse(parts[3]);
    Duration n = Duration(hours: hours, minutes: minutes, seconds: seconds);

    // int timeInSecond = timeNow.hour * 60 * 60 + timeNow.minute * 60;
    // int durationsecond = n.inSeconds;
    // int def = durationsecond - timeInSecond;

    return Duration(hours: hours, minutes: minutes, seconds: seconds);
  }

  Duration timeNowOnDurtion(Duration i) {
    final now = TimeOfDay.now();
    final String time = '${now.hour}:${now.minute}';
    final parts = time.split(":");
    final hours = int.parse(parts[0]);
    final minutes = int.parse(parts[1]);
    return Duration(hours: hours, minutes: minutes);
  }

}
