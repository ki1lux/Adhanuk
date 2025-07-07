import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:myadhan/model/QiblahModel.dart';
import 'package:permission_handler/permission_handler.dart';

class QiblahController {
  final QiblahModel _model = QiblahModel();

  
  Future<void> init() async {
    await _model.requestPermissions();
  }

  Stream getQiblaStream() {
    return _model.getQiblaStream();
  }
}
