import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' show sha1;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'background_audio.dart';
import 'realtime_service.dart';

import '../utils/drive_link.dart';
import '../utils/weekdays.dart';

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
  StreamSubscription<void>? _settingsSub;

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
    // Jam/hari yang baru disimpan admin langsung kepakai, nggak nunggu TTL
    // 5 menit di bawah kedaluwarsa.
    _settingsSub = RealtimeService.instance.onSettingsUpdate.listen(
      (_) => _settingsFetchedAt = null,
    );
    _listenForTestRequests();
  }

  Future<void> stop() async {
    _ticker?.cancel();
    _ticker = null;
    await _testSub?.cancel();
    _testSub = null;
    await _settingsSub?.cancel();
    _settingsSub = null;
  }

  /// Putar sekarang juga — dipakai uji manual dari Admin.
  Future<void> play(CeremonyAudio audio) async {
    // Selalu dihentikan dulu. Pemutar yang sebelumnya gagal (URL nggak bisa
    // diputar) tertinggal dalam keadaan error, dan dari situ perintah play
    // berikutnya nggak berbunyi apa-apa — termasuk yang seharusnya jatuh ke
    // rekaman bawaan.
    try {
      await _player.stop();
    } catch (_) {}

    if (audio == CeremonyAudio.adzan) {
      await _playAsset('audio/adhan.mp3');
      return;
    }

    // Uji manual harus memutar apa yang BARU SAJA disimpan admin, bukan
    // nilai yang masih nyangkut di cache 30 detik.
    Injection.instance.settingsDatasource.invalidateCache();
    final url = (await Injection.instance.settingsDatasource.get(
      'indonesia_raya_audio_url',
    )).trim();

    // BPN boleh menyediakan rekaman sendiri lewat Pengaturan. Kalau kosong,
    // pakai yang dibundel — itu yang bikin fitur ini tetap jalan walau
    // internetnya mati.
    if (url.isEmpty) {
      await _playAsset('audio/indonesia_raya.mp3');
      return;
    }

    // Diunduh dulu, baru diputar dari berkas lokal — BUKAN di-stream lewat
    // UrlSource. Tiga alasan, semuanya kejadian nyata:
    //
    // 1. Drive membalas 303 redirect. `package:http` mengikutinya sendiri;
    //    pemutar Android belum tentu.
    // 2. Kalau sharing-nya belum publik, Drive membalas halaman HTML dengan
    //    status 200. Di sini bisa dideteksi dan ditolak; kalau di-stream,
    //    pemutar cuma diam tanpa pesan apa pun.
    // 3. Setelah tersimpan, pemutarannya nggak lagi bergantung koneksi
    //    persis di detik lagunya harus bunyi.
    //
    // Pola yang sama sudah dipakai ScheduledAudioService.
    final localPath = await _cachedFile(url);
    if (localPath == null) {
      debugPrint('CeremonyAudioService: pakai rekaman bawaan.');
      await _playAsset('audio/indonesia_raya.mp3');
      return;
    }

    try {
      await _player.play(DeviceFileSource(localPath), volume: 1.0);
    } catch (e) {
      debugPrint('CeremonyAudioService: gagal memutar berkas unduhan: $e');
      await _playAsset('audio/indonesia_raya.mp3');
    }
  }

  /// Unduh sekali per URL lalu simpan lokal. Null berarti gagal — pemanggil
  /// yang memutuskan jatuh ke rekaman bawaan.
  Future<String?> _cachedFile(String rawUrl) async {
    final url = upgradeDriveLink(rawUrl);
    try {
      final dir = await getApplicationSupportDirectory();
      final hash = sha1.convert(utf8.encode(url)).toString();
      final file = File('${dir.path}/ceremony_$hash.mp3');
      if (await file.exists() && await file.length() > 0) return file.path;

      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) {
        debugPrint('CeremonyAudioService: unduh gagal ${response.statusCode}.');
        return null;
      }
      // Drive membalas halaman HTML dengan status 200 kalau berkasnya belum
      // di-share publik. Tanpa pemeriksaan ini, HTML-nya tersimpan sebagai
      // .mp3 dan gagal diputar selamanya karena cache-nya dianggap valid.
      if (looksLikeHtml(response.bodyBytes)) {
        debugPrint(
          'CeremonyAudioService: yang diunduh halaman HTML, bukan audio. '
          'Berkas Drive-nya kemungkinan belum di-share "siapa saja yang '
          'punya link".',
        );
        return null;
      }

      await file.writeAsBytes(response.bodyBytes);
      return file.path;
    } catch (e) {
      debugPrint('CeremonyAudioService: gagal menyiapkan berkas audio: $e');
      return null;
    }
  }

  Future<void> _playAsset(String path) async {
    try {
      await _player.play(AssetSource(path), volume: 1.0);
    } catch (e) {
      debugPrint('CeremonyAudioService: gagal memutar $path: $e');
    }
  }

  /// Pengaturan di-cache sebentar supaya ticker 20 detik nggak menembak
  /// Firestore tiap kali. Sehari penuh menunggu jam tayang bisa jadi ribuan
  /// pembacaan, dan kuota gratis dipakai bareng seluruh sistem.
  static const Duration _settingsTtl = Duration(minutes: 5);
  DateTime? _settingsFetchedAt;
  String _jamCache = '';
  String _hariCache = '';

  Future<void> _refreshSettings() async {
    final now = DateTime.now();
    final fetchedAt = _settingsFetchedAt;
    if (fetchedAt != null && now.difference(fetchedAt) < _settingsTtl) return;

    final settings = Injection.instance.settingsDatasource;
    _jamCache = await settings.get('indonesia_raya_jam');
    _hariCache = await settings.get('indonesia_raya_hari');
    _settingsFetchedAt = now;
  }

  Future<void> _tick() async {
    final now = DateTime.now();

    if (_playedDate == _todayKey) return;

    await _refreshSettings();

    // Hari yang dipilih admin, boleh meloncat (mis. Senin dan Kamis saja).
    // Kosong berarti hari kerja — perilaku lama, biar pemasangan yang belum
    // pernah menyentuh pengaturan ini nggak berubah diam-diam.
    final hari = parseWeekdays(_hariCache);
    if (!(hari.isEmpty ? workdays : hari).contains(now.weekday)) return;

    final raw = _jamCache;
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

            // "Hentikan Suara" di Admin. Lewat dokumen yang sama supaya
            // nggak perlu jalur baru — perintahnya cuma beda isi `type`.
            if (type == 'stop') {
              debugPrint('CeremonyAudioService: perintah stop dari Admin.');
              unawaited(_player.stop());
              unawaited(BackgroundAudio.stopAll());
              return;
            }

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
