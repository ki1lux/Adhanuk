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

  bool _hasPermission = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    // Ask for permission via controller
    bool granted = await _controller.hasPermission();

    if (!granted) {
      // Try requesting it again
      await _controller.init(); // this asks again
      granted = await _controller.hasPermission(); // check again after asking
    }

    setState(() {
      _hasPermission = granted;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: const Color(0xff0A2239),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_hasPermission) {
      return Scaffold(
        backgroundColor: const Color(0xff0A2239),
        body: Center(
          child: Text(
            "Location permission is required to use the compass.",
            style: TextStyle(color: Colors.white, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

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
                        " ${qiblahDirection.direction.toStringAsFixed(0)}°",
                        style: TextStyle(
                          fontSize: 28,
                          fontFamily: 'cairo',
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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
