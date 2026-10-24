import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/utils/responsive.dart';

enum AppButtonVariant {
  /// Navy penuh — aksi utama di layar.
  primary,

  /// Garis tipis, teks navy — aksi pendamping di sebelah tombol utama.
  secondary,
  destructive,
  success,
  warning,
}

/// Tombol standar kiosk: rata (tanpa gradasi/bayangan), radius kecil.
/// Bentuk dan variannya sama dengan `AppButton` di app Loket; ukurannya
/// lewat [Responsive] supaya ikut skala kanvas kiosk.
///
/// [large] untuk aksi utama pengunjung ("Ambil Nomor Antrian", "Selesai")
/// — target sentuh besar karena yang menekan bisa siapa saja, termasuk
/// lansia.
class AppButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool loading;
  final bool large;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.loading = false,
    this.large = false,
  });

  static Color colorFor(AppButtonVariant variant) {
    switch (variant) {
      case AppButtonVariant.destructive:
        return AppColors.danger;
      case AppButtonVariant.success:
        return AppColors.success;
      case AppButtonVariant.warning:
        return AppColors.orange;
      case AppButtonVariant.primary:
      case AppButtonVariant.secondary:
        return AppColors.navy;
    }
  }

  @override
  Widget build(BuildContext context) {
    final outlined = variant == AppButtonVariant.secondary;
    final color = colorFor(variant);
    final disabled = onPressed == null || loading;
    final fg = outlined ? color : AppColors.white;
    final fontSize = Responsive.sp(large ? 19 : 15);
    final iconSize = Responsive.sp(large ? 24 : 20);

    // Tinggi konten dikunci — tanpa ini state loading (spinner) dan normal
    // (teks) beda tinggi intrinsik sedikit, tombolnya "melompat".
    final child = SizedBox(
      height: Responsive.sp(large ? 28 : 24),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (loading)
            SizedBox(
              width: iconSize,
              height: iconSize,
              child: CircularProgressIndicator(strokeWidth: 2.6, color: fg),
            )
          else ...[
            if (icon != null) ...[
              Icon(icon, size: iconSize),
              SizedBox(width: Responsive.w(10)),
            ],
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.button),
    );
    // Tinggi tombol dari padding, bukan `height:` tetap — lihat aturan
    // h() vs sp() di DESIGN_SYSTEM.md.
    final padding = EdgeInsets.symmetric(
      horizontal: Responsive.w(large ? 28 : 22),
      vertical: Responsive.sp(large ? 18 : 14),
    );

    if (outlined) {
      return OutlinedButton(
        onPressed: disabled ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          backgroundColor: AppColors.white,
          disabledForegroundColor: AppColors.textMuted.withValues(alpha: 0.6),
          padding: padding,
          shape: shape,
          enableFeedback: false,
          side: BorderSide(
            color: disabled ? AppColors.border : AppColors.borderStrong,
          ),
        ),
        child: child,
      );
    }

    return FilledButton(
      onPressed: disabled ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: AppColors.white,
        // Saat loading tombolnya tetap berwarna — cuma "sedang diproses",
        // bukan "tidak bisa dipakai".
        disabledBackgroundColor: loading ? color : AppColors.border,
        disabledForegroundColor: loading ? AppColors.white : AppColors.textMuted,
        padding: padding,
        shape: shape,
        elevation: 0,
        enableFeedback: false,
      ),
      child: child,
    );
  }
}
