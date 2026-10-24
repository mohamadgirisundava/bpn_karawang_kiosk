import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../widgets/brand.dart';
import '../widgets/code_avatar.dart';
import '../widgets/kiosk_settings_menu.dart';
import '../widgets/status_badge.dart';

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
        body: IdentityLayout(
          title: 'Ambil Nomor\nAntrian',
          subtitle: 'Sistem antrian pelayanan pertanahan\nKabupaten Karawang.',
          onLogoLongPress: () => showKioskSettingsMenu(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CodeAvatar(
                icon: Icons.pause_rounded,
                size: Responsive.w(76),
                color: AppColors.orange,
              ),
              SizedBox(height: Responsive.h(28)),
              StatusBadge(
                label: 'Sedang istirahat',
                color: AppColors.orange,
                fontSize: Responsive.sp(14),
              ),
              SizedBox(height: Responsive.h(14)),
              Text(
                'Pengambilan nomor antrian sementara tidak tersedia',
                style: TextStyle(
                  fontSize: Responsive.sp(28),
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                  height: 1.2,
                ),
              ),
              SizedBox(height: Responsive.h(14)),
              Text(
                'Mohon tunggu, petugas akan segera kembali.',
                style: TextStyle(
                  fontSize: Responsive.sp(16),
                  color: AppColors.textMuted,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
