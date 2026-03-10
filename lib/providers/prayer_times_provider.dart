import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myadhan/controller/LocationController.dart';
import 'package:myadhan/model/PrayerTimeModel.dart';
import 'package:myadhan/services/prayer_times_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for the API service instance
final prayerTimesApiServiceProvider = Provider<PrayerTimesApiService>((ref) {
  return PrayerTimesApiService();
});

/// Provider for the location controller
final locationControllerProvider = Provider<LocationController>((ref) {
  return LocationController();
});

/// StateNotifier for managing prayer times state with loading/success/error
class PrayerTimesNotifier extends StateNotifier<AsyncValue<PrayerTimeModel>> {
  final PrayerTimesApiService _apiService;
  final LocationController _locationController;

  PrayerTimesNotifier(this._apiService, this._locationController)
      : super(const AsyncValue.loading());
  // Note: fetchPrayerTimes() is called from main.dart after permissions are granted

  /// Parses time string "HH:mm" or "HH:mm (TZ)" to DateTime for today
  DateTime _parseTimeString(String timeStr) {
    final cleanTime = timeStr.split(' ').first;
    final parts = cleanTime.split(':');
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
  }

  /// Gets coordinates from GPS or saved location
  Future<({double lat, double lng})> _getCoordinates() async {
    final prefs = await SharedPreferences.getInstance();
    
    try {
      final position = await _locationController.determinePosition()
          .timeout(const Duration(seconds: 10));
      
      // Cache location for offline use
      await prefs.setDouble('last_latitude', position.latitude);
      await prefs.setDouble('last_longitude', position.longitude);
      
      return (lat: position.latitude, lng: position.longitude);
    } catch (e) {
      print('⚠️ GPS failed: $e');
      
      // Fallback to cached location
      final savedLat = prefs.getDouble('last_latitude');
      final savedLng = prefs.getDouble('last_longitude');
      
      if (savedLat != null && savedLng != null) {
        print('📍 Using cached location');
        return (lat: savedLat, lng: savedLng);
      }
      throw Exception('لا يوجد موقع. يرجى تفعيل GPS أو البحث عن مدينة.');
    }
  }

  /// Fetches prayer times from API.
  /// If [lat] and [lng] are provided, uses them directly (manual location).
  /// Otherwise, tries GPS then falls back to cached location.
  Future<void> fetchPrayerTimes({double? lat, double? lng}) async {
    print('🕌 fetchPrayerTimes called');
    state = const AsyncValue.loading();

    try {
      double latitude;
      double longitude;

      if (lat != null && lng != null) {
        // Manual location — use directly, skip GPS
        latitude = lat;
        longitude = lng;
        print('📍 Using manual location: $latitude, $longitude');
      } else {
        // Auto location — try GPS, fallback to cached
        print('📍 Getting coordinates...');
        final coords = await _getCoordinates();
        latitude = coords.lat;
        longitude = coords.lng;
        print('📍 Got coordinates: $latitude, $longitude');
      }
      
      // Read user's preferred calculation method (default: 19 = Algeria)
      final prefs = await SharedPreferences.getInstance();
      final method = prefs.getInt('calculation_method') ?? 19;
      
      final response = await _apiService.fetchPrayerTimes(
        latitude: latitude,
        longitude: longitude,
        method: method,
      );
      print('✅ Got prayer times from API (method=$method)');

      final model = PrayerTimeModel(
        fajer: _parseTimeString(response.fajr),
        dhuhr: _parseTimeString(response.dhuhr),
        asr: _parseTimeString(response.asr),
        maghrib: _parseTimeString(response.maghrib),
        isha: _parseTimeString(response.isha),
        dateOnHijri: response.dateOnHijri.toString(),
      );

      // Cache Hijri date to SharedPreferences
      await prefs.setString('cached_hijri_date', model.dateOnHijri);

      state = AsyncValue.data(model);
    } catch (e, st) {
      print('❌ Error fetching prayer times: $e');
      state = AsyncValue.error(e, st);
    }
  }

  

  /// Refresh prayer times
  Future<void> refresh() => fetchPrayerTimes();
}

/// Provider for prayer times with loading, success, and error states
final prayerTimesProvider =
    StateNotifierProvider<PrayerTimesNotifier, AsyncValue<PrayerTimeModel>>((ref) {
  return PrayerTimesNotifier(
    ref.watch(prayerTimesApiServiceProvider),
    ref.watch(locationControllerProvider),
  );
});
