import 'operating_hours_service.dart';

/// Kapan aplikasi ini perlu tersambung ke data antrian.
///
/// KIOSK menyala 24 jam, tapi antrian cuma bergerak saat kantor buka. Di luar
/// jam itu tetap ada biaya: tiap kali WiFi putus-nyambung, listener tersambung
/// ulang dan snapshot pertamanya ditagih lagi. Pada 2026-08-05 terukur 20.104
/// baca (29% dari seluruh hari) terjadi di luar jam layanan, saat nol tiket
/// keluar — murni pemborosan.
///
/// ## Kenapa jendelanya dilebarkan
///
/// Ada DUA pasang setelan jam di Firestore yang isinya beda: `jam_buka`/
/// `jam_tutup` (08:00-15:00, yang diedit Admin di app Loket) dan `open_hour`/
/// `close_hour` (08:00-16:00, peninggalan). Daripada menebak mana yang benar,
/// jendelanya diambil paling longgar dari keduanya lalu ditambah margin.
///
/// Salah tidur jauh lebih mahal daripada salah bangun: bangun kepagian cuma
/// memboroskan sedikit baca, sedangkan tidur saat masih ada yang antre bikin
/// kiosk menolak melayani orang yang sedang berdiri di depannya.
///
/// **Kalau setelannya nggak terbaca sama sekali, jawabannya selalu BUKA.**
/// Fail open — aplikasi boros masih jauh lebih baik daripada aplikasi yang
/// nggak pernah menyala.
///
/// ## Kenapa akhir pekan TIDAK dicek di sini
///
/// `work_days` sengaja diabaikan, mengikuti keputusan yang sudah ada di
/// [OperatingHoursService]: aturan yang memblokir berdasarkan TANGGAL
/// risikonya sepihak — kalau tanggalnya keliru, kantor yang sebenarnya
/// sedang melayani jadi terkunci, dan nggak ada yang bisa membetulkan dari
/// lapangan. Jam buka/tutup salah paling banter menggeser beberapa jam;
/// hari salah membunuh satu hari penuh.
///
/// Penghematannya pun kecil: 14,5 jam tiap hari sudah tertangkap jendela
/// harian, sehingga tambahan dari akhir pekan nggak sebanding risikonya.
class ServiceWindow {
  const ServiceWindow._();

  static const List<String> _openKeys = ['jam_buka', 'open_hour'];
  static const List<String> _closeKeys = ['jam_tutup', 'close_hour'];
  static const int _marginBeforeMinutes = 30;
  static const int _marginAfterMinutes = 60;

  static int? _toMinutes(String? value) {
    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch((value ?? '').trim());
    if (match == null) return null;
    final minutes = int.parse(match.group(1)!) * 60 + int.parse(match.group(2)!);
    return (minutes >= 0 && minutes < 24 * 60) ? minutes : null;
  }

  static bool isOpen(Map<String, String> settings, [DateTime? nowOrNull]) {
    // Satpam boleh maksa buka walau di luar jam — kalau jam operasionalnya
    // keliru diset dan pelayanan tetap jalan, listener juga harus ikut
    // menyala. Tanpa ini, layar mati padahal kiosknya sengaja dibuka paksa.
    if (OperatingHoursService.instance.isOverridden) return true;

    final now = nowOrNull ?? DateTime.now();

    final opens = _openKeys.map((k) => _toMinutes(settings[k])).whereType<int>();
    final closes = _closeKeys
        .map((k) => _toMinutes(settings[k]))
        .whereType<int>();
    if (opens.isEmpty || closes.isEmpty) return true; // fail open

    final open = opens.reduce((a, b) => a < b ? a : b) - _marginBeforeMinutes;
    final close = closes.reduce((a, b) => a > b ? a : b) + _marginAfterMinutes;
    final minutes = now.hour * 60 + now.minute;

    return minutes >= open && minutes < close;
  }
}
