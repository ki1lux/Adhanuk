import 'package:flutter_qiblah/flutter_qiblah.dart';

class QiblahModel {
  Stream<QiblahDirection> getQiblaStream() {
    return FlutterQiblah.qiblahStream;
  }

  Future<void> requestPermissions() async {
    await FlutterQiblah.requestPermissions();
  }
}
