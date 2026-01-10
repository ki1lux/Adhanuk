import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:myadhan/model/PrayerTimeModel.dart';
import 'package:myadhan/providers/prayer_times_provider.dart';
import 'package:myadhan/view/CountDown.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrayerTimeScreen extends ConsumerStatefulWidget {
  const PrayerTimeScreen({super.key});

  @override
  ConsumerState<PrayerTimeScreen> createState() => _PrayerTimeState();
}

class _PrayerTimeState extends ConsumerState<PrayerTimeScreen> {
  String _countryText = 'الموقع...';
  String _cityText = '';

@override
void initState() {
  super.initState();
  _loadSavedLocation();
}

Future<void> _loadLocation() async {
  try {

    final position = await Geolocator.getCurrentPosition();

    // save location
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('lat', position.latitude);
    await prefs.setDouble('lon', position.longitude);

    // converting coordinates to country and city name
    final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
    
    if (placemarks.isNotEmpty) {
      String country = placemarks[0].country ?? '';
      String city = placemarks[0].locality ?? '';
      
      // save names of country and city for quick access
      await prefs.setString('country_name', country);
      await prefs.setString('city_name', city);

      _updateLocation(country, city);
    }
  } catch (e) {
    print("Error: $e");
  }
}

// set saved location if it exist
Future<void> _loadSavedLocation() async {
  final prefs = await SharedPreferences.getInstance();
  String? savedCountry = prefs.getString('country_name');
  String? savedCity = prefs.getString('city_name');

  if (savedCountry != null) {
    _updateLocation(savedCountry, savedCity ?? '');
  } else {
    // if location not available , search for it
    _loadLocation();
  }
}

  void _updateLocation(String country, String city) {
    if (mounted) {
      setState(() {
        _countryText = country;
        _cityText = city;
      });
    }
  }

  int _getNextPrayerIndex(List<({String name, String time})> prayers) {
    final now = TimeOfDay.now();
    for (int i = 0; i < prayers.length; i++) {
      final parts = prayers[i].time.split(':');
      final prayerTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      if (prayerTime.hour > now.hour ||
          (prayerTime.hour == now.hour && prayerTime.minute > now.minute)) {
        return i;
      }
    }
    return 0;
  }

  List<({String name, String time})> _buildPrayersList(PrayerTimeModel data) {
    return [
      (name: 'الفجر', time: DateFormat('HH:mm').format(data.fajer)),
      (name: 'الظهر', time: DateFormat('HH:mm').format(data.dhuhr)),
      (name: 'العصر', time: DateFormat('HH:mm').format(data.asr)),
      (name: 'المغرب', time: DateFormat('HH:mm').format(data.maghrib)),
      (name: 'العشاء', time: DateFormat('HH:mm').format(data.isha)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final prayerTimesAsync = ref.watch(prayerTimesProvider);

    return Scaffold(
      body: prayerTimesAsync.when(
        loading: () => _buildLoadingState(),
        error: (error, _) => _buildErrorState(error),
        data: (data) => _buildSuccessState(data),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      color: const Color(0xff0A2239),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 24),
            const Text(
              'جاري التحميل...',
              style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.read(prayerTimesProvider.notifier).fetchPrayerTimes(),
              icon: const Icon(Icons.refresh),
              label: const Text('تحديث الصفحة', style: TextStyle(fontFamily: 'Cairo')),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white24,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Container(
      color: const Color(0xff0A2239),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('حدث خطأ', style: TextStyle(color: Colors.red, fontSize: 18)),
            const SizedBox(height: 8),
            Text('$error', style: const TextStyle(color: Colors.red, fontSize: 14), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(prayerTimesProvider.notifier).refresh(),
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessState(PrayerTimeModel data) {
    final prayers = _buildPrayersList(data);
    final nextIndex = _getNextPrayerIndex(prayers);

    return Scaffold(
      backgroundColor: const Color(0xff0A2239),
      body: Stack(
        children: [
          SvgPicture.asset('assets/Vector.svg', fit: BoxFit.cover, width: double.infinity, height: double.infinity),
          Column(
            children: [
              _buildLocationHeader(),
              const SizedBox(height: 64),
              ...prayers.asMap().entries.map((e) => _buildPrayerCard(e.value.name, e.value.time, e.key == nextIndex)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationHeader() {
    return Padding(
      padding: const EdgeInsets.only(right: 16, top: 89),
      child: InkWell(
        onTap: _showLocationDialog,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_countryText, style: const TextStyle(
                  color: Color(0xffF0F8FF), fontFamily: 'Cairo', fontSize: 38, fontWeight: FontWeight.bold,
                )),
                Row(
                  children: [
                    const Icon(Icons.edit, color: Colors.white54, size: 14),
                    const SizedBox(width: 4),
                    Text(_cityText, style: const TextStyle(
                      color: Color(0xffF0F8FF), fontFamily: 'Cairo', fontSize: 24, fontWeight: FontWeight.w100,
                    )),
                  ],
                ),
              ],
            ),
            const Icon(Icons.location_on, color: Color(0xffF0F8FF), size: 42),
          ],
        ),
      ),
    );
  }

  void _showLocationDialog() {
    final cityController = TextEditingController();
    List<Location> suggestions = [];
    bool isSearching = false;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF2D4356),
          title: const Text(
            'تغيير الموقع',
            style: TextStyle(color: Colors.white, fontFamily: 'Cairo'),
            textAlign: TextAlign.right,
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: cityController,
                  textAlign: TextAlign.right,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'أدخل اسم المدينة (بالإنجليزية)',
                    hintStyle: const TextStyle(color: Colors.white54),
                    suffixIcon: isSearching 
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54),
                            ),
                          )
                        : null,
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white54),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                  onChanged: (value) async {
                    if (value.length >= 3) {
                      setDialogState(() => isSearching = true);
                      try {
                        final results = await locationFromAddress(value);
                        setDialogState(() {
                          suggestions = results.take(5).toList();
                          isSearching = false;
                        });
                      } catch (_) {
                        setDialogState(() {
                          suggestions = [];
                          isSearching = false;
                        });
                      }
                    } else {
                      setDialogState(() => suggestions = []);
                    }
                  },
                ),
                if (suggestions.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 150),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: suggestions.length,
                      itemBuilder: (context, index) {
                        final loc = suggestions[index];
                        return FutureBuilder<List<Placemark>>(
                          future: placemarkFromCoordinates(loc.latitude, loc.longitude),
                          builder: (context, snapshot) {
                            final name = snapshot.hasData && snapshot.data!.isNotEmpty
                                ? '${snapshot.data![0].locality ?? ''}, ${snapshot.data![0].country ?? ''}'
                                : '${loc.latitude.toStringAsFixed(2)}, ${loc.longitude.toStringAsFixed(2)}';
                            return ListTile(
                              dense: true,
                              leading: const Icon(Icons.location_on, color: Colors.white54, size: 20),
                              title: Text(
                                name,
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                              ),
                              onTap: () async {
                                Navigator.pop(context);
                                // Save and use this location
                                final prefs = await SharedPreferences.getInstance();
                                await prefs.setDouble('last_latitude', loc.latitude);
                                await prefs.setDouble('last_longitude', loc.longitude);
                                
                                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                                  _updateLocation(
                                    snapshot.data![0].country ?? '',
                                    snapshot.data![0].locality ?? '',
                                  );
                                }
                                ref.read(prayerTimesProvider.notifier).fetchPrayerTimes();
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _loadLocation();
                  },
                  icon: const Icon(Icons.my_location),
                  label: const Text('استخدم GPS', style: TextStyle(fontFamily: 'Cairo')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white24,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء', style: TextStyle(color: Colors.white54, fontFamily: 'Cairo')),
            ),
            TextButton(
              onPressed: () async {
                final city = cityController.text.trim();
                if (city.isNotEmpty) {
                  Navigator.pop(context);
                  await _searchAndSetLocation(city);
                }
              },
              child: const Text('بحث', style: TextStyle(color: Colors.white, fontFamily: 'Cairo')),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _searchAndSetLocation(String cityName) async {
    setState(() {
      _countryText = 'جاري البحث...';
      _cityText = cityName;
    });

    try {
      // Search for city coordinates using geocoding
      final locations = await locationFromAddress(cityName);
      if (locations.isNotEmpty) {
        final location = locations.first;
        
        // Save to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble('last_latitude', location.latitude);
        await prefs.setDouble('last_longitude', location.longitude);
        await prefs.setString('manual_city', cityName);
        
        // Get place name
        final placemarks = await placemarkFromCoordinates(
          location.latitude,
          location.longitude,
        );
        
        if (placemarks.isNotEmpty) {
          _updateLocation(
            placemarks[0].country ?? cityName,
            placemarks[0].locality ?? '',
          );
        } else {
          _updateLocation(cityName, '');
        }
        
        // Refresh prayer times
        ref.read(prayerTimesProvider.notifier).fetchPrayerTimes();
      } else {
        _updateLocation('لم يتم العثور', cityName);
      }
    } catch (e) {
      _updateLocation('خطأ في البحث', cityName);
    }
  }

  Widget _buildPrayerCard(String name, String time, bool isNext) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18, right: 12, left: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(36),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
          child: Container(
            height: 76,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(36),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.volume_up, color: Color(0xffF0F8FF)),
                  if (isNext) CountdownTimer(onFinish: () => setState(() {})) else const SizedBox.shrink(),
                  const SizedBox(width: 64),
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(name, style: const TextStyle(
                          fontFamily: 'Cairo', color: Color(0xffF0F8FF), fontWeight: FontWeight.w500, fontSize: 16,
                        )),
                        const SizedBox(height: 2),
                        Text(time, style: const TextStyle(
                          fontFamily: 'Cairo', color: Color(0xffF0F8FF), fontWeight: FontWeight.w100, fontSize: 14,
                        )),
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
}
