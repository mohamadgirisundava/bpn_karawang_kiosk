import '../../injection.dart';

/// Kenapa layanan lagi tutup — dipakai buat nyusun kalimat di layar.
///
/// Sengaja cuma jam buka/tutup. Hari libur dan akhir pekan pernah ikut
/// dicek lalu dibuang: aturan yang MEMBLOKIR pelayanan berdasarkan tanggal
/// itu risikonya sepihak — kalau tanggalnya keliru, kantor yang sebenarnya
/// sedang melayani jadi terkunci. Kalau Sabtu nggak ada yang datang, ya
/// nggak ada antrian; itu nggak perlu diatur sistem.
enum ClosedReason { none, beforeOpen, afterClose }

class OperatingHours {
  final ClosedReason reason;
  final String openTime;
  final String closeTime;

  const OperatingHours({
    required this.reason,
    this.openTime = '',
    this.closeTime = '',
  });

  bool get isClosed => reason != ClosedReason.none;

  String get message {
    switch (reason) {
      case ClosedReason.none:
        return '';
      case ClosedReason.beforeOpen:
        return 'Layanan belum dibuka. Jam buka pukul $openTime.';
      case ClosedReason.afterClose:
        return 'Layanan sudah tutup pukul $closeTime.';
    }
  }
}

/// Nentuin kiosk lagi di dalam jam layanan atau nggak.
///
/// Sebelumnya `jam_buka` dan `jam_tutup` cuma dibaca Display TV — kiosk
/// sama sekali nggak peduli, jadi nomor antrian tetap keluar tengah malam.
class OperatingHoursService {
  OperatingHoursService._();
  static final OperatingHoursService instance = OperatingHoursService._();

  /// Satpam boleh maksa buka walau di luar jam. Ini penting: jam operasional
  /// bisa aja salah diset sementara layanan tetap jalan dan nggak ada admin
  /// buat mbenerin. Tanpa jalan keluar ini, kiosk mengunci pelayanan yang
  /// sebenarnya sedang berjalan.
  ///
  /// Disimpan di memori dan diikat ke tanggal — besok balik normal sendiri,
  /// jadi kelalaian mematikannya nggak kebawa berhari-hari.
  String? _overrideDate;

  bool get isOverridden => _overrideDate == _todayKey;

  void overrideOpenForToday() => _overrideDate = _todayKey;

  void clearOverride() => _overrideDate = null;

  String get _todayKey {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  /// Baca "HH:mm" jadi menit sejak tengah malam. Null kalau formatnya nggak
  /// karuan — dan kalau begitu, jamnya sengaja diabaikan (dianggap buka)
  /// daripada mengunci layanan gara-gara salah ketik di Pengaturan.
  int? _minutesOf(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0].trim());
    final m = int.tryParse(parts[1].trim());
    if (h == null || m == null || h > 23 || m > 59) return null;
    return h * 60 + m;
  }

  Future<OperatingHours> check() async {
    if (isOverridden) return const OperatingHours(reason: ClosedReason.none);

    final settings = Injection.instance.settingsDatasource;
    final open = await settings.get('jam_buka');
    final close = await settings.get('jam_tutup');

    final now = DateTime.now();

    final nowMinutes = now.hour * 60 + now.minute;
    final openMinutes = _minutesOf(open);
    final closeMinutes = _minutesOf(close);

    if (openMinutes != null && nowMinutes < openMinutes) {
      return OperatingHours(
        reason: ClosedReason.beforeOpen,
        openTime: open,
        closeTime: close,
      );
    }
    if (closeMinutes != null && nowMinutes >= closeMinutes) {
      return OperatingHours(
        reason: ClosedReason.afterClose,
        openTime: open,
        closeTime: close,
      );
    }

    return OperatingHours(
      reason: ClosedReason.none,
      openTime: open,
      closeTime: close,
    );
  }
}
