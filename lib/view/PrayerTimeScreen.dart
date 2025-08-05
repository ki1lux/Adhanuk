import 'dart:ui';
import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:myadhan/controller/LocationController.dart';
import 'package:myadhan/controller/PrayerTimeController.dart';
import 'package:myadhan/view/CountDown.dart';
import 'package:permission_handler/permission_handler.dart';

class PrayerTimeScreen extends StatefulWidget {
  @override
  _PrayerTimeState createState() => _PrayerTimeState();
}

class _PrayerTimeState extends State<PrayerTimeScreen> {
  final LocationController _controller = LocationController();
  final PrayerTimeController prayerController = PrayerTimeController();

  String countryLocationText = "location...";
  String cityLocationText = "";
  late Future<bool> _initFuture;
  // PrayerTimeModel? _prayerTimes;
  List<Map<String, String>> prayerTimesList = [];
  bool isLoading = false;
  String error = "error";

  @override
  void initState() {
    super.initState();
    // initEverything();
    // loadPrayerTimesOnce();
    _initFuture = prepareApp();
  }

  Future<Position> determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception("خدمة تحديد الموقع غير مفعلة");
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception("تم رفض صلاحية تحديد الموقع");
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception("صلاحية تحديد الموقع مرفوضة بشكل دائم");
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<bool> prepareApp() async {
    final status = await Permission.location.request();
    late List<Placemark> placemark;
    Coordinates? fallbackCoordinates;

    if (!status.isGranted) {
      throw Exception("يرجى منح صلاحية تحديد الموقع للتطبيق");
    }

    try {
      final position = await determinePosition();
      placemark = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      // احفظ الموقع لاستخدامه لاحقًا
      await prayerController.saveLastLocation();
    } catch (e) {
      // لم يتمكن من تحديد الموقع، جرب استخدام الموقع المحفوظ
      fallbackCoordinates = await prayerController.getLastSavedLocation();
      if (fallbackCoordinates == null) {
        throw Exception("لم نتمكن من تحديد الموقع أو العثور على موقع محفوظ");
      }

      placemark = await placemarkFromCoordinates(
        fallbackCoordinates.latitude,
        fallbackCoordinates.longitude,
      );
    }

    countryLocationText = placemark[0].country ?? "";
    cityLocationText = placemark[0].locality ?? "";

    final data = await prayerController.getPrayerTimes(

    );

    prayerTimesList = [
      {"name": "الفجر", "time": DateFormat('HH:mm').format(data.fajer)},
      {"name": "الظهر", "time": DateFormat('HH:mm').format(data.dhuhr)},
      {"name": "العصر", "time": DateFormat('HH:mm').format(data.asr)},
      {"name": "المغرب", "time": DateFormat('HH:mm').format(data.maghrib)},
      {"name": "العشاء", "time": DateFormat('HH:mm').format(data.isha)},
    ];

    return true;
  }

  Future<void> initEverything() async {
    try {
      final position = await _controller.determinePosition();
      final placemark = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      setState(() {
        countryLocationText = placemark[0].country ?? "";
        cityLocationText = placemark[0].locality ?? "";
      });
    } catch (e) {
      setState(() {
        countryLocationText = "خطأ في تحديد الموقع";
        cityLocationText = "$e";
      });
    }
  }

  Future<void> loadPrayerTimesOnce() async {
    try {
      final data = await prayerController.getPrayerTimes();
      // _prayerTimes = data;
      prayerTimesList = [
        {"name": "الفجر", "time": DateFormat('HH:mm').format(data.fajer)},
        {"name": "الظهر", "time": DateFormat('HH:mm').format(data.dhuhr)},
        {"name": "العصر", "time": DateFormat('HH:mm').format(data.asr)},
        {"name": "المغرب", "time": DateFormat('HH:mm').format(data.maghrib)},
        {"name": "العشاء", "time": DateFormat('HH:mm').format(data.isha)},
      ];
      // setState(() => isLoading = false);
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  int getNextPrayer(List<Map<String, String>> prayerTimes) {
    final timeNow = TimeOfDay.now();
    for (var i = 0; i < prayerTimes.length; i++) {
      final time = prayerTimes[i]['time']!;
      final hour = int.parse(time.split(":")[0]);
      final minute = int.parse(time.split(":")[1]);
      final prayerTime = TimeOfDay(hour: hour, minute: minute);
      if (prayerTime.hour > timeNow.hour ||
          (prayerTime.hour == timeNow.hour &&
              prayerTime.minute > timeNow.minute)) {
        return i;
      }
    }
    return 0;
  }

  Widget prayerCard(String name, String time, bool isNext) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18, right: 12, left: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(36),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
          child: Container(
            height: 76,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(36),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(Icons.volume_up, color: Color(0xffF0F8FF)),
                  isNext
                      ? CountdownTimer(
                        onFinish: () {
                          setState(() {
                            // Your method to update name/time/isNext etc.
                          });
                        },
                      )
                      : Text(""),
                  SizedBox(width: 64),
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "$name",
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            color: Color(0xffF0F8FF),
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "$time",
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            color: Color(0xffF0F8FF),
                            fontWeight: FontWeight.w100,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: _initFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              color: Color(0xff0A2239), // نفس خلفية الـ Scaffold
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                "حدث خطأ: ${snapshot.error}",
                style: TextStyle(color: Colors.red, fontSize: 18),
              ),
            );
          } else {
            return Scaffold(
              backgroundColor: Color(0xff0A2239),
              body: Stack(
                children: [
                  SvgPicture.asset(
                    'assets/Vector.svg',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                  Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(right: 16, top: 89),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  countryLocationText,
                                  style: TextStyle(
                                    color: Color(0xffF0F8FF),
                                    fontFamily: 'Cairo',
                                    fontSize: 38,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  cityLocationText,
                                  style: TextStyle(
                                    color: Color(0xffF0F8FF),
                                    fontFamily: 'Cairo',
                                    fontSize: 24,
                                    fontWeight: FontWeight.w100,
                                  ),
                                ),
                              ],
                            ),
                            Icon(
                              Icons.location_on,
                              color: Color(0xffF0F8FF),
                              size: 42,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 64),
                      if (isLoading)
                        Center(child: CircularProgressIndicator())
                      else
                        Column(
                          children:
                              prayerTimesList.asMap().entries.map((entry) {
                                int i = entry.key;
                                var prayer = entry.value;
                                return prayerCard(
                                  prayer["name"]!,
                                  prayer["time"]!,
                                  i == getNextPrayer(prayerTimesList),
                                );
                              }).toList(),
                        ),
                    ],
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
