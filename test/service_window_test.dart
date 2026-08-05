import 'package:flutter_test/flutter_test.dart';
import 'package:bpn_karawang_kiosk/core/services/service_window.dart';

/// Gerbang ini yang menentukan aplikasi tersambung ke Firestore atau tidak.
/// Salah tidur = kiosk mati di depan orang yang mau ambil nomor, jadi
/// perilakunya dikunci di sini — terutama sisi fail open-nya.

// Setelan asli di Firestore per 2026-08-05.
const nyata = {
  'jam_buka': '08:00',
  'jam_tutup': '15:00',
  'open_hour': '08:00',
  'close_hour': '16:00',
  'work_days': '1, 2, 3, 4, 5',
};

DateTime rabu(int jam, [int menit = 0]) =>
    DateTime(2026, 8, 5, jam, menit); // 2026-08-05 = Rabu
DateTime minggu(int jam) => DateTime(2026, 8, 9, jam); // 2026-08-09 = Minggu

void main() {
  group('setelan nyata (buka 08:00, tutup 15:00/16:00)', () {
    test('tengah jam layanan = buka', () {
      expect(ServiceWindow.isOpen(nyata, rabu(11)), isTrue);
    });

    test('bangun 30 menit sebelum buka', () {
      expect(ServiceWindow.isOpen(nyata, rabu(7, 29)), isFalse);
      expect(ServiceWindow.isOpen(nyata, rabu(7, 30)), isTrue);
    });

    test('masih buka satu jam setelah jam tutup terlonggar', () {
      // close_hour 16:00 + margin 60 menit = 17:00
      expect(ServiceWindow.isOpen(nyata, rabu(16, 59)), isTrue);
      expect(ServiceWindow.isOpen(nyata, rabu(17, 0)), isFalse);
    });

    test('jam-jam yang kemarin memboroskan kuota = tutup', () {
      for (final jam in [0, 3, 5, 19, 21, 23]) {
        expect(
          ServiceWindow.isOpen(nyata, rabu(jam)),
          isFalse,
          reason: 'jam $jam seharusnya tutup',
        );
      }
    });

    test('akhir pekan TIDAK diblokir — sengaja, lihat OperatingHoursService', () {
      // Memblokir berdasarkan tanggal risikonya sepihak: kalau kantor
      // ternyata melayani di hari itu, layarnya mati tanpa jalan keluar.
      expect(ServiceWindow.isOpen(nyata, minggu(11)), isTrue);
      expect(ServiceWindow.isOpen(nyata, minggu(23)), isFalse);
    });
  });

  group('fail open — jangan sampai diam selamanya', () {
    test('settings kosong = buka', () {
      expect(ServiceWindow.isOpen(const {}, rabu(3)), isTrue);
    });

    test('jam rusak/nggak terbaca = buka', () {
      expect(
        ServiceWindow.isOpen(const {
          'jam_buka': 'pagi',
          'jam_tutup': '25:99',
        }, rabu(3)),
        isTrue,
      );
    });

    test('work_days diabaikan sepenuhnya', () {
      // Diisi apa pun, yang menentukan tetap jamnya.
      expect(
        ServiceWindow.isOpen({...nyata, 'work_days': '6'}, rabu(11)),
        isTrue,
      );
    });

    test('cuma satu pasang key yang terisi tetap dipakai', () {
      expect(
        ServiceWindow.isOpen(const {
          'jam_buka': '08:00',
          'jam_tutup': '15:00',
        }, rabu(11)),
        isTrue,
      );
      expect(
        ServiceWindow.isOpen(const {
          'jam_buka': '08:00',
          'jam_tutup': '15:00',
        }, rabu(23)),
        isFalse,
      );
    });
  });

  test('jendela diambil dari pasangan paling longgar', () {
    // jam_tutup 12:00 tapi close_hour 16:00 -> yang dipakai 16:00 (+1 jam).
    final s = {...nyata, 'jam_tutup': '12:00'};
    expect(ServiceWindow.isOpen(s, rabu(15)), isTrue);
  });
}
