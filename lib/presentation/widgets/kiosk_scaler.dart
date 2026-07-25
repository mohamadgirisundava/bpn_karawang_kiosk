import 'package:flutter/material.dart';

/// Membungkus seluruh app dengan kanvas desain landscape tetap
/// (1920x1080) yang di-scale seragam (letterboxed, bukan reflow) ke
/// ukuran layar sungguhan. Jadi proporsi grid/font selalu identik di
/// resolusi berapapun (1920x1080 s.d. 4K) — nggak pernah jatuh ke mode
/// list atau scroll gara-gara layar lebih kecil dari yang diharapkan.
class KioskScaler extends StatelessWidget {
  static const Size designSize = Size(1920, 1080);

  final Widget child;

  const KioskScaler({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return FittedBox(
      fit: BoxFit.contain,
      child: MediaQuery(
        data: mediaQuery.copyWith(size: designSize),
        child: SizedBox(
          width: designSize.width,
          height: designSize.height,
          child: child,
        ),
      ),
    );
  }
}
