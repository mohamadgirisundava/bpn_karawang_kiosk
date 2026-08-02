import 'package:flutter/services.dart';

/// Umpan balik saat pengunjung menekan layar kiosk — getaran saja, tanpa
/// suara.
///
/// Sempat ada "ding" saat tiket berhasil diambil dan klik saat menyentuh
/// tombol. Dua-duanya dihapus 2026-08-02: speaker kiosk tersambung ke
/// amplifier ruangan, jadi bunyi kecil yang wajar di tablet jadi terdengar
/// sekeras pengumuman ke seluruh lobi. Setiap orang yang menekan tombol
/// akan terdengar semua orang.
///
/// Yang boleh keluar dari amplifier cuma yang memang ditujukan ke seisi
/// ruangan: panggilan antrian, adzan, Indonesia Raya, dan jadwal audio.
///
/// Getaran dipertahankan — dirasakan hanya oleh yang menyentuh, dan itulah
/// satu-satunya konfirmasi yang tersisa bahwa tekanannya terbaca.
class SoundService {
  SoundService._();

  /// Tiket berhasil diambil.
  static Future<void> playSuccess() async {
    await HapticFeedback.heavyImpact();
  }

  /// Sentuhan tombol biasa.
  static Future<void> playTap() async {
    await HapticFeedback.lightImpact();
  }

  /// Gagal — digetarkan dua kali supaya beda rasanya dari yang berhasil.
  static Future<void> playError() async {
    await HapticFeedback.heavyImpact();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.heavyImpact();
  }
}
