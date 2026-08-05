import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../data/models/queue_model.dart';
import '../../injection.dart';
import 'service_window.dart';

/// Kunci tanggal hari ini, "YYYY-MM-DD" — sama persis dengan `dateKey` di
/// dokumen antrian.
String _todayKey() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';
}

/// Service untuk realtime subscription ke semua collection Firestore.
///
/// ## Aturan pertama: listener adalah SUMBER DATA, bukan bel pemberitahuan
///
/// Firestore menagih PER DOKUMEN DIBACA. Snapshot `queues` di bawah sudah
/// mengirimkan setiap tiket hari ini ke aplikasi ini, dan itu SUDAH DIBAYAR.
/// Kalau cubit-nya cuma memakai snapshot itu sebagai penanda "ada yang
/// berubah" lalu menjalankan query sendiri, dokumen yang sama dibayar dua
/// kali — dikali jumlah layanan, dikali jumlah perangkat.
///
/// Itu yang terjadi sampai 2026-08-05: 185 tiket menghabiskan 69.672 baca
/// (~350 per tiket) dan kuota 50.000 jebol di tengah jam pelayanan.
/// Sekarang [todayQueues] menyimpan hasil snapshot di memori dan
/// [onQueuesData] menyiarkan datanya — nol query tambahan.
///
/// **Jangan mengembalikan pola query-ulang-saat-ada-event.**
///
/// ## Filternya juga wajib dipertahankan
///
/// Snapshot pertama sebuah listener mengirim seluruh hasil query sebagai
/// "added", jadi biayanya terbayar lagi tiap koneksi putus-nyambung — dan di
/// lokasi jaringannya memang begitu (2026-08-04: `UNAVAILABLE: Unable to
/// resolve host`). Tanpa `where('dateKey')`, sekali menyambung ulang
/// menyeret seluruh isi collection. Kalau butuh data lama, ambil sekali
/// lewat `.get()` — jangan dijadikan listener.
class RealtimeService {
  RealtimeService._();
  static final RealtimeService instance = RealtimeService._();

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  /// Tiket hari ini, apa adanya dari snapshot terakhir. Ini SATU-SATUNYA
  /// sumber data antrian di app ini — jangan query ulang untuk sesuatu yang
  /// sudah ada di sini.
  List<QueueModel> _todayQueues = const [];
  List<QueueModel> get todayQueues => _todayQueues;

  final StreamController<List<QueueModel>> _queuesDataController =
      StreamController<List<QueueModel>>.broadcast();
  final StreamController<void> _counterUpdateController =
      StreamController<void>.broadcast();
  final StreamController<void> _settingsUpdateController =
      StreamController<void>.broadcast();

  /// Data tiket hari ini tiap kali berubah. Cubit yang baru dibuat harus
  /// menyemai dirinya dari [todayQueues] dulu — stream broadcast nggak
  /// mengulang emit terakhir buat pendengar yang telat.
  Stream<List<QueueModel>> get onQueuesData => _queuesDataController.stream;
  Stream<void> get onCounterUpdate => _counterUpdateController.stream;
  Stream<void> get onSettingsUpdate => _settingsUpdateController.stream;

  /// Pancarkan ulang isi cache sekarang juga — dipakai setelah aksi yang
  /// KITA SENDIRI tau pasti ngubah `queues` (mis. reset antrian), daripada
  /// nunggu propagasi listener Firestore yang kadang ada jeda dikit.
  void notifyQueueUpdate() => _queuesDataController.add(_todayQueues);

  /// Dulu di sini ada debounce 800ms. Itu tambalan supaya satu aksi yang
  /// menghasilkan beberapa perubahan beruntun nggak memicu beberapa putaran
  /// query penuh. Sekarang event-nya nggak memicu query sama sekali — cuma
  /// menyalin daftar yang sudah ada di memori — jadi penundaannya nggak ada
  /// gunanya lagi.

  bool _subscribed = false;

  /// Tanggal yang sedang dilanggan. Listener `queues` dibuat sekali dengan
  /// tanggal tetap, jadi kiosk yang menyala melewati tengah malam bakal
  /// terus mendengarkan tanggal kemarin dan antrian hari baru nggak pernah
  /// muncul. [_dateWatcher] yang menanganinya.
  String _subscribedDate = _todayKey();
  Timer? _dateWatcher;
  Timer? _windowWatcher;
  final List<StreamSubscription<QuerySnapshot>> _subscriptions = [];

  /// Listener `settings` sengaja DIPISAH dan selalu hidup.
  ///
  /// Dia yang jadi sumber jam buka/tutup, jadi kalau ikut dilepas waktu
  /// kantor tutup, aplikasi nggak akan pernah tau kapan harus bangun lagi.
  /// Isinya cuma 20 dokumen dan nyaris nggak pernah berubah, jadi biayanya
  /// dapat diabaikan dibanding `queues` yang berubah ratusan kali sehari.
  StreamSubscription<QuerySnapshot>? _settingsSub;
  bool _windowOpen = true;

  /// Buka/tutup menurut setelan terakhir yang terbaca.
  bool get isServiceWindowOpen => _windowOpen;

  Map<String, String> get _settingsSnapshot =>
      Injection.instance.settingsDatasource.cachedValues;

  /// Terapkan gerbang jam layanan: sambungkan yang berat kalau buka, lepas
  /// kalau tutup. Aman dipanggil berulang — keduanya no-op kalau statusnya
  /// nggak berubah.
  Future<void> _applyServiceWindow() async {
    final open = ServiceWindow.isOpen(_settingsSnapshot);
    _windowOpen = open;

    if (open && !_subscribed) {
      await _subscribeHeavy();
    } else if (!open && _subscribed) {
      debugPrint('Realtime: di luar jam layanan — lepas listener antrian');
      await _unsubscribeHeavy();
    }
  }

  /// Sambungkan listener `settings` (selalu) lalu jalankan gerbang jamnya.
  Future<void> subscribe() async {
    _settingsSub ??= _db.collection('settings').snapshots().listen((
      snapshot,
    ) {
      debugPrint('Realtime settings: ${snapshot.docChanges.length} change(s)');
      // SettingsRemoteDatasource menyimpan seluruh settings di memori
      // selama 30 detik. Cache itu punya invalidateCache(), tapi sebelumnya
      // nggak ada yang memanggilnya dari sini — jadi perubahan dari Admin
      // baru kebaca kiosk setelah cache-nya kedaluwarsa sendiri.
      //
      // Efeknya bikin bingung waktu uji suara: admin ganti berkas audio lalu
      // langsung menekan Uji, yang berbunyi masih berkas yang lama.
      Injection.instance.settingsDatasource.primeCache(snapshot);
      _settingsUpdateController.add(null);
      // Jam buka/tutup baru saja mungkin berubah — terapkan sekarang juga.
      unawaited(_applyServiceWindow());
    }, onError: (Object e) => debugPrint('Realtime settings error: $e'));

    // Diperiksa tiap menit; murah, dan cuma menyentuh Firestore saat
    // statusnya benar-benar berpindah.
    _windowWatcher ??= Timer.periodic(
      const Duration(minutes: 1),
      (_) => unawaited(_applyServiceWindow()),
    );

    await _applyServiceWindow();
  }

  Future<void> _subscribeHeavy() async {
    if (_subscribed) return;

    // Tanggalnya dihitung ULANG di sini, bukan sekali saat objek ini dibuat.
    //
    // Service ini singleton, dan method ini dipanggil lagi tiap kali gerbang
    // jam layanan membangunkan aplikasi — termasuk pagi berikutnya. Kalau
    // `_subscribedDate` cuma diisi di deklarasi field, dia terkunci ke
    // tanggal saat kiosk pertama dinyalakan, dan setelah lewat tengah malam
    // aplikasi menyambung ke tanggal KEMARIN: antrian hari baru nggak pernah
    // muncul walau datanya ada.
    _subscribedDate = _todayKey();

    try {
      _subscriptions.add(
        _db
            .collection('queues')
            .where('dateKey', isEqualTo: _subscribedDate)
            .snapshots()
            .listen((snapshot) {
              debugPrint(
                'Realtime queues: ${snapshot.docChanges.length} change(s), '
                '${snapshot.docs.length} dokumen',
              );
              _todayQueues = snapshot.docs
                  .map(QueueModel.fromDoc)
                  .toList(growable: false);
              _queuesDataController.add(_todayQueues);
            }),
      );

      _subscriptions.add(
        _db.collection('counters').snapshots().listen((snapshot) {
          debugPrint(
            'Realtime counters: ${snapshot.docChanges.length} change(s)',
          );
          _counterUpdateController.add(null);
        }),
      );

      // Listener `calls` sengaja NGGAK ADA di sini. `onCallUpdate` dulu nol
      // pemakai — pengumuman suara panggilan punya listener sendiri yang
      // sudah difilter `is_active` + `limit(1)` di CallAnnouncerService, dan
      // itu yang benar-benar dipakai. Listener di sini cuma membayar ulang
      // dokumen yang sama tanpa ada yang membacanya.

      // Tengah malam listener `queues` harus dibuat ulang dengan tanggal
      // baru — kalau nggak, dia terus mendengarkan tanggal kemarin dan
      // antrian hari baru NGGAK PERNAH muncul.
      //
      // Diperiksa tiap menit, bukan tiap 10 menit. Pengecekannya sendiri
      // gratis (cuma banding string) dan baru menembak Firestore kalau
      // tanggalnya benar-benar berganti, jadi interval rapat nggak menambah
      // biaya apa pun — yang dipotong cuma lamanya layar salah tanggal.
      _dateWatcher ??= Timer.periodic(const Duration(minutes: 1), (_) {
        final today = _todayKey();
        if (today == _subscribedDate) return;
        debugPrint('Realtime: ganti hari $_subscribedDate -> $today');
        _subscribedDate = today;
        _unsubscribeHeavy().then((_) => _subscribeHeavy());
      });

      _subscribed = true;
      debugPrint('Realtime: subscribed to all collections');
    } catch (e) {
      debugPrint('Realtime subscribe error: $e');
    }
  }

  Future<void> _unsubscribeHeavy() async {
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    _subscriptions.clear();
    _subscribed = false;

    // Tengah malam (dan tiap kali kantor tutup) listener dibuat ulang. Tanpa
    // dikosongkan di sini, daftar lama tetap nangkring di memori sampai
    // snapshot pertama yang baru datang.
    _todayQueues = const [];
    _queuesDataController.add(_todayQueues);
  }

  /// Lepas SEMUA listener, termasuk `settings`. Dipakai saat aplikasi ditutup
  /// — bukan saat kantor tutup (itu `_unsubscribeHeavy`, yang menyisakan
  /// `settings` supaya masih tau kapan harus bangun).
  Future<void> unsubscribe() async {
    await _unsubscribeHeavy();
    await _settingsSub?.cancel();
    _settingsSub = null;
    _windowWatcher?.cancel();
    _windowWatcher = null;
  }

  void dispose() {
    _dateWatcher?.cancel();
    _dateWatcher = null;
    _windowWatcher?.cancel();
    _windowWatcher = null;
    _queuesDataController.close();
    _counterUpdateController.close();
    _settingsUpdateController.close();
  }
}
