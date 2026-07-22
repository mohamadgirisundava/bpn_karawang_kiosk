import 'package:cloud_firestore/cloud_firestore.dart';

/// Remote data source untuk counter collection.
class CounterRemoteDatasource {
  final FirebaseFirestore _db;

  CounterRemoteDatasource() : _db = FirebaseFirestore.instance;

  static const Duration _timeout = Duration(seconds: 5);

  /// Ambil semua counter aktif, urut sort_order.
  Future<List<DocumentSnapshot<Map<String, dynamic>>>> getActiveCounters() async {
    final result = await _db
        .collection('counters')
        .where('is_active', isEqualTo: true)
        .orderBy('sort_order')
        .get()
        .timeout(_timeout);
    return result.docs;
  }

  /// Ambil counter by ID.
  Future<DocumentSnapshot<Map<String, dynamic>>> getCounter(String id) async {
    return await _db.collection('counters').doc(id).get().timeout(_timeout);
  }
}
