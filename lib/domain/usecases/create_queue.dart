import '../entities/applicant_type.dart';
import '../entities/queue_entity.dart';
import '../repositories/queue_repository.dart';

/// Use case untuk membuat tiket antrian baru.
class CreateQueue {
  final QueueRepository repository;

  const CreateQueue(this.repository);

  Future<QueueEntity> call({
    required String counterId,
    required String counterCode,
    ApplicantType? applicantType,
  }) {
    return repository.createQueue(
      counterId: counterId,
      counterCode: counterCode,
      applicantType: applicantType,
    );
  }
}
