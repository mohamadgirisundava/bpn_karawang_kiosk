import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Koordinator suara latar panjang (adzan, Indonesia Raya, jadwal audio)
/// terhadap panggilan antrian.
///
/// Kiosk punya beberapa pemutar audio yang berdiri sendiri-sendiri. Tanpa
/// koordinasi, adzan yang durasinya ~3 menit bakal ketimpa panggilan
/// antrian dan dua-duanya jadi nggak jelas.
///
/// Pilihannya bukan "tunda panggilannya": pengunjung yang nomornya keluar
/// harus dipanggil sekarang, bukan setelah adzan kelar. Jadi yang
/// dilakukan sebaliknya — suara latar DIKECILKAN sementara panggilan
/// berlangsung, lalu dikembalikan. Antrian nggak pernah tertunda, dan
/// adzan/lagu tetap jalan tanpa dipotong di tengah.
class BackgroundAudio {
  BackgroundAudio._();

  /// Volume suara latar selama panggilan berlangsung. Sengaja nggak nol —
  /// kalau dibisukan penuh, orang mengira adzannya mati.
  static const double _duckedVolume = 0.12;

  static final List<AudioPlayer> _players = [];
  static int _activeCalls = 0;

  /// Didaftarkan oleh tiap service yang memutar suara panjang.
  static void register(AudioPlayer player) {
    if (!_players.contains(player)) _players.add(player);
  }

  /// Dipanggil sebelum panggilan/pengumuman mulai berbunyi.
  ///
  /// Pakai penghitung, bukan boolean: dua pengumuman yang beruntun jangan
  /// sampai bikin volume balik normal di tengah pengumuman kedua.
  static Future<void> duck() async {
    _activeCalls++;
    if (_activeCalls > 1) return;
    await _setVolume(_duckedVolume);
  }

  static Future<void> restore() async {
    if (_activeCalls > 0) _activeCalls--;
    if (_activeCalls > 0) return;
    await _setVolume(1.0);
  }

  static Future<void> _setVolume(double volume) async {
    for (final player in _players) {
      try {
        await player.setVolume(volume);
      } catch (e) {
        // Pemutar yang lagi nggak aktif bisa nolak setVolume — nggak apa,
        // yang penting jangan sampai kegagalan di satu pemutar bikin
        // pemutar lain nggak ikut dikecilkan.
        debugPrint('BackgroundAudio: gagal set volume: $e');
      }
    }
  }
}
