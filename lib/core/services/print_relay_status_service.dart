import 'package:cloud_firestore/cloud_firestore.dart';

/// Status program pencetak tiket (helper Windows di komputer kiosk).
class PrintRelayStatus {
  /// Relay masih melapor belakangan ini.
  final bool alive;

  /// Cetak terakhir berhasil. Relay bisa hidup tapi printernya bermasalah —
  /// kertas habis, kabel lepas — jadi ini dipisah dari [alive].
  final bool printerOk;

  /// Pesan error terakhir dari printer, kalau ada.
  final String lastError;

  /// Kapan relay terakhir melapor. Null kalau belum pernah sama sekali.
  final DateTime? lastSeen;

  const PrintRelayStatus({
    required this.alive,
    required this.printerOk,
    this.lastError = '',
    this.lastSeen,
  });

  /// Tiket kemungkinan besar gagal dicetak kalau salah satu bermasalah.
  bool get healthy => alive && printerOk;

  /// Kalimat siap tampil buat satpam — sengaja nyebutin tindakannya, bukan
  /// cuma statusnya, karena yang baca bukan orang teknis.
  String get message {
    if (lastSeen == null) {
      return 'Program pencetak belum pernah melapor. Tiket tidak akan '
          'tercetak — hubungi teknisi.';
    }
    if (!alive) {
      return 'Program pencetak berhenti. Tiket tidak akan tercetak — '
          'jalankan restart-relay.bat di komputer kiosk.';
    }
    if (!printerOk) {
      return lastError.isEmpty
          ? 'Printer bermasalah. Periksa kertas dan kabel USB.'
          : lastError;
    }
    return 'Printer siap.';
  }
}

/// Memantau `system_status/print_relay` — dokumen yang ditulis print relay
/// tiap 30 detik.
///
/// Relay jalan sebagai Windows Service tanpa jendela, jadi nggak ada cara
/// lain buat tau dia hidup selain lewat laporannya sendiri. Kalau laporan
/// terakhirnya lebih tua dari [staleAfter], anggap mati: entah service-nya
/// berhenti atau komputernya kehilangan internet — dua-duanya bikin tiket
/// nggak tercetak, dan dua-duanya perlu ditangani orang.
class PrintRelayStatusService {
  PrintRelayStatusService._();
  static final PrintRelayStatusService instance = PrintRelayStatusService._();

  /// Tiga kali interval detak — satu detak yang kelewat (jaringan lag
  /// sesaat) nggak langsung bikin alarm palsu.
  static const Duration staleAfter = Duration(seconds: 95);

  Stream<PrintRelayStatus> watch() {
    return FirebaseFirestore.instance
        .collection('system_status')
        .doc('print_relay')
        .snapshots()
        .map(_fromDoc);
  }

  Future<PrintRelayStatus> fetch() async {
    final doc = await FirebaseFirestore.instance
        .collection('system_status')
        .doc('print_relay')
        .get();
    return _fromDoc(doc);
  }

  PrintRelayStatus _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      return const PrintRelayStatus(alive: false, printerOk: false);
    }

    final lastSeen = DateTime.tryParse(data['last_seen'] as String? ?? '');
    final alive =
        lastSeen != null &&
        DateTime.now().toUtc().difference(lastSeen.toUtc()) < staleAfter;

    return PrintRelayStatus(
      alive: alive,
      printerOk: data['printer_ok'] as bool? ?? false,
      lastError: data['last_error'] as String? ?? '',
      lastSeen: lastSeen,
    );
  }
}
