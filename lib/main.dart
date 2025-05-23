// import 'dart:nativewrappers/_internal/vm/lib/ffi_patch.dart';

import 'package:flutter/material.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:myadhan/view/AnalogClockView.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:adhan/adhan.dart';
import 'package:myadhan/view/adhan_screen.dart';
// import 'package:myadhan/test.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        extendBody: true,
        body: AdhanScreen(),
      bottomNavigationBar: BottomNavigationBar(items: [
            BottomNavigationBarItem (icon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(icon: Icon(Icons.compass_calibration), label: "Compass"),
            BottomNavigationBarItem(icon: Icon(Icons.access_time), label: "Time"),
          ]),
      ),
    );
  }
}
