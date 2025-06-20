import 'package:adhan/adhan.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:myadhan/controller/LocationController.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:myadhan/controller/LocationController.dart';
import 'package:myadhan/model/PrayerTimeModel.dart';

class PrayerTimeController {
  final LocationController _controller = LocationController();
  Future<Position> getPosition() async {
    Position position = await _controller.determinePosition();
    return position;
  }

// Future<Map<String, String>> getLocationDetails() async {
//     try {
//       Position position = await _controller.determinePosition();
//       List<Placemark> placemarks = await placemarkFromCoordinates(
//         position.latitude,
//         position.longitude,
//       );
//       Placemark placemark = placemarks[0];
//       return {
//         "country": placemark.country ?? "not detected",
//         "city": placemark.locality ?? "not detected",
//       };
//     } catch (e) {
//       throw Exception("Location error: $e");
//     }
//   }

  Future<PrayerTimeModel> getPrayerTimes() async {
    try{
      Position position = await getPosition();
    final batnaCoordinates = Coordinates(position.latitude, position.longitude);

    final params = CalculationMethod.karachi.getParameters();
    params.madhab = Madhab.shafi;
    final prayerTimes = PrayerTimes.today(batnaCoordinates, params);
    return PrayerTimeModel(
      fajer: prayerTimes.fajr,
      dhuhr: prayerTimes.dhuhr,
      asr: prayerTimes.asr,
      maghrib: prayerTimes.maghrib,
      isha: prayerTimes.isha,
    );
    }catch(e){
      throw Exception("Failed to get prayer times: $e");
    }
    
  }
}
