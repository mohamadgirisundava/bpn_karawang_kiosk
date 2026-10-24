import '../utils/responsive.dart';

/// Satu skala radius terpusat, nilainya sama dengan app Loket (6/8/10/4)
/// tapi lewat [Responsive.r] supaya ikut skala kanvas kiosk. Sudutnya
/// sengaja kecil supaya bentuknya tegas, dan semua kontrol yang bisa
/// disentuh (tombol, chip, kotak kode) memakai radius yang SAMA persis.
class AppRadius {
  AppRadius._();

  /// Tombol, chip, kotak kode. Satu nilai untuk semua.
  static double get control => Responsive.r(6);

  /// Kartu layanan dan kartu info.
  static double get card => Responsive.r(8);

  /// Panel besar dan dialog.
  static double get cardLarge => Responsive.r(10);

  /// Label status kecil ("Prioritas").
  static double get badge => Responsive.r(4);

  /// Alias, sama dengan [control].
  static double get chip => control;
  static double get button => control;
}
