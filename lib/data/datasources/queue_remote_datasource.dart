import 'package:cloud_firestore/cloud_firestore.dart';

/// Remote data source untuk queue collection.
class QueueRemoteDatasource {
  final FirebaseFirestore _db;

  QueueRemoteDatasource() : _db = FirebaseFirestore.instance;

  static const Duration _timeout = Duration(seconds: 5);

  /// Key tanggal hari ini, format "YYYY-MM-DD".
  String get _todayKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Buat tiket antrian baru dengan nomor urut yang dijamin unik lewat
  /// Firestore transaction — menghindari race condition saat dua request
  /// nge-generate nomor bersamaan.
  Future<DocumentSnapshot<Map<String, dynamic>>> createQueue({
    required String counterId,
    required String counterCode,
  }) async {
    final dateKey = _todayKey;
    final counterRef = _db
        .collection('queue_counters')
        .doc('${counterId}_$dateKey');
    final queueRef = _db.collection('queues').doc();

    await _db.runTransaction((transaction) async {
      final counterSnap = await transaction.get(counterRef);
      final lastNumber = counterSnap.exists
          ? (counterSnap.data()?['lastNumber'] as int? ?? 0)
          : 0;
      final nextNumber = lastNumber + 1;
      final queueCode = '$counterCode${nextNumber.toString().padLeft(3, '0')}';

      transaction.set(counterRef, {'lastNumber': nextNumber});
      transaction.set(queueRef, {
        'counter': counterId,
        'queue_number': nextNumber,
        'queue_code': queueCode,
        'status': 'waiting',
        'date': dateKey,
        'dateKey': dateKey,
        'taken_at': DateTime.now().toUtc().toIso8601String(),
      });
    }).timeout(_timeout);

    return await queueRef.get();
  }

  /// Get nomor yang sedang dipanggil/dilayani untuk counter tertentu.
  Future<DocumentSnapshot<Map<String, dynamic>>?> getCurrentServing(
    String counterId,
  ) async {
    final result = await _db
        .collection('queues')
        .where('counter', isEqualTo: counterId)
        .where('dateKey', isEqualTo: _todayKey)
        .where('status', whereIn: ['called', 'serving'])
        .orderBy('called_at', descending: true)
        .limit(1)
        .get()
        .timeout(_timeout);

    if (result.docs.isEmpty) return null;
    return result.docs.first;
  }

  /// Get jumlah antrian menunggu untuk counter tertentu.
  Future<int> getWaitingCount(String counterId) async {
    final result = await _db
        .collection('queues')
        .where('counter', isEqualTo: counterId)
        .where('dateKey', isEqualTo: _todayKey)
        .where('status', isEqualTo: 'waiting')
        .count()
        .get()
        .timeout(_timeout);
    return result.count ?? 0;
  }
}
