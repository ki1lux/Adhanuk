import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:myadhan/view/AnalogClockView.dart';

class AdhanScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {

SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.white, // أو transparent لو عندك AppBar
    statusBarIconBrightness: Brightness.dark, // أيقونات سوداء
    statusBarBrightness: Brightness.light, // لأجهزة iOS
  ));

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
          Positioned(
            top:
                -200, // Adjust this value to control how much of the circle shows
            left: -100,
            right: -100,
            child: Container(
              height: 600, // Large enough to create a circle
              decoration: const BoxDecoration(
                color: Color(0xFFF0F8FF),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(child: Analogclockview()),
        ],
      ),
    );
  }
}
