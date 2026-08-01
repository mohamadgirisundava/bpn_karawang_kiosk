/// Klasifikasi pemohon yang dipilih di langkah "Plotting" (layar pertama
/// sebelum memilih loket) — cuma tag buat pencatatan, nggak ngaruh ke
/// loket/kategori tujuan yang dipilih pemohon setelahnya.
enum ApplicantType { langsungPrioritas, kuasa }

String applicantTypeToFirestore(ApplicantType type) {
  return type == ApplicantType.kuasa ? 'kuasa' : 'langsung_prioritas';
}
