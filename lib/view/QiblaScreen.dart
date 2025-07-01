import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
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
              final tdirection = snapshot.data;
              
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Transform.rotate(angle: tdirection.direction * (pi / 180),
                    child: Image.asset("assets/qiblahanim.png" ,width: 100,),
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
