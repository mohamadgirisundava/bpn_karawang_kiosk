import 'package:flutter/material.dart';
import 'app_colors.dart';
import '../utils/responsive.dart';

/// Style untuk TextButton (tombol tersier — "Batal", "Tutup", dsb). Tombol
/// primer/destruktif sekarang lewat [GradientButton] (gaya glossy,
/// disamain sama app Loket/Admin), bukan lewat class ini lagi.
class AppButtonStyles {
  AppButtonStyles._();

  static ButtonStyle text({Color? color}) {
    return TextButton.styleFrom(
      foregroundColor: color ?? AppColors.textMuted,
      enableFeedback: false,
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.w(16),
        vertical: Responsive.sp(12),
      ),
      textStyle: TextStyle(fontFamily: 'Nunito', fontSize: Responsive.sp(16)),
    );
  }
}
