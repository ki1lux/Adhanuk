import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:myadhan/controller/LocationController.dart';
import 'package:myadhan/controller/PrayerTimeController.dart';
import 'package:myadhan/view/CountDown.dart';

class PrayerTimeScreen extends StatefulWidget {
  @override
  _PrayerTimeState createState() => _PrayerTimeState();
}

class _PrayerTimeState extends State<PrayerTimeScreen> {
  final LocationController _controller = LocationController();
  String countryLocationText = "fetching location...";
  String cityLocationText = "fetching location...";

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // fetchLocation();
    initEverything();
  }

  // Future<void> fetchLocation() async {
  //   try {
  //     final location = await _controller.getLocationDetails();
  //     setState(() {
  //       countryLocationText = location["country"]!;
  //       cityLocationText = location["city"]!;
  //     });
  //   } catch (e) {
  //     setState(() {
  //       countryLocationText = "خطأ: $e";
  //       cityLocationText = "خطأ: $e";
  //     });
  //   }
  // }

  Future<void> initEverything() async {
    try {
      final position = await _controller.determinePosition();
      final placemark = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      setState(() {
        countryLocationText = placemark[0].country ?? "";
        cityLocationText = placemark[0].locality ?? "";
      });
    } catch (e) {
      setState(() {
        countryLocationText = "خطأ في تحديد الموقع";
        cityLocationText = "$e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // int nextIndex = getNextPrayer(prayerTimes);
    // final PrayerTimeController controller = PrayerTimeController();
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
              // الموقع
              Padding(
                padding: EdgeInsets.only(right: 16, top: 89),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        PrayerTimeController().callNativeAdhanNow("الفجر");
                      },
                      child: Text(
                        "Test\n Notification",
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          countryLocationText,
                          style: TextStyle(
                            color: Color(0xffF0F8FF),
                            fontFamily: 'Cairo',
                            fontSize: 38,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          cityLocationText,
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

              FutureBuilder(
                future: controller.getPrayerTimes(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text("خطأ: ${snapshot.error}"));
                  } else if (!snapshot.hasData) {
                    return Center(child: Text("لم يتم العثور على البيانات"));
                  }

                  final prayerTimesData = snapshot.data!;
                  final List<Map<String, String>> prayerTimes = [
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
                      "time": DateFormat(
                        'HH:mm',
                      ).format(prayerTimesData.maghrib),
                    },
                    {
                      "name": "العشاء",
                      "time": DateFormat('HH:mm').format(prayerTimesData.isha),
                    },
                  ];

                  int nextIndex = getNextPrayer(prayerTimes);

                  return Column(
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
                  );
                },
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

                  isNext
                      ? CountdownTimer(
                        onFinish: () {
                          setState(() {
                            // Your method to update name/time/isNext etc.
                          });
                        },
                      )
                      : Text(""),
                  SizedBox(width: 64),

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

  // String formatDurationIntl(Duration duration) {
  //   final format = DateFormat('HH:mm:ss');
  //   return format.format(
  //     DateTime(
  //       0,
  //       0,
  //       0,
  //       duration.inHours,
  //       duration.inMinutes.remainder(60),
  //       duration.inSeconds.remainder(60),
  //     ),
  //   );
  // }

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

  // Duration nextPrayerTimeDuration(int nextPrayer) {
  //   final time = prayerTimes[nextPrayer]['time'];
  //   final parts = time!.split(":");
  //   final hours = int.parse(parts[0]);
  //   final minutes = int.parse(parts[1]);
  //   final seconds = int.parse(parts[3]);

  //   final now = TimeOfDay.now();
  //   final String timeNow = '${now.hour}:${now.minute}';
  //   final partsNow = timeNow.split(":");
  //   final hoursNow = int.parse(partsNow[0]);
  //   final minutesNow = int.parse(partsNow[1]);

  //   final prayertime = Duration(
  //     hours: hours,
  //     minutes: minutes,
  //     seconds: seconds,
  //   );
  //   final Duration n = Duration(hours: hoursNow, minutes: minutesNow);
  //   final lastDuration = prayertime - n;
  //   // int timeInSecond = timeNow.hour * 60 * 60 + timeNow.minute * 60;
  //   // int durationsecond = n.inSeconds;
  //   // int def = durationsecond - timeInSecond;

  //   return lastDuration;
  // }

  // Duration timeNowOnDurti() {
  //   final now = TimeOfDay.now();
  //   final String time = '${now.hour}:${now.minute}';
  //   final parts = time.split(":");
  //   final hours = int.parse(parts[0]);
  //   final minutes = int.parse(parts[1]);
  //   return Duration(hours: hours, minutes: minutes);
  // }
}
