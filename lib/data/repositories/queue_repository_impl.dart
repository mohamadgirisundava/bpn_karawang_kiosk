import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/queue_entity.dart';
import '../../domain/entities/queue_info.dart';
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
  }) async {
    final doc = await datasource.createQueue(
      counterId: counterId,
      counterCode: counterCode,
    );

    return QueueModel.fromDoc(doc);
  }

  @override
  Future<String> createPrintJob({
    required String queueCode,
    required String counterName,
    required String takenAt,
  }) {
    return datasource.createPrintJob(
      queueCode: queueCode,
      counterName: counterName,
      takenAt: takenAt,
    );
  }

  @override
  Stream<String> watchPrintJobStatus(String printJobId) {
    return datasource.watchPrintJobStatus(printJobId);
  }

  @override
  Future<QueueInfo> getQueueInfo(String counterId) async {
    // Sengaja nggak nangkep error di sini (dulu ada try/catch yang balikin
    // QueueInfo(0) diem-diem kalau query gagal/timeout — bikin UI nampilin
    // "0 antrian" yang KELIATAN valid padahal sebenernya fetch-nya gagal,
    // dan nggak pernah retry sampe ada trigger nggak sengaja dari tempat
    // lain kayak realtime listener). Biarin error nyebar ke caller
    // (CounterCubit) yang punya logic retry buat kasus ini.
    final results = await Future.wait([
      datasource.getCurrentServing(counterId),
      datasource.getWaitingCount(counterId),
    ]);
    final serving = results[0] as DocumentSnapshot<Map<String, dynamic>>?;
    final waiting = results[1] as int;

    return QueueInfo(
      currentServing: serving?.data()?['queue_code'] as String? ?? '-',
      waitingCount: waiting,
    );
  }

  @override
  Future<Map<String, QueueInfo>> getAllQueueInfo(
    List<String> counterIds,
  ) async {
    // Paralel, bukan satu-satu berurutan — selain lebih cepat, juga
    // ngurangin resiko query belakangan kena timeout gara-gara nunggu
    // antrian query di depannya kelar dulu (nyumbang ke bug "0 antrian"
    // pas cold-start, lihat komentar di getQueueInfo).
    final entries = await Future.wait(
      counterIds.map((id) async => MapEntry(id, await getQueueInfo(id))),
    );
    return Map.fromEntries(entries);
  }
}
