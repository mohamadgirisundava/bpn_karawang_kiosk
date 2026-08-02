import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../injection.dart';

/// Service untuk realtime subscription ke semua collection Firestore.
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

  bool _subscribed = false;
  final List<StreamSubscription<QuerySnapshot>> _subscriptions = [];

  /// Subscribe ke semua collection
  Future<void> subscribe() async {
    if (_subscribed) return;

    try {
      _subscriptions.add(
        _db.collection('queues').snapshots().listen((snapshot) {
          debugPrint(
            'Realtime queues: ${snapshot.docChanges.length} change(s)',
          );
          _queueUpdateController.add(null);
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
        _db.collection('calls').snapshots().listen((snapshot) {
          debugPrint('Realtime calls: ${snapshot.docChanges.length} change(s)');
          _callUpdateController.add(null);
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
    _queueUpdateController.close();
    _counterUpdateController.close();
    _callUpdateController.close();
    _settingsUpdateController.close();
  }
}
