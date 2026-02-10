import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:myadhan/prayer_alarm_scheduler.dart';

class SettingsScreen extends StatefulWidget {
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}



class _SettingsScreenState extends State<SettingsScreen> {
  bool isFullScreen = true;
  Map<String, dynamic> alarmStatus = {};

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
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
                      activeThumbColor: Colors.white,
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
                _settingsButtons(
                  Icons.alarm,
                  "Reschedule Prayer Alarms",
                  () {},
                ),
                _settingsButtons(Icons.info, "Alarm Status", () {
                  _showAlarmStatusDialog();
                }),
                _settingsButtons(Icons.timer, "Test Native Alarm (10s)", () {
                  PrayerAlarmScheduler.testNativeAlarm();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Alarm scheduled! Close app to test.')),
                  );
                }),
                _settingsButtons(Icons.build, "Troubleshoot Alarm", () {
                  _showTroubleshootDialog();
                }),
                _settingsButtons(Icons.battery_alert, "تعطيل تحسين البطارية", () {
                  _openBatteryOptimizationSettings();
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
                      await launchUrl(
                        url,
                        mode: LaunchMode.externalApplication,
                      );
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
          onTap: onTap,
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
              children:
                  alarmStatus.entries.map((entry) {
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
                            isPassed
                                ? 'Tomorrow $nextOccurrence'
                                : 'Today ${data['time']}',
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

  void _showTroubleshootDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2D4356),
          title: Text(
            'استكشاف الأخطاء وإصلاحها',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'cairo',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTroubleshootItem(
                  "1. إذن التنبيه الدقيق (Exact Alarm)",
                  "تأكد من تفعيل هذا الإذن لضمان عمل الأذان في وقته الدقيق.",
                  () async {
                    bool granted = await PrayerAlarmScheduler.checkExactAlarmPermission();
                    if (!granted) {
                      await PrayerAlarmScheduler.requestExactAlarmPermission();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('الإذن مفعل بالفعل ✅')),
                      );
                    }
                  },
                ),
                SizedBox(height: 16),
                _buildTroubleshootItem(
                  "2. تحسين البطارية (Battery Optimization)",
                  "بعض الهواتف توقف التطبيق في الخلفية. يرجى استثناء التطبيق من تحسين البطارية.",
                  () async {
                     const channel = MethodChannel('com.myadhan/notification');
                     await channel.invokeMethod('openBatterySettings');
                  },
                ),
                SizedBox(height: 16),
                Text(
                  "نصيحة: إذا كان هاتفك من نوع Xiaomi أو Huawei، ابحث عن إعدادات 'التشغيل التلقائي' (Autostart) وقم بتفعيل التطبيق.",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontFamily: 'cairo',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'إغلاق',
                style: TextStyle(color: Colors.white, fontFamily: 'cairo'),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTroubleshootItem(String title, String desc, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
              fontFamily: 'cairo',
            ),
          ),
          SizedBox(height: 4),
          Text(
            desc,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontFamily: 'cairo',
            ),
          ),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blueAccent.withOpacity(0.5)),
            ),
            child: Text(
              "اضغط هنا للتحقق / الإصلاح",
              style: TextStyle(color: Colors.blueAccent, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// Opens Android battery optimization settings for this app
  /// This helps users disable battery restrictions that delay notifications
  void _openBatteryOptimizationSettings() async {
    // Show explanation dialog first
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xff0A2239),
        title: const Text(
          'تعطيل تحسين البطارية',
          style: TextStyle(color: Colors.white, fontFamily: 'cairo'),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.battery_alert, color: Colors.orange, size: 48),
            const SizedBox(height: 16),
            const Text(
              'لضمان وصول إشعارات الصلاة في وقتها بدقة:\n\n'
              '1. اضغط "فتح الإعدادات"\n'
              '2. ابحث عن التطبيق واختر "غير مُحسّن"\n'
              '3. هذا يمنع Android من تأخير الإشعارات',
              style: TextStyle(color: Colors.white70, fontFamily: 'cairo', height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // Open battery optimization settings using native channel
              try {
                const channel = MethodChannel('com.myadhan/notification');
                await channel.invokeMethod('openBatterySettings');
              } catch (e) {
                // Fallback: open general Android settings
                final uri = Uri.parse('package:com.example.myadhan');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('فتح الإعدادات', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
