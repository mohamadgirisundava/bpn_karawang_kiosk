import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive.dart';
import 'gradient_button.dart';

/// Badge/pill label glossy — buat status singkat kayak "PRIORITAS", beda
/// dari [GradientButton] (nggak bisa ditekan, `IgnorePointer` implisit
/// lewat nggak ada `InkWell`). Sama gaya gradient+highlight-nya, cuma
/// ukuran lebih kecil & selalu bentuk pill (stadium).
class GlossyBadge extends StatelessWidget {
  final String label;
  final Color color;
  final double? fontSize;
  final EdgeInsetsGeometry? padding;

  const GlossyBadge({
    super.key,
    required this.label,
    this.color = AppColors.navy,
    this.fontSize,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    const radius = 999.0;
    return Container(
      clipBehavior: Clip.antiAlias,
      padding:
          padding ??
          EdgeInsets.symmetric(
            horizontal: Responsive.w(10),
            vertical: Responsive.h(4),
          ),
      decoration: GlossyStyle.decoration(color, radius: radius),
      child: Stack(
        alignment: Alignment.center,
        children: [
          GlossyStyle.highlight(radius: radius, height: Responsive.h(10)),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: fontSize ?? Responsive.sp(11),
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
