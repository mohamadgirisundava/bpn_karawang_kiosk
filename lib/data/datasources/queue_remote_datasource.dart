import 'package:cloud_firestore/cloud_firestore.dart';
import '../../injection.dart';
import '../../domain/entities/applicant_type.dart';

/// Remote data source untuk queue collection.
class QueueRemoteDatasource {
  final FirebaseFirestore _db;

  QueueRemoteDatasource() : _db = FirebaseFirestore.instance;

  // 8 detik (bukan 5) — query pertama abis app cold-start butuh waktu
  // ekstra buat Firestore ngebuka koneksi pertama kalinya.
  static const Duration _timeout = Duration(seconds: 8);

  /// Key tanggal hari ini, format "YYYY-MM-DD".
  String get _todayKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Panjang nomor antrian dari setting `digit_nomor_antrian` — mis. 3
  /// menghasilkan "A001". Dibatasi 1-6 biar salah ketik nggak bikin kode
  /// tiket sepanjang satu baris; default 3 kalau belum diatur.
  Future<int> _queueNumberDigits() async {
    final raw = await Injection.instance.settingsDatasource.get(
      'digit_nomor_antrian',
    );
    final parsed = int.tryParse(raw.trim());
    if (parsed == null || parsed < 1 || parsed > 6) return 3;
    return parsed;
  }

  /// Buat tiket antrian baru dengan nomor urut yang dijamin unik lewat
  /// Firestore transaction — menghindari race condition saat dua request
  /// nge-generate nomor bersamaan.
  ///
  /// Sengaja TIDAK bikin `print_jobs` di sini — job cetak baru dibuat saat
  /// user menekan tombol "Cetak Tiket Antrian" (lihat [createPrintJob]),
  /// supaya printer nggak jalan otomatis begitu nomor antrian diambil.
  Future<DocumentSnapshot<Map<String, dynamic>>> createQueue({
    required String counterId,
    required String counterCode,
    ApplicantType? applicantType,
  }) async {
    final dateKey = _todayKey;
    // Dibaca sebelum transaction dimulai — di dalam transaction Firestore
    // nggak boleh ada operasi lain selain get/set dokumen.
    final digits = await _queueNumberDigits();
    final counterRef = _db
        .collection('queue_counters')
        .doc('${counterId}_$dateKey');
    final queueRef = _db.collection('queues').doc();

    await _db
        .runTransaction((transaction) async {
          final counterSnap = await transaction.get(counterRef);
          final lastNumber = counterSnap.exists
              ? (counterSnap.data()?['lastNumber'] as int? ?? 0)
              : 0;
          final nextNumber = lastNumber + 1;
          final queueCode =
              '$counterCode${nextNumber.toString().padLeft(digits, '0')}';
          final takenAt = DateTime.now().toUtc().toIso8601String();

          transaction.set(counterRef, {'lastNumber': nextNumber});
          transaction.set(queueRef, {
            'counter': counterId,
            'queue_number': nextNumber,
            'queue_code': queueCode,
            'status': 'waiting',
            'date': dateKey,
            'dateKey': dateKey,
            'taken_at': takenAt,
            if (applicantType != null)
              'applicant_type': applicantTypeToFirestore(applicantType),
          });
        })
        .timeout(_timeout);

    return await queueRef.get();
  }

  /// Buat job pencetakan tiket fisik — dipanggil saat user menekan tombol
  /// "Cetak Tiket Antrian", bukan saat nomor antrian diambil. Diproses oleh
  /// helper terpisah di sisi Windows (BlueStacks nggak dukung USB
  /// passthrough ke printer thermal), bukan oleh app kiosk ini langsung.
  Future<String> createPrintJob({
    required String queueCode,
    required String counterName,
    required String takenAt,
    String? applicantType,
  }) async {
    final dateKey = _todayKey;
    final printJobRef = await _db
        .collection('print_jobs')
        .add({
          'status': 'pending',
          'queue_code': queueCode,
          'counter_name': counterName,
          'date': dateKey,
          'dateKey': dateKey,
          'taken_at': takenAt,
          // Cuma ada di tiket layanan Plotting — relay nyetak ini di bawah
          // nama layanannya biar petugas langsung tau tanpa nanya lagi.
          if (applicantType != null) 'applicant_type': applicantType,
        })
        .timeout(_timeout);

    return printJobRef.id;
  }

  /// Pantau status job cetak (`pending` / `printed` / `error`) secara
  /// realtime — dipakai UI kiosk buat nunggu hasil cetak beneran, bukan
  /// animasi loading yang durasinya dikira-kira.
  Stream<String> watchPrintJobStatus(String printJobId) {
    return _db
        .collection('print_jobs')
        .doc(printJobId)
        .snapshots()
        .map((doc) => doc.data()?['status'] as String? ?? 'pending');
  }

  /// Get nomor yang sedang dipanggil/dilayani untuk counter tertentu.
  Future<DocumentSnapshot<Map<String, dynamic>>?> getCurrentServing(
    String counterId,
  ) async {
    final result = await _db
        .collection('queues')
        .where('counter', isEqualTo: counterId)
        .where('dateKey', isEqualTo: _todayKey)
        .where('status', whereIn: ['called', 'serving'])
        .orderBy('called_at', descending: true)
        .limit(1)
        .get()
        .timeout(_timeout);

    if (result.docs.isEmpty) return null;
    return result.docs.first;
  }

  /// Get jumlah antrian menunggu untuk counter tertentu.
  Future<int> getWaitingCount(String counterId) async {
    final result = await _db
        .collection('queues')
        .where('counter', isEqualTo: counterId)
        .where('dateKey', isEqualTo: _todayKey)
        .where('status', isEqualTo: 'waiting')
        .count()
        .get()
        .timeout(_timeout);
    return result.count ?? 0;
  }
}
