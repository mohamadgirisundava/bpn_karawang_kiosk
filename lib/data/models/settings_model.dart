import 'package:pocketbase/pocketbase.dart';

/// Model data untuk settings dari PocketBase.
class SettingsModel {
  final String id;
  final String key;
  final String value;
  final String description;

  const SettingsModel({
    required this.id,
    required this.key,
    required this.value,
    this.description = '',
  });

  /// Construct dari PocketBase RecordModel.
  factory SettingsModel.fromRecord(RecordModel record) {
    return SettingsModel(
      id: record.id,
      key: record.getStringValue('key').trim(),
      value: record.getStringValue('value').trim(),
      description: record.getStringValue('description'),
    );
  }
}
