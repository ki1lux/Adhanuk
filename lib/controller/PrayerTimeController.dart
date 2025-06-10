import 'package:adhan/adhan.dart';
import 'package:myadhan/model/PrayerTimeModel.dart';

class PrayerTimeController {
  PrayerTimeModel getPrayerTimes() {
    final batnaCoordinates = Coordinates(35.5559, 6.1741);

    final params = CalculationMethod.karachi.getParameters();
    params.madhab = Madhab.hanafi;
    final prayerTimes = PrayerTimes.today(batnaCoordinates, params);
    return PrayerTimeModel(
      fajer: prayerTimes.fajr,
      dhuhr: prayerTimes.dhuhr,
      asr: prayerTimes.asr,
      maghrib: prayerTimes.maghrib,
      isha: prayerTimes.isha,
    );
  }
}
