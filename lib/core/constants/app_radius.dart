import '../utils/responsive.dart';

/// Satu skala radius terpusat — diacu semua kartu/tombol biar konsisten.
/// Gaya sekarang niru referensi "Kumo" (design system Cloudflare, lihat
/// diskusi Threads yang jadi acuan): flat, radius sedang (bukan pill
/// penuh), definisi bentuk pakai border tipis — bukan shadow tebal.
class AppRadius {
  AppRadius._();

  /// Kartu utama (ticket detail, printed view, info banner, dsb).
  static double get card => Responsive.r(14);

  /// Kartu/kontainer besar pembungkus grid atau panel.
  static double get cardLarge => Responsive.r(16);

  /// Elemen kecil (chip, badge, avatar kotak, input field).
  static double get chip => Responsive.r(10);

  /// Tombol — radius sedang, bukan StadiumBorder/pill penuh (beda dari
  /// iterasi sebelumnya; Kumo pakai rounded-rectangle biasa).
  static double get button => Responsive.r(10);
}
