import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../injection.dart';

/// Kunci tanggal hari ini, "YYYY-MM-DD" — sama persis dengan `dateKey` di
/// dokumen antrian.
String _todayKey() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';
}

/// Service untuk realtime subscription ke semua collection Firestore.
///
/// ## Kenapa `queues` dan `calls` WAJIB difilter
///
/// Firestore menagih PER DOKUMEN DIBACA, dan snapshot pertama sebuah
/// listener mengirim seluruh isi hasil query sebagai "added". Jadi biaya
/// satu listener bukan sekali seumur hidup — dia terbayar lagi setiap kali
/// koneksinya putus lalu tersambung ulang.
///
/// Di lokasi, jaringannya putus-nyambung (2026-08-04: `UNAVAILABLE: Unable
/// to resolve host`). Tiap penyambungan ulang membaca ulang semuanya, dikali
/// jumlah aplikasi dan perangkat. Itu yang menghabiskan 44.000 baca dan
/// mematikan pelayanan di tengah jam kerja, bukan data yang menumpuk —
/// isinya waktu itu cuma 1.267 dokumen.
///
/// Yang paling mahal justru `calls`: 393 dokumen dan nggak pernah dihapus,
/// padahal yang dipakai cuma yang `is_active`. Sekarang `queues` dibatasi ke
/// hari ini dan `calls` ke yang aktif — dari ~530 dokumen per penyambungan
/// jadi puluhan saja.
///
/// **Jangan menghapus filternya.** Kalau butuh data lama, ambil sekali lewat
/// `.get()` — jangan dijadikan listener.
class RealtimeService {
  RealtimeService._();
  static final RealtimeService instance = RealtimeService._();

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  final StreamController<void> _queueUpdateController =
      StreamController<void>.broadcast();
  final StreamController<void> _counterUpdateController =
      StreamController<void>.broadcast();
  final StreamController<void> _callUpdateController =
      StreamController<void>.broadcast();
  final StreamController<void> _settingsUpdateController =
      StreamController<void>.broadcast();

  Stream<void> get onQueueUpdate => _queueUpdateController.stream;
  Stream<void> get onCounterUpdate => _counterUpdateController.stream;
  Stream<void> get onCallUpdate => _callUpdateController.stream;
  Stream<void> get onSettingsUpdate => _settingsUpdateController.stream;

  /// Paksa semua cubit yang lagi dengerin `onQueueUpdate` refresh sekarang
  /// juga — dipakai setelah aksi yang KITA SENDIRI tau pasti ngubah data
  /// `queues` (mis. reset antrian), daripada nunggu propagasi listener
  /// Firestore yang kadang ada jeda dikit.
  void notifyQueueUpdate() => _queueUpdateController.add(null);

  /// Perubahan data digabung dulu sebelum diteruskan ke cubit.
  ///
  /// Tiap event `onQueueUpdate`/`onCallUpdate` bikin cubit MENJALANKAN QUERY
  /// BARU (lihat CounterCubit.refreshQueueInfo) — satu query per layanan,
  /// jadi sekali refresh itu belasan query, bukan satu.
  ///
  /// Masalahnya satu aksi petugas nggak menghasilkan satu perubahan.
  /// "Panggil Berikutnya" saja mengubah dokumen antrian, membuat dokumen
  /// panggilan baru, dan menonaktifkan panggilan sebelumnya — tiga event
  /// dalam hitungan milidetik. Tanpa penggabungan ini, masing-masing memicu
  /// refresh penuh sendiri-sendiri.
  ///
  /// Inilah penyumbang terbesar habisnya 44.000 baca pada 2026-08-04 —
  /// bukan ukuran datanya, yang cuma 1.267 dokumen. 800ms nggak terasa di
  /// layar antrian, tapi memotong refresh berlipat jadi satu.
  static const Duration _debounce = Duration(milliseconds: 800);
  Timer? _queueDebounceTimer;
  Timer? _callDebounceTimer;

  void _emitQueueUpdate() {
    _queueDebounceTimer?.cancel();
    _queueDebounceTimer = Timer(
      _debounce,
      () => _queueUpdateController.add(null),
    );
  }

  void _emitCallUpdate() {
    _callDebounceTimer?.cancel();
    _callDebounceTimer = Timer(
      _debounce,
      () => _callUpdateController.add(null),
    );
  }

  bool _subscribed = false;

  /// Tanggal yang sedang dilanggan. Listener `queues` dibuat sekali dengan
  /// tanggal tetap, jadi kiosk yang menyala melewati tengah malam bakal
  /// terus mendengarkan tanggal kemarin dan antrian hari baru nggak pernah
  /// muncul. [_dateWatcher] yang menanganinya.
  String _subscribedDate = _todayKey();
  Timer? _dateWatcher;
  final List<StreamSubscription<QuerySnapshot>> _subscriptions = [];

  /// Subscribe ke semua collection
  Future<void> subscribe() async {
    if (_subscribed) return;

    try {
      _subscriptions.add(
        _db
            .collection('queues')
            .where('dateKey', isEqualTo: _subscribedDate)
            .snapshots()
            .listen((snapshot) {
              debugPrint(
                'Realtime queues: ${snapshot.docChanges.length} change(s)',
              );
              _emitQueueUpdate();
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

      _subscriptions.add(
        _db
            .collection('calls')
            .where('is_active', isEqualTo: true)
            .snapshots()
            .listen((snapshot) {
              debugPrint(
                'Realtime calls: ${snapshot.docChanges.length} change(s)',
              );
              _emitCallUpdate();
            }),
      );

      _subscriptions.add(
        _db.collection('settings').snapshots().listen((snapshot) {
          debugPrint(
            'Realtime settings: ${snapshot.docChanges.length} change(s)',
          );
          // SettingsRemoteDatasource menyimpan seluruh settings di memori
          // selama 30 detik. Cache itu punya invalidateCache(), tapi
          // sebelumnya nggak ada yang memanggilnya dari sini — jadi
          // perubahan dari Admin baru kebaca kiosk setelah cache-nya
          // kedaluwarsa sendiri.
          //
          // Efeknya bikin bingung waktu uji suara: admin ganti berkas audio
          // lalu langsung menekan Uji, yang berbunyi masih berkas yang lama.
          // Dikosongkan pun sama — yang kebaca masih URL lama.
          Injection.instance.settingsDatasource.invalidateCache();
          _settingsUpdateController.add(null);
        }),
      );

      // Tengah malam listener `queues` harus dibuat ulang dengan tanggal
      // baru. Diperiksa tiap 10 menit — murah, dan cuma menembak Firestore
      // kalau tanggalnya benar-benar berganti.
      _dateWatcher ??= Timer.periodic(const Duration(minutes: 10), (_) {
        final today = _todayKey();
        if (today == _subscribedDate) return;
        debugPrint('Realtime: ganti hari $_subscribedDate -> $today');
        _subscribedDate = today;
        unsubscribe().then((_) => subscribe());
      });

      _subscribed = true;
      debugPrint('Realtime: subscribed to all collections');
    } catch (e) {
      debugPrint('Realtime subscribe error: $e');
    }
  }

  /// Unsubscribe semua
  Future<void> unsubscribe() async {
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    _subscriptions.clear();
    _subscribed = false;
  }

  void dispose() {
    _queueDebounceTimer?.cancel();
    _callDebounceTimer?.cancel();
    _dateWatcher?.cancel();
    _dateWatcher = null;
    _queueUpdateController.close();
    _counterUpdateController.close();
    _callUpdateController.close();
    _settingsUpdateController.close();
  }
}
