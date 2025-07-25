import 'package:flutter/material.dart';

class SettingsMenu extends StatelessWidget {
  const SettingsMenu({super.key, required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Container(
      alignment: Alignment.center,
      height: 64,
      decoration: BoxDecoration(
        // color: const Color(0xFF2D4356),
        borderRadius: BorderRadius.circular(24),
      ),

      child: ListTile(
        leading: Icon(icon, size: 28, color: Colors.white),
        title: Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontFamily: 'cairo',
            fontWeight: FontWeight.bold,
          ),
        ),
        onTap: () {},
        // subtitle: Text(subtitle, style: Theme.of(context).textTheme.labelMedium),
      ),
    );
  }
}
