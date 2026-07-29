import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/utils/responsive.dart';
import '../widgets/kiosk_settings_menu.dart';

/// Ditampilkan alih-alih IdleScreen kalau kiosk lagi "Mode Istirahat" —
/// satpam sengaja nonaktifkan sementara ambil nomor antrian pas nggak
/// ada yang jaga, biar nggak ada customer iseng ambil nomor tanpa
/// pengawasan. Akses admin (buat matiin mode ini) tetap lewat gesture
/// rahasia yang sama kayak HomeScreen: long-press logo — nggak ada
/// indikasi visual apapun buat customer biasa.
class BreakScreen extends StatelessWidget {
  const BreakScreen({super.key});

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
                GestureDetector(
                  onLongPress: () => showKioskSettingsMenu(context),
                  child: Image.asset(
                    'assets/images/bpn_karawang_logo.png',
                    width: Responsive.w(160),
                    height: Responsive.w(160),
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: Responsive.w(160),
                        height: Responsive.w(160),
                        decoration: const BoxDecoration(
                          color: AppColors.navy,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.account_balance,
                          size: Responsive.sp(100),
                          color: AppColors.white,
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: Responsive.h(24)),
                Text(
                  'Kantor Pertanahan\nKabupaten Karawang',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: Responsive.sp(28),
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),
                SizedBox(height: Responsive.h(32)),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.w(20),
                    vertical: Responsive.h(10),
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.navy.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                    border: Border.all(color: AppColors.navy, width: 2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.pause_circle_outline,
                        color: AppColors.navy,
                        size: Responsive.sp(20),
                      ),
                      SizedBox(width: Responsive.w(8)),
                      Text(
                        'SEDANG ISTIRAHAT',
                        style: TextStyle(
                          fontSize: Responsive.sp(16),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: AppColors.navy,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: Responsive.h(14)),
                Text(
                  'Layanan pengambilan nomor antrian sementara tidak tersedia.\nMohon tunggu petugas kembali.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: Responsive.sp(14),
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
