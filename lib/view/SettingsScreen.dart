import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SettingsScreen extends StatefulWidget {
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isFullScreen = true;

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
              SizedBox(height: 6),

              Align(
                // alignment: Alignment.topLeft,
                child: Text(
                  "Settings",
                  style: TextStyle(
                    color: Colors.blueGrey,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Container(
                  alignment: Alignment.center,
                  height: 64,
                  decoration: _tileDecoration(),
                  child: SwitchListTile(
                    value: isFullScreen,
                    onChanged: (val) {
                      setState(() {
                        isFullScreen = val;
                      });
                    },
                    activeColor: Colors.white,
                    title: const Text(
                      "Full screen notif",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: 'cairo',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    secondary: const Icon(
                      Icons.notifications,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              // SettingsMenu(icon: Icons.color_lens, title: "Choose theme"),
              _settingsButtons(Icons.color_lens, "Choose theme", () {}),
              _settingsButtons(Icons.share, "Share App", () {}),
              _settingsButtons(Icons.star, "Rate App", () {}),
              _settingsButtons(Icons.mosque, "Adhani\nversion : 1.0", () {}),

              const Spacer(),

              const Divider(color: Colors.white24),
              SizedBox(height: 5),
              Center(
                child: const Text(
                  "Designed & Devloped by :",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontFamily: 'cairo',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () => {},
                child: Icon(
                  FontAwesomeIcons.github,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "khalilbenfiala001@gmail.com",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontFamily: 'cairo',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _settingsButtons(IconData icon, String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Material(
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
                Icon(icon, color: Colors.white, size: 28),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'cairo',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _tileDecoration() {
    return BoxDecoration(
      color: const Color(0xFF2D4356),
      borderRadius: BorderRadius.circular(24),
    );
  }
}
