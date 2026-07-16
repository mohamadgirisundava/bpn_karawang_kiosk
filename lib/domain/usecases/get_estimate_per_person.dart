import '../repositories/settings_repository.dart';

/// Use case untuk mengambil estimasi waktu per orang.
class GetEstimatePerPerson {
  final SettingsRepository repository;

  const GetEstimatePerPerson(this.repository);

  Future<int> call() {
    return repository.getEstimatePerPerson();
  }
}
