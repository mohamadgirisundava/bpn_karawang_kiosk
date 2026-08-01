import 'package:flutter/material.dart';
import '../../core/services/print_relay_status_service.dart';
import 'glossy_avatar.dart';
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
import 'gradient_button.dart';
import '../screens/idle_screen.dart';

/// Pindah ke layar Idle biasa, atau ke layar "Sedang Istirahat" kalau
/// mode istirahat lagi aktif — satu titik keputusan dipakai bareng oleh
/// idle-timeout HomeScreen dan aksi-aksi di menu pengaturan ini.
void goToIdleOrBreak(BuildContext context) {
  Navigator.of(context).pushReplacement(
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          KioskBreakService.instance.isOnBreak
          ? const BreakScreen()
          : const IdleScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 500),
    ),
  );
}

/// Menu admin kiosk — diakses lewat long-press logo (rahasia, cuma
/// satpam yang tau letaknya). Sengaja TANPA input PIN: kiosk nggak
/// punya keyboard fisik buat ngetik PIN, dan akses fisik ke
/// perangkatnya sendiri sudah jadi penghalang yang cukup buat kasus ini.
void showKioskSettingsMenu(BuildContext context) {
  final isOnBreak = KioskBreakService.instance.isOnBreak;

  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: const BorderSide(color: AppColors.border, width: 2),
      ),
      title: Row(
        children: [
          GlossyAvatar(
            icon: Icons.settings,
            size: Responsive.w(36),
            color: AppColors.navy,
          ),
          SizedBox(width: Responsive.w(8)),
          Text(
            'Pengaturan',
            style: TextStyle(
              fontSize: Responsive.sp(18),
              fontWeight: FontWeight.bold,
              color: AppColors.navy,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _PrintRelayStatusTile(),
          SizedBox(height: Responsive.h(12)),
          ListTile(
            leading: GlossyAvatar(
              icon: isOnBreak
                  ? Icons.play_circle_outline
                  : Icons.pause_circle_outline,
              size: Responsive.w(38),
              color: AppColors.navy,
            ),
            title: Text(
              isOnBreak ? 'Selesai Istirahat' : 'Mulai Istirahat',
              style: TextStyle(fontSize: Responsive.sp(16)),
            ),
            subtitle: Text(
              isOnBreak
                  ? 'Aktifkan lagi ambil nomor antrian buat customer'
                  : 'Sembunyikan ambil nomor antrian sementara (satpam sedang tidak di tempat)',
              style: TextStyle(
                fontSize: Responsive.sp(13),
                color: AppColors.textMuted,
              ),
            ),
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
          SizedBox(height: Responsive.h(8)),
          Container(height: 2, color: AppColors.border),
          SizedBox(height: Responsive.h(8)),
          ListTile(
            leading: GlossyAvatar(
              icon: Icons.refresh,
              size: Responsive.w(38),
              color: AppColors.navy,
            ),
            title: Text(
              'Restart ke Idle',
              style: TextStyle(fontSize: Responsive.sp(16)),
            ),
            subtitle: Text(
              'Kembali ke layar awal',
              style: TextStyle(
                fontSize: Responsive.sp(13),
                color: AppColors.textMuted,
              ),
            ),
            onTap: () {
              Navigator.of(dialogContext).pop();
              goToIdleOrBreak(context);
            },
          ),
          SizedBox(height: Responsive.h(8)),
          Container(height: 2, color: AppColors.border),
          SizedBox(height: Responsive.h(8)),
          ListTile(
            leading: GlossyAvatar(
              icon: Icons.restart_alt,
              size: Responsive.w(38),
              color: AppColors.danger,
            ),
            title: Text(
              'Reset Antrian',
              style: TextStyle(fontSize: Responsive.sp(16)),
            ),
            subtitle: Text(
              'Hapus semua tiket & panggilan hari ini, nomor urut balik ke 0',
              style: TextStyle(
                fontSize: Responsive.sp(13),
                color: AppColors.textMuted,
              ),
            ),
            onTap: () {
              Navigator.of(dialogContext).pop();
              _confirmResetQueue(context);
            },
          ),
          SizedBox(height: Responsive.h(8)),
          Container(height: 2, color: AppColors.border),
          SizedBox(height: Responsive.h(8)),
          ListTile(
            leading: GlossyAvatar(
              icon: Icons.exit_to_app,
              size: Responsive.w(38),
              color: AppColors.danger,
            ),
            title: Text(
              'Keluar Aplikasi',
              style: TextStyle(fontSize: Responsive.sp(16)),
            ),
            subtitle: Text(
              'Tutup aplikasi kiosk',
              style: TextStyle(
                fontSize: Responsive.sp(13),
                color: AppColors.textMuted,
              ),
            ),
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
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: const BorderSide(color: AppColors.danger, width: 2),
      ),
      title: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: AppColors.danger,
            size: Responsive.sp(28),
          ),
          SizedBox(width: Responsive.w(8)),
          Expanded(
            child: Text(
              'Reset Antrian Hari Ini?',
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
        'Semua tiket & panggilan aktif HARI INI akan DIHAPUS PERMANEN, dan nomor '
        'urut tiap loket balik ke 0. Tindakan ini tidak bisa dibatalkan.\n\n'
        'Pastikan memang diperlukan (mis. testing pagi sebelum buka layanan, atau '
        'ada kesalahan sistem) sebelum lanjut.',
        style: TextStyle(
          fontSize: Responsive.sp(14),
          color: AppColors.textMuted,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          style: AppButtonStyles.text(),
          child: const Text('Batal'),
        ),
        GradientButton(
          label: 'Ya, Reset Antrian',
          variant: GradientButtonVariant.destructive,
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
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: const BorderSide(color: AppColors.border, width: 2),
      ),
      content: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: Responsive.sp(28),
            height: Responsive.sp(28),
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.navy),
            ),
          ),
          SizedBox(width: Responsive.w(18)),
          Text(
            'Mereset antrian...',
            style: TextStyle(
              fontSize: Responsive.sp(16),
              fontWeight: FontWeight.w600,
              color: AppColors.navy,
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
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: const BorderSide(color: AppColors.border, width: 2),
      ),
      title: Text(
        'Keluar Aplikasi?',
        style: TextStyle(
          fontSize: Responsive.sp(18),
          fontWeight: FontWeight.bold,
          color: AppColors.navy,
        ),
      ),
      content: Text(
        'Aplikasi kiosk akan ditutup. Pastikan ini memang diperlukan.',
        style: TextStyle(
          fontSize: Responsive.sp(14),
          color: AppColors.textMuted,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          style: AppButtonStyles.text(),
          child: const Text('Batal'),
        ),
        GradientButton(
          label: 'Keluar',
          variant: GradientButtonVariant.destructive,
          onPressed: () => SystemNavigator.pop(),
        ),
      ],
    ),
  );
}

/// Status printer buat satpam — dia garda terdepan yang ditanya pengunjung
/// waktu tiket nggak keluar, jadi dia yang paling perlu tau duluan.
///
/// Sengaja BUKAN ListTile dengan avatar glossy kayak baris lain di menu ini:
/// baris-baris itu semuanya aksi yang bisa ditekan, dan kalau status ikut
/// bergaya sama, dia kebaca seolah bisa diklik padahal cuma informasi.
/// Bentuknya panel bertepi berwarna — beda jelas, dan warnanya sekaligus
/// jadi sinyal kondisi.
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
            : (ok ? AppColors.green : AppColors.orange);

        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.w(12),
            vertical: Responsive.h(10),
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(AppRadius.chip),
            border: Border.all(
              color: color.withValues(alpha: 0.45),
              width: 1.5,
            ),
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
                  ok ? Icons.check_circle : Icons.error_outline,
                  color: color,
                  size: Responsive.sp(18),
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
                        fontSize: Responsive.sp(14),
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    if (!loading) ...[
                      SizedBox(height: Responsive.h(2)),
                      Text(
                        status.message,
                        style: TextStyle(
                          fontSize: Responsive.sp(12),
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
