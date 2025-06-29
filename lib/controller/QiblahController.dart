import 'package:myadhan/model/QiblahModel.dart';
import 'package:permission_handler/permission_handler.dart';

class QiblahController {
  final QiblahModel _model = QiblahModel();

  
  Future<void> init() async {
    final status = await Permission.location.status;
    if (!status.isGranted) {
      await Permission.location.request();
    }
    await _model.requestPermissions();
  }

  Stream getQiblaStream() {
    return _model.getQiblaStream();
  }
}
