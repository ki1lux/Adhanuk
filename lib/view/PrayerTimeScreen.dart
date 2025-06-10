import 'dart:ui';

// import 'package:adhan/adhan.dart';
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

class _PrayerTimeState extends State<PrayerTimeScreen> {
  final List<Map<String, String>> prayerTimes = [
    {
      "name": "الفجر",
      "time": "${DateFormat('h:mm').format(PrayerTimes.fajer)}",
    },
    {
      "name": "الظهر",
      "time": "${DateFormat('h:mm').format(PrayerTimes.dhuhr)}",
    },
    {"name": "العصر", "time": "${DateFormat('h:mm').format(PrayerTimes.asr)}"},
    {
      "name": "المغرب",
      "time": "${DateFormat('h:mm').format(PrayerTimes.maghrib)}",
    },
    {
      "name": "العشاء",
      "time": "${DateFormat('h:mm').format(PrayerTimes.isha)}",
    },
  ];

  @override
  Widget build(BuildContext context) {
    // final prayerTime = controller.getPrayerTimes;
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
                    prayerTimes.map((prayer) {
                      return prayerCard(prayer["name"]!, prayer["time"]!);
                    }).toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Widget prayerCard(String name, String time) {
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
                // Text("data"),
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
