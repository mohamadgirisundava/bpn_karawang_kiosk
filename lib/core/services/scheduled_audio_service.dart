import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart' show sha1;
import 'package:flutter/foundation.dart';

import 'background_audio.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Satu entri agenda audio custom yang diatur admin lewat Loket — mirip
/// konsep jadwal transaksi terjadwal di bank: admin bikin sendiri "jam
/// segini, bunyi audio ini, sekali atau tiap hari".
class _ScheduleEntry {
  final String id;
  final String label;
  final String time; // "HH:mm"
  final String repeatType; // "daily" | "weekly" | "once"
  final String? date; // "YYYY-MM-DD", cuma dipakai kalau repeatType == once
  /// Hari terpilih (1 = Senin ... 7 = Minggu), cuma dipakai kalau
  /// repeatType == weekly. Boleh meloncat, mis. {1, 4}.
  final Set<int> days;
  final String audioUrl;

  _ScheduleEntry({
    required this.id,
    required this.label,
    required this.time,
    required this.repeatType,
    required this.date,
    required this.days,
    required this.audioUrl,
  });

  factory _ScheduleEntry.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return _ScheduleEntry(
      id: doc.id,
      label: data['label'] as String? ?? '',
      time: data['time'] as String? ?? '',
      repeatType: data['repeatType'] as String? ?? 'daily',
      date: data['date'] as String?,
      days: (data['days'] as List<dynamic>? ?? [])
          .map((e) => (e as num).toInt())
          .toSet(),
      audioUrl: data['audioUrl'] as String? ?? '',
    );
  }
}

/// Mainkan audio custom (lagu/rekaman apa saja yang diatur admin) sesuai
/// jadwal jam yang mereka bikin sendiri di Loket — collection
/// `audio_schedules`. Beda dari [AdhanSchedulerService] yang jadwalnya
/// datang dari `prayer_schedule` (waktu sholat, berubah tiap hari); di sini
/// jadwalnya murni jam tetap yang diinput admin sendiri.
class ScheduledAudioService {
  ScheduledAudioService._();
  static final ScheduledAudioService instance = ScheduledAudioService._();

  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  Timer? _ticker;
  List<_ScheduleEntry> _entries = [];
  final Set<String> _playedToday = {}; // "$dateKey:$scheduleId"

  String get _todayKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> start() async {
    BackgroundAudio.register(_player);
    if (_sub != null) return;
    await _player.setReleaseMode(ReleaseMode.stop);

    _sub = FirebaseFirestore.instance
        .collection('audio_schedules')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .listen(
          (snapshot) {
            _entries = snapshot.docs.map(_ScheduleEntry.fromDoc).toList();
          },
          onError: (Object e) =>
              debugPrint('ScheduledAudioService: listen error: $e'),
        );

    _ticker = Timer.periodic(const Duration(seconds: 20), (_) => _tick());
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    _ticker?.cancel();
    _ticker = null;
  }

  Future<void> _tick() async {
    final now = DateTime.now();
    final nowHHmm =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final dateKey = _todayKey;

    for (final entry in _entries) {
      if (entry.time != nowHHmm) continue;
      if (entry.repeatType == 'once' && entry.date != dateKey) continue;
      // Daftar hari kosong sengaja diperlakukan sebagai "nggak pernah",
      // bukan "tiap hari": jadwal weekly tanpa hari terpilih itu belum
      // selesai diisi, dan lebih aman diam daripada bunyi tiap hari.
      if (entry.repeatType == 'weekly' && !entry.days.contains(now.weekday)) {
        continue;
      }

      final playedKey = '$dateKey:${entry.id}';
      if (_playedToday.contains(playedKey)) continue;
      _playedToday.add(playedKey);

      unawaited(_play(entry));
    }
  }

  Future<void> _play(_ScheduleEntry entry) async {
    try {
      final localPath = await _cachedFilePath(entry);
      await _player.stop();
      await _player.play(DeviceFileSource(localPath), volume: 1.0);
      debugPrint(
        'ScheduledAudioService: muter "${entry.label}" (${entry.time}).',
      );
      await _markPlayed(entry);
    } catch (e) {
      debugPrint('ScheduledAudioService: gagal muter "${entry.label}": $e');
    }
  }

  Future<void> _markPlayed(_ScheduleEntry entry) async {
    try {
      final update = <String, dynamic>{
        'lastPlayedAt': DateTime.now().toUtc().toIso8601String(),
      };
      // Jadwal "sekali" nggak akan pernah cocok tanggal lagi setelah ini,
      // tapi dimatiin eksplisit biar keliatan jelas statusnya di Admin
      // (bukan cuma nunggu tanggal nggak pernah match lagi selamanya).
      if (entry.repeatType == 'once') {
        update['isActive'] = false;
      }
      await FirebaseFirestore.instance
          .collection('audio_schedules')
          .doc(entry.id)
          .update(update);
    } catch (e) {
      debugPrint(
        'ScheduledAudioService: gagal update status "${entry.label}": $e',
      );
    }
  }

  /// Download sekali & cache lokal per URL (nama file dari hash URL-nya),
  /// biar pemutaran nggak bergantung koneksi/latency Google Drive persis
  /// di detik jadwalnya bunyi. Re-download otomatis kalau file cache-nya
  /// somehow kehapus.
  Future<String> _cachedFilePath(_ScheduleEntry entry) async {
    final dir = await getApplicationSupportDirectory();
    final hash = sha1.convert(entry.audioUrl.codeUnits).toString();
    final file = File('${dir.path}/scheduled_audio_$hash.mp3');

    if (await file.exists() && await file.length() > 0) {
      return file.path;
    }

    final response = await http.get(Uri.parse(entry.audioUrl));
    if (response.statusCode != 200) {
      throw Exception('Download audio gagal, status ${response.statusCode}');
    }
    await file.writeAsBytes(response.bodyBytes);
    return file.path;
  }
}
