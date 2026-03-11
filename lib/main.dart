import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myadhan/model/PrayerTimeModel.dart';
import 'package:myadhan/prayer_alarm_scheduler.dart';
import 'package:myadhan/providers/prayer_times_provider.dart';
import 'package:myadhan/view/QiblaScreen.dart';
import 'package:myadhan/view/PrayerTimeScreen.dart';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:myadhan/view/SettingsScreen.dart';
import 'package:myadhan/view/adhan_screen.dart';
import 'package:myadhan/view/splash_screen.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  
  // Register native daily prayer worker (replaces Flutter WorkManager)
  const channel = MethodChannel('com.myadhan/notification');
  try {
    await channel.invokeMethod('registerDailyPrayerWorker');
  } catch (e) {
    debugPrint('Failed to register daily prayer worker: $e');
  }
  
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  final _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _notificationsScheduled = false;

  @override
  void initState() {
    super.initState();
    _initNotificationsSync();
    // Wait for widget tree to be built before requesting permissions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestPermissions();
    });
  }

  void _initNotificationsSync() {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Africa/Algiers'));

    const androidSettings = AndroidInitializationSettings('@drawable/ic_stat_adhan');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    
    _notificationsPlugin.initialize(settings);
  }

  Future<void> _requestPermissions() async {
    debugPrint('Requesting permissions...');
    // Request all permissions at once - avoids race conditions
    final statuses = await [
      Permission.notification,
      Permission.locationWhenInUse,
    ].request();
    
    debugPrint('Permission results: $statuses');
    
    // Request exact alarm permission via native channel
    await PrayerAlarmScheduler.requestExactAlarmPermission();
    
    // Only fetch prayer times if location permission is granted
    final locationStatus = statuses[Permission.locationWhenInUse];
    if (locationStatus != null && locationStatus.isGranted) {
      debugPrint('Location granted - fetching prayer times...');
      ref.read(prayerTimesProvider.notifier).fetchPrayerTimes();
    } else {
      debugPrint('Location permission denied');
    }
  }

  Future<void> _scheduleNotifications(PrayerTimeModel data) async {
    // PrayerAlarmScheduler now handles standard local notifications
    await PrayerAlarmScheduler.scheduleAllPrayersWithData(data);
  }

  @override
  Widget build(BuildContext context) {
    // Schedule notifications when prayer times load
    ref.listen<AsyncValue<PrayerTimeModel>>(prayerTimesProvider, (previous, next) {
      if (previous?.isLoading == true && next.hasValue && !_notificationsScheduled) {
        _notificationsScheduled = true;
        _scheduleNotifications(next.value!);
      }
    });

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(scaffoldBackgroundColor: const Color(0xff0A2239),
      canvasColor: const Color(0xff0A2239)),
      home: const SplashScreen(nextScreen: MainScreen()),
    );
  }
}

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _selectedIndex = 0;

  static final _pages = <Widget>[
    AdhanScreen(),
    PrayerTimeScreen(),
    QiblaScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        transitionBuilder: (child, animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: KeyedSubtree(
          key: ValueKey<int>(_selectedIndex),
          child: _pages[_selectedIndex],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, right: 12, left: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Container(
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
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
    );
  }

  Widget _buildNavItem(String asset, int index) {
    final isSelected = _selectedIndex == index;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          onTap: () {
            setState(() => _selectedIndex = index);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: double.infinity,
            padding: const EdgeInsets.all(18),
            child: AnimatedScale(
              scale: isSelected ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.25),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: SvgPicture.asset(
                  asset,
                  colorFilter: ColorFilter.mode(
                    isSelected ? Colors.white : Colors.white60,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
