import 'package:equatable/equatable.dart';

/// Entity yang merepresentasikan satu record antrian.
class QueueEntity extends Equatable {
  final String id;
  final String counterId;
  final int queueNumber;
  final String queueCode;
  final String status;
  final String date;
  final String? takenAt;
  final String? calledAt;
  final String? completedAt;
  final String? calledBy;

  /// Nomor meja fisik saat dipanggil. **Number di Firestore**, bukan string —
  /// app Loket menulisnya lewat `required int deskNumber`. Sempat dideklarasi
  /// `String?` di sini, dan cast-nya throw untuk tiap tiket yang sudah
  /// dipanggil (lihat `core/utils/firestore_value.dart`).
  final int? deskNumber;
  final String? applicantType;

  const QueueEntity({
    required this.id,
    required this.counterId,
    required this.queueNumber,
    required this.queueCode,
    required this.status,
    required this.date,
    this.takenAt,
    this.calledAt,
    this.completedAt,
    this.calledBy,
    this.deskNumber,
    this.applicantType,
  });

  @override
  List<Object?> get props => [id, counterId, queueNumber, queueCode, status];
}
