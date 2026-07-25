import 'package:flutter/material.dart';

/// Membungkus seluruh app dengan kanvas desain landscape tetap
/// (1920x1080) yang di-scale seragam ke ukuran layar sungguhan. Jadi
/// proporsi grid/font selalu identik di resolusi berapapun — nggak
/// pernah jatuh ke mode list atau scroll gara-gara layar lebih kecil
/// dari yang diharapkan.
///
/// `fitWidth`, bukan `contain`: layar kiosk sungguhan (lewat BlueStacks)
/// rasio aspeknya lebih "tinggi"/kotak dibanding kanvas desain 16:9,
/// jadi `contain` nyisain strip kosong di atas-bawah. `fitWidth` isi
/// penuh lebar layar tanpa strip kosong — konsekuensinya, kalau
/// proporsi layarnya lebih tinggi dari 16:9, bagian bawah kanvas bisa
/// kepotong (bukan nyisa blank). Prioritasnya isi tampilan penuh, bukan
/// simetris sempurna.
class KioskScaler extends StatelessWidget {
  static const Size designSize = Size(1920, 1080);

  final Widget child;

  const KioskScaler({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return FittedBox(
      fit: BoxFit.fitWidth,
      clipBehavior: Clip.hardEdge,
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
