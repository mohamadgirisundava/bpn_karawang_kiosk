/// Abstract repository untuk settings.
abstract class SettingsRepository {
  /// Ambil estimasi menit per orang.
  Future<int> getEstimatePerPerson();
}
