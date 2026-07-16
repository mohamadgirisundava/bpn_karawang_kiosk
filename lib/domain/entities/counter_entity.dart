import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Entity yang merepresentasikan loket/counter layanan.
class CounterEntity extends Equatable {
  final String id;
  final String code;
  final String name;
  final String description;
  final Color color;
  final IconData icon;
  final bool isPriority;

  const CounterEntity({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.color,
    required this.icon,
    this.isPriority = false,
  });

  @override
  List<Object?> get props => [id, code, name, description, isPriority];
}
