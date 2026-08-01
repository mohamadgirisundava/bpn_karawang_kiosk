import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

// Field jadwal sholat yang beneran punya adzan — nggak termasuk imsak,
// terbit, dan dhuha (itu bukan waktu adzan).
const List<String> _adhanFields = [
  'subuh',
  'dzuhur',
  'ashar',
  'maghrib',
  'isya',
];

/// Putar adzan asli (`assets/audio/adhan.mp3`) otomatis pas waktu sholat
/// tiba, berdasarkan jadwal di collection `prayer_schedule` (sama yang
/// dipakai app Display — lihat CLAUDE.md-nya). Kiosk cuma jadi konsumen
/// pasif di sini: kalau jadwal hari ini belum ke-sync, adzan otomatis
/// nggak bunyi hari itu (bukan tanggung jawab kiosk buat live-fetch/
/// self-heal, itu udah ditangani app Display).
class AdhanSchedulerService {
  AdhanSchedulerService._();
  static final AdhanSchedulerService instance = AdhanSchedulerService._();

  final AudioPlayer _player = AudioPlayer();
  Timer? _ticker;
  Map<String, String>? _todaySchedule; // field -> "HH:mm"
  String? _scheduleDateKey;
  final Set<String> _playedToday = {}; // "$dateKey:$field"

  String get _todayKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> start() async {
    if (_ticker != null) return;
    await _player.setReleaseMode(ReleaseMode.stop);
    await _refreshScheduleIfNeeded();
    _ticker = Timer.periodic(const Duration(seconds: 20), (_) => _tick());
  }

  Future<void> stop() async {
    _ticker?.cancel();
    _ticker = null;
  }

  Future<void> _refreshScheduleIfNeeded() async {
    final dateKey = _todayKey;
    if (_scheduleDateKey == dateKey && _todaySchedule != null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('prayer_schedule')
          .doc(dateKey)
          .get();
      if (!doc.exists) {
        debugPrint(
          'AdhanSchedulerService: jadwal $dateKey belum ada di prayer_schedule.',
        );
        return;
      }
      final data = doc.data() ?? {};
      _todaySchedule = {
        for (final field in _adhanFields)
          if (data[field] is String) field: data[field] as String,
      };
      _scheduleDateKey = dateKey;
      _playedToday.removeWhere((key) => !key.startsWith('$dateKey:'));
    } catch (e) {
      debugPrint('AdhanSchedulerService: gagal ambil jadwal: $e');
    }
  }

  Future<void> _tick() async {
    await _refreshScheduleIfNeeded();
    final schedule = _todaySchedule;
    if (schedule == null) return;

    final now = DateTime.now();
    final nowHHmm =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final dateKey = _todayKey;

    for (final entry in schedule.entries) {
      if (entry.value != nowHHmm) continue;
      final playedKey = '$dateKey:${entry.key}';
      if (_playedToday.contains(playedKey)) continue;
      _playedToday.add(playedKey);
      unawaited(_playAdhan());
    }
  }

  Future<void> _playAdhan() async {
    try {
      await _player.stop();
      await _player.play(AssetSource('audio/adhan.mp3'), volume: 1.0);
    } catch (e) {
      debugPrint('AdhanSchedulerService: gagal muter adzan: $e');
    }
  }

  /// Dipanggil dari tombol tes manual — muter langsung tanpa mengubah
  /// state jadwal/dedupe otomatis.
  Future<void> playTest() => _playAdhan();
}
