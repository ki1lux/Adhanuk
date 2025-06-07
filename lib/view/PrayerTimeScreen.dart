import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PrayerTimeScreen extends StatefulWidget {
  @override
  _PrayerTimeState createState() => _PrayerTimeState();
}

class _PrayerTimeState extends State<PrayerTimeScreen> {
  final List<Map<String, String>> prayerTimes = [
    {"name": "الفجر", "time": "04:32"},
    {"name": "الظهر", "time": "12:41"},
    {"name": "العصر", "time": "16:11"},
    {"name": "المغرب", "time": "19:35"},
    {"name": "العشاء", "time": "20:52"},
  ];

  @override
  Widget build(BuildContext context) {
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
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          height: 76,
          // padding: EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
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
                Text(
                  "$name",
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: Color(0xffF0F8FF),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
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
