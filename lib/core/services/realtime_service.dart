import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';
import 'pocketbase_service.dart';

/// Service untuk realtime subscription ke semua collection PocketBase.
class RealtimeService {
  RealtimeService._();
  static final RealtimeService instance = RealtimeService._();

  PocketBase get _pb => PocketBaseService.instance.client;

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

  bool _subscribed = false;

  /// Subscribe ke semua collection
  Future<void> subscribe() async {
    if (_subscribed) return;

    try {
      await _pb.collection('queues').subscribe('*', (event) {
        debugPrint('Realtime queues: ${event.action}');
        _queueUpdateController.add(null);
      });

      await _pb.collection('counters').subscribe('*', (event) {
        debugPrint('Realtime counters: ${event.action}');
        _counterUpdateController.add(null);
      });

      await _pb.collection('calls').subscribe('*', (event) {
        debugPrint('Realtime calls: ${event.action}');
        _callUpdateController.add(null);
      });

      await _pb.collection('settings').subscribe('*', (event) {
        debugPrint('Realtime settings: ${event.action}');
        _settingsUpdateController.add(null);
      });

      _subscribed = true;
      debugPrint('Realtime: subscribed to all collections');
    } catch (e) {
      debugPrint('Realtime subscribe error: $e');
    }
  }

  /// Unsubscribe semua
  Future<void> unsubscribe() async {
    try {
      await _pb.collection('queues').unsubscribe('*');
      await _pb.collection('counters').unsubscribe('*');
      await _pb.collection('calls').unsubscribe('*');
      await _pb.collection('settings').unsubscribe('*');
      _subscribed = false;
    } catch (_) {}
  }

  void dispose() {
    _queueUpdateController.close();
    _counterUpdateController.close();
    _callUpdateController.close();
    _settingsUpdateController.close();
  }
}
