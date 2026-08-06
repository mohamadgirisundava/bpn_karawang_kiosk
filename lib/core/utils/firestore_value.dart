/// Baca field dari data Firestore secara toleran.
///
/// Cast langsung (`as int?` / `as String?`) THROW kalau tipe dokumennya beda
/// dari dugaan — dan di app ini satu dokumen yang throw bisa mengosongkan
/// SELURUH layar, karena `RealtimeService` memetakan seluruh snapshot dalam
/// satu `map().toList()`. Itu yang terjadi pada 2026-08-06: `desk_number`
/// ditulis app Loket sebagai number, sementara kiosk membacanya `as String?`,
/// jadi tiap tiket yang sudah dipanggil meledakkan pemetaannya dan papan
/// antrian kiosk permanen menampilkan "0 orang dalam antrian".
///
/// Aturannya sekarang: **field dari Firestore dibaca lewat helper ini**,
/// jangan di-cast langsung. Tipe di dokumen bisa beda dari yang kita kira
/// (peninggalan PocketBase, input manual lewat Firebase Console, atau app
/// lain yang menulis dengan tipe berbeda), dan salah tipe di satu tiket
/// nggak boleh membuat papannya kosong.
library;

int asInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

/// Versi nullable: `null` kalau field-nya nggak ada atau nggak bisa dibaca
/// sebagai angka — dipakai untuk field opsional seperti `desk_number`.
int? asIntOrNull(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

/// Angka yang tersimpan sebagai number tetap terbaca sebagai teks —
/// mis. `queue_code: 12` jadi `"12"`, bukan bikin pemetaannya throw.
String asString(dynamic value, {String fallback = ''}) {
  if (value is String) return value;
  if (value == null) return fallback;
  return value.toString();
}

/// Versi nullable: `null` kalau field-nya nggak ada atau kosong.
String? asStringOrNull(dynamic value) {
  if (value == null) return null;
  final text = value is String ? value : value.toString();
  return text.isEmpty ? null : text;
}
