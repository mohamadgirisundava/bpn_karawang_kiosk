import 'package:pocketbase/pocketbase.dart';
import '../../core/services/pocketbase_service.dart';

/// Remote data source untuk counter collection.
class CounterRemoteDatasource {
  final PocketBase _pb;

  CounterRemoteDatasource() : _pb = PocketBaseService.instance.client;

  static const Duration _timeout = Duration(seconds: 5);

  /// Ambil semua counter aktif, urut sort_order.
  Future<List<RecordModel>> getActiveCounters() async {
    final result = await _pb
        .collection('counters')
        .getFullList(filter: 'is_active = true', sort: 'sort_order')
        .timeout(_timeout);
    return result;
  }

  /// Ambil counter by ID.
  Future<RecordModel> getCounter(String id) async {
    return await _pb.collection('counters').getOne(id).timeout(_timeout);
  }
}
