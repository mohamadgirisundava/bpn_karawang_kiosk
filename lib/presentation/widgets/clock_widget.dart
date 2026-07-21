import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive.dart';

/// Widget jam dan tanggal real-time untuk header kiosk.
class ClockWidget extends StatefulWidget {
  const ClockWidget({super.key});

  @override
  State<ClockWidget> createState() => _ClockWidgetState();
}

class _ClockWidgetState extends State<ClockWidget> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  static const List<String> _namaHari = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  static const List<String> _namaBulan = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String get _formattedTime {
    final hour = _now.hour.toString().padLeft(2, '0');
    final minute = _now.minute.toString().padLeft(2, '0');
    final second = _now.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }

  String get _formattedDate {
    final hari = _namaHari[_now.weekday - 1];
    final tanggal = _now.day;
    final bulan = _namaBulan[_now.month - 1];
    final tahun = _now.year;
    return '$hari, $tanggal $bulan $tahun';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          _formattedTime,
          style: TextStyle(
            fontSize: Responsive.sp(22 * 0.8),
            fontWeight: FontWeight.bold,
            color: AppColors.white,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        Text(
          _formattedDate,
          style: TextStyle(
            fontSize: Responsive.sp(11 * 0.8),
            color: AppColors.goldLight,
          ),
        ),
      ],
    );
  }
}
