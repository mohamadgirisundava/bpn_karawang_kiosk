import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive.dart';
import 'gradient_button.dart';

/// Avatar (kotak atau bulat) dengan gradient glossy yang sama kayak
/// [GradientButton] — dipakai buat avatar kode loket (kartu "Pilih Jenis
/// Layanan", detail tiket) dan ikon fallback logo. Sama persis kayak app
/// Loket (Admin) biar konsisten, cuma ukurannya lewat Responsive.w()/sp().
class GlossyAvatar extends StatelessWidget {
  final String? code;
  final IconData? icon;
  final double size;
  final Color color;
  final BoxShape shape;
  final double? fontSize;

  const GlossyAvatar({
    super.key,
    this.code,
    this.icon,
    required this.size,
    this.color = AppColors.navy,
    this.shape = BoxShape.rectangle,
    this.fontSize,
  }) : assert(
         code != null || icon != null,
         'GlossyAvatar butuh salah satu dari code atau icon',
       );

  @override
  Widget build(BuildContext context) {
    final radius = shape == BoxShape.circle ? size / 2 : Responsive.r(12);
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: GlossyStyle.decoration(color, radius: radius),
      child: Stack(
        alignment: Alignment.center,
        children: [
          GlossyStyle.highlight(radius: radius, height: size * 0.5),
          if (icon != null)
            Icon(icon, size: fontSize ?? size * 0.5, color: AppColors.white)
          else
            Text(
              code!,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: fontSize ?? size * 0.38,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ),
        ],
      ),
    );
  }
}
