
import 'package:myadhan/model/QiblahModel.dart';

class QiblahController {
  final QiblahModel _model = QiblahModel();

  Future<bool> init() async {
    return await _model.requestPermissions();
  }

  Future<bool> hasPermission() async {
    return await _model.hasPermission();
    
  }

  Stream getQiblaStream() {
    return _model.getQiblaStream();
  }

  

  Future<void> initializeQiblah() async {
    await Future.delayed(
      Duration(milliseconds: 500),
    );
  }
}
