import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:myadhan/controller/QiblahController.dart';
import 'package:myadhan/view/CompassView.dart';

class QiblaScreen extends StatefulWidget {
  @override
  _QiblaScreenState createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen>
    with SingleTickerProviderStateMixin {
  final QiblahController _controller = QiblahController();
  Animation<double>? animation;
  AnimationController? _animationController;
  double begin = 0.0;

  @override
  void initState() {
    // TODO: implement initState
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    animation = Tween(begin: 0.0, end: 0.0).animate(_animationController!);
    super.initState();
    _controller.init();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 48, 48, 48),
        body: StreamBuilder(
          stream: FlutterQiblah.qiblahStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                alignment: Alignment.center,
                child: const CircularProgressIndicator(color: Colors.white),
              );
            }

            final qiblahDirection = snapshot.data;
            animation = Tween(
              begin: begin,
              end: (qiblahDirection!.qiblah * (pi / 180) * -1),
            ).animate(_animationController!);
            begin = (qiblahDirection.qiblah * (pi / 180) * -1);
            _animationController!.forward(from: 0);

            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "${qiblahDirection.direction.toInt()}°",
                    style: const TextStyle(color: Colors.white, fontSize: 24),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 300,
                    child: AnimatedBuilder(
                      animation: animation!,
                      builder:
                          (context, child) => Transform.rotate(
                            angle: animation!.value,
                            child: Image.asset('assets/qiblahanim.png'),
                          ),
                    ),
                  ),
                ],
              ),
            );
          },
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
