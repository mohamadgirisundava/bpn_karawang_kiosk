import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/audio_feedback.dart';
import '../../core/utils/responsive.dart';

const String _logoAsset = 'assets/images/logo_atr_bpn_mark.png';

/// Logo ATR/BPN, dengan fallback kotak kosong kalau asetnya gagal dimuat.
class BrandLogo extends StatelessWidget {
  final double size;

  const BrandLogo({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      _logoAsset,
      width: size,
      height: size,
      filterQuality: FilterQuality.medium,
      errorBuilder: (context, error, stackTrace) =>
          SizedBox(width: size, height: size),
    );
  }
}

/// Pita tipis navy–emas–hijau, urutan warna logo dari atas ke bawah (bola
/// dunia, cincin, daratan). Sama dengan `BrandStripe` di app Loket — tanda
/// tangan identitas BPN Karawang tanpa membuat layar ramai.
class BrandStripe extends StatelessWidget {
  final double? height;

  const BrandStripe({super.key, this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height ?? Responsive.r(4),
      // stretch wajib: ColoredBox tanpa child ukurannya sekecil constraint
      // yang dia terima, dan Row default-nya kasih tinggi longgar (0..h) —
      // tanpa ini pitanya setinggi 0 dan tidak kelihatan.
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 6, child: ColoredBox(color: AppColors.navy)),
          Expanded(flex: 3, child: ColoredBox(color: AppColors.gold)),
          Expanded(flex: 2, child: ColoredBox(color: AppColors.green)),
        ],
      ),
    );
  }
}

/// Logo + nama instansi dalam satu baris, untuk header putih.
class BrandLockup extends StatelessWidget {
  const BrandLockup({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        BrandLogo(size: Responsive.w(40)),
        SizedBox(width: Responsive.w(12)),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kantor Pertanahan',
              style: TextStyle(
                fontSize: Responsive.sp(15),
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
                height: 1.2,
              ),
            ),
            Text(
              'Kabupaten Karawang',
              style: TextStyle(
                fontSize: Responsive.sp(12.5),
                color: AppColors.textMuted,
                height: 1.25,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Header putih kiosk: pita identitas di atas, lalu bagian kiri (logo +
/// nama kantor di layar utama, atau tombol "Kembali" di layar lanjutan),
/// judul layar, dan [trailing] di kanan (jam, dsb).
///
/// [onLogoLongPress] memasang gesture rahasia satpam di logo — tidak ada
/// petunjuk visual apa pun untuk pengunjung.
class KioskHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;
  final VoidCallback? onLogoLongPress;
  final List<Widget> trailing;

  const KioskHeader({
    super.key,
    required this.title,
    this.onBack,
    this.onLogoLongPress,
    this.trailing = const [],
  });

  @override
  Widget build(BuildContext context) {
    final Widget leading;
    if (onBack != null) {
      leading = KioskBackButton(onPressed: onBack!);
    } else {
      leading = GestureDetector(
        onLongPress: onLogoLongPress,
        child: const BrandLockup(),
      );
    }

    return Material(
      color: AppColors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BrandStripe(),
          // Tinggi dari padding, bukan `height:` tetap — header berisi teks
          // sp(), lihat aturan h() vs sp() di DESIGN_SYSTEM.md.
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.w(20),
              vertical: Responsive.sp(12),
            ),
            child: Row(
              children: [
                leading,
                Container(
                  width: 1,
                  height: Responsive.sp(30),
                  margin: EdgeInsets.symmetric(horizontal: Responsive.w(20)),
                  color: AppColors.border,
                ),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: Responsive.sp(19),
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                ...trailing,
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.border),
        ],
      ),
    );
  }
}

/// Tombol "Kembali" — teks + ikon, bukan panah polos, supaya pengunjung
/// yang jarang memakai layar sentuh tidak menebak-nebak.
class KioskBackButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;

  const KioskBackButton({
    super.key,
    required this.onPressed,
    this.label = 'Kembali',
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () {
        AudioFeedback.tap();
        onPressed();
      },
      icon: Icon(Icons.arrow_back_rounded, size: Responsive.sp(22)),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.navy,
        enableFeedback: false,
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.w(14),
          vertical: Responsive.sp(10),
        ),
        textStyle: TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: Responsive.sp(16),
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          side: const BorderSide(color: AppColors.borderStrong),
        ),
      ),
    );
  }
}

/// Kartu putih bergaris tipis — wadah standar konten.
class Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? width;

  const Panel({super.key, required this.child, this.padding, this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      clipBehavior: Clip.antiAlias,
      padding: padding ?? EdgeInsets.all(Responsive.w(20)),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
      ),
      // Garis di depan isi, bukan di belakang — isi yang berlatar sendiri
      // (pita, kaki kartu abu) menutupi garis kalau digambar di decoration.
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

/// Label kecil di atas sebuah nilai, mis. "Sedang dilayani".
class SectionLabel extends StatelessWidget {
  final String text;
  final Color color;
  final double? fontSize;

  const SectionLabel(
    this.text, {
    super.key,
    this.color = AppColors.textMuted,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize ?? Responsive.sp(13),
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }
}

/// Layout layar "di luar alur ambil nomor" (Idle, Istirahat, Tutup): panel
/// identitas navy bermotif fasad gedung di kiri, konten di kanan. Sama
/// persis dengan layar login app Loket, supaya ketiga aplikasi terasa
/// satu keluarga.
class IdentityLayout extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  /// Gesture rahasia satpam di logo panel kiri.
  final VoidCallback? onLogoLongPress;

  const IdentityLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.onLogoLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 5,
          child: _IdentityPanel(
            title: title,
            subtitle: subtitle,
            onLogoLongPress: onLogoLongPress,
          ),
        ),
        Expanded(
          flex: 4,
          child: ColoredBox(
            color: AppColors.white,
            child: Padding(
              padding: EdgeInsets.all(Responsive.w(48)),
              child: Center(child: child),
            ),
          ),
        ),
      ],
    );
  }
}

class _IdentityPanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onLogoLongPress;

  const _IdentityPanel({
    required this.title,
    required this.subtitle,
    this.onLogoLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.navy,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: FacadePainter(scale: Responsive.scaleFactor),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(Responsive.w(48)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onLongPress: onLogoLongPress,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Langsung di atas navy, tanpa wadah: padi di sisi kiri
                      // logo bikin bola dunianya selalu terlihat miring kalau
                      // dimasukkan ke kotak atau lingkaran.
                      BrandLogo(size: Responsive.w(60)),
                      SizedBox(width: Responsive.w(14)),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kantor Pertanahan',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: Responsive.sp(17),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Kabupaten Karawang',
                            style: TextStyle(
                              color: AppColors.onNavyMuted,
                              fontSize: Responsive.sp(14),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: Responsive.sp(42),
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
                SizedBox(height: Responsive.h(12)),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.onNavyMuted,
                    fontSize: Responsive.sp(17),
                    height: 1.5,
                  ),
                ),
                SizedBox(height: Responsive.h(56)),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BrandStripe(height: Responsive.r(6)),
          ),
        ],
      ),
    );
  }
}

/// Kisi vertikal seperti fasad gedung Kantor Pertanahan Karawang: batang
/// tipis berjarak rapat, dengan satu pita gelombang emas yang melintang.
/// Batang di luar gelombang nyaris tak terlihat, jadi teks di atasnya tetap
/// terbaca. Digambar pakai kode, bukan foto, supaya tetap tajam di layar
/// sebesar apa pun.
///
/// Sama dengan motif di layar login app Loket; [scale] menyesuaikan jarak
/// batang dengan skala kanvas kiosk supaya kerapatannya terlihat sama.
class FacadePainter extends CustomPainter {
  final double scale;

  const FacadePainter({this.scale = 1});

  @override
  void paint(Canvas canvas, Size size) {
    final pitch = 9.0 * scale;
    final bar = 3.0 * scale;
    final base = Paint()..color = const Color(0x0FFFFFFF);
    final gold = Paint();

    // Gelombang ditaruh di sepertiga atas sampai tengah panel, menjauh
    // dari judul di bawah.
    final mid = size.height * 0.42;
    final amp = size.height * 0.07;
    final band = size.height * 0.11;

    for (var x = pitch / 2; x < size.width; x += pitch) {
      final t = x / size.width;
      canvas.drawRect(Rect.fromLTWH(x, 0, bar, size.height), base);

      // Dua gelombang ditumpuk supaya bentuknya nggak terlalu rapi seperti
      // grafik sinus, mirip gelombang di fasad yang naik-turun tak sama.
      final center =
          mid +
          amp * math.sin(t * math.pi * 2.2 + 0.6) +
          amp * 0.45 * math.sin(t * math.pi * 5.1);
      final half =
          band * (0.55 + 0.45 * math.sin(t * math.pi * 1.3 + 1.0).abs());
      final top = center - half;
      final height = half * 2;

      gold.shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.gold.withValues(alpha: 0),
          AppColors.gold.withValues(alpha: 0.55),
          AppColors.gold.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromLTWH(x, top, bar, height));
      canvas.drawRect(Rect.fromLTWH(x, top, bar, height), gold);
    }
  }

  @override
  bool shouldRepaint(covariant FacadePainter oldDelegate) =>
      oldDelegate.scale != scale;
}
