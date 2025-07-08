import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:myadhan/controller/QiblahController.dart';

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
              final double screenWidth = MediaQuery.of(context).size.width;
              return SizedBox(
                height: screenWidth + 70,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SvgPicture.asset(
                      'assets/Vector.svg',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),

                    Transform.rotate(
                      angle:
                          ((qiblahDirection.direction ?? 0) * (pi / 180) * -1),
                      child: SvgPicture.asset("assets/test.svg"),
                    ),

                    Transform.rotate(
                      angle: ((qiblahDirection.qiblah ?? 0) * (pi / 180) * -1),
                      child: SvgPicture.asset("assets/ka3baInCompass.svg"),
                    ),

                    Align(
                      alignment: Alignment.topCenter,
                      child: SvgPicture.asset("assets/arrow.svg"),
                    ),

                    Center(
                      child: Text(
                        " ${qiblahDirection.offset.toStringAsFixed(0)}°",
                        style: TextStyle(
                          fontSize: 28,
                          fontFamily: 'cairo',
                          fontWeight: FontWeight.bold,
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
