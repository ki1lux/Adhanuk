import 'dart:convert';
import 'dart:ui';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:myadhan/model/PrayerTimeModel.dart';
import 'package:myadhan/prayer_alarm_scheduler.dart';
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

      // save location (same keys the rest of the app uses)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('last_latitude', position.latitude);
      await prefs.setDouble('last_longitude', position.longitude);

      // Get Arabic location names via Nominatim reverse geocoding
      try {
        final geoUri = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?lat=${position.latitude}&lon=${position.longitude}&format=json&addressdetails=1&accept-language=ar',
        );
        final geoResponse = await http.get(
          geoUri,
          headers: {'User-Agent': 'Adhani-App/1.0'},
        );
        if (geoResponse.statusCode == 200) {
          final geoData = json.decode(geoResponse.body);
          final address = geoData['address'] as Map<String, dynamic>?;
          if (address != null) {
            String country = address['country'] as String? ?? '';
            String city = address['city'] as String? 
                ?? address['town'] as String? 
                ?? address['village'] as String? 
                ?? address['state'] as String? 
                ?? '';

            await prefs.setString('country_name', country);
            await prefs.setString('city_name', city);
            _updateLocation(country, city);
          }
        }
      } catch (e) {
        // Fallback to geocoding package if Nominatim fails
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          String country = placemarks[0].country ?? '';
          String city = placemarks[0].locality ?? '';
          await prefs.setString('country_name', country);
          await prefs.setString('city_name', city);
          _updateLocation(country, city);
        }
      }

      // Refresh prayer times with GPS coordinates
      ref.read(prayerTimesProvider.notifier).fetchPrayerTimes(
        lat: position.latitude,
        lng: position.longitude,
      );
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
      final prayerTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
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
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Cairo',
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed:
                  () =>
                      ref.read(prayerTimesProvider.notifier).fetchPrayerTimes(),
              icon: const Icon(Icons.refresh),
              label: const Text(
                'تحديث الصفحة',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
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
            const Text(
              'حدث خطأ',
              style: TextStyle(color: Colors.red, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              '$error',
              style: const TextStyle(color: Colors.red, fontSize: 14),
              textAlign: TextAlign.center,
            ),
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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,  // White icons on Android
        statusBarBrightness: Brightness.dark,        // White icons on iOS
      ),
      child: Scaffold(
      backgroundColor: const Color(0xff0A2239),
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
              _buildLocationHeader(),
              SizedBox(height: MediaQuery.sizeOf(context).height * 0.05),
              ...prayers.asMap().entries.map(
                (e) => _buildPrayerCard(
                  e.value.name,
                  e.value.time,
                  e.key == nextIndex,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildLocationHeader() {
    return Padding(
      padding: EdgeInsets.only(right: 16, left: 48, top: MediaQuery.sizeOf(context).height * 0.1),
      child: InkWell(
        onTap: _showLocationDialog,
        borderRadius: BorderRadius.circular(12),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width * 2 / 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      _countryText,
                      style: const TextStyle(
                        color: Color(0xffF0F8FF),
                        fontFamily: 'Cairo',
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.edit, color: Colors.white54, size: 14),
                      const SizedBox(width: 4),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            _cityText,
                            style: const TextStyle(
                              color: Color(0xffF0F8FF),
                              fontFamily: 'Cairo',
                              fontSize: 24,
                              fontWeight: FontWeight.w100,
                            ),
                            maxLines: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.location_on, color: Color(0xffF0F8FF), size: 42),
          ],
        ),
      ),
    );
  }

  void _showLocationDialog() {
    final cityController = TextEditingController();
    List<Map<String, dynamic>> suggestions = [];
    bool isSearching = false;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (context, primaryAnimation, secondaryAnimation, child) {
        final curve = CurvedAnimation(
          parent: primaryAnimation,
          curve: Curves.easeInOutCubic,
        );
        final scaleAnimation = Tween<double>(
          begin: 0.85,
          end: 1.0,
        ).animate(curve);
        return ScaleTransition(
          scale: scaleAnimation,
          child: FadeTransition(
            opacity: curve,
            child: child,
          ),
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  backgroundColor: const Color(0xFF0E2031),
                  title: const Text(
                    'تغيير الموقع',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w700,
                      fontSize: 24,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  content: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.5,
                    ),
                    child: SizedBox(
                      width: double.maxFinite,
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 24),
                            TextField(
                              controller: cityController,
                              textAlign: TextAlign.right,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'أدخل اسم المدينة (بالإنجليزية)',
                                hintStyle: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 16,
                                ),
                                suffixIcon:
                                    isSearching
                                        ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: Padding(
                                            padding: EdgeInsets.all(12),
                                            child: CircularProgressIndicator(
                                              strokeWidth: 1,
                                              color: Colors.white70,
                                            ),
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
                                    // Use Nominatim API for better city suggestions
                                    final uri = Uri.parse(
                                      'https://nominatim.openstreetmap.org/search?q=$value&format=json&limit=5&addressdetails=1&accept-language=ar',
                                    );
                                    final response = await http.get(
                                      uri,
                                      headers: {'User-Agent': 'AdhanUK-App/1.0'},
                                    );
                                    if (response.statusCode == 200) {
                                      final List<dynamic> data = json.decode(
                                        response.body,
                                      );
                                    final List<Map<String, dynamic>> results =
                                        data
                                            .map(
                                              (item) {
                                                final address = item['address'] as Map<String, dynamic>? ?? {};
                                                final city = address['city'] as String?
                                                    ?? address['town'] as String?
                                                    ?? address['village'] as String?
                                                    ?? address['state'] as String?
                                                    ?? (item['display_name'] as String).split(',').first.trim();
                                                final country = address['country'] as String? ?? '';
                                                return {
                                                  'city': city,
                                                  'country': country,
                                                  'lat': double.parse(item['lat'] as String),
                                                  'lon': double.parse(item['lon'] as String),
                                                };
                                              },
                                            )
                                            .toList();
                                      setDialogState(() {
                                        suggestions = results;
                                        isSearching = false;
                                      });
                                    } else {
                                      setDialogState(() {
                                        suggestions = [];
                                        isSearching = false;
                                      });
                                    }
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
                              const SizedBox(height: 18),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxHeight: 200),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: suggestions.length,
                                  itemBuilder: (context, index) {
                                    final loc = suggestions[index];
                                    final cityName = loc['city'] as String;
                                    final countryName = loc['country'] as String;
                                    return ListTile(
                                      dense: true,
                                      leading: const Icon(
                                        Icons.location_on,
                                        color: Colors.white54,
                                        size: 20,
                                      ),
                                      title: Text(
                                        '$cityName، $countryName',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      onTap: () async {
                                        Navigator.pop(context);
                                        final lat = loc['lat'] as double;
                                        final lon = loc['lon'] as double;
                                        // Save location and names
                                        final prefs =
                                            await SharedPreferences.getInstance();
                                        await prefs.setDouble('last_latitude', lat);
                                        await prefs.setDouble('last_longitude', lon);
                                        await prefs.setString('country_name', countryName);
                                        await prefs.setString('city_name', cityName);

                                        _updateLocation(countryName, cityName);
                                        ref
                                            .read(prayerTimesProvider.notifier)
                                            .fetchPrayerTimes(lat: lat, lng: lon);
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _loadLocation();
                              },
                              icon: const Icon(Icons.my_location),
                              label: const Text(
                                'استخدم GPS',
                                style: TextStyle(fontFamily: 'Cairo'),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(
                                  255,
                                  255,
                                  255,
                                  255,
                                ),
                                foregroundColor: Color(0xff0E2031),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'إلغاء',
                        style: TextStyle(
                          color: Colors.white54,
                          fontFamily: 'Cairo',
                          fontSize: 16,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final city = cityController.text.trim();
                        if (city.isNotEmpty) {
                          Navigator.pop(context);
                          await _searchAndSetLocation(city);
                        }
                      },
                      child: const Text(
                        'بحث',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Cairo',
                          fontSize: 16,
                        ),
                      ),
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

        // Refresh prayer times with manual coordinates
        ref.read(prayerTimesProvider.notifier).fetchPrayerTimes(
          lat: location.latitude,
          lng: location.longitude,
        );
      } else {
        _updateLocation('لم يتم العثور', cityName);
      }
    } catch (e) {
      _updateLocation('خطأ في البحث', cityName);
    }
  }

  Widget _buildPrayerCard(String name, String time, bool isNext) {
    return _AnimatedPrayerCard(
      name: name,
      time: time,
      isNext: isNext,
      isAdhanEnabledFuture: _isAdhanEnabled(name),
      onSoundTap: () => _showSoundDialog(name),
      onToggleAdhan: (enabled) async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('adhan_enabled_$name', enabled);
        setState(() {}); // Refresh parent list
        final prayerTimesAsync = ref.read(prayerTimesProvider);
        if (prayerTimesAsync.hasValue) {
          await PrayerAlarmScheduler.scheduleAllPrayersWithData(
            prayerTimesAsync.value!,
          );
        }
      },
    );
  }


  Future<bool> _isAdhanEnabled(String prayerName) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('adhan_enabled_$prayerName') ?? true;
  }

  void _showSoundDialog(String prayerName) async {
    final prefs = await SharedPreferences.getInstance();
    bool isEnabled = prefs.getBool('adhan_enabled_$prayerName') ?? true;
    String selectedSound =
        prefs.getString('adhan_sound_$prayerName') ?? 'adhan1';

    final audioPlayer = AudioPlayer();
    String? playingSound;

    // Available sounds - add more as you add mp3 files
    final sounds = [
      {'id': 'adhan1', 'name': 'الأذان الأول'},
      {'id': 'adhan2', 'name': 'أذان الثاني'},
      {'id': 'adhan3', 'name': 'أذان الثالث'},
    ];

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (context, primaryAnimation, secondaryAnimation, child) {
        final curve = CurvedAnimation(
          parent: primaryAnimation,
          curve: Curves.easeInOutCubic,
        );
        return ScaleTransition(
          scale: Tween<double>(begin: 0.85, end: 1.0).animate(curve),
          child: FadeTransition(
            opacity: curve,
            child: child,
          ),
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  backgroundColor: const Color(0xFF0E2031),
                  title: Text(
                    'اشعار $prayerName',
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w700,
                      fontSize: 24,
                      
                    ),
                    textAlign: TextAlign.center,
                  ),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Enable/Disable toggle
                        SwitchListTile(
                          title: const Text(
                            'تفعيل الأذان',
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Cairo',
                            ),
                            textAlign: TextAlign.right,
                          ),
                          value: isEnabled,
                          activeColor: const Color(0xFF4DB3E5),
                          onChanged: (value) {
                            setDialogState(() => isEnabled = value);
                          },
                        ),
                        const Divider(color: Colors.white24),
                        // Sound selection
                        const Text(
                          'اختر نغمة الأذان',
                          style: TextStyle(
                            color: Colors.white70,
                            fontFamily: 'Cairo',
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...sounds.map(
                          (sound) => RadioListTile<String>(
                            title: Text(
                              sound['name']!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontFamily: 'Cairo',
                                fontSize: 16,
                              ),
                            ),
                            secondary: IconButton(
                              icon: Icon(
                                playingSound == sound['id']
                                    ? Icons.stop_circle_outlined
                                    : Icons.play_circle_outline,
                                color: const Color(0xFFF0F8FF),
                              ),
                              onPressed: () async {
                                if (playingSound == sound['id']) {
                                  await audioPlayer.stop();
                                  setDialogState(() => playingSound = null);
                                } else {
                                  await audioPlayer.stop();
                                  setDialogState(() => playingSound = sound['id']);
                                  await audioPlayer.play(AssetSource('audio/${sound['id']}.mp3'));
                                  audioPlayer.onPlayerComplete.listen((_) {
                                    setDialogState(() => playingSound = null);
                                  });
                                }
                              },
                            ),
                            value: sound['id']!,
                            groupValue: selectedSound,
                            activeColor: const Color(0xFF4DB3E5),
                            onChanged:
                                isEnabled
                                    ? (value) {
                                      setDialogState(
                                        () => selectedSound = value!,
                                      );
                                    }
                                    : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'إلغاء',
                        style: TextStyle(
                          color: Colors.white54,
                          fontFamily: 'Cairo',
                          fontSize: 16,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        await prefs.setBool(
                          'adhan_enabled_$prayerName',
                          isEnabled,
                        );
                        await prefs.setString(
                          'adhan_sound_$prayerName',
                          selectedSound,
                        );
                        Navigator.pop(context);
                        setState(() {}); // Refresh UI to show icon change

                        // 🔄 Reschedule notifications with new settings
                        final prayerTimesAsync = ref.read(prayerTimesProvider);
                        if (prayerTimesAsync.hasValue) {
                          await PrayerAlarmScheduler.scheduleAllPrayersWithData(
                            prayerTimesAsync.value!,
                          );
                        }
                      },
                      child: const Text(
                        'حفظ',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Cairo',
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
          ),
    ).then((_) {
      // Clean up the player when dialog is closed/dismissed
      audioPlayer.stop();
      audioPlayer.dispose();
    });
  }
}

class _AnimatedPrayerCard extends StatefulWidget {
  final String name;
  final String time;
  final bool isNext;
  final Future<bool> isAdhanEnabledFuture;
  final VoidCallback onSoundTap;
  final ValueChanged<bool> onToggleAdhan;

  const _AnimatedPrayerCard({
    required this.name,
    required this.time,
    required this.isNext,
    required this.isAdhanEnabledFuture,
    required this.onSoundTap,
    required this.onToggleAdhan,
  });

  @override
  State<_AnimatedPrayerCard> createState() => _AnimatedPrayerCardState();
}

class _AnimatedPrayerCardState extends State<_AnimatedPrayerCard> {
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18, right: 12, left: 12),
      child: GestureDetector(
        onTapDown: (_) => setState(() => isPressed = true),
        onTapUp: (_) {
          setState(() => isPressed = false);
          widget.onSoundTap();
        },
        onTapCancel: () => setState(() => isPressed = false),
        child: AnimatedScale(
          scale: isPressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          child: AnimatedOpacity(
            opacity: isPressed ? 0.7 : 1.0,
            duration: const Duration(milliseconds: 150),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(36),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(36),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        FutureBuilder<bool>(
                          future: widget.isAdhanEnabledFuture,
                          builder: (context, snapshot) {
                            final enabled = snapshot.data ?? true;
                            return GestureDetector(
                              onTap: () => widget.onToggleAdhan(!enabled),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Icon(
                                  enabled ? Icons.volume_up : Icons.volume_off,
                                  color: enabled
                                      ? const Color(0xffF0F8FF)
                                      : Colors.white38,
                                ),
                              ),
                            );
                          },
                        ),
                        if (widget.isNext)
                          CountdownTimer(onFinish: () => setState(() {}))
                        else
                          const SizedBox.shrink(),
                        const SizedBox(width: 64),
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                widget.name,
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  color: Color(0xffF0F8FF),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.time,
                                style: const TextStyle(
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
          ),
        ),
      ),
    );
  }
}
