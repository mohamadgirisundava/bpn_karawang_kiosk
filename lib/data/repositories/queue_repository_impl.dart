import '../../domain/entities/applicant_type.dart';
import '../../domain/entities/queue_entity.dart';
import '../../domain/repositories/queue_repository.dart';
import '../datasources/queue_remote_datasource.dart';
import '../models/queue_model.dart';

/// Implementasi QueueRepository.
class QueueRepositoryImpl implements QueueRepository {
  final QueueRemoteDatasource datasource;

  const QueueRepositoryImpl(this.datasource);

  @override
  Future<QueueEntity> createQueue({
    required String counterId,
    required String counterCode,
    ApplicantType? applicantType,
  }) async {
    final doc = await datasource.createQueue(
      counterId: counterId,
      counterCode: counterCode,
      applicantType: applicantType,
    );

    return QueueModel.fromDoc(doc);
  }

  @override
  Future<String> createPrintJob({
    required String queueCode,
    required String counterName,
    required String takenAt,
    String? applicantType,
  }) {
    return datasource.createPrintJob(
      queueCode: queueCode,
      counterName: counterName,
      takenAt: takenAt,
      applicantType: applicantType,
    );
  }

  @override
  Stream<String> watchPrintJobStatus(String printJobId) {
    return datasource.watchPrintJobStatus(printJobId);
  }

}
