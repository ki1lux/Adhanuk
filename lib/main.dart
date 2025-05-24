// import 'dart:nativewrappers/_internal/vm/lib/ffi_patch.dart';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
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
  int _slectIndex = 1;

  void _onTap(int index) {
    setState(() {
      _slectIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        extendBody: true,
        body: AdhanScreen(),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.only(bottom: 16, right: 12, left: 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 58,
              // padding: EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem('assets/h1.svg', 0),
                  _buildNavItem('assets/h2.svg', 1),
                  _buildNavItem('assets/h3.svg', 2),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(String assets, int index) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onTap(index),
        child: Container(
          padding: EdgeInsets.all(16),
          
          child: SvgPicture.asset(
            assets,
            colorFilter: ColorFilter.mode(
              _slectIndex == index ? Colors.white : Colors.white60,
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }
}
