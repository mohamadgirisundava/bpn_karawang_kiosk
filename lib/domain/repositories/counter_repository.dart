import '../entities/counter_entity.dart';

/// Abstract repository untuk operasi counter.
abstract class CounterRepository {
  /// Ambil semua counter yang aktif, terurut.
  Future<List<CounterEntity>> getActiveCounters();
}
