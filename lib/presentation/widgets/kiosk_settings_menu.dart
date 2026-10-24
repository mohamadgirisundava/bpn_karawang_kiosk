import 'package:flutter/material.dart';
import '../../core/services/print_relay_status_service.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_button_styles.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/services/kiosk_break_service.dart';
import '../../core/services/queue_reset_service.dart';
import '../../core/services/realtime_service.dart';
import '../../core/utils/error_snackbar.dart';
import '../../core/utils/responsive.dart';
import '../screens/break_screen.dart';
import 'app_button.dart';
import 'code_avatar.dart';
import 'kiosk_dialog.dart';
import '../../core/services/operating_hours_service.dart';
import '../screens/closed_screen.dart';
import '../screens/idle_screen.dart';

/// Pindah ke layar Idle biasa, layar "Sedang Istirahat", atau layar
/// "Layanan Sedang Tutup" — satu titik keputusan dipakai bareng oleh
/// idle-timeout HomeScreen dan aksi-aksi di menu pengaturan ini.
///
/// Urutannya: istirahat menang duluan karena itu keputusan sadar satpam
/// yang lagi berdiri di situ; jam tutup baru dicek setelahnya.
Future<void> goToIdleOrBreak(BuildContext context) async {
  final hours = KioskBreakService.instance.isOnBreak
      ? const OperatingHours(reason: ClosedReason.none)
      : await OperatingHoursService.instance.check();
  if (!context.mounted) return;

  Navigator.of(context).pushReplacement(
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          KioskBreakService.instance.isOnBreak
          ? const BreakScreen()
          : (hours.isClosed ? ClosedScreen(hours: hours) : const IdleScreen()),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 500),
    ),
  );
}

/// Satu baris aksi di menu satpam: ikon dalam kotak warna tipis, judul,
/// keterangan. Semua baris menu memakai ini supaya seragam.
class _MenuAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.color = AppColors.navy,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(
        horizontal: Responsive.w(8),
        vertical: Responsive.h(4),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      enableFeedback: false,
      leading: CodeAvatar(icon: icon, size: Responsive.w(40), color: color),
      title: Text(
        title,
        style: TextStyle(
          fontSize: Responsive.sp(16),
          fontWeight: FontWeight.w700,
          color: color == AppColors.danger ? AppColors.danger : null,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: Responsive.sp(13),
          color: AppColors.textMuted,
        ),
      ),
      onTap: onTap,
    );
  }
}

/// Menu admin kiosk — diakses lewat long-press logo (rahasia, cuma
/// satpam yang tau letaknya). Sengaja TANPA input PIN: kiosk nggak
/// punya keyboard fisik buat ngetik PIN, dan akses fisik ke
/// perangkatnya sendiri sudah jadi penghalang yang cukup buat kasus ini.
void showKioskSettingsMenu(BuildContext context) {
  final isOnBreak = KioskBreakService.instance.isOnBreak;

  showDialog(
    context: context,
    builder: (dialogContext) => KioskDialog(
      icon: Icons.settings_outlined,
      title: 'Pengaturan',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _PrintRelayStatusTile(),
          if (OperatingHoursService.instance.isOverridden) ...[
            SizedBox(height: Responsive.h(8)),
            _MenuAction(
              icon: Icons.lock_open_rounded,
              color: AppColors.orange,
              title: 'Ikuti Jam Layanan Lagi',
              subtitle: 'Saat ini layanan dipaksa buka di luar jam operasional',
              onTap: () {
                OperatingHoursService.instance.clearOverride();
                Navigator.of(context).pop();
                goToIdleOrBreak(context);
              },
            ),
          ],
          SizedBox(height: Responsive.h(12)),
          _MenuAction(
            icon: isOnBreak ? Icons.play_arrow_rounded : Icons.pause_rounded,
            title: isOnBreak ? 'Selesai Istirahat' : 'Mulai Istirahat',
            subtitle: isOnBreak
                ? 'Aktifkan lagi ambil nomor antrian buat customer'
                : 'Sembunyikan ambil nomor antrian sementara (satpam sedang tidak di tempat)',
            onTap: () {
              Navigator.of(dialogContext).pop();
              if (isOnBreak) {
                KioskBreakService.instance.endBreak();
              } else {
                KioskBreakService.instance.startBreak();
              }
              goToIdleOrBreak(context);
            },
          ),
          _MenuAction(
            icon: Icons.refresh_rounded,
            title: 'Restart ke Idle',
            subtitle: 'Kembali ke layar awal',
            onTap: () {
              Navigator.of(dialogContext).pop();
              goToIdleOrBreak(context);
            },
          ),
          SizedBox(height: Responsive.h(6)),
          const Divider(),
          SizedBox(height: Responsive.h(6)),
          _MenuAction(
            icon: Icons.restart_alt_rounded,
            color: AppColors.danger,
            title: 'Reset Antrian',
            subtitle:
                'Hapus semua tiket & panggilan hari ini, nomor urut balik ke 0',
            onTap: () {
              Navigator.of(dialogContext).pop();
              _confirmResetQueue(context);
            },
          ),
          _MenuAction(
            icon: Icons.logout_rounded,
            color: AppColors.danger,
            title: 'Keluar Aplikasi',
            subtitle: 'Tutup aplikasi kiosk',
            onTap: () {
              Navigator.of(dialogContext).pop();
              confirmExitKiosk(context);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          style: AppButtonStyles.text(),
          child: const Text('Tutup'),
        ),
      ],
    ),
  );
}

/// Dialog konfirmasi "Reset Antrian" — aksi ini nghapus semua tiket &
/// panggilan aktif HARI INI dan balikin nomor urut tiap loket ke 0.
/// TIDAK BISA dibatalkan, makanya perlu konfirmasi tegas sebelum jalan.
void _confirmResetQueue(BuildContext context) {
  showDialog(
    context: context,
    builder: (dialogContext) => KioskDialog(
      icon: Icons.warning_amber_rounded,
      iconColor: AppColors.danger,
      title: 'Reset Antrian Hari Ini?',
      content: const Text(
        'Semua tiket & panggilan aktif HARI INI akan DIHAPUS PERMANEN, dan nomor '
        'urut tiap loket balik ke 0. Tindakan ini tidak bisa dibatalkan.\n\n'
        'Pastikan memang diperlukan (mis. testing pagi sebelum buka layanan, atau '
        'ada kesalahan sistem) sebelum lanjut.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          style: AppButtonStyles.text(),
          child: const Text('Batal'),
        ),
        AppButton(
          label: 'Ya, Reset Antrian',
          variant: AppButtonVariant.destructive,
          onPressed: () {
            Navigator.of(dialogContext).pop();
            _runResetQueue(context);
          },
        ),
      ],
    ),
  );
}

Future<void> _runResetQueue(BuildContext context) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
      ),
      content: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: Responsive.sp(28),
            height: Responsive.sp(28),
            child: const CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.navy),
            ),
          ),
          SizedBox(width: Responsive.w(18)),
          Text(
            'Mereset antrian...',
            style: TextStyle(
              fontSize: Responsive.sp(16),
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    ),
  );

  String? errorMessage;
  try {
    await QueueResetService.instance.resetToday();
    // Firestore listener biasanya juga bakal ngasih tau semua cubit yang
    // dengerin buat refresh, tapi bisa ada jeda propagasi dikit — karena
    // kita SENDIRI yang tau persis data queues barusan berubah, langsung
    // paksa refresh sekarang juga biar HomeScreen/QueueInfoScreen yang
    // lagi kebuka nggak nyangkut nampilin angka lama.
    RealtimeService.instance.notifyQueueUpdate();
  } catch (e) {
    errorMessage = '$e';
  }

  if (!context.mounted) return;
  Navigator.of(context).pop(); // Tutup dialog loading.

  if (errorMessage == null) {
    showSuccessSnackbar(context, 'Antrian hari ini berhasil di-reset.');
  } else {
    showErrorSnackbar(context, 'Gagal reset antrian: $errorMessage');
  }
}

/// Dialog konfirmasi keluar aplikasi — dipakai dari menu pengaturan di
/// atas, dan juga dari tombol logout yang selalu tampil di header
/// HomeScreen.
void confirmExitKiosk(BuildContext context) {
  showDialog(
    context: context,
    builder: (dialogContext) => KioskDialog(
      icon: Icons.logout_rounded,
      iconColor: AppColors.danger,
      title: 'Keluar Aplikasi?',
      content: const Text(
        'Aplikasi kiosk akan ditutup. Pastikan ini memang diperlukan.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          style: AppButtonStyles.text(),
          child: const Text('Batal'),
        ),
        AppButton(
          label: 'Keluar',
          variant: AppButtonVariant.destructive,
          onPressed: () => SystemNavigator.pop(),
        ),
      ],
    ),
  );
}

/// Status printer buat satpam — dia garda terdepan yang ditanya pengunjung
/// waktu tiket nggak keluar, jadi dia yang paling perlu tau duluan.
///
/// Sengaja BUKAN baris aksi seperti baris lain di menu ini: baris-baris itu
/// semuanya aksi yang bisa ditekan, dan kalau status ikut bergaya sama, dia
/// kebaca seolah bisa diklik padahal cuma informasi. Bentuknya panel
/// berlatar warna tipis — beda jelas, dan warnanya sekaligus jadi sinyal
/// kondisi.
///
/// Dibaca realtime, bukan sekali waktu menu dibuka, supaya statusnya ikut
/// berubah kalau printer pulih sambil menu masih kebuka.
class _PrintRelayStatusTile extends StatelessWidget {
  const _PrintRelayStatusTile();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PrintRelayStatus>(
      stream: PrintRelayStatusService.instance.watch(),
      builder: (context, snapshot) {
        final status = snapshot.data;
        final loading = status == null;
        final ok = status?.healthy ?? false;
        final color = loading
            ? AppColors.textMuted
            : (ok ? AppColors.success : AppColors.orange);

        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.w(14),
            vertical: Responsive.sp(12),
          ),
          decoration: BoxDecoration(
            color: Color.alphaBlend(
              color.withValues(alpha: 0.1),
              AppColors.white,
            ),
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (loading)
                SizedBox(
                  width: Responsive.sp(18),
                  height: Responsive.sp(18),
                  child: const CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  ok ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                  color: color,
                  size: Responsive.sp(20),
                ),
              SizedBox(width: Responsive.w(10)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      loading
                          ? 'Memeriksa printer...'
                          : (ok ? 'Printer Siap' : 'Printer Bermasalah'),
                      style: TextStyle(
                        fontSize: Responsive.sp(15),
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    if (!loading) ...[
                      SizedBox(height: Responsive.h(2)),
                      Text(
                        status.message,
                        style: TextStyle(
                          fontSize: Responsive.sp(13),
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
