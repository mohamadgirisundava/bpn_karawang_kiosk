import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/entities/counter_entity.dart';

/// Model data untuk counter, meng-extend entity.
class CounterModel extends CounterEntity {
  const CounterModel({
    required super.id,
    required super.code,
    required super.name,
    required super.description,
    required super.color,
    required super.icon,
    super.isPriority,
  });

  /// Construct dari PocketBase RecordModel.
  factory CounterModel.fromRecord(RecordModel record) {
    final code = record.getStringValue('code');
    final name = record.getStringValue('name');
    final description = record.getStringValue('description');
    final colorHex = record.getStringValue('color');
    final iconName = record.getStringValue('icon');
    final isPriority = record.getBoolValue('is_priority');

    return CounterModel(
      id: record.id,
      code: code,
      name: name,
      description: description,
      color: _parseColor(colorHex),
      icon: _parseIcon(iconName),
      isPriority: isPriority,
    );
  }

  /// Parse hex color string ke Color.
  static Color _parseColor(String hex) {
    hex = hex.trim();
    if (hex.isEmpty) return AppColors.navy;
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    try {
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return AppColors.navy;
    }
  }

  /// Parse icon name ke IconData.
  static IconData _parseIcon(String iconName) {
    switch (iconName) {
      case 'assignment':
        return Icons.assignment;
      case 'swap_horiz':
        return Icons.swap_horiz;
      case 'priority_high':
        return Icons.priority_high;
      case 'info_outline':
        return Icons.info_outline;
      case 'description':
        return Icons.description;
      case 'home':
        return Icons.home;
      case 'person':
        return Icons.person;
      case 'receipt':
        return Icons.receipt;
      default:
        return Icons.confirmation_number;
    }
  }
}
