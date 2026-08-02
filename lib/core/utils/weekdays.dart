/// Penomoran hari mengikuti `DateTime` (1 = Senin ... 7 = Minggu), bukan
/// bikin sendiri — biar `now.weekday` bisa langsung dicocokkan tanpa
/// konversi, dan nggak ada peluang salah geser satu hari.
///
/// Salinan dari `bpn_karawang_loket/lib/core/utils/weekdays.dart`. Dua repo
/// terpisah, dan penomorannya HARUS sama: Admin yang menulis, kiosk yang
/// membaca. Kalau salah satu diubah, ubah dua-duanya.
const Set<int> workdays = {1, 2, 3, 4, 5};

/// "1,4" -> {1, 4}. Nilai di luar 1-7 dibuang, bukan bikin error — data
/// pengaturan diketik manusia dan nggak boleh bikin kiosk berhenti bunyi
/// cuma gara-gara satu karakter nyasar.
Set<int> parseWeekdays(String raw) {
  return raw
      .split(',')
      .map((e) => int.tryParse(e.trim()))
      .whereType<int>()
      .where((d) => d >= 1 && d <= 7)
      .toSet();
}
