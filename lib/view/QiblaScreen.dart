import 'dart:math';

import 'package:flutter/material.dart';
import 'package:myadhan/view/CompassView.dart';

class QiblaScreen extends StatefulWidget {
  @override
  _QiblaScreenState createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      backgroundColor: const Color(0xff0A2239),
      body: SafeArea(
        child: Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Use smallest dimension to calculate radius
              double size = min(constraints.maxWidth, constraints.maxHeight);
              double radius = size / 2.5; // smaller fraction for padding

              return Stack(
                alignment: Alignment.center,
                children: [
                  // Compass circle
                  Positioned(
                    left: -100,
                    right: -100,
                    top: -100,
                    bottom: -100,
                    child: Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        color: const Color(0xffF0F8FF),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),

                  // Direction labels
                  _buildDirectionLabel("N", -pi / 2, radius + 15),
                  _buildDirectionLabel("E", 0, radius + 15),
                  _buildDirectionLabel("S", pi / 2, radius + 15),
                  _buildDirectionLabel("W", pi, radius + 15),

                  // Your Compass widget
                  // Compassview(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

Widget _buildDirectionLabel(String label, double angle, double radius) {
  return Transform.translate(
    offset: Offset(radius * cos(angle), radius * sin(angle)),
    child: Text(
      label,
      style: TextStyle(
        color: Colors.black,
        fontSize: 24,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}
