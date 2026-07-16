import 'package:pocketbase/pocketbase.dart';
import '../../core/services/pocketbase_service.dart';

/// Remote data source untuk queue collection.
class QueueRemoteDatasource {
  final PocketBase _pb;

  QueueRemoteDatasource() : _pb = PocketBaseService.instance.client;

  static const Duration _timeout = Duration(seconds: 5);

  /// Filter hari ini menggunakan format date ~ "YYYY-MM-DD".
  String get _todayFilter {
    final now = DateTime.now();
    final today =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return 'date ~ "$today"';
  }

  /// Value date untuk create record.
  String get _todayDateValue {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} 12:00:00.000Z';
  }

  /// Ambil nomor antrian berikutnya untuk counter tertentu.
  Future<int> getNextQueueNumber(String counterId) async {
    final result = await _pb
        .collection('queues')
        .getList(
          filter: 'counter = "$counterId" && $_todayFilter',
          sort: '-queue_number',
          perPage: 1,
        )
        .timeout(_timeout);

    if (result.items.isEmpty) return 1;
    return (result.items.first.getIntValue('queue_number')) + 1;
  }

  /// Buat tiket antrian baru.
  Future<RecordModel> createQueue({
    required String counterId,
    required String counterCode,
    required int queueNumber,
    required String queueCode,
  }) async {
    final record = await _pb
        .collection('queues')
        .create(
          body: {
            'counter': counterId,
            'queue_number': queueNumber,
            'queue_code': queueCode,
            'status': 'waiting',
            'date': _todayDateValue,
            'taken_at': DateTime.now().toUtc().toIso8601String().replaceFirst(
              'T',
              ' ',
            ),
          },
        )
        .timeout(_timeout);
    return record;
  }

  /// Get nomor yang sedang dipanggil/dilayani untuk counter tertentu.
  Future<RecordModel?> getCurrentServing(String counterId) async {
    final result = await _pb
        .collection('queues')
        .getList(
          filter:
              'counter = "$counterId" && $_todayFilter && (status = "called" || status = "serving")',
          sort: '-called_at',
          perPage: 1,
        )
        .timeout(_timeout);

    if (result.items.isEmpty) return null;
    return result.items.first;
  }

  /// Get jumlah antrian menunggu untuk counter tertentu.
  Future<int> getWaitingCount(String counterId) async {
    final result = await _pb
        .collection('queues')
        .getList(
          filter:
              'counter = "$counterId" && $_todayFilter && status = "waiting"',
          perPage: 1,
        )
        .timeout(_timeout);
    return result.totalItems;
  }
}
