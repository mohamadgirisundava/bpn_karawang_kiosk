import '../entities/counter_entity.dart';
import '../repositories/counter_repository.dart';

/// Use case untuk mengambil daftar counter aktif.
class GetActiveCounters {
  final CounterRepository repository;

  const GetActiveCounters(this.repository);

  Future<List<CounterEntity>> call() {
    return repository.getActiveCounters();
  }
}
