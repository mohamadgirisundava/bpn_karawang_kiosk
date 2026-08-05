import '../entities/queue_entity.dart';
import '../entities/queue_info.dart';

/// Menghitung "sedang dilayani" + "jumlah menunggu" per layanan.
///
/// **Murni perhitungan di memori — nggak menyentuh Firestore.** Dulu ini
/// menjalankan 2 query per layanan (satu "sedang dilayani", satu `count()`),
/// diulang tiap ada perubahan apa pun di `queues`. Sumbernya sekarang
/// `RealtimeService.todayQueues`, snapshot yang sudah dibayar sekali.
///
/// Catatan: `QueueEntity.status` di app ini masih String (di app Loket sudah
/// enum), jadi perbandingannya pakai teks.
class GetQueueInfo {
  const GetQueueInfo();

  /// [todayQueues] seluruh tiket hari ini, [counterIds] layanan aktif.
  /// Layanan tanpa tiket tetap muncul dengan nilai kosong, biar kartunya
  /// nggak hilang dari layar kiosk.
  Map<String, QueueInfo> getAll(
    List<QueueEntity> todayQueues,
    List<String> counterIds,
  ) {
    final waiting = <String, int>{};
    final serving = <String, QueueEntity>{};

    for (final q in todayQueues) {
      if (q.status == 'waiting') {
        waiting[q.counterId] = (waiting[q.counterId] ?? 0) + 1;
        continue;
      }
      if (q.status != 'called' && q.status != 'serving') continue;

      // Panggilan terbaru layanan ini — sama seperti
      // `orderBy('called_at', descending: true).limit(1)` dulu.
      final current = serving[q.counterId];
      if (current == null ||
          (q.calledAt ?? '').compareTo(current.calledAt ?? '') > 0) {
        serving[q.counterId] = q;
      }
    }

    return {
      for (final id in counterIds)
        id: QueueInfo(
          currentServing: serving[id]?.queueCode ?? '-',
          waitingCount: waiting[id] ?? 0,
        ),
    };
  }
}
