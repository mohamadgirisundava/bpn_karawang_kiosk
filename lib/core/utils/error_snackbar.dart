import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_radius.dart';
import 'responsive.dart';

void _showKioskSnackbar(
  BuildContext context, {
  required String message,
  required Color background,
  required IconData icon,
  required Duration duration,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: duration,
        backgroundColor: background,
        behavior: SnackBarBehavior.floating,
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.w(18),
          vertical: Responsive.h(14),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
        content: Row(
          children: [
            Icon(icon, color: AppColors.white, size: Responsive.sp(22)),
            SizedBox(width: Responsive.w(12)),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: Responsive.sp(15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
}

/// Snackbar error seragam — merah tegas + teks putih, kontras jelas
/// (dulu kuning/oren dengan teks putih default, susah dibaca).
void showErrorSnackbar(
  BuildContext context,
  String message, {
  Duration duration = const Duration(seconds: 4),
}) {
  _showKioskSnackbar(
    context,
    message: message,
    background: AppColors.danger,
    icon: Icons.error_outline,
    duration: duration,
  );
}

/// Snackbar sukses seragam — hijau, dipakai buat konfirmasi aksi berhasil
/// (mis. reset antrian) biar konsisten sama gaya error di atas.
void showSuccessSnackbar(
  BuildContext context,
  String message, {
  Duration duration = const Duration(seconds: 4),
}) {
  _showKioskSnackbar(
    context,
    message: message,
    background: AppColors.green,
    icon: Icons.check_circle_outline,
    duration: duration,
  );
}
