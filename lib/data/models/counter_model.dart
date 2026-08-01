import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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
    super.isPlotting,
  });

  /// Construct dari Firestore DocumentSnapshot.
  factory CounterModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final code = data['code'] as String? ?? '';
    final name = data['name'] as String? ?? '';
    final description = data['description'] as String? ?? '';
    final colorHex = data['color'] as String? ?? '';
    final iconName = data['icon'] as String? ?? '';
    final isPriority = data['is_priority'] as bool? ?? false;
    final isPlotting = data['is_plotting'] as bool? ?? false;

    return CounterModel(
      id: doc.id,
      code: code,
      name: name,
      description: description,
      color: _parseColor(colorHex),
      icon: _parseIcon(iconName),
      isPriority: isPriority,
      isPlotting: isPlotting,
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
