import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:myadhan/providers/prayer_times_provider.dart';
import 'package:myadhan/view/AnalogClockView.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class AdhanScreen extends ConsumerStatefulWidget {

  const AdhanScreen({super.key});

  @override
  ConsumerState<AdhanScreen> createState() => _adhanScreen();
}

class _adhanScreen extends ConsumerState<AdhanScreen>{
  @override
  Widget build(BuildContext context) {
    final prayerTimesAsync = ref.watch(prayerTimesProvider);

  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.white,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  ));

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
              
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (data) => Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  // decoration: BoxDecoration(
                  //   color: const Color.fromARGB(255, 36, 100, 239).withValues(alpha: 0.08),
                  //   borderRadius: BorderRadius.circular(20),
                  // ),
                  
                  child: Text(
                    data.dateOnHijri,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                      color: Color.fromARGB(255, 255, 255, 255),
                      fontFamily: 'Cairo',
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
