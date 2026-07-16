import 'package:flutter/services.dart';

/// Utility untuk audio/haptic feedback saat user menyentuh layar.
class AudioFeedback {
  AudioFeedback._();

  /// Feedback ringan saat tap tombol biasa
  static void tap() {
    HapticFeedback.lightImpact();
    SystemSound.play(SystemSoundType.click);
  }

  /// Feedback medium saat aksi penting (ambil nomor)
  static void action() {
    HapticFeedback.mediumImpact();
    SystemSound.play(SystemSoundType.click);
  }

  /// Feedback sukses (cetak tiket berhasil)
  static void success() {
    HapticFeedback.heavyImpact();
  }
}
