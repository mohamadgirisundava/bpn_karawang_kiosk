import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/firestore_value.dart';
import '../../domain/entities/queue_entity.dart';

/// Model data untuk queue, meng-extend entity.
class QueueModel extends QueueEntity {
  const QueueModel({
    required super.id,
    required super.counterId,
    required super.queueNumber,
    required super.queueCode,
    required super.status,
    required super.date,
    super.takenAt,
    super.calledAt,
    super.completedAt,
    super.calledBy,
    super.deskNumber,
    super.applicantType,
  });

  /// Construct dari Firestore DocumentSnapshot.
  factory QueueModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      QueueModel.fromMap(doc.id, doc.data() ?? const {});

  /// Pemetaan sebenarnya, dipisah dari [DocumentSnapshot] supaya bisa diuji
  /// tanpa Firestore.
  ///
  /// **Semua field dibaca lewat helper toleran, bukan cast langsung.** Itu
  /// bukan soal kerapian: `RealtimeService` memetakan SELURUH snapshot dalam
  /// satu `map().toList()`, jadi satu dokumen yang bikin cast throw
  /// mengosongkan seluruh papan antrian sekaligus. Lihat
  /// `core/utils/firestore_value.dart` untuk kejadian yang melatarbelakanginya.
  factory QueueModel.fromMap(String id, Map<String, dynamic> data) {
    return QueueModel(
      id: id,
      counterId: asString(data['counter']),
      queueNumber: asInt(data['queue_number']),
      queueCode: asString(data['queue_code']),
      status: asString(data['status']),
      date: asString(data['date']),
      takenAt: asStringOrNull(data['taken_at']),
      calledAt: asStringOrNull(data['called_at']),
      completedAt: asStringOrNull(data['completed_at']),
      calledBy: asStringOrNull(data['called_by']),
      // Ditulis app Loket sebagai number (`required int deskNumber`), tapi
      // dokumen lama hasil input manual bisa saja string — makanya toleran.
      deskNumber: asIntOrNull(data['desk_number']),
      applicantType: asStringOrNull(data['applicant_type']),
    );
  }
}
