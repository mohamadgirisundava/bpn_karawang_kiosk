import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/utils/audio_feedback.dart';
import '../../core/utils/responsive.dart';
import '../../domain/entities/applicant_type.dart';
import '../../domain/entities/counter_entity.dart';
import '../widgets/clock_widget.dart';
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
      backgroundColor: AppColors.background.withValues(alpha: 0.4),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.w(150),
                vertical: Responsive.h(100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pemohon merupakan',
                    style: TextStyle(
                      fontSize: Responsive.sp(18),
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy,
                    ),
                  ),
                  SizedBox(height: Responsive.h(4)),
                  Text(
                    'Pilih salah satu untuk melanjutkan ambil nomor antrian',
                    style: TextStyle(
                      fontSize: Responsive.sp(12),
                      color: AppColors.textMuted,
                    ),
                  ),
                  SizedBox(height: Responsive.h(24)),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: _OptionCard(
                            icon: Icons.person_outline,
                            title: 'Pemohon Langsung/Prioritas',
                            description:
                                'Mengurus sendiri, termasuk lansia & disabilitas',
                            onTap: () =>
                                _pilih(ApplicantType.langsungPrioritas),
                          ),
                        ),
                        SizedBox(width: Responsive.w(20)),
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
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      height: 100,
      padding: EdgeInsets.only(left: Responsive.w(14), right: Responsive.w(14)),
      decoration: BoxDecoration(
        color: AppColors.navy,
        border: Border(
          bottom: BorderSide(color: AppColors.gold, width: Responsive.h(3)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Kembali',
            icon: Icon(
              Icons.arrow_back,
              color: AppColors.white,
              size: Responsive.w(24),
            ),
          ),
          SizedBox(width: Responsive.w(4)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.counter.name.toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'NunitoSans',
                    fontSize: Responsive.sp(15),
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
                Text(
                  'Sistem Antrian Digital',
                  style: TextStyle(
                    fontFamily: 'NunitoSans',
                    fontSize: Responsive.sp(11),
                    color: AppColors.goldLight,
                  ),
                ),
              ],
            ),
          ),
          const ClockWidget(),
        ],
      ),
    );
  }
}

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
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
        enableFeedback: false,
        child: Container(
          clipBehavior: Clip.antiAlias,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppRadius.cardLarge),
            border: Border.all(color: AppColors.border, width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: Responsive.sp(56), color: AppColors.navy),
              SizedBox(height: Responsive.h(16)),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: Responsive.sp(18),
                  fontWeight: FontWeight.bold,
                  color: AppColors.navy,
                ),
              ),
              SizedBox(height: Responsive.h(8)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: Responsive.w(16)),
                child: Text(
                  description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: Responsive.sp(12),
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
