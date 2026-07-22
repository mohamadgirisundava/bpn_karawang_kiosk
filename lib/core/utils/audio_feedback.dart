import 'package:flutter/services.dart';

/// Utility untuk audio/haptic feedback saat user menyentuh layar.
///
/// Aturan: kalau sebuah aksi berujung ke sound sukses (chime, lihat
/// [SoundService.playSuccess]), jangan tambah haptic juga di aksi yang
/// sama — dua-duanya bareng kerasa dobel.
class AudioFeedback {
  AudioFeedback._();

  /// Feedback ringan saat tap tombol biasa (navigasi, batal, dsb).
  static void tap() {
    HapticFeedback.lightImpact();
    SystemSound.play(SystemSoundType.click);
  }
}
