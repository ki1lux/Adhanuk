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
    // 1. Check if we already have permission
    bool granted = await _controller.hasPermission();

    if (!granted) {
      try {
        // 2. UNCOMMENT this line to show the popup
        // We wrap it in try-catch to stop the crash if it's called twice
        await _controller.init();

        // 3. Check again after the user clicks Allow/Deny
        granted = await _controller.hasPermission();
      } catch (e) {
        // 4. If the error "Already requesting" happens, we ignore it safely.
        print("Popup is already open: $e");
      }
    }

    // 5. Update the UI
    if (mounted) {
      setState(() {
        _hasPermission = granted;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: const Color(0xff0A2239),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 24),
              const Text(
                'جاري التحميل...',
                style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _checkPermission,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة', style: TextStyle(fontFamily: 'Cairo')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white24,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_hasPermission) {
      return Scaffold(
        backgroundColor: const Color(0xff0A2239),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_off, color: Colors.white54, size: 64),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  "يجب السماح بإذن الموقع لاستخدام البوصلة",
                  style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Cairo'),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _checkPermission,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة', style: TextStyle(fontFamily: 'Cairo')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white24,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xff0A2239),
      body: Stack(
        children: [
          SvgPicture.asset(
            'assets/Vector.svg',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          Center(
            child: StreamBuilder(
              stream: _controller.getQiblaStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final qiblahDirection = snapshot.data;
                final double screenWidth = MediaQuery.of(context).size.width;

                return SizedBox(
                  height: screenWidth + 75,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Transform.rotate(
                        angle:
                            ((qiblahDirection.direction ?? 0) *
                                (pi / 180) *
                                -1),
                        child: SvgPicture.asset("assets/test.svg"),
                      ),
                      Transform.rotate(
                        angle:
                            ((qiblahDirection.qiblah ?? 0) * (pi / 180) * -1),
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
                            color: const Color(0xff0A2239),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // Reset Qibla button
          Positioned(
            bottom: 96,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _loading = true;
                  });
                  _checkPermission();
                },
                icon: const Icon(Icons.compass_calibration, size: 20),
                label: const Text(
                  'إعادة ضبط القبلة',
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
