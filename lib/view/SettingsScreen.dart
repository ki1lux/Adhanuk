import 'package:flutter/material.dart';
import 'package:myadhan/view/SettingsMenu.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      backgroundColor: const Color(0xff0A2239),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            children: [
              SizedBox(height: 12),

              Text(
                "Settings",
                style: TextStyle(
                  color: Colors.blueGrey,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              // SettingsMenu(icon: Icons.color_lens, title: "Choose theme"),
              _settingsButtons(Icons.color_lens, "Choose theme", () {}),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _settingsButtons(IconData icon, String title, VoidCallback onTap) {
  return Material(
    borderRadius: BorderRadius.circular(24),
    color: const Color(0xFF2D4356),
    child: InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () {},
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 16),
            Text(title, style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    ),
  );
}

BoxDecoration _tileDecoration() {
  return BoxDecoration(
    color: const Color(0xFF2D4356),
    borderRadius: BorderRadius.circular(15),
  );
}
