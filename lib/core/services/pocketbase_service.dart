import 'package:pocketbase/pocketbase.dart';

/// Service singleton untuk koneksi ke PocketBase.
class PocketBaseService {
  PocketBaseService._();

  static final PocketBaseService instance = PocketBaseService._();

  static const String baseUrl = 'http://10.10.10.89:8090';

  late final PocketBase _pb;

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _pb = PocketBase(baseUrl);
    _initialized = true;
  }

  PocketBase get client => _pb;
}
