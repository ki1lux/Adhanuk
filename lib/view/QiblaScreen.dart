import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:flutter_svg/svg.dart';
import 'package:myadhan/controller/QiblahController.dart';
import 'package:myadhan/view/CompassView.dart';

class QiblaScreen extends StatefulWidget {
  @override
  _QiblaScreenState createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  final QiblahController _controller = QiblahController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _controller.init();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      backgroundColor: const Color(0xff0A2239),
      body: SafeArea(
        child: Center(
          child: StreamBuilder(
            stream: _controller.getQiblaStream(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }
              final qiblahDirection = snapshot.data;

              return Center(
                child: Stack(
                  children: [
                    SvgPicture.asset(
                      'assets/Vector.svg',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),

                    Positioned(
                      top: -100,
                      bottom: -100,
                      left: -100,
                      right: -100,
                      child: Transform.rotate(
                        angle:
                            ((qiblahDirection.direction ?? 0) *
                                (pi / 180) *
                                -1),
                        child: SvgPicture.asset("assets/normal_compass.svg"),
                      ),
                    ),

                    Positioned(
                      top: -130,
                      bottom: -130,
                      left: -130,
                      right: -130,
                      child: Transform.rotate(
                        angle:
                            ((qiblahDirection.qiblah ?? 0) * (pi / 180) * -1),
                        child: SvgPicture.asset("assets/qiblah_direction.svg"),
                      ),
                    ),
                    Center(
                      child: Positioned(
                        bottom: 8,
                        child: Text(
                          "${qiblahDirection.offset.toStringAsFixed(0)}°",
                          style: TextStyle(
                            fontSize: 24,
                            fontFamily: 'cairo',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// Widget _buildDirectionLabel(String label, double angle, double radius) {
//   return Transform.translate(
//     offset: Offset(radius * cos(angle), radius * sin(angle)),
//     child: Text(
//       label,
//       style: TextStyle(
//         color: Colors.black,
//         fontSize: 24,
//         fontWeight: FontWeight.w500,
//       ),
//     ),
//   );
// }
