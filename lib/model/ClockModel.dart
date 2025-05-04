import 'dart:math';

class ClockModel {
  final DateTime time;
  ClockModel(this.time);
  double get second => (time.second * 6) * pi /180;
  double get minuteAngle => (time.minute * 6 + time.second * 0.1) * pi / 180;
  double get hourAngle => ((time.hour % 12) * 30 + time.minute * 0.5) * pi / 180;
  
}
