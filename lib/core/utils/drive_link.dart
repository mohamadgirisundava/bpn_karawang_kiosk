/// Perbaiki link Google Drive bentuk lama jadi endpoint unduh yang masih
/// berfungsi.
///
/// Aplikasi Loket sudah menyimpan bentuk yang benar sejak 2026-08-02, tapi
/// nilai yang TERLANJUR tersimpan sebelum itu masih bentuk lama. Tanpa ini,
/// admin harus membuka Pengaturan dan menyimpan ulang link yang sama persis
/// supaya berbunyi — dan nggak akan ada yang menebak itu solusinya.
///
/// Bentuk lama `uc?export=download&id=...` berakhir di halaman HTML, bukan
/// berkas audio (diuji 2026-08-02). Pemutar yang dikasih HTML diam tanpa
/// pesan error.
String upgradeDriveLink(String rawUrl) {
  final url = rawUrl.trim();
  if (!url.contains('drive.google.com')) return url;

  final id =
      Uri.tryParse(url)?.queryParameters['id'] ??
      RegExp(r'/d/([a-zA-Z0-9_-]+)').firstMatch(url)?.group(1);
  if (id == null || id.isEmpty) return url;

  return 'https://drive.usercontent.google.com/download'
      '?id=$id&export=download&confirm=t';
}

/// Tebak apakah isi respons sebenarnya halaman HTML, bukan berkas audio.
///
/// Ini yang dikembalikan Drive kalau sharing-nya belum publik atau
/// link-nya salah — dan statusnya tetap 200, jadi kode status nggak bisa
/// dipakai buat membedakan.
bool looksLikeHtml(List<int> bytes) {
  final head = bytes.take(64).toList();
  if (head.isEmpty) return true;
  final text = String.fromCharCodes(head).trimLeft().toLowerCase();
  return text.startsWith('<!doctype html') ||
      text.startsWith('<html') ||
      text.startsWith('<?xml');
}
