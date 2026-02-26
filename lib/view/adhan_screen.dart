import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:myadhan/providers/prayer_times_provider.dart';
import 'package:myadhan/view/AnalogClockView.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdhanScreen extends ConsumerStatefulWidget {
  const AdhanScreen({super.key});

  @override
  ConsumerState<AdhanScreen> createState() => _adhanScreen();
}

class _adhanScreen extends ConsumerState<AdhanScreen> {
  String _cachedHijri = '';

  @override
  void initState() {
    super.initState();
    _loadCachedHijri();
  }

  Future<void> _loadCachedHijri() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('cached_hijri_date') ?? '';
    print("❤️ date hejri :$cached");
    if (cached.isNotEmpty && mounted) {
      setState(() => _cachedHijri = cached);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prayerTimesAsync = ref.watch(prayerTimesProvider);

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      body: Stack(
        children: [
          Container(color: Color(0xff0A2239)),
          SvgPicture.asset(
            'assets/Vector.svg',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          Positioned(
            top: -200,
            left: -100,
            right: -100,
            child: Container(
              height: 600,
              decoration: const BoxDecoration(
                color: Color(0xFFF0F8FF),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(child: Analogclockview()),

          Positioned(
            top: 550,
            left: 0,
            right: 0,
            child: prayerTimesAsync.when(
              loading: () => _buildHijriText(_cachedHijri),
              error: (_, __) => _buildHijriText(_cachedHijri),
              data: (data) {
                // Update cache when fresh data arrives
                print("🩵 new date : $data");
                if (data.dateOnHijri.isNotEmpty &&
                    data.dateOnHijri != _cachedHijri) {
                  _cachedHijri = data.dateOnHijri;
                  SharedPreferences.getInstance().then((prefs) {
                    prefs.setString('cached_hijri_date', data.dateOnHijri);
                  });
                }
                return _buildHijriText(data.dateOnHijri);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHijriText(String text) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Text(
          text,
          textDirection: TextDirection.rtl,
          style: const TextStyle(
            color: Color.fromARGB(255, 255, 255, 255),
            fontFamily: 'Cairo',
            fontSize: 22,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
