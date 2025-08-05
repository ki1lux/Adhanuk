import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:myadhan/controller/PrayerTimeController.dart';

class SettingsScreen extends StatefulWidget {
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isFullScreen = true;
  Map<String, dynamic> alarmStatus = {};
  final PrayerTimeController _prayerController = PrayerTimeController();

  @override
  void initState() {
    super.initState();
    
  }

  // Future<void> _loadAlarmStatus() async {
  //   final status = await _prayerController.getAlarmStatus();
  //   setState(() {
  //     alarmStatus = status;
  //   });
  // }

  @override
  Widget build(BuildContext context) {

    // SystemChrome.setSystemUIOverlayStyle(
    //   SystemUiOverlayStyle(
    //     statusBarColor: Colors.black, // أو لون الخلفية الداكنة للصفحة
    //     statusBarIconBrightness: Brightness.light, // أيقونات بيضاء
    //     statusBarBrightness: Brightness.dark,
    //   ),
    // );
    // TODO: implement build
    return Scaffold(
      backgroundColor: const Color(0xff0A2239),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 6),
          
                Text(
                  "Settings",
                  style: TextStyle(
                    color: Colors.blueGrey,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
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
                _settingsButtons(Icons.alarm, "Reschedule Prayer Alarms", () {}),
                _settingsButtons(Icons.info, "Alarm Status", () {
                  _showAlarmStatusDialog();
                }),
                _settingsButtons(Icons.mosque, "Adhani\nversion : 1.0", () {}),
          
                const SizedBox(height: 32),
          
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
                  onTap: () async {
                    final url = Uri.parse("https://github.com/ki1lux");
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    } else {
                      throw 'Could not launch $url';
                    }
                  },
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

  void _showAlarmStatusDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2D4356),
          title: Text(
            'Prayer Alarm Status',
            style: TextStyle(color: Colors.white, fontFamily: 'cairo'),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: alarmStatus.entries.map((entry) {
                final prayerName = entry.key;
                final data = entry.value as Map<String, dynamic>;
                final isPassed = data['isPassed'] as bool;
                final nextOccurrence = data['nextOccurrence'] as String;
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        prayerName,
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'cairo',
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        isPassed ? 'Tomorrow $nextOccurrence' : 'Today ${data['time']}',
                        style: TextStyle(
                          color: isPassed ? Colors.orange : Colors.green,
                          fontFamily: 'cairo',
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: TextStyle(color: Colors.white, fontFamily: 'cairo'),
              ),
            ),
          ],
        );
      },
    );
  }
}
