import 'package:flutter/material.dart';

/// Palet warna resmi BPN Karawang — diambil dari logo. Sama persis dengan
/// app Loket (`bpn_karawang_loket/lib/core/constants/app_colors.dart`);
/// kalau mengubah satu, ubah keduanya.
///
/// Arah visualnya minimalis: hampir semua permukaan putih/abu sangat muda,
/// dan warna logo dipakai hemat sebagai penanda — navy untuk aksi utama dan
/// teks penting, emas untuk penanda "aktif", hijau untuk "selesai". Pita
/// navy–emas–hijau ([BrandStripe]) jadi tanda tangan identitasnya.
class AppColors {
  AppColors._();

  // Primary — bola dunia di logo.
  static const Color navy = Color(0xFF1B456F);
  static const Color navyDark = Color(0xFF12324F);

  /// Latar tipis navy buat elemen terpilih (chip, avatar).
  static const Color navySoft = Color(0xFFE8EEF5);

  // Accent — cincin emas di logo. Hanya untuk penanda, bukan teks di atas
  // putih (kontrasnya terlalu rendah).
  static const Color gold = Color(0xFFFACB1D);
  static const Color goldSoft = Color(0xFFFDF4D3);

  // Secondary accent — daratan hijau di logo.
  static const Color green = Color(0xFF95C535);

  // Warning / prioritas — padi di logo.
  static const Color orange = Color(0xFFC46829);
  static const Color orangeSoft = Color(0xFFF8ECE3);

  // Aksen biru muda — air di logo.
  static const Color lightBlue = Color(0xFF2C8FD0);
  static const Color lightBlueSoft = Color(0xFFE6F2FA);

  // Variasi tambahan
  static const Color goldLight = Color(0xFFEFCF47);
  static const Color orangeLight = Color(0xFFE6A62B);
  static const Color olive = Color(0xFFD2B845);

  // Status
  static const Color danger = Color(0xFFC93C3C);
  static const Color dangerSoft = Color(0xFFFAE9E9);
  static const Color success = Color(0xFF2E8B4E);
  static const Color successSoft = Color(0xFFE6F3EA);

  // Netral
  static const Color white = Colors.white;
  static const Color background = Color(0xFFF4F6F9);
  static const Color textDark = Color(0xFF15273A);
  static const Color textMuted = Color(0xFF56677A);
  static const Color border = Color(0xFFE2E7EE);

  /// Garis tombol bergaris: lebih gelap dari [border] kartu.
  static const Color borderStrong = Color(0xFFAFBBC8);

  /// Teks sekunder di atas navy (panel identitas).
  static const Color onNavyMuted = Color(0xCCFFFFFF);
}
