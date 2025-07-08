import 'package:myadhan/model/QiblahModel.dart';


class QiblahController {
  final QiblahModel _model = QiblahModel();

  
  Future<void> init() async {
    await _model.requestPermissions();
  }

  Stream getQiblaStream() {
    return _model.getQiblaStream();
  }
}
