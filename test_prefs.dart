import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final keys = prefs.getKeys();
  for (var key in keys) {
    if (key.startsWith('adhan_sound_') || key.startsWith('prayer_')) {
      print('PREF: \$key = \${prefs.get(key)}');
    }
  }
}
