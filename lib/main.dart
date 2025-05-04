import 'package:flutter/material.dart';
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
      home: Stack(
        children: [
          Container(
            color: const Color(0xFF1A2B3C), // Dark blue background
          ),
          Positioned(
            top:
                -200, // Adjust this value to control how much of the circle shows
            left: -100,
            right: -100,
            child: Container(
              height: 500, // Large enough to create a circle
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}



