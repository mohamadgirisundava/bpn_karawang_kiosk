/// Mode istirahat kiosk — kalau aktif, customer diarahkan ke layar
/// "Sedang Istirahat" (lihat `BreakScreen`) alih-alih bisa ambil nomor
/// antrian, buat mencegah customer iseng ambil nomor pas satpam nggak
/// di tempat. Cuma state lokal di device ini (nggak disinkron ke
/// Firestore) — sengaja reset ke off tiap app restart, biar kiosk nggak
/// "kejebak" mode istirahat kalau aplikasinya sempat restart nggak
/// sengaja pas satpam lupa matiin sebelumnya.
class KioskBreakService {
  KioskBreakService._();
  static final KioskBreakService instance = KioskBreakService._();

  bool isOnBreak = false;

  void startBreak() => isOnBreak = true;
  void endBreak() => isOnBreak = false;
}
