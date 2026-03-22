import 'package:adhan/adhan.dart';
import 'package:geolocator/geolocator.dart';
import 'package:myadhan/controller/LocationController.dart';
import 'package:myadhan/model/PrayerTimeModel.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrayerTimeController {
  final LocationController _controller = LocationController();

  Future<Position> getPosition() async {
    Position position = await _controller.determinePosition();
    return position;
  }

  Future<PrayerTimeModel> getPrayerTimes() async {
    Coordinates? userCoordinates;

    try {
      Position position = await getPosition();
      userCoordinates = Coordinates(position.latitude, position.longitude);
      await saveLastLocation();
    } catch (e) {
      print("Failed to get current location, trying saved one: $e");
      userCoordinates = await getLastSavedLocation();

      if (userCoordinates == null) {
        throw Exception("No saved location found.");
      }
    }

    final params = CalculationMethod.karachi.getParameters();
    params.madhab = Madhab.shafi;
    final prayerTimes = PrayerTimes.today(userCoordinates, params);

    return PrayerTimeModel(
      fajer: prayerTimes.fajr,
      dhuhr: prayerTimes.dhuhr,
      asr: prayerTimes.asr,
      maghrib: prayerTimes.maghrib,
      isha: prayerTimes.isha,
      dateOnHijri: '',
    );
  }

  Future<void> saveLastLocation() async {
    Position position = await getPosition();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('last_latitude', position.latitude);
    await prefs.setDouble('last_longitude', position.longitude);
  }

  Future<Coordinates?> getLastSavedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final latitude = prefs.getDouble('last_latitude');
    final longitude = prefs.getDouble('last_longitude');
    if (latitude != null && longitude != null) {
      return Coordinates(latitude, longitude);
    } else {
      return null;
    }
  }

}
