import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'background_audio.dart';

import '../../injection.dart';

/// Jenis suara yang bisa diputar di luar panggilan antrian.
enum CeremonyAudio { adzan, indonesiaRaya }

String _keyOf(CeremonyAudio a) =>
    a == CeremonyAudio.adzan ? 'adzan' : 'indonesia_raya';

/// Pemutar Indonesia Raya (terjadwal) + penerima permintaan uji suara dari
/// Aplikasi Loket.
///
/// Semua suara sistem ini keluar dari KIOSK — Display TV nggak punya
/// speaker. Polanya sama seperti panggilan antrian: pemicunya bisa dari
/// Admin/Loket, tapi yang bunyi selalu kiosk.
///
/// Indonesia Raya sebelumnya dijadwalkan di app Display, jadi praktis nggak
/// pernah kedengaran siapa pun.
class CeremonyAudioService {
  CeremonyAudioService._();
  static final CeremonyAudioService instance = CeremonyAudioService._();

  final AudioPlayer _player = AudioPlayer();
  Timer? _ticker;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _testSub;

  /// Sudah diputar hari ini atau belum — "YYYY-M-D" terakhir.
  String? _playedDate;

  /// Permintaan uji yang lebih tua dari ini diabaikan, biar kiosk yang baru
  /// dinyalakan nggak memutar ulang permintaan kemarin.
  static const Duration _maxTestAge = Duration(seconds: 60);

  String get _todayKey {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  Future<void> start() async {
    if (_ticker != null) return;
    await _player.setReleaseMode(ReleaseMode.stop);
    // Didaftarkan biar volumenya otomatis dikecilkan waktu ada
    // panggilan antrian — lihat BackgroundAudio.
    BackgroundAudio.register(_player);
    _ticker = Timer.periodic(const Duration(seconds: 20), (_) => _tick());
    _listenForTestRequests();
  }

  Future<void> stop() async {
    _ticker?.cancel();
    _ticker = null;
    await _testSub?.cancel();
    _testSub = null;
  }

  /// Putar sekarang juga — dipakai uji manual dari Admin.
  Future<void> play(CeremonyAudio audio) async {
    try {
      if (audio == CeremonyAudio.adzan) {
        await _player.play(AssetSource('audio/adhan.mp3'), volume: 1.0);
        return;
      }

      // BPN boleh menyediakan rekaman sendiri lewat Pengaturan. Kalau
      // kosong, pakai yang dibundel — itu yang bikin fitur ini tetap jalan
      // walau internetnya mati.
      final url = await Injection.instance.settingsDatasource.get(
        'indonesia_raya_audio_url',
      );
      if (url.trim().isEmpty) {
        await _player.play(
          AssetSource('audio/indonesia_raya.mp3'),
          volume: 1.0,
        );
      } else {
        await _player.play(UrlSource(url.trim()), volume: 1.0);
      }
    } catch (e) {
      debugPrint('CeremonyAudioService: gagal memutar ${_keyOf(audio)}: $e');
    }
  }

  Future<void> _tick() async {
    final now = DateTime.now();

    // Hari kerja saja — sama seperti sebelumnya di Display.
    if (now.weekday == DateTime.saturday || now.weekday == DateTime.sunday) {
      return;
    }
    if (_playedDate == _todayKey) return;

    final raw = await Injection.instance.settingsDatasource.get(
      'indonesia_raya_jam',
    );
    final parts = raw.trim().split(':');
    if (parts.length != 2) return;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return;

    // Toleransi 1 menit: ticker jalan tiap 20 detik, jadi jamnya nggak
    // harus kena persis. Ditandai sudah diputar supaya nggak berulang di
    // detik-detik berikutnya dalam menit yang sama.
    final target = h * 60 + m;
    final current = now.hour * 60 + now.minute;
    if (current < target || current > target + 1) return;

    _playedDate = _todayKey;
    debugPrint('CeremonyAudioService: memutar Indonesia Raya ($raw).');
    await play(CeremonyAudio.indonesiaRaya);
  }

  /// Dengerin permintaan uji dari Aplikasi Loket.
  ///
  /// Gunanya: membuktikan jalur suara kiosk hidup tanpa nunggu jam tayang
  /// tiba. Kalau uji manualnya bunyi, yang terjadwal juga bakal bunyi —
  /// jalur pemutarannya sama persis (method [play] yang sama).
  void _listenForTestRequests() {
    var primed = false;

    _testSub = FirebaseFirestore.instance
        .collection('system_status')
        .doc('audio_test')
        .snapshots()
        .listen(
          (snap) {
            // Snapshot pertama cuma menandai posisi awal — kalau diputar,
            // tiap kiosk dibuka bakal memutar permintaan uji terakhir.
            if (!primed) {
              primed = true;
              return;
            }
            final data = snap.data();
            if (data == null) return;

            final requestedAt = DateTime.tryParse(
              data['requested_at'] as String? ?? '',
            );
            if (requestedAt == null) return;
            if (DateTime.now().toUtc().difference(requestedAt.toUtc()) >
                _maxTestAge) {
              return;
            }

            final type = data['type'] as String? ?? '';
            final audio = CeremonyAudio.values
                .where((a) => _keyOf(a) == type)
                .firstOrNull;
            if (audio == null) return;

            debugPrint('CeremonyAudioService: uji suara dari Admin -> $type');
            unawaited(play(audio));
          },
          onError: (Object e) =>
              debugPrint('CeremonyAudioService: listen error: $e'),
        );
  }
}
