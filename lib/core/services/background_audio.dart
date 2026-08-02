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

  /// Wajib dipanggil sekali sebelum ada yang diputar.
  ///
  /// Bawaan audioplayers di Android meminta audio focus `gain` tiap kali
  /// sebuah player mulai berbunyi. Efeknya: pemutar lain di aplikasi yang
  /// sama kehilangan focus dan langsung DIHENTIKAN sistem. Itulah kenapa
  /// adzan mati begitu ada panggilan antrian — bukan karena kode ini
  /// menghentikannya, tapi karena Android yang menghentikannya.
  ///
  /// Dengan `none`, tidak ada pemutar yang merebut focus dari yang lain,
  /// jadi adzan terus berjalan dan pengumuman menumpang di atasnya. Volume
  /// relatifnya baru diatur di [duck]/[restore] — dan pengaturan itu memang
  /// baru berfungsi setelah baris ini ada.
  static Future<void> configure() async {
    try {
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.none,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: {AVAudioSessionOptions.mixWithOthers},
          ),
        ),
      );
    } catch (e) {
      debugPrint('BackgroundAudio: gagal set audio context: $e');
    }
  }

  /// Didaftarkan oleh tiap service yang memutar suara panjang.
  static void register(AudioPlayer player) {
    if (!_players.contains(player)) _players.add(player);
  }

  /// Hentikan semua suara latar sekarang juga — dipakai tombol "Hentikan
  /// Suara" di Admin. Adzan berdurasi menit; tanpa ini satu-satunya cara
  /// menghentikannya adalah mendatangi kiosk secara fisik.
  static Future<void> stopAll() async {
    _activeCalls = 0;
    for (final player in _players) {
      try {
        await player.stop();
        await player.setVolume(1.0);
      } catch (e) {
        debugPrint('BackgroundAudio: gagal stop: $e');
      }
    }
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
