import 'package:flutter/material.dart';
import '../../core/constants/app_button_styles.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/services/operating_hours_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../widgets/app_button.dart';
import '../widgets/brand.dart';
import '../widgets/code_avatar.dart';
import '../widgets/kiosk_dialog.dart';
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
      // Bentuk dan pasangan tombol Batal + AppButton sengaja disamakan
      // persis dengan dialog Reset Antrian & Keluar Aplikasi di menu
      // satpam — semuanya konfirmasi tindakan penting.
      builder: (dialogContext) => KioskDialog(
        icon: Icons.lock_open_rounded,
        iconColor: AppColors.orange,
        title: 'Tetap Buka Layanan?',
        content: Text(
          '${hours.message}\n\n'
          'Kalau layanan sebenarnya sedang berjalan, kiosk bisa dibuka '
          'sekarang. Pengaturan jam tidak diubah, dan kiosk kembali normal '
          'besok.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            style: AppButtonStyles.text(),
            child: const Text('Batal'),
          ),
          AppButton(
            label: 'Ya, Buka Layanan',
            variant: AppButtonVariant.warning,
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

    final hasHours = hours.openTime.isNotEmpty && hours.closeTime.isNotEmpty;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: IdentityLayout(
          title: 'Ambil Nomor\nAntrian',
          subtitle: 'Sistem antrian pelayanan pertanahan\nKabupaten Karawang.',
          // Gesture rahasia yang sama kayak layar lain — satpam masih bisa
          // masuk menu pengaturan dari sini.
          onLogoLongPress: () => showKioskSettingsMenu(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CodeAvatar(
                icon: Icons.schedule_rounded,
                size: Responsive.w(76),
                color: AppColors.orange,
              ),
              SizedBox(height: Responsive.h(28)),
              Text(
                'Layanan Sedang Tutup',
                style: TextStyle(
                  fontSize: Responsive.sp(32),
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                  height: 1.15,
                ),
              ),
              SizedBox(height: Responsive.h(12)),
              Text(
                hours.message,
                style: TextStyle(
                  fontSize: Responsive.sp(16),
                  color: AppColors.textMuted,
                  height: 1.5,
                ),
              ),
              if (hasHours) ...[
                SizedBox(height: Responsive.h(24)),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.w(18),
                    vertical: Responsive.sp(12),
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SectionLabel('Jam layanan'),
                      SizedBox(height: Responsive.h(2)),
                      Text(
                        '${hours.openTime} – ${hours.closeTime} WIB',
                        style: TextStyle(
                          fontFamily: AppTheme.numberFamily,
                          fontSize: Responsive.sp(22),
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              SizedBox(height: Responsive.h(40)),
              // Ditulis terang-terangan buat petugas, bukan disembunyikan
              // di gesture rahasia: kalau jam-nya keliru sementara layanan
              // jalan, satpam harus bisa nemu jalan keluarnya cepat.
              // Bergaris (bukan navy penuh) supaya pengunjung tidak
              // membacanya sebagai tombol untuk mereka.
              AppButton(
                label: 'Buka Layanan (Petugas)',
                icon: Icons.lock_open_rounded,
                variant: AppButtonVariant.secondary,
                onPressed: () => _confirmOpenAnyway(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
