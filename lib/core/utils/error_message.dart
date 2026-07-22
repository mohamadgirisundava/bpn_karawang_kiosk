import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Bedakan "server nggak bisa dihubungi" dari error lain, biar pesan yang
/// ditampilkan ke user selalu jelas penyebabnya — bukan cuma dump exception
/// mentah atau nge-generalisasi semua error jadi satu pesan yang sama.
String friendlyErrorMessage(Object error) {
  if (error is TimeoutException) {
    return 'Tidak dapat terhubung ke server. Periksa koneksi jaringan.';
  }

  if (error is FirebaseException) {
    // unavailable/deadline-exceeded = request nggak pernah sampai (koneksi
    // putus, offline, dll), bukan ditolak server.
    if (error.code == 'unavailable' || error.code == 'deadline-exceeded') {
      return 'Tidak dapat terhubung ke server. Periksa koneksi jaringan.';
    }
    if (error.code == 'permission-denied') {
      return 'Server menolak permintaan: akses ditolak.';
    }
    final message = error.message;
    if (message != null && message.isNotEmpty) {
      return 'Server menolak permintaan: $message';
    }
    return 'Terjadi kesalahan pada server (${error.code}).';
  }

  return 'Terjadi kesalahan tak terduga. Coba lagi.';
}
