import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_button_styles.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/services/kiosk_break_service.dart';
import '../../core/services/queue_reset_service.dart';
import '../../core/utils/error_snackbar.dart';
import '../../core/utils/responsive.dart';
import '../screens/break_screen.dart';
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
          Icon(Icons.settings, color: AppColors.navy, size: Responsive.sp(28)),
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
          ListTile(
            leading: Icon(
              isOnBreak ? Icons.play_circle_outline : Icons.pause_circle_outline,
              color: AppColors.navy,
              size: Responsive.sp(24),
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
            leading: Icon(
              Icons.refresh,
              color: AppColors.navy,
              size: Responsive.sp(24),
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
            leading: Icon(
              Icons.restart_alt,
              color: AppColors.danger,
              size: Responsive.sp(24),
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
            leading: Icon(
              Icons.exit_to_app,
              color: AppColors.danger,
              size: Responsive.sp(24),
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
          Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: Responsive.sp(28)),
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
        style: TextStyle(fontSize: Responsive.sp(14), color: AppColors.textMuted),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          style: AppButtonStyles.text(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(dialogContext).pop();
            _runResetQueue(context);
          },
          style: AppButtonStyles.elevated(background: AppColors.danger),
          child: const Text('Ya, Reset Antrian'),
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
        style: TextStyle(fontSize: Responsive.sp(14), color: AppColors.textMuted),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          style: AppButtonStyles.text(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () => SystemNavigator.pop(),
          style: AppButtonStyles.elevated(background: AppColors.danger),
          child: const Text('Keluar'),
        ),
      ],
    ),
  );
}
