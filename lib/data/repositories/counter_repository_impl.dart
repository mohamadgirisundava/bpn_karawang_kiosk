import '../../domain/entities/counter_entity.dart';
import '../../domain/repositories/counter_repository.dart';
import '../datasources/counter_remote_datasource.dart';
import '../models/counter_model.dart';

/// Implementasi CounterRepository.
class CounterRepositoryImpl implements CounterRepository {
  final CounterRemoteDatasource datasource;

  const CounterRepositoryImpl(this.datasource);

  @override
  Future<List<CounterEntity>> getActiveCounters() async {
    final docs = await datasource.getActiveCounters();
    return docs.map((d) => CounterModel.fromDoc(d)).toList();
  }
}
