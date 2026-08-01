import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive.dart';

enum GradientButtonVariant { primary, destructive, success, warning }

/// Helper gradient glossy (gaya skeuomorphic "Aqua" lama) dipakai bareng
/// oleh [GradientButton] dan [GlossyAvatar] — biar tombol dan avatar kotak
/// kode loket punya bahasa visual yang sama persis, bukan cuma warnanya.
/// Sama persis kayak app Loket (Admin), cuma nilai ukurannya lewat
/// Responsive.r() biar ngikut scale-factor kiosk.
class GlossyStyle {
  GlossyStyle._();

  static Color shade(Color color, double lightnessDelta) {
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness + lightnessDelta).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  static Color colorFor(GradientButtonVariant variant) {
    switch (variant) {
      case GradientButtonVariant.destructive:
        return AppColors.danger;
      case GradientButtonVariant.success:
        return AppColors.green;
      case GradientButtonVariant.warning:
        return AppColors.orange;
      case GradientButtonVariant.primary:
        return AppColors.navy;
    }
  }

  static BoxDecoration decoration(Color base, {required double radius}) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [shade(base, 0.14), base, shade(base, -0.08)],
        stops: const [0.0, 0.55, 1.0],
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: shade(base, -0.22), width: 1.5),
      boxShadow: [
        BoxShadow(
          color: base.withValues(alpha: 0.35),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  /// Pita highlight putih transparan di bagian atas — kesan cahaya
  /// memantul di permukaan glossy.
  static Widget highlight({required double radius, required double height}) {
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(radius),
          topRight: Radius.circular(radius),
        ),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withValues(alpha: 0.35),
                Colors.white.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tombol gradient glossy — pengganti ElevatedButton/OutlinedButton +
/// AppButtonStyles.elevated()/outlined() yang tadinya flat. `ButtonStyle`
/// Material nggak bisa ngecat gradient langsung (cuma warna solid), jadi
/// ini widget custom: `Ink` + `InkWell` buat ripple, plus overlay
/// highlight dari [GlossyStyle]. Sama persis kayak app Loket (Admin) biar
/// kedua app konsisten, cuma ukurannya lewat Responsive.r()/w()/sp().
class GradientButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final GradientButtonVariant variant;
  final bool loading;

  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = GradientButtonVariant.primary,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final base = GlossyStyle.colorFor(variant);
    final disabled = onPressed == null || loading;
    final radius = Responsive.r(18);
    final contentHeight = Responsive.sp(24);

    return Opacity(
      opacity: disabled && !loading ? 0.5 : 1,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: GlossyStyle.decoration(base, radius: radius),
          child: InkWell(
            borderRadius: BorderRadius.circular(radius),
            onTap: disabled ? null : onPressed,
            child: Stack(
              children: [
                GlossyStyle.highlight(
                  radius: radius,
                  height: Responsive.sp(22),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.w(24),
                    vertical: Responsive.sp(16),
                  ),
                  // Tinggi konten dikunci fixed — tanpa ini, state loading
                  // (spinner) vs normal (teks bold) punya tinggi intrinsik
                  // beda dikit, bikin tombol "melompat" pas transisi
                  // ke/dari loading.
                  child: SizedBox(
                    height: contentHeight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (loading)
                          SizedBox(
                            width: Responsive.sp(20),
                            height: Responsive.sp(20),
                            child: const CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        else ...[
                          if (icon != null) ...[
                            Icon(
                              icon,
                              color: Colors.white,
                              size: Responsive.sp(20),
                            ),
                            SizedBox(width: Responsive.w(8)),
                          ],
                          Text(
                            label,
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: Responsive.sp(16),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
