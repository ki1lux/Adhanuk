import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:flutter_svg/svg.dart';
import 'package:myadhan/controller/QiblahController.dart';


class QiblaScreen extends StatefulWidget {
  @override
  _QiblaScreenState createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  final QiblahController _controller = QiblahController();
  bool _isPermissionGranted = false;
  @override
  void initState() {
    super.initState();
    checkPermissions();
  }

  Future<void> checkPermissions() async {
    await FlutterQiblah.requestPermissions();
    setState(() {
      _isPermissionGranted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0A2239),
      body: SafeArea(
        child: _isPermissionGranted
            ? StreamBuilder<QiblahDirection>(
                stream: FlutterQiblah.qiblahStream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final qiblahDirection = snapshot.data!;

                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      SvgPicture.asset(
                        'assets/Vector.svg',
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),

                      Transform.rotate(
                        angle: (qiblahDirection.direction * (pi / 180) * -1),
                        child: SvgPicture.asset("assets/normal_compass.svg"),
                      ),

                      Transform.rotate(
                        angle: (qiblahDirection.qiblah * (pi / 180) * -1),
                        child: SvgPicture.asset("assets/qiblah_direction.svg"),
                      ),

                      Positioned(
                        bottom: 32,
                        child: Text(
                          "${qiblahDirection.offset.toStringAsFixed(0)}°",
                          style: TextStyle(
                            fontSize: 24,
                            fontFamily: 'cairo',
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              )
            : Center(child: CircularProgressIndicator()),
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
