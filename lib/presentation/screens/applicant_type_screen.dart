import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/utils/audio_feedback.dart';
import '../../core/utils/responsive.dart';
import '../../domain/entities/applicant_type.dart';
import '../../domain/entities/counter_entity.dart';
import '../widgets/app_footer.dart';
import '../widgets/brand.dart';
import '../widgets/clock_widget.dart';
import '../widgets/code_avatar.dart';
import 'ticket_screen.dart';

/// Layar loket "Plotting" — sebelum ambil tiket, pemohon klasifikasi diri:
/// Pemohon Langsung/Prioritas atau Kuasa. Cuma muncul kalau yang dipilih
/// dari HomeScreen adalah loket dengan `isPlotting = true` — loket lain
/// langsung ke TicketScreen tanpa langkah ini (lihat home_screen.dart).
/// Hasil pilihan ini cuma tag pencatatan (lihat ApplicantType), nggak
/// ngaruh ke loket tujuan (loket-nya sendiri udah ditentukan sebelumnya).
class ApplicantTypeScreen extends StatefulWidget {
  final CounterEntity counter;

  const ApplicantTypeScreen({super.key, required this.counter});

  @override
  State<ApplicantTypeScreen> createState() => _ApplicantTypeScreenState();
}

class _ApplicantTypeScreenState extends State<ApplicantTypeScreen> {
  // Sama kayak TicketScreen — auto-balik ke Home kalau dibiarin kelamaan.
  static const Duration _pageTimeout = Duration(seconds: 60);
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    _resetTimeout();
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  void _resetTimeout() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(_pageTimeout, () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  void _pilih(ApplicantType type) {
    AudioFeedback.tap();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) =>
            TicketScreen(counter: widget.counter, applicantType: type),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          KioskHeader(
            title: '${widget.counter.name} · ${widget.counter.description}',
            onBack: () => Navigator.of(context).pop(),
            trailing: const [ClockWidget()],
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.w(80),
                vertical: Responsive.h(48),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pemohon merupakan',
                    style: TextStyle(
                      fontSize: Responsive.sp(26),
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: Responsive.h(6)),
                  Text(
                    'Pilih salah satu untuk melanjutkan ambil nomor antrian.',
                    style: TextStyle(
                      fontSize: Responsive.sp(15),
                      color: AppColors.textMuted,
                    ),
                  ),
                  SizedBox(height: Responsive.h(28)),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _OptionCard(
                            icon: Icons.person_outline_rounded,
                            title: 'Pemohon Langsung/Prioritas',
                            description:
                                'Mengurus sendiri, termasuk lansia & disabilitas',
                            onTap: () =>
                                _pilih(ApplicantType.langsungPrioritas),
                          ),
                        ),
                        SizedBox(width: Responsive.w(16)),
                        Expanded(
                          child: _OptionCard(
                            icon: Icons.assignment_ind_outlined,
                            title: 'Kuasa',
                            description: 'Mengurus atas nama orang lain',
                            onTap: () => _pilih(ApplicantType.kuasa),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const AppFooter(),
        ],
      ),
    );
  }
}

/// Kartu pilihan — bentuknya sama dengan kartu layanan di HomeScreen
/// (putih bergaris, pita navy "Pilih" di kaki kartu), supaya pengunjung
/// langsung paham ini juga bisa disentuh.
class _OptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _OptionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        enableFeedback: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(Responsive.w(24)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CodeAvatar(icon: icon, size: Responsive.w(88)),
                    SizedBox(height: Responsive.h(22)),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: Responsive.sp(22),
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    SizedBox(height: Responsive.h(8)),
                    Text(
                      description,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: Responsive.sp(15),
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              color: AppColors.navy,
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.w(20),
                vertical: Responsive.sp(11),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Pilih',
                    style: TextStyle(
                      fontSize: Responsive.sp(15),
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                  SizedBox(width: Responsive.w(8)),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: Responsive.sp(20),
                    color: AppColors.white,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
