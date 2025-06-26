import 'package:flutter/material.dart';

class Compassview extends StatefulWidget {
  @override
  _Compassview createState() => _Compassview();
}

class _Compassview extends State<Compassview> {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          top: 38,
          child: Text(
            "N",
            style: TextStyle(
              color: Colors.black,
              fontSize: 32,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        Positioned(
          right: 10,
          child: Text(
            "E",
            style: TextStyle(
              color: Colors.black,
              fontSize: 32,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
