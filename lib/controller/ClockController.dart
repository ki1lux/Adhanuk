import 'dart:async';

import 'package:myadhan/model/clockModel.dart';

class ClockController {
  late Timer _timer;
  DateTime time = DateTime.now();
  final void Function(ClockModel) onTick;

  ClockController({required this.onTick}) {
    _onStart();
    
  }

  void _onStart() {
    _timer = Timer.periodic(Duration(seconds: 1), (_) {
      onTick(ClockModel(DateTime.now()));
    });
  }

  void textTime() {
   _timer = Timer.periodic(Duration(seconds: 1), (_) {
      time = DateTime.now();
    });
  }

  void dispose() {
    _timer.cancel();
  }
}
