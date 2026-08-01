import 'package:cloud_firestore/cloud_firestore.dart';

/// Reset manual antrian hari ini — dipicu dari menu satpam (Kiosk),
/// bukan operasi rutin. Menghapus semua tiket & panggilan aktif hari
/// ini, dan balikin nomor urut tiap loket ke 0 lagi. TIDAK BISA
/// dibatalkan — UI pemanggil wajib konfirmasi eksplisit dulu.
class QueueResetService {
  QueueResetService._();
  static final QueueResetService instance = QueueResetService._();

  String get _todayKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> resetToday() async {
    final db = FirebaseFirestore.instance;
    final todayKey = _todayKey;

    final queuesToday = await db
        .collection('queues')
        .where('dateKey', isEqualTo: todayKey)
        .get();
    final activeCalls = await db
        .collection('calls')
        .where('is_active', isEqualTo: true)
        .get();
    final activeCounters = await db
        .collection('counters')
        .where('is_active', isEqualTo: true)
        .get();

    // Skala kiosk kantor kecil — jauh di bawah limit 500 operasi/batch
    // Firestore, jadi nggak perlu di-chunk.
    final batch = db.batch();
    for (final doc in queuesToday.docs) {
      batch.delete(doc.reference);
    }
    for (final doc in activeCalls.docs) {
      batch.delete(doc.reference);
    }
    for (final counterDoc in activeCounters.docs) {
      batch.delete(
        db.collection('queue_counters').doc('${counterDoc.id}_$todayKey'),
      );
    }
    await batch.commit();
  }
}
