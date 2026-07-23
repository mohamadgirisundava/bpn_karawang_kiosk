import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'responsive.dart';

/// Snackbar error seragam — merah tegas + teks putih, kontras jelas
/// (dulu kuning/oren dengan teks putih default, susah dibaca).
void showErrorSnackbar(
  BuildContext context,
  String message, {
  Duration duration = const Duration(seconds: 4),
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      duration: duration,
      backgroundColor: AppColors.danger,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Responsive.r(10)),
      ),
      content: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.white),
          SizedBox(width: Responsive.w(10)),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
                fontSize: Responsive.sp(13),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
