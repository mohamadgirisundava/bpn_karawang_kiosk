import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Service untuk memainkan sound effect di kiosk.
class SoundService {
  SoundService._();

  static final AudioPlayer _player = AudioPlayer();
  static bool _initialized = false;

  /// Inisialisasi player
  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    await _player.setReleaseMode(ReleaseMode.stop);
  }

  /// Sound "ding" saat tiket berhasil diambil
  static Future<void> playSuccess() async {
    await init();
    try {
      await _player.play(AssetSource('audio/success.mp3'));
    } catch (_) {
      SystemSound.play(SystemSoundType.click);
      HapticFeedback.heavyImpact();
    }
  }

  /// Sound tap ringan
  static Future<void> playTap() async {
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.lightImpact();
  }

  /// Sound error / warning
  static Future<void> playError() async {
    await init();
    try {
      await _player.play(AssetSource('audio/error.mp3'));
    } catch (_) {
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      HapticFeedback.heavyImpact();
    }
  }

  /// Dispose player
  static void dispose() {
    _player.dispose();
  }
}
