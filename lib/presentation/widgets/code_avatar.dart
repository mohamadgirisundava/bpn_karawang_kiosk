import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/theme/app_theme.dart';

/// Kotak kecil berisi kode layanan ("A") atau ikon — latar warna tipis,
/// isi berwarna penuh. Sama dengan `CodeAvatar` di app Loket, supaya kode
/// layanan bentuknya sama di kiosk, layar petugas, dan dashboard admin.
class CodeAvatar extends StatelessWidget {
  final String? code;
  final IconData? icon;
  final double size;
  final Color color;
  final BoxShape shape;
  final double? fontSize;

  const CodeAvatar({
    super.key,
    this.code,
    this.icon,
    required this.size,
    this.color = AppColors.navy,
    this.shape = BoxShape.rectangle,
    this.fontSize,
  }) : assert(
         code != null || icon != null,
         'CodeAvatar butuh salah satu dari code atau icon',
       );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Color.alphaBlend(color.withValues(alpha: 0.1), AppColors.white),
        shape: shape,
        borderRadius: shape == BoxShape.circle
            ? null
            : BorderRadius.circular(AppRadius.control),
      ),
      child: icon != null
          ? Icon(icon, size: fontSize ?? size * 0.5, color: color)
          : Text(
              code!,
              style: TextStyle(
                fontFamily: AppTheme.numberFamily,
                fontSize: fontSize ?? size * 0.42,
                fontWeight: FontWeight.w700,
                color: color,
                height: 1,
              ),
            ),
    );
  }
}
