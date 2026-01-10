import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:myadhan/controller/PrayerTimeController.dart';
import 'package:myadhan/model/PrayerTimeModel.dart';
import 'package:myadhan/providers/prayer_times_provider.dart';

class CountdownTimer extends ConsumerStatefulWidget {
  final VoidCallback onFinish;

  const CountdownTimer({required this.onFinish, super.key});

  @override
  ConsumerState<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends ConsumerState<CountdownTimer> {
  static const _iqamaDelay = Duration(minutes: 1);
  static const _textStyle = TextStyle(fontWeight: FontWeight.bold, fontSize: 16);

  final _controller = PrayerTimeController();
  Timer? _timer;
  Duration _remaining = Duration.zero;
  Duration _countUp = Duration.zero;
  bool _isAdhanPhase = true;
  String? _lastPlayedPrayer;
  DateTime? _targetTime;
  DateTime? _iqamaStartTime;
  String? _nextPrayerName;
  String? _prayerTime;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown(PrayerTimeModel data) {
    _timer?.cancel();

    final prayers = [
      (name: 'الفجر', time: data.fajer),
      (name: 'الظهر', time: data.dhuhr),
      (name: 'العصر', time: data.asr),
      (name: 'المغرب', time: data.maghrib),
      (name: 'العشاء', time: data.isha),
    ];

    final now = DateTime.now();
    final nextIndex = _findNextPrayerIndex(prayers, now);
    final next = prayers[nextIndex];
    
    _nextPrayerName = next.name;
    _prayerTime = DateFormat('HH:mm').format(next.time);
    _targetTime = _getNextPrayerTime(next.time, now);
    _isAdhanPhase = true;
    _iqamaStartTime = null;
    _countUp = Duration.zero;
    _updateRemaining();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _updateRemaining();
        _handlePhaseTransition();
      });
    });
  }

  void _updateRemaining() {
    if (_targetTime != null) {
      _remaining = _targetTime!.difference(DateTime.now());
    }
  }

  void _handlePhaseTransition() {
    if (_isAdhanPhase && _remaining.inSeconds <= 0 && _lastPlayedPrayer != _nextPrayerName) {
      _isAdhanPhase = false;
      _lastPlayedPrayer = _nextPrayerName;
      _controller.callNativeAdhanNow(_nextPrayerName!, _prayerTime!);
      _iqamaStartTime = DateTime.now();
      _countUp = Duration.zero;
    } else if (!_isAdhanPhase && _iqamaStartTime != null) {
      _countUp = DateTime.now().difference(_iqamaStartTime!);
      if (_countUp >= _iqamaDelay) {
        _timer?.cancel();
        widget.onFinish();
        ref.read(prayerTimesProvider).whenData(_startCountdown);
      }
    }
  }

  int _findNextPrayerIndex(List<({String name, DateTime time})> prayers, DateTime now) {
    for (int i = 0; i < prayers.length; i++) {
      if (prayers[i].time.isAfter(now)) return i;
    }
    return 0;
  }

  DateTime _getNextPrayerTime(DateTime prayerTime, DateTime now) {
    final candidate = DateTime(now.year, now.month, now.day, prayerTime.hour, prayerTime.minute);
    return candidate.isBefore(now) ? candidate.add(const Duration(days: 1)) : candidate;
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(d.inHours)}:${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}';
  }

  @override
  Widget build(BuildContext context) {
    return ref.watch(prayerTimesProvider).when(
      loading: () => Text('00:00:00', style: _textStyle.copyWith(color: const Color(0xffF0F8FF))),
      error: (_, __) => Text('--:--:--', style: _textStyle.copyWith(color: Colors.red)),
      data: (data) {
        if (_targetTime == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _startCountdown(data));
        }
        return Text(
          _formatDuration(_isAdhanPhase ? _remaining : _countUp),
          style: _textStyle.copyWith(color: _isAdhanPhase ? const Color(0xffF0F8FF) : Colors.red),
        );
      },
    );
  }
}
