// import 'dart:nativewrappers/_internal/vm/lib/ffi_patch.dart';

// import 'dart:ffi';
import 'package:myadhan/view/QiblaScreen.dart';
import 'package:myadhan/view/PrayerTimeScreen.dart';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
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

  final List<Widget> _whichPage = [
    QiblaScreen(),
    AdhanScreen(),
    PrayerTimeScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        extendBody: true,
        body: IndexedStack(index: _slectIndex, children: _whichPage),

        bottomNavigationBar: Padding(
          padding: const EdgeInsets.only(bottom: 16, right: 12, left: 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: Container(
                height: 58,
                // padding: EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
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
      ),
    );
  }

  Widget _buildNavItem(String assets, int index) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          splashColor: Color.fromARGB(255, 14, 43, 70),
          highlightColor: Color(0xff0A2239),
          hoverColor: Color(0xff0A2239),
          onTap: () => _onTap(index),
          child: Container(
            height: double.infinity,
            padding: EdgeInsets.all(18),
            child: SvgPicture.asset(
              assets,
              colorFilter: ColorFilter.mode(
                _slectIndex == index ? Colors.white : Colors.white60,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
