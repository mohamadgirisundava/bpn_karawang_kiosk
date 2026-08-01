import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

const List<String> _ones = [
  '',
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
const List<String> _teens = [
  'sepuluh',
  'sebelas',
  'dua belas',
  'tiga belas',
  'empat belas',
  'lima belas',
  'enam belas',
  'tujuh belas',
  'delapan belas',
  'sembilan belas',
];
const List<String> _tens = [
  '',
  '',
  'dua puluh',
  'tiga puluh',
  'empat puluh',
  'lima puluh',
  'enam puluh',
  'tujuh puluh',
  'delapan puluh',
  'sembilan puluh',
];

/// Angka ke kata Bahasa Indonesia ("1" -> "satu", "10" -> "sepuluh", "100"
/// -> "seratus") — dibaca sebagai angka utuh, bukan dieja digit-per-digit
/// (yang kedengeran berulang-ulang dan sebagian mesin TTS ngucapin "nol"
/// yang jelek/bergetar — sudah dites di app Display).
String _numberToWords(int n) {
  if (n == 0) return 'nol';
  if (n < 10) return _ones[n];
  if (n < 20) return _teens[n - 10];
  if (n < 100) {
    final tens = n ~/ 10;
    final ones = n % 10;
    return ones == 0 ? _tens[tens] : '${_tens[tens]} ${_ones[ones]}';
  }
  if (n < 1000) {
    final hundreds = n ~/ 100;
    final rest = n % 100;
    final hundredsWord = hundreds == 1 ? 'seratus' : '${_ones[hundreds]} ratus';
    return rest == 0 ? hundredsWord : '$hundredsWord ${_numberToWords(rest)}';
  }
  final thousands = n ~/ 1000;
  final rest = n % 1000;
  final thousandsWord = thousands == 1
      ? 'seribu'
      : '${_numberToWords(thousands)} ribu';
  return rest == 0 ? thousandsWord : '$thousandsWord ${_numberToWords(rest)}';
}

/// Pisah kode antrian jadi huruf loket + nomor ("A001" -> "A" + 1).
({String prefix, int? number}) _parseQueueCode(String code) {
  final match = RegExp(r'^([A-Za-z]*)0*(\d+)$').firstMatch(code);
  if (match == null) return (prefix: '', number: null);
  return (
    prefix: match.group(1)!.toUpperCase(),
    number: int.parse(match.group(2)!),
  );
}

/// Baca field angka dari data Firestore secara toleran — beberapa dokumen
/// bisa nyimpen angka sebagai string (input manual lewat Console), bukan
/// number asli.
int _asInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

String _buildAnnouncementText(Map<String, dynamic> data) {
  final code = data['queue_code'] as String? ?? '';
  final parsed = _parseQueueCode(code);
  final spokenNumber = parsed.number == null
      ? code
      : _numberToWords(parsed.number!);
  final spokenCode = parsed.prefix.isNotEmpty
      ? '${parsed.prefix}, $spokenNumber'
      : spokenNumber;
  final deskNumber = _asInt(data['desk_number']);
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

/// Bunyiin chime + suara tiap ada panggilan nomor antrian baru (collection
/// `calls`, `is_active == true`) ATAU pengumuman suara baru dari admin
/// (collection `voice_announcements`, `played == false`) — dua-duanya
/// lewat antrian ucap yang sama biar nggak saling motong (TTS cuma bisa
/// ngomong satu hal dalam satu waktu). Speaker fisik kiosk-lah yang
/// beneran kepake buat pengumuman ini (bukan TV Display) — makanya
/// logic-nya taruh di sini, pakai audio/TTS native Flutter (`audioplayers`
/// + `flutter_tts`) bukan Web Speech API kayak versi Display, jadi nggak
/// kena masalah autoplay policy / daftar voice kosong / force-dark yang
/// bikin ribet di browser.
class CallAnnouncerService {
  CallAnnouncerService._();
  static final CallAnnouncerService instance = CallAnnouncerService._();

  final AudioPlayer _chimePlayer = AudioPlayer();
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
  bool _ttsReady = false;

  // Antrian ucap — kalau ada beberapa loket manggil atau pengumuman baru
  // hampir bersamaan, diproses satu-satu berurutan.
  final List<_SpokenItem> _queue = [];
  bool _processing = false;

  Future<void> _ensureTtsReady() async {
    if (_ttsReady) return;
    _ttsReady = true;
    try {
      await _tts.awaitSpeakCompletion(true);
      await _tts.setLanguage('id-ID');
      await _tts.setSpeechRate(0.45);
      await _tts.setVolume(1.0);
    } catch (e) {
      debugPrint('CallAnnouncerService: gagal setup TTS: $e');
    }
  }

  /// Mulai dengerin panggilan & pengumuman baru. Aman dipanggil
  /// berkali-kali (no-op kalau udah jalan).
  Future<void> start() async {
    if (_callSub != null) return;

    await _chimePlayer.setReleaseMode(ReleaseMode.stop);
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
    try {
      while (_queue.isNotEmpty) {
        final item = _queue.removeAt(0);
        await _playChime();
        await Future<void>.delayed(const Duration(milliseconds: 400));
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
      _processing = false;
    }
  }

  Future<void> _playChime() {
    final completer = Completer<void>();
    late final StreamSubscription<void> sub;
    sub = _chimePlayer.onPlayerComplete.listen((_) {
      sub.cancel();
      if (!completer.isCompleted) completer.complete();
    });

    _chimePlayer.play(AssetSource('audio/chime.wav'), volume: 0.8).catchError((
      Object e,
    ) {
      debugPrint('CallAnnouncerService: gagal muter chime: $e');
      sub.cancel();
      if (!completer.isCompleted) completer.complete();
    });

    // Jaring pengaman kalau onPlayerComplete nggak pernah nyala.
    unawaited(
      Future<void>.delayed(const Duration(seconds: 2), () {
        sub.cancel();
        if (!completer.isCompleted) completer.complete();
      }),
    );

    return completer.future;
  }

  Future<void> _speak(String text) async {
    try {
      await _ensureTtsReady();
      await _tts.speak(text);
    } catch (e) {
      debugPrint('CallAnnouncerService: gagal ngomong: $e');
    }
  }
}
