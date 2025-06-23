import 'package:flutter/material.dart';

class QiblaScreen extends StatefulWidget {
  @override
  _QiblaScreenState createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      backgroundColor: Color(0xff0A2239),
      body: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Container(color: Color(0xff0A2239)),
            Positioned(
              left: -120,
              right: -120,
              top: -120,
              bottom: -120,
              child: Container(
                width: 500,
                height: 500,
                decoration: BoxDecoration(
                  color: Color(0xffF0F8FF),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // CompassView(),
          ],
        ),
      ),
    );
  }
}
