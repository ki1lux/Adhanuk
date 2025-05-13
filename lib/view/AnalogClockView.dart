// import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
// import 'package:flutter/scheduler.dart';
import 'package:myadhan/controller/ClockController.dart';
import 'package:myadhan/model/ClockModel.dart';
import 'package:intl/intl.dart';

class Analogclockview extends StatefulWidget {
  const Analogclockview({super.key});

  @override
  _AnalogclockviewState createState() => _AnalogclockviewState();
}

class _AnalogclockviewState extends State<Analogclockview> {
  DateTime time = DateTime.now();
  late String timeAfterReform = DateFormat('h:mm a').format(time);
  late ClockModel model;
  late ClockController controller;

  @override
  void initState() {
    super.initState();
    controller = ClockController(
      onTick: (newModel) {
        setState(() {
          model = ClockModel(DateTime.now());
          time = DateTime.now();
          timeAfterReform = DateFormat('h:mm a').format(time);
        });
      },
    );
    model = ClockModel(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomPaint(
          painter: ClockPainter(model),
          size: Size(
            MediaQuery.sizeOf(context).width,
            MediaQuery.sizeOf(context).width,
          ),
        ),
        SizedBox(height: 50),
        Text(
          "$timeAfterReform",
          style: TextStyle(
            fontFamily: 'cairo',
            decoration: TextDecoration.none,
            color: Color(0xffF0F8FF),
          ),
        ),
      ],
    );
  }
}

class ClockPainter extends CustomPainter {
  final ClockModel degree;

  ClockPainter(this.degree);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 3.5;

    final paintCircle =
        Paint()
          ..color = Color(0xffD3E0EC)
          ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius / 2, paintCircle);

    // علامات الساعة
    final tickPaint =
        Paint()
          ..color = Color(0xffD3E0EC)
          ..strokeWidth = 3.3;

    for (int i = 0; i < 60; i++) {
      final angle = 2 * pi * i / 60;
      final outer = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
      final inner = Offset(
        center.dx + (radius - 8) * cos(angle),
        center.dy + (radius - 8) * sin(angle),
      );
      canvas.drawLine(inner, outer, tickPaint);
    }

    // عقرب الساعات
    final hourAngle = degree.hourAngle;
    final hourHand = Offset(
      center.dx + radius * 0.5 * cos(hourAngle - pi / 2),
      center.dy + radius * 0.5 * sin(hourAngle - pi / 2),
    );
    final hourPaint =
        Paint()
          ..color = Color(0xff283F54)
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, hourHand, hourPaint);

    // عقرب الدقائق
    final minuteAngle = degree.minuteAngle;
    final minuteHand = Offset(
      center.dx + radius * 0.8 * cos(minuteAngle - pi / 2),
      center.dy + radius * 0.8 * sin(minuteAngle - pi / 2),
    );
    final minutePaint =
        Paint()
          ..color = Color(0xff283F54)
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, minuteHand, minutePaint);

    // final paint = Paint()..color = Colors.red;
    // final handRect = RRect.fromLTRBR(
    //   15,
    //   0,
    //   8,
    //   9, // Start at 15 to leave space for tail
    //   Radius.circular(radius),
    // );
    // canvas.drawRRect(handRect, paint);

    // عقرب الثواني
    final secondAngle = degree.second;
    final secondHand = Offset(
      center.dx + radius * cos(secondAngle - pi / 2),
      center.dy + radius * sin(secondAngle - pi / 2),
    );
    final secondPaint =
        Paint()
          ..color = Color(0xff283F54)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round;
    // canvas.drawLine(center, secondHand, secondPaint);
    final tailLength = radius * 0.15;
    final secondHandTail = Offset(
      center.dx - tailLength * cos(secondAngle - pi / 2),
      center.dy - tailLength * sin(secondAngle - pi /2),
      );
    canvas.drawLine(secondHandTail, secondHand, secondPaint);

    // دائرة في المنتصف
    final centerDot = Paint()..color = Color(0xff283F54);
    canvas.drawCircle(center, 6.5, centerDot);
    final additionalCenterDot = Paint()..color = Color(0xffD3E0EC);
    canvas.drawCircle(center, 3, additionalCenterDot);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
