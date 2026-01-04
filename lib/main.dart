// import 'dart:nativewrappers/_internal/vm/lib/ffi_patch.dart';

// import 'dart:ffi';
// import 'package:adhan/adhan.dart';
// import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:myadhan/controller/PrayerTimeController.dart';
// import 'package:myadhan/notification_service.dart';
import 'package:myadhan/view/QiblaScreen.dart';
import 'package:myadhan/view/PrayerTimeScreen.dart';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:myadhan/view/SettingsScreen.dart';
import 'package:myadhan/view/adhan_screen.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:timezone/data/latest.dart' as tz;
// import 'package:timezone/data/latest.dart';
import 'package:timezone/timezone.dart';
import 'package:timezone/timezone.dart' as tz;
// import 'package:myadhan/test.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  // await AndroidAlarmManager.initialize();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  List<Map<String, String>> prayerTimesList = [];
  final PrayerTimeController prayerController = PrayerTimeController();

  int _slectIndex = 0;

  @override
  void initState() {
    requestNotificationPermission();
    init();
    // _loadPrayerTimes();
    // _scheduleAllPrayers();

    super.initState();
    schedulePrayerNotifications();
    // scheduleReminder(id: 4, title: 'Scheduled work!', body: 'body');
  }

  Future<void> schedulePrayerNotifications() async {
    // هنا تحسب مواقيت الصلاة من API أو من مكتبة عندك
    // حاليا سنضع أوقات تجريبية (يجب تعويضها بوقتك الحقيقي)

    int id = 2;
    final now = DateTime.now();
    // final prayerTimesList = [
    //   {"name": "العصر", "time": "12:06"},

    // ];
    final data = await prayerController.getPrayerTimes();
    final prayerTimesList = [
      {"name": "الفجر", "time": DateFormat('HH:mm').format(data.fajer)},
      {"name": "الظهر", "time": DateFormat('HH:mm').format(data.dhuhr)},
      {"name": "العصر", "time": "16:39"},
      {"name": "المغرب", "time": DateFormat('HH:mm').format(data.maghrib)},
      {"name": "العشاء", "time": DateFormat('HH:mm').format(data.isha)},
    ];

    for (var prayer in prayerTimesList) {
      String name = prayer['name']!;
      String time = prayer['time']!;

      // print('!!!!!!!!!!!!!' + time + '!!!!!!!!!!!!!');

      final parts = time.split(':');
      final scheduledTime = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
      id = id + 1;
      await scheduleReminder(
        id: id,
        title: name,
        body: time,
        time: scheduledTime,
      );
    }
  }

  Future<void> scheduleReminder({
    required int id,
    required String title,
    String? body,
    required DateTime time,
  }) async {
    // TZDateTime now = TZDateTime.now(local);
    TZDateTime salat = TZDateTime.from(time, tz.local);
    TZDateTime scheduledDate = salat;
    await notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder_channel_id',
          'Daily Reminders',
          channelDescription: 'Reminder to complete daily habits',
          importance: Importance.max,
          priority: Priority.high,
          //! addition part
          playSound: true,
          // sound: RawResourceAndroidNotificationSound('adhan1'),
          // actions: <AndroidNotificationAction>[
          //   AndroidNotificationAction(
          //     'STOP_ADHAN',
          //     'Stop',
          //     showsUserInterface: true,
          //     cancelNotification: true,
          //   ),
          // ],
        ),

        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  Future<void> requestNotificationPermission() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }

  Future<void> init() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(getLocation('Africa/Algiers'));

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();
    const InitializationSettings initializationSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);
    await notificationsPlugin.initialize(initializationSettings);

    // await notificationsPlugin.initialize(
    //   initializationSettings,
    //   onDidReceiveNotificationResponse: (NotificationResponse response) {
    //     if (response.actionId == 'STOP_ADHAN') {
    //       notificationsPlugin.cancelAll(); // stop Adhan
    //     }
    //   },
    // );
  }

  // Future<void> _loadPrayerTimes() async {
  //   final data = await prayerController.getPrayerTimes();

  //   prayerTimesList = [
  //     {"name": "الفجر", "time": DateFormat('HH:mm').format(data.fajer)},
  //     {"name": "الظهر", "time": DateFormat('HH:mm').format(data.dhuhr)},
  //     {"name": "العصر", "time": DateFormat('HH:mm').format(data.asr)},
  //     {"name": "المغرب", "time": DateFormat('HH:mm').format(data.maghrib)},
  //     {"name": "العشاء", "time": DateFormat('HH:mm').format(data.isha)},
  //   ];

  //   _scheduleAllPrayers();
  // }

  // Future<void> schedulePrayerNotification(
  //   String title,
  //   DateTime dateTime,
  // ) async {
  //   final androidDetails = AndroidNotificationDetails(
  //     'prayer_channel',
  //     'Prayer Notifications',
  //     channelDescription: 'Notifications for prayer times',
  //     importance: Importance.max,
  //     priority: Priority.high,
  //   );

  //   final notificationDetails = NotificationDetails(android: androidDetails);

  //   await flutterLocalNotificationsPlugin.zonedSchedule(
  //     dateTime.millisecondsSinceEpoch ~/ 1000, // id فريد
  //     'موعد $title',
  //     'حان الآن وقت صلاة $title',
  //     tz.TZDateTime.from(dateTime, tz.local),
  //     notificationDetails,
  //     androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,

  //     matchDateTimeComponents: DateTimeComponents.time, // حتى يتكرر يومياً
  //   );
  // }

  // Future<void> _scheduleAllPrayers() async {
  //   // هنا prayerTimesList يكون جاهز (حسب أوقات اليوم)
  //   for (var prayer in prayerTimesList) {
  //     String name = prayer['name']!;
  //     String time = prayer['time']!;

  //     // حوّل النص "HH:mm" إلى DateTime لليوم الحالي
  //     final parts = time.split(':');
  //     final now = DateTime.now();
  //     final scheduledTime = DateTime(
  //       now.year,
  //       now.month,
  //       now.day,
  //       int.parse(parts[0]),
  //       int.parse(parts[1]),
  //     );

  //     // لو الوقت فات، خلي الإشعار لغدوة
  //     final notificationTime =
  //         scheduledTime.isBefore(now)
  //             ? scheduledTime.add(const Duration(days: 1))
  //             : scheduledTime;

  //     await schedulePrayerNotification(name, notificationTime);
  //   }
  // }

  void _onTap(int index) {
    setState(() {
      _slectIndex = index;
    });
  }

  final List<Widget> _whichPage = [
    AdhanScreen(),
    PrayerTimeScreen(),
    QiblaScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        extendBody: true,
        body: IndexedStack(index: _slectIndex, children: _whichPage),

        bottomNavigationBar: Padding(
          padding: const EdgeInsets.only(bottom: 16, right: 12, left: 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: Container(
                height: 58,
                // padding: EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem('assets/h2.svg', 0),
                    _buildNavItem('assets/h3.svg', 1),
                    _buildNavItem('assets/h1.svg', 2),
                    _buildNavItem('assets/settingsIcon.svg', 3),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(String assets, int index) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          splashColor: Color.fromARGB(255, 14, 43, 70),
          highlightColor: Color(0xff0A2239),
          hoverColor: Color(0xff0A2239),
          onTap: () => _onTap(index),
          child: Container(
            height: double.infinity,
            padding: EdgeInsets.all(18),
            child: SvgPicture.asset(
              assets,
              colorFilter: ColorFilter.mode(
                _slectIndex == index ? Colors.white : Colors.white60,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
