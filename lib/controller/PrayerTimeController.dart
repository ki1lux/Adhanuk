import 'package:adhan/adhan.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:myadhan/controller/LocationController.dart';
import 'package:myadhan/model/PrayerTimeModel.dart';

class PrayerTimeController {
  final LocationController _controller = LocationController();
  static const MethodChannel _channel = MethodChannel(
    'com.myadhan/notification',
  );

  Future<Position> getPosition() async {
    Position position = await _controller.determinePosition();
    return position;
  }


  Future<PrayerTimeModel> getPrayerTimes() async {
    try {
      Position position = await getPosition();
      final userCoordinates = Coordinates(
        position.latitude,
        position.longitude,
      );

      final params = CalculationMethod.karachi.getParameters();
      params.madhab = Madhab.shafi;
      final prayerTimes = PrayerTimes.today(userCoordinates, params);
      return PrayerTimeModel(
        fajer: prayerTimes.fajr,
        dhuhr: prayerTimes.dhuhr,
        asr: prayerTimes.asr,
        maghrib: prayerTimes.maghrib,
        isha: prayerTimes.isha,
      );
    } catch (e) {
      throw Exception("Failed to get prayer times: $e");
    }
  }

  Future<void> callNativeAdhanNow(String prayerName, String prayerTime) async {
    try {
      await _channel.invokeMethod('showFullScreenAdhan', {
        'prayerName': prayerName,
        'prayerTime': prayerTime,
      });
    } catch (e) {
      print("Error calling native Adhan: $e");
    }
  }

  



}
