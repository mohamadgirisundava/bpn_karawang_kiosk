import 'dart:async';
import 'package:pocketbase/pocketbase.dart';

/// Bedakan "server nggak bisa dihubungi" dari error lain, biar pesan yang
/// ditampilkan ke user selalu jelas penyebabnya — bukan cuma dump exception
/// mentah atau nge-generalisasi semua error jadi satu pesan yang sama.
String friendlyErrorMessage(Object error) {
  if (error is TimeoutException) {
    return 'Tidak dapat terhubung ke server. Periksa koneksi jaringan.';
  }

  if (error is ClientException) {
    // statusCode 0 = request nggak pernah sampai ke server sama sekali
    // (server mati, salah alamat, jaringan putus, dll).
    if (error.statusCode == 0) {
      return 'Tidak dapat terhubung ke server. Periksa koneksi jaringan.';
    }
    final message = error.response['message'] as String?;
    if (message != null && message.isNotEmpty) {
      return 'Server menolak permintaan: $message';
    }
    return 'Terjadi kesalahan pada server (kode ${error.statusCode}).';
  }

  return 'Terjadi kesalahan tak terduga. Coba lagi.';
}
