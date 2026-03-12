import 'dart:async';

import 'package:myadhan/model/ClockModel.dart';

class ClockController {
  Timer? _timer;
  DateTime time = DateTime.now();
  final void Function(ClockModel) onTick;
  bool _isActive = true;

  ClockController({required this.onTick}) {
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isActive) {
        onTick(ClockModel(DateTime.now()));
      }
    });
  }

  /// Pause the timer (when screen is not visible)
  void pause() {
    _isActive = false;
  }

  /// Resume the timer (when screen becomes visible)
  void resume() {
    _isActive = true;
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
