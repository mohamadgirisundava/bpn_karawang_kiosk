import 'package:flutter/material.dart';
import 'app_colors.dart';
import '../utils/responsive.dart';

/// Satu sumber definisi style tombol untuk seluruh app — semua tombol
/// (di layar manapun, di dialog manapun) harus lewat sini supaya
/// tinggi/padding/font/radius-nya selalu identik. Warna boleh beda untuk
/// keperluan semantik (merah = destruktif, gold = CTA highlight), tapi
/// bentuk & ukurannya tidak.
class AppButtonStyles {
  AppButtonStyles._();

  static ButtonStyle elevated({Color? background, Color? foreground}) {
    return ElevatedButton.styleFrom(
      backgroundColor: background ?? AppColors.navy,
      foregroundColor: foreground ?? AppColors.white,
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.w(24),
        vertical: Responsive.sp(14),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Responsive.r(4)),
      ),
      textStyle: TextStyle(
        fontFamily: 'Nunito',
        fontSize: Responsive.sp(16),
        fontWeight: FontWeight.bold,
      ),
      iconSize: Responsive.sp(20),
    );
  }

  static ButtonStyle outlined({Color? color}) {
    final resolvedColor = color ?? AppColors.navy;
    return OutlinedButton.styleFrom(
      foregroundColor: resolvedColor,
      side: BorderSide(color: resolvedColor, width: 1.5),
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.w(24),
        vertical: Responsive.sp(14),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Responsive.r(4)),
      ),
      textStyle: TextStyle(fontFamily: 'Nunito', fontSize: Responsive.sp(16)),
      iconSize: Responsive.sp(20),
    );
  }

  static ButtonStyle text({Color? color}) {
    return TextButton.styleFrom(
      foregroundColor: color ?? AppColors.textMuted,
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.w(16),
        vertical: Responsive.sp(12),
      ),
      textStyle: TextStyle(fontFamily: 'Nunito', fontSize: Responsive.sp(16)),
    );
  }
}
