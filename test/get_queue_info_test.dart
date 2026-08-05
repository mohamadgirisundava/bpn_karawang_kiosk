import 'package:flutter_test/flutter_test.dart';
import 'package:bpn_karawang_kiosk/domain/entities/queue_entity.dart';
import 'package:bpn_karawang_kiosk/domain/usecases/get_queue_info.dart';

/// Kartu layanan di kiosk sekarang dihitung dari snapshot di memori, bukan
/// dari query per layanan. Tes ini mengunci perilaku yang dulu dijamin oleh
/// query `count()` + `orderBy(called_at).limit(1)`.

QueueEntity q({
  required String counterId,
  required int number,
  required String status,
  String? calledAt,
}) => QueueEntity(
  id: '$counterId-$number',
  counterId: counterId,
  queueNumber: number,
  queueCode: '${counterId.toUpperCase()}${number.toString().padLeft(3, '0')}',
  status: status,
  date: '2026-08-06',
  calledAt: calledAt,
);

void main() {
  const usecase = GetQueueInfo();

  test('hitung menunggu per layanan, terpisah antar layanan', () {
    final info = usecase.getAll([
      q(counterId: 'a', number: 1, status: 'waiting'),
      q(counterId: 'a', number: 2, status: 'waiting'),
      q(counterId: 'b', number: 1, status: 'waiting'),
      q(counterId: 'a', number: 3, status: 'completed'),
    ], ['a', 'b']);

    expect(info['a']!.waitingCount, 2);
    expect(info['b']!.waitingCount, 1);
  });

  test('sedang dilayani = panggilan terbaru layanan itu', () {
    final info = usecase.getAll([
      q(
        counterId: 'a',
        number: 1,
        status: 'called',
        calledAt: '2026-08-06T02:00:00Z',
      ),
      q(
        counterId: 'a',
        number: 2,
        status: 'serving',
        calledAt: '2026-08-06T05:00:00Z',
      ),
      q(
        counterId: 'a',
        number: 3,
        status: 'called',
        calledAt: '2026-08-06T03:00:00Z',
      ),
    ], ['a']);

    expect(info['a']!.currentServing, 'A002');
  });

  test('layanan tanpa tiket tetap muncul dengan nilai kosong', () {
    final info = usecase.getAll([
      q(counterId: 'a', number: 1, status: 'waiting'),
    ], ['a', 'b', 'c']);

    expect(info.keys, containsAll(['a', 'b', 'c']));
    expect(info['c']!.waitingCount, 0);
    expect(info['c']!.currentServing, '-');
  });

  test('tiket selesai/dilewati nggak dihitung sebagai menunggu', () {
    final info = usecase.getAll([
      q(counterId: 'a', number: 1, status: 'completed'),
      q(counterId: 'a', number: 2, status: 'skipped'),
    ], ['a']);

    expect(info['a']!.waitingCount, 0);
    expect(info['a']!.currentServing, '-');
  });

  test('daftar kosong nggak bikin error', () {
    final info = usecase.getAll(const [], ['a']);
    expect(info['a']!.waitingCount, 0);
    expect(info['a']!.currentServing, '-');
  });
}
