import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Tema kiosk — minimalis, sama dengan app Loket: permukaan putih, garis
/// tipis 1px, tanpa bayangan dan gradasi. Warna logo dipakai hemat (lihat
/// [AppColors]).
///
/// Beda dengan Loket, ukuran (font, padding, radius) TIDAK diatur di sini:
/// di kiosk semuanya lewat `Responsive`, yang baru siap setelah layar
/// pertama di-build — jauh sesudah ThemeData ini dibuat. Jadi tema cuma
/// memegang warna dan font; ukuran ada di widget masing-masing.
class AppTheme {
  AppTheme._();

  /// Font teks — sama dengan Loket.
  static const String fontFamily = 'NunitoSans';

  /// Font angka antrian — Nunito yang membulat, sama dengan tiket tercetak
  /// dan layar petugas di Loket.
  static const String numberFamily = 'Nunito';

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.navy,
      primary: AppColors.navy,
      onPrimary: AppColors.white,
      secondary: AppColors.gold,
      tertiary: AppColors.green,
      error: AppColors.danger,
      surface: AppColors.white,
      onSurface: AppColors.textDark,
      onSurfaceVariant: AppColors.textMuted,
      outline: AppColors.border,
      outlineVariant: AppColors.border,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      dividerColor: AppColors.border,
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(color: AppColors.textMuted),
      // Material 3 default-nya dialog pakai surfaceContainerHigh (abu
      // ke-tint navy), bukan putih seperti kartu lain.
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.textMuted,
        textColor: AppColors.textDark,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.navy,
      ),
    );
  }
}
