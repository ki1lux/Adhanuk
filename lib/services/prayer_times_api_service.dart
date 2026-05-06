import 'dart:convert';
import 'package:http/http.dart' as http;

/// Response model for the Aladhan API timings
class AladhanApiResponse {
  final String fajr;
  final String dhuhr;
  final String asr;
  final String maghrib;
  final String isha;
  final String dateOnHijri;

  const AladhanApiResponse({
    required this.fajr,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.dateOnHijri,
  });

  static String _addMinutes(String timeStr, int minutes) {
    try {
      final cleanTime = timeStr.split(' ').first;
      final parts = cleanTime.split(':');
      var hr = int.parse(parts[0]);
      var min = int.parse(parts[1]);
      
      min += minutes;
      if (min >= 60) {
        hr += (min ~/ 60);
        min = min % 60;
      }
      if (hr >= 24) hr = hr % 24;
      
      return '${hr.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}';
    } catch (e) {
      return timeStr.split(' ').first;
    }
  }

  factory AladhanApiResponse.fromJson(Map<String, dynamic> json) {
    final timings = json['data']['timings'] as Map<String, dynamic>;
    final date = json['data']['date']['hijri'];
    final hijriStr = '${date['day']} ${date['month']['ar']} ${date['year']}';
    return AladhanApiResponse(
      fajr: _addMinutes(timings['Fajr'] as String, 1),
      dhuhr: _addMinutes(timings['Dhuhr'] as String, 1),
      asr: _addMinutes(timings['Asr'] as String, 2),
      maghrib: _addMinutes(timings['Maghrib'] as String, 4),
      isha: _addMinutes(timings['Isha'] as String, 3),
      dateOnHijri: hijriStr,
    );
  }
}

/// Service for fetching prayer times from the Aladhan API
/// API Docs: https://aladhan.com/prayer-times-api
class PrayerTimesApiService {
  static const _baseUrl = 'https://api.aladhan.com/v1/timings';
  static const _timeout = Duration(seconds: 20);

  final http.Client _client;

  PrayerTimesApiService({http.Client? client})
    : _client = client ?? http.Client();

  /// Fetches prayer times for the given coordinates
  /// [method] 19 = Algeria
  /// [school] 0 = Shafi
  Future<AladhanApiResponse> fetchPrayerTimes({
    required double latitude,
    required double longitude,
    int method = 19,
    int school = 0,
    DateTime? targetDate,
  }) async {
    final now = targetDate ?? DateTime.now();
    final dateStr = '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}';
    final uri = Uri.parse(
      '$_baseUrl/$dateStr?latitude=$latitude&longitude=$longitude&method=$method&school=$school',
    );

    final response = await _client.get(uri).timeout(_timeout);

    if (response.statusCode != 200) {
      throw Exception('API request failed: ${response.statusCode}');
    }

    final jsonData = json.decode(response.body) as Map<String, dynamic>;

    if (jsonData['code'] != 200) {
      throw Exception('API error: ${jsonData['status']}');
    }

    return AladhanApiResponse.fromJson(jsonData);
  }
}

