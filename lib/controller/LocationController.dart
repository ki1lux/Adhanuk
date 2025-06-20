import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationController {
  Future<Position> determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location service are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are dendied.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<Map<String, String>> getLocationDetails() async {
    try {
      Position position = await determinePosition();
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      Placemark placemark = placemarks[0];
      return {
        "country": placemark.country ?? "not detected",
        "city": placemark.locality ?? "not detected",
      };
    } catch (e) {
      throw Exception("Location error: $e");
    }
  }
}
