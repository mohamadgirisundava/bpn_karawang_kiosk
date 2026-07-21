import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';

/// Service singleton untuk koneksi ke PocketBase.
class PocketBaseService {
  PocketBaseService._();

  static final PocketBaseService instance = PocketBaseService._();

  // Emulator Android mengakses loopback host lewat 10.0.2.2, bukan 127.0.0.1.
  static String get baseUrl {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8090';
    }
    return 'http://127.0.0.1:8090';
  }

  late final PocketBase _pb;

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _pb = PocketBase(baseUrl);
    _initialized = true;
  }

  PocketBase get client => _pb;
}
