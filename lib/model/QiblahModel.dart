import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:permission_handler/permission_handler.dart';
class QiblahModel {
  Stream getQiblaStream() {
    return FlutterQiblah.qiblahStream;
  }

  /// Returns true if location permission is granted.
  /// Note: Actual permission request happens in main.dart at app startup.
  Future<bool> requestPermissions() async {
    return await Permission.locationWhenInUse.isGranted;
  }

   Future<bool> hasPermission() async {
    return await Permission.locationWhenInUse.isGranted;
  }

  
}
