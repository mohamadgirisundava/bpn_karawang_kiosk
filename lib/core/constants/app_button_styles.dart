import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_radius.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';

/// Style untuk TextButton (tombol tersier — "Batal", "Tutup", dsb). Tombol
/// utama/destruktif lewat [AppButton], bukan class ini.
class AppButtonStyles {
  AppButtonStyles._();

  static ButtonStyle text({Color? color}) {
    return TextButton.styleFrom(
      foregroundColor: color ?? AppColors.navy,
      enableFeedback: false,
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.w(16),
        vertical: Responsive.sp(12),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      // fontFamily wajib di sini: textStyle ButtonStyle tidak mewarisi
      // font tema, tanpa ini jatuh ke font bawaan platform.
      textStyle: TextStyle(
        fontFamily: AppTheme.fontFamily,
        fontSize: Responsive.sp(15),
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
