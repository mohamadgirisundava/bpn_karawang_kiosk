import 'package:flutter/services.dart';

/// Umpan balik saat pengunjung menyentuh tombol — getaran saja.
///
/// Bunyi klik dihapus 2026-08-02, alasannya sama seperti di `SoundService`:
/// speaker kiosk tersambung ke amplifier ruangan, jadi bunyi sekecil apa
/// pun terdengar seisi lobi. Tiap orang yang menekan tombol akan kedengaran
/// semua orang.
class AudioFeedback {
  AudioFeedback._();

  /// Feedback ringan saat tap tombol biasa (navigasi, batal, dsb).
  static void tap() {
    HapticFeedback.lightImpact();
  }
}
