import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/adhan_scheduler_service.dart';
import '../../core/utils/responsive.dart';
import '../widgets/glossy_avatar.dart';
import 'home_screen.dart';

/// Idle Screen - tampil saat tidak ada interaksi.
/// Menampilkan logo BPN dan teks "Sentuh layar untuk mulai".
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

  void _navigateToHome() {
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
              SizedBox.expand(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/bpn_karawang_logo.png',
                        width: Responsive.w(160),
                        height: Responsive.w(160),
                        errorBuilder: (context, error, stackTrace) {
                          return GlossyAvatar(
                            icon: Icons.account_balance,
                            shape: BoxShape.circle,
                            size: Responsive.w(160),
                            fontSize: Responsive.sp(100),
                          );
                        },
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
                      SizedBox(height: Responsive.h(40)),
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Text(
                          'Sentuh layar untuk mulai',
                          style: TextStyle(
                            fontSize: Responsive.sp(20),
                            color: AppColors.textMuted,
                          ),
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
