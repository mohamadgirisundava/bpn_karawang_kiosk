import 'package:bpn_karawang_kiosk/data/models/queue_model.dart';
import 'package:bpn_karawang_kiosk/domain/usecases/get_queue_info.dart';
import 'package:flutter_test/flutter_test.dart';

/// Dokumen `queues` seperti yang ditulis app Loket saat tiket dipanggil.
/// `desk_number` di sini NUMBER — itu tipe aslinya di Firestore.
Map<String, dynamic> _calledDoc({
  String counter = 'counter-a',
  String code = 'A001',
}) => {
  'counter': counter,
  'queue_number': 1,
  'queue_code': code,
  'status': 'called',
  'date': '2026-08-06',
  'dateKey': '2026-08-06',
  'taken_at': '2026-08-06T01:00:00.000Z',
  'called_at': '2026-08-06T01:05:00.000Z',
  'desk_number': 3,
  'called_by': 'petugas-1',
};

void main() {
  group('QueueModel.fromMap', () {
    test('desk_number bertipe number nggak bikin pemetaan throw', () {
      // Regresi 2026-08-06: field ini dibaca `as String?`, padahal Loket
      // menulisnya sebagai int. Tiap tiket yang sudah dipanggil bikin
      // pemetaan snapshot throw, `_todayQueues` tetap kosong, dan papan
      // kiosk permanen menampilkan "0 orang dalam antrian".
      final model = QueueModel.fromMap('doc-1', _calledDoc());

      expect(model.deskNumber, 3);
      expect(model.status, 'called');
      expect(model.queueCode, 'A001');
    });

    test('desk_number bertipe string (dokumen lama) tetap terbaca', () {
      final model = QueueModel.fromMap('doc-1', {
        ..._calledDoc(),
        'desk_number': '3',
      });

      expect(model.deskNumber, 3);
    });

    test('field opsional yang kosong jadi null, bukan throw', () {
      final model = QueueModel.fromMap('doc-1', {
        'counter': 'counter-a',
        'queue_number': 7,
        'queue_code': 'A007',
        'status': 'waiting',
        'date': '2026-08-06',
        'taken_at': '2026-08-06T01:00:00.000Z',
      });

      expect(model.deskNumber, isNull);
      expect(model.calledAt, isNull);
      expect(model.calledBy, isNull);
      expect(model.applicantType, isNull);
    });

    test('dokumen kosong nggak menjatuhkan seluruh snapshot', () {
      final model = QueueModel.fromMap('doc-kosong', const {});

      expect(model.id, 'doc-kosong');
      expect(model.counterId, '');
      expect(model.queueNumber, 0);
    });

    test('queue_number bertipe string tetap jadi angka', () {
      final model = QueueModel.fromMap('doc-1', {
        ..._calledDoc(),
        'queue_number': '12',
      });

      expect(model.queueNumber, 12);
    });
  });

  test('snapshot campuran tetap terhitung penuh sampai UI', () {
    // Bentuk aslinya: satu list yang dipetakan sekaligus, persis seperti
    // `RealtimeService`. Sebelum perbaikan, dokumen "called" di tengah bikin
    // `map().toList()` throw dan MENGOSONGKAN hasil buat semua layanan —
    // bukan cuma layanan yang tiketnya bermasalah.
    final docs = [
      {..._calledDoc(counter: 'counter-a', code: 'A001')},
      {
        ..._calledDoc(counter: 'counter-a', code: 'A002'),
        'status': 'waiting',
        'called_at': null,
        'desk_number': null,
      },
      {
        ..._calledDoc(counter: 'counter-b', code: 'B001'),
        'status': 'waiting',
        'called_at': null,
        'desk_number': null,
      },
    ];

    final queues = docs
        .map((d) => QueueModel.fromMap('doc', d))
        .toList(growable: false);

    final info = const GetQueueInfo().getAll(queues, [
      'counter-a',
      'counter-b',
    ]);

    expect(info['counter-a']!.currentServing, 'A001');
    expect(info['counter-a']!.waitingCount, 1);
    expect(info['counter-b']!.waitingCount, 1);
  });
}
