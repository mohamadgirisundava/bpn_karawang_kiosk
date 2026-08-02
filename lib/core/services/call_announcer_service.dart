import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter_tts/flutter_tts.dart';

import 'background_audio.dart';

/// Nama angka 0-9 untuk mengeja kode antrian.
const List<String> _ones = [
  'nol',
  'satu',
  'dua',
  'tiga',
  'empat',
  'lima',
  'enam',
  'tujuh',
  'delapan',
  'sembilan',
];

/// Angka ke kata Bahasa Indonesia ("1" -> "satu", "10" -> "sepuluh", "100"
/// -> "seratus") — dibaca sebagai angka utuh, bukan dieja digit-per-digit
/// (yang kedengeran berulang-ulang dan sebagian mesin TTS ngucapin "nol"
/// yang jelek/bergetar — sudah dites di app Display).
/// Pisah kode antrian jadi huruf loket + nomor ("A001" -> "A" + 1).
/// Baca field angka dari data Firestore secara toleran — beberapa dokumen
/// bisa nyimpen angka sebagai string (input manual lewat Console), bukan
/// number asli.
int _asInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

/// Eja kode antrian per karakter: "A1001" jadi "A, satu, nol, nol, satu".
///
/// Dulu angkanya dibaca sebagai bilangan utuh, jadi "A1001" terbaca
/// "A seribu satu". Dua masalahnya:
///
/// 1. Bilangan utuh susah dicocokkan dengan yang tercetak di kertas.
///    Pengunjung memegang "A1001", bukan "seribu satu".
/// 2. Kode layanan sekarang bisa mengandung angka (A1 = Plotting,
///    A2 = Informasi). Pemisah lama cuma mengambil hurufnya, jadi "A1001"
///    dipecah jadi "A" + 1001 — padahal yang benar "A1" + 001.
///
/// Mengeja per karakter menyelesaikan dua-duanya sekaligus, dan nggak perlu
/// menebak di mana prefix berakhir.
///
/// Koma di antara karakter itu disengaja: TTS memberi jeda pendek di koma,
/// jadi angkanya nggak terdengar berdempet.
String _spellQueueCode(String code) {
  final spoken = <String>[];
  for (final char in code.trim().toUpperCase().split('')) {
    final digit = int.tryParse(char);
    if (digit != null) {
      spoken.add(_ones[digit]);
    } else if (char.trim().isNotEmpty) {
      spoken.add(char);
    }
  }
  return spoken.join(', ');
}

String _buildAnnouncementText(Map<String, dynamic> data) {
  final code = data['queue_code'] as String? ?? '';
  final spokenCode = _spellQueueCode(code);
  final deskNumber = _asInt(data['desk_number']);
  // Nomor loket sengaja TIDAK dieja per angka — "loket sepuluh" lebih
  // wajar didengar daripada "loket satu nol".
  final desk = deskNumber != 0 ? ', silakan menuju loket $deskNumber' : '';
  return 'Nomor antrian $spokenCode$desk';
}

/// Satu item dalam antrian ucap — `announcementRef` cuma keisi kalau
/// asalnya dari pengumuman admin (`voice_announcements`), dipakai buat
/// nandain "udah dibacain" abis diucapkan biar nggak keulang.
typedef _SpokenItem = ({
  String text,
  DocumentReference<Map<String, dynamic>>? announcementRef,
});

/// Bacakan tiap ada panggilan nomor antrian baru (collection
/// `calls`, `is_active == true`) ATAU pengumuman suara baru dari admin
/// (collection `voice_announcements`, `played == false`) — dua-duanya
/// lewat antrian ucap yang sama biar nggak saling motong (TTS cuma bisa
/// ngomong satu hal dalam satu waktu). Speaker fisik kiosk-lah yang
/// beneran kepake buat pengumuman ini (bukan TV Display) — makanya
/// logic-nya taruh di sini, pakai TTS native Flutter (`flutter_tts`)
/// bukan Web Speech API kayak versi Display, jadi nggak
/// kena masalah autoplay policy / daftar voice kosong / force-dark yang
/// bikin ribet di browser.
class CallAnnouncerService {
  CallAnnouncerService._();
  static final CallAnnouncerService instance = CallAnnouncerService._();

  final FlutterTts _tts = FlutterTts();

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _callSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _voiceAnnouncementSub;
  String? _lastAnnouncedCallId;

  /// Sudah lewat snapshot pertama dari langganan `calls` atau belum.
  bool _primed = false;

  /// Batas umur pengumuman suara yang masih layak dibacakan. Lebih tua dari
  /// ini dianggap sudah nggak relevan.
  static const Duration _maxAnnouncementAge = Duration(minutes: 5);

  /// Batas waktu satu kali pengucapan. Kalimat terpanjang ("Nomor antrian
  /// A001, silakan menuju loket 10") sekitar 8 detik di kecepatan 0.45,
  /// jadi 20 detik lebih dari cukup — ini jaring pengaman, bukan batas
  /// normal.
  static const Duration _speakTimeout = Duration(seconds: 20);
  bool _ttsReady = false;

  // Antrian ucap — kalau ada beberapa loket manggil atau pengumuman baru
  // hampir bersamaan, diproses satu-satu berurutan.
  final List<_SpokenItem> _queue = [];
  bool _processing = false;

  Future<void> _ensureTtsReady() async {
    if (_ttsReady) return;
    try {
      await _tts.awaitSpeakCompletion(true);

      // Dicek biar kelihatan di log kalau perangkatnya nggak punya suara
      // Indonesia — penyebab paling sering panggilan nggak kedengaran
      // sama sekali. BlueStacks mis. sering nggak punya mesin TTS.
      final hasIndonesian = await _tts.isLanguageAvailable('id-ID');
      if (hasIndonesian != true) {
        debugPrint(
          'CallAnnouncerService: suara id-ID nggak tersedia di perangkat '
          'ini, jadi panggilan nggak diucapkan sama sekali. '
          'Pasang mesin Text-to-Speech + bahasa Indonesia di perangkat.',
        );
      }

      await _tts.setLanguage('id-ID');
      await _tts.setSpeechRate(0.45);
      await _tts.setVolume(1.0);
      // Ditandai siap SETELAH setup sukses, bukan sebelum — kalau ditandai
      // di awal lalu setupnya gagal, percobaan berikutnya nggak pernah
      // nyoba lagi.
      _ttsReady = true;
    } catch (e) {
      debugPrint('CallAnnouncerService: gagal setup TTS: $e');
    }
  }

  /// Mulai dengerin panggilan & pengumuman baru. Aman dipanggil
  /// berkali-kali (no-op kalau udah jalan).
  Future<void> start() async {
    if (_callSub != null) return;

    await _ensureTtsReady();

    _callSub = FirebaseFirestore.instance
        .collection('calls')
        .where('is_active', isEqualTo: true)
        .orderBy('called_at', descending: true)
        .limit(1)
        .snapshots()
        .listen(
          (snapshot) {
            if (snapshot.docs.isEmpty) {
              _primed = true;
              return;
            }
            final doc = snapshot.docs.first;

            // Snapshot PERTAMA cuma dicatat, nggak dibacakan. Firestore
            // ngirim semua dokumen yang sudah ada sebagai "baru" waktu
            // listener dipasang — tanpa penjaga ini, tiap kali aplikasi
            // dibuka panggilan terakhir yang masih aktif ikut diteriakkan
            // ulang, padahal orangnya udah dipanggil dari tadi.
            if (!_primed) {
              _primed = true;
              _lastAnnouncedCallId = doc.id;
              return;
            }

            if (doc.id == _lastAnnouncedCallId) return;
            _lastAnnouncedCallId = doc.id;
            _queue.add((
              text: _buildAnnouncementText(doc.data()),
              announcementRef: null,
            ));
            unawaited(_processQueue());
          },
          onError: (Object e) =>
              debugPrint('CallAnnouncerService: listen error (calls): $e'),
        );

    _voiceAnnouncementSub = FirebaseFirestore.instance
        .collection('voice_announcements')
        .where('played', isEqualTo: false)
        .orderBy('createdAt')
        .snapshots()
        .listen(
          (snapshot) {
            for (final change in snapshot.docChanges) {
              if (change.type != DocumentChangeType.added) continue;
              final data = change.doc.data();
              final text = data?['text'] as String? ?? '';
              if (text.trim().isEmpty) continue;

              // Pengumuman yang sudah basi dilewati, bukan dibacakan telat.
              // Isinya biasanya terikat waktu ("layanan tutup 15 menit
              // lagi") — dibacakan dua jam kemudian malah menyesatkan.
              // Ini kejadian tiap kiosk restart, karena Firestore ngirim
              // semua dokumen yang belum dibacakan sebagai "baru".
              final createdAt = DateTime.tryParse(
                data?['createdAt'] as String? ?? '',
              );
              if (createdAt != null &&
                  DateTime.now().toUtc().difference(createdAt.toUtc()) >
                      _maxAnnouncementAge) {
                // Ditandai sudah dibacakan biar nggak nyangkut dan nggak
                // dicek ulang tiap kali kiosk dibuka.
                unawaited(
                  change.doc.reference.update({'played': true}).catchError((
                    Object e,
                  ) {
                    debugPrint(
                      'CallAnnouncerService: gagal menandai pengumuman '
                      'basi: $e',
                    );
                  }),
                );
                continue;
              }

              _queue.add((text: text, announcementRef: change.doc.reference));
            }
            unawaited(_processQueue());
          },
          onError: (Object e) => debugPrint(
            'CallAnnouncerService: listen error (voice_announcements): $e',
          ),
        );
  }

  Future<void> stop() async {
    await _callSub?.cancel();
    _callSub = null;
    await _voiceAnnouncementSub?.cancel();
    _voiceAnnouncementSub = null;
    _primed = false;
    _queue.clear();
  }

  Future<void> _processQueue() async {
    if (_processing) return;
    _processing = true;

    // Adzan/Indonesia Raya/jadwal audio dikecilkan selama panggilan
    // berbunyi, bukan dihentikan dan bukan bikin panggilannya ditunda.
    // Pengunjung yang nomornya keluar harus dipanggil sekarang, dan adzan
    // yang dipotong di tengah lebih buruk daripada adzan yang mengecil.
    await BackgroundAudio.duck();
    try {
      while (_queue.isNotEmpty) {
        final item = _queue.removeAt(0);
        await _speak(item.text);
        if (item.announcementRef != null) {
          // Nandain udah dibacain SETELAH selesai ngomong, bukan sebelum —
          // kalau app ke-kill di tengah ngomong, pengumuman ini masih
          // berstatus "belum dibacain" dan bakal diulang pas app nyala
          // lagi, daripada hilang kebaca gara-gara nggak sempet mark.
          unawaited(
            item.announcementRef!.update({'played': true}).catchError((
              Object e,
            ) {
              debugPrint(
                'CallAnnouncerService: gagal update status played: $e',
              );
            }),
          );
        }
        await Future<void>.delayed(const Duration(milliseconds: 300));
      }
    } finally {
      await BackgroundAudio.restore();
      _processing = false;
    }
  }

  Future<void> _speak(String text) async {
    try {
      await _ensureTtsReady();
      // `awaitSpeakCompletion(true)` bikin speak() nunggu laporan "selesai"
      // dari mesin TTS. Kalau mesinnya nggak ada, laporan itu nggak pernah
      // datang dan await-nya MENGGANTUNG SELAMANYA — dan karena
      // `_processQueue` nunggu di sini, `_processing` nggak pernah dilepas.
      // Akibatnya bukan cuma panggilan ini yang bisu: semua panggilan dan
      // pengumuman sesudahnya ikut mati diam-diam.
      await _tts
          .speak(text)
          .timeout(
            _speakTimeout,
            onTimeout: () {
              debugPrint(
                'CallAnnouncerService: TTS nggak selesai dalam '
                '${_speakTimeout.inSeconds} detik — dilewati biar antrian '
                'pengumuman nggak ikut macet.',
              );
              unawaited(_tts.stop());
              return 0;
            },
          );
    } catch (e) {
      debugPrint('CallAnnouncerService: gagal ngomong: $e');
    }
  }
}
