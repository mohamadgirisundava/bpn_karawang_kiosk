import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/utils/responsive.dart';

/// Label status singkat seperti "Prioritas": latar warna tipis, teks
/// berwarna. Huruf biasa, bukan kapital berjarak, supaya terbaca sebagai
/// keterangan dan bukan hiasan. Sama dengan `StatusBadge` di app Loket.
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final double? fontSize;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    this.color = AppColors.navy,
    this.fontSize,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final size = fontSize ?? Responsive.sp(12);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: size * 0.7,
        vertical: size * 0.28,
      ),
      decoration: BoxDecoration(
        color: Color.alphaBlend(color.withValues(alpha: 0.12), AppColors.white),
        borderRadius: BorderRadius.circular(AppRadius.badge),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: size * 1.2, color: color),
            SizedBox(width: size * 0.4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: size,
              fontWeight: FontWeight.w700,
              color: color,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}
