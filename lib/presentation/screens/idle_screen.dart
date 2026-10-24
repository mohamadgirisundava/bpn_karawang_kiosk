import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/adhan_scheduler_service.dart';
import '../../core/services/operating_hours_service.dart';
import '../../core/utils/responsive.dart';
import 'closed_screen.dart';
import '../widgets/brand.dart';
import '../widgets/code_avatar.dart';
import 'home_screen.dart';

/// Idle Screen - tampil saat tidak ada interaksi.
/// Panel identitas bermotif fasad di kiri, ajakan "Sentuh layar untuk
/// mulai" di kanan. Seluruh layar bisa disentuh, bukan cuma teksnya.
class IdleScreen extends StatefulWidget {
  const IdleScreen({super.key});

  @override
  State<IdleScreen> createState() => _IdleScreenState();
}

class _IdleScreenState extends State<IdleScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Dicek di sini, bukan cuma di `goToIdleOrBreak`: aplikasi start dingin
  /// langsung ke IdleScreen, jadi tanpa ini kiosk yang baru dinyalakan di
  /// luar jam layanan tetap ngeloloskan pengunjung ke layar ambil nomor.
  Future<void> _navigateToHome() async {
    final hours = await OperatingHoursService.instance.check();
    if (!mounted) return;

    if (hours.isClosed) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              ClosedScreen(hours: hours),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const HomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);

    return PopScope(
      canPop: false,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _navigateToHome,
        child: Scaffold(
          backgroundColor: AppColors.white,
          body: Stack(
            children: [
              Positioned.fill(
                child: IdentityLayout(
                  title: 'Ambil Nomor\nAntrian',
                  subtitle:
                      'Sistem antrian pelayanan pertanahan\nKabupaten Karawang.',
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CodeAvatar(
                        icon: Icons.touch_app_outlined,
                        size: Responsive.w(76),
                      ),
                      SizedBox(height: Responsive.h(28)),
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Text(
                          'Sentuh layar\nuntuk mulai',
                          style: TextStyle(
                            fontSize: Responsive.sp(34),
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                            height: 1.15,
                          ),
                        ),
                      ),
                      SizedBox(height: Responsive.h(16)),
                      Text(
                        'Pilih jenis layanan, lalu ambil dan cetak nomor '
                        'antrian Anda.',
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
              // Tombol tes adzan buat petugas — sengaja kecil & pojok
              // biar nggak mengganggu tampilan customer, tapi tetap
              // gampang diakses buat verifikasi suara keluar apa nggak
              // tanpa harus nunggu jadwal sholat beneran.
              Positioned(
                right: Responsive.w(12),
                bottom: Responsive.h(12),
                child: IconButton(
                  onPressed: () => AdhanSchedulerService.instance.playTest(),
                  icon: Icon(
                    Icons.volume_up_outlined,
                    color: AppColors.textMuted.withValues(alpha: 0.4),
                    size: Responsive.sp(22),
                  ),
                  tooltip: 'Tes suara adzan',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
