import 'package:flutter/material.dart';
import '../../core/constants/app_button_styles.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/services/operating_hours_service.dart';
import '../../core/utils/responsive.dart';
import '../widgets/glossy_avatar.dart';
import '../widgets/gradient_button.dart';
import '../widgets/kiosk_settings_menu.dart';
import 'home_screen.dart';

/// Ditampilkan kalau kiosk lagi di luar jam layanan (atau hari libur).
///
/// Sebelumnya kiosk sama sekali nggak peduli jam operasional — nomor
/// antrian tetap keluar tengah malam, dan pengunjung nggak dikasih tau
/// apa-apa.
///
/// Beda dari [BreakScreen] yang dipicu satpam manual, layar ini muncul
/// sendiri dari setelan `jam_buka`/`jam_tutup`/`hari_libur`. Karena setelan
/// itu bisa saja keliru sementara layanan sebenarnya jalan, ada jalan
/// keluar buat satpam — tapi lewat konfirmasi, bukan sekali sentuh.
class ClosedScreen extends StatelessWidget {
  final OperatingHours hours;

  const ClosedScreen({super.key, required this.hours});

  Future<void> _confirmOpenAnyway(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        // Bentuk, ikon judul, dan pasangan tombol Batal + GradientButton
        // sengaja disamakan persis dengan dialog Reset Antrian & Keluar
        // Aplikasi di menu satpam — semuanya konfirmasi tindakan penting,
        // jadi jangan sampai kelihatan dari aplikasi yang beda.
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: const BorderSide(color: AppColors.orange, width: 2),
        ),
        title: Row(
          children: [
            Icon(
              Icons.lock_open,
              color: AppColors.orange,
              size: Responsive.sp(28),
            ),
            SizedBox(width: Responsive.w(8)),
            Expanded(
              child: Text(
                'Tetap Buka Layanan?',
                style: TextStyle(
                  fontSize: Responsive.sp(18),
                  fontWeight: FontWeight.bold,
                  color: AppColors.navy,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          '${hours.message}\n\n'
          'Kalau layanan sebenarnya sedang berjalan, kiosk bisa dibuka '
          'sekarang. Pengaturan jam tidak diubah, dan kiosk kembali normal '
          'besok.',
          style: TextStyle(
            fontSize: Responsive.sp(14),
            color: AppColors.textMuted,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            style: AppButtonStyles.text(),
            child: const Text('Batal'),
          ),
          GradientButton(
            label: 'Ya, Buka Layanan',
            variant: GradientButtonVariant.warning,
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    OperatingHoursService.instance.overrideOpenForToday();
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SizedBox.expand(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Gesture rahasia yang sama kayak layar lain — satpam masih
                // bisa masuk menu pengaturan dari sini.
                GestureDetector(
                  onLongPress: () => showKioskSettingsMenu(context),
                  child: Image.asset(
                    'assets/images/bpn_karawang_logo.png',
                    width: Responsive.w(150),
                    height: Responsive.w(150),
                    errorBuilder: (context, error, stackTrace) => GlossyAvatar(
                      icon: Icons.account_balance,
                      shape: BoxShape.circle,
                      size: Responsive.w(150),
                      fontSize: Responsive.sp(94),
                    ),
                  ),
                ),
                SizedBox(height: Responsive.h(24)),
                Text(
                  'Kantor Pertanahan\nKabupaten Karawang',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: Responsive.sp(20),
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),
                SizedBox(height: Responsive.h(28)),
                GlossyAvatar(
                  icon: Icons.schedule,
                  shape: BoxShape.circle,
                  size: Responsive.w(72),
                  color: AppColors.orange,
                  fontSize: Responsive.sp(38),
                ),
                SizedBox(height: Responsive.h(16)),
                Text(
                  'Layanan Sedang Tutup',
                  style: TextStyle(
                    fontSize: Responsive.sp(26),
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),
                SizedBox(height: Responsive.h(8)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: Responsive.w(40)),
                  child: Text(
                    hours.message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: Responsive.sp(15),
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                if (hours.openTime.isNotEmpty &&
                    hours.closeTime.isNotEmpty) ...[
                  SizedBox(height: Responsive.h(16)),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.w(18),
                      vertical: Responsive.h(10),
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                      border: Border.all(color: AppColors.border, width: 2),
                    ),
                    child: Text(
                      'Jam layanan ${hours.openTime} - ${hours.closeTime} WIB',
                      style: TextStyle(
                        fontSize: Responsive.sp(14),
                        fontWeight: FontWeight.w600,
                        color: AppColors.navy,
                      ),
                    ),
                  ),
                ],
                SizedBox(height: Responsive.h(32)),
                // Ditulis terang-terangan buat petugas, bukan disembunyikan
                // di gesture rahasia: kalau jam-nya keliru sementara layanan
                // jalan, satpam harus bisa nemu jalan keluarnya cepat.
                GradientButton(
                  label: 'Buka Layanan (Petugas)',
                  icon: Icons.lock_open,
                  onPressed: () => _confirmOpenAnyway(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
