import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:permission_handler/permission_handler.dart';
class QiblahModel {
  Stream getQiblaStream() {
    return FlutterQiblah.qiblahStream;
  }

  Future<bool> requestPermissions() async {
    final status = await Permission.locationWhenInUse.request();
    return status.isGranted;
  }

   Future<bool> hasPermission() async {
    return await Permission.locationWhenInUse.isGranted;
  }
}
