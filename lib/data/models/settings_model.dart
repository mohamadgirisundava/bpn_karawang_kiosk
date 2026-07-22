import 'package:cloud_firestore/cloud_firestore.dart';

/// Model data untuk settings dari Firestore. Document ID = key.
class SettingsModel {
  final String key;
  final String value;
  final String description;

  const SettingsModel({
    required this.key,
    required this.value,
    this.description = '',
  });

  /// Construct dari Firestore DocumentSnapshot.
  factory SettingsModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return SettingsModel(
      key: doc.id,
      value: (data['value'] as String? ?? '').trim(),
      description: data['description'] as String? ?? '',
    );
  }
}
