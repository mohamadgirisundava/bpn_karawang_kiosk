import 'package:pocketbase/pocketbase.dart';
import '../../core/services/pocketbase_service.dart';

/// Remote data source untuk settings collection.
class SettingsRemoteDatasource {
  final PocketBase _pb;

  SettingsRemoteDatasource() : _pb = PocketBaseService.instance.client;

  static const Duration _timeout = Duration(seconds: 5);

  // Cache settings
  final Map<String, String> _cache = {};
  DateTime? _lastFetch;
  static const Duration _cacheDuration = Duration(seconds: 30);

  /// Ambil semua settings dan cache.
  Future<void> _fetchAll() async {
    final now = DateTime.now();
    if (_lastFetch != null && now.difference(_lastFetch!) < _cacheDuration) {
      return;
    }

    try {
      final records = await _pb
          .collection('settings')
          .getFullList()
          .timeout(_timeout);

      _cache.clear();
      for (final record in records) {
        final key = record.getStringValue('key').trim();
        final value = record.getStringValue('value').trim();
        if (key.isNotEmpty) _cache[key] = value;
      }
      _lastFetch = now;
    } catch (_) {
      // Pakai cache lama kalau gagal
    }
  }

  /// Get setting by key.
  Future<String> get(String key, {String defaultValue = ''}) async {
    await _fetchAll();
    return _cache[key] ?? defaultValue;
  }

  /// Get setting as int.
  Future<int> getInt(String key, {int defaultValue = 0}) async {
    final value = await get(key);
    return int.tryParse(value) ?? defaultValue;
  }

  /// Invalidate cache (dipanggil saat realtime update settings).
  void invalidateCache() {
    _lastFetch = null;
  }
}
