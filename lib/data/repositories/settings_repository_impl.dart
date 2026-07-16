import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_remote_datasource.dart';

/// Implementasi SettingsRepository.
class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsRemoteDatasource datasource;

  const SettingsRepositoryImpl(this.datasource);

  @override
  Future<int> getEstimatePerPerson() async {
    datasource.invalidateCache(); // Selalu fetch fresh
    return await datasource.getInt('estimate_per_person', defaultValue: 5);
  }
}
