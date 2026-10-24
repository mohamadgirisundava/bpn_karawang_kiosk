import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/services/sound_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/audio_feedback.dart';
import '../../core/utils/error_snackbar.dart';
import '../../core/utils/responsive.dart';
import '../../domain/entities/applicant_type.dart';
import '../../domain/entities/counter_entity.dart';
import '../../injection.dart';
import '../cubits/ticket/ticket_cubit.dart';
import '../cubits/ticket/ticket_state.dart';
import '../widgets/app_button.dart';
import '../widgets/app_footer.dart';
import '../widgets/brand.dart';
import '../widgets/clock_widget.dart';
import '../widgets/code_avatar.dart';
import '../widgets/status_badge.dart';

/// Ticket Screen - Halaman konfirmasi & cetak tiket setelah memilih counter.
class TicketScreen extends StatefulWidget {
  final CounterEntity counter;
  // Diisi cuma kalau berasal dari loket Plotting (lihat
  // ApplicantTypeScreen) — loket lain langsung ke sini tanpa klasifikasi.
  final ApplicantType? applicantType;

  const TicketScreen({super.key, required this.counter, this.applicantType});

  @override
  State<TicketScreen> createState() => _TicketScreenState();
}

class _TicketScreenState extends State<TicketScreen>
    with SingleTickerProviderStateMixin {
  late final TicketCubit _ticketCubit;
  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  static const Duration _pageTimeout = Duration(seconds: 60);
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    _ticketCubit = Injection.instance.ticketCubit;
    _ticketCubit.loadQueueInfo(widget.counter.id);

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      value: 1,
    );
    _scaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.elasticOut),
    );
    _resetTimeout();
  }

  @override
  void dispose() {
    _animController.dispose();
    _timeoutTimer?.cancel();
    super.dispose();
  }

  void _resetTimeout() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(_pageTimeout, () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  Future<void> _ambilNomor() async {
    _resetTimeout();
    _animController.value = 0;

    _ticketCubit.takeTicket(
      counterId: widget.counter.id,
      counterCode: widget.counter.code,
      applicantType: widget.applicantType,
    );
  }

  void _mulaiCetak() {
    _timeoutTimer?.cancel();
    _ticketCubit.watchPrintJob(counterName: widget.counter.name);
  }

  void _selesai() {
    AudioFeedback.tap();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);

    return Listener(
      onPointerDown: (_) => _resetTimeout(),
      child: BlocProvider.value(
        value: _ticketCubit,
        child: BlocListener<TicketCubit, TicketState>(
          listener: (context, state) {
            if (state.status == TicketStatus.success) {
              SoundService.playSuccess();
              _animController.forward();
            } else if (state.status == TicketStatus.error) {
              SoundService.playError();
              _animController.forward();
              showErrorSnackbar(
                context,
                'Gagal: ${state.errorMessage}',
                duration: const Duration(seconds: 5),
              );
            }

            if (state.printJobStatus == PrintJobStatus.printed) {
              SoundService.playSuccess();
              _resetTimeout();
            } else if (state.printJobStatus == PrintJobStatus.failed) {
              SoundService.playError();
              _resetTimeout();
            }
          },
          child: Scaffold(
            backgroundColor: AppColors.background,
            body: Column(
              children: [
                KioskHeader(
                  title:
                      '${widget.counter.name} · ${widget.counter.description}',
                  onBack: () => Navigator.of(context).pop(),
                  trailing: const [ClockWidget()],
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.w(20),
                      vertical: Responsive.h(28),
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: Responsive.w(620),
                          maxHeight: Responsive.h(800),
                        ),
                        child: BlocBuilder<TicketCubit, TicketState>(
                          builder: (context, state) {
                            switch (state.status) {
                              case TicketStatus.confirm:
                                return _buildTicketDetailView(state);
                              case TicketStatus.loading:
                                return _buildLoadingView();
                              case TicketStatus.success:
                                switch (state.printJobStatus) {
                                  case PrintJobStatus.idle:
                                    return _buildTicketDetailView(state);
                                  case PrintJobStatus.printing:
                                    return _buildPrintingView();
                                  case PrintJobStatus.printed:
                                    return _buildPrintedView(state);
                                  case PrintJobStatus.failed:
                                    return _buildPrintFailedView(state);
                                }
                              case TicketStatus.error:
                                return _buildErrorView(state);
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                const AppFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgress({required String label, required Color color}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: Responsive.w(56),
          height: Responsive.w(56),
          child: CircularProgressIndicator(
            strokeWidth: Responsive.w(4),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        SizedBox(height: Responsive.h(20)),
        Text(
          label,
          style: TextStyle(
            fontSize: Responsive.sp(18),
            color: AppColors.textDark,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingView() =>
      _buildProgress(label: 'Memproses nomor antrian...', color: AppColors.navy);

  Widget _buildPrintingView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: Responsive.w(72),
          height: Responsive.w(72),
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(
                child: CircularProgressIndicator(
                  strokeWidth: Responsive.w(4),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.gold,
                  ),
                ),
              ),
              Icon(
                Icons.print_outlined,
                size: Responsive.sp(26),
                color: AppColors.navy,
              ),
            ],
          ),
        ),
        SizedBox(height: Responsive.h(20)),
        Text(
          'Tiket sedang dicetak...',
          style: TextStyle(
            fontSize: Responsive.sp(18),
            color: AppColors.textDark,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPrintFailedView(TicketState state) => _buildTicketResultView(
    state,
    icon: Icons.print_disabled_outlined,
    accent: AppColors.orange,
    title: 'Tiket Gagal Dicetak',
    // Alasannya kalau ada; kalau kosong, tetap kasih arahan yang bisa
    // dikerjakan pengunjung sekarang juga.
    subtitle: state.printFailureReason.isEmpty
        ? 'Nomor antrian Anda tetap berlaku. Silakan foto layar ini.'
        : '${state.printFailureReason} Nomor antrian Anda tetap berlaku.',
    footnote: 'Foto layar ini sebagai bukti nomor antrian Anda',
  );

  Widget _buildErrorView(TicketState state) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CodeAvatar(
            icon: Icons.cloud_off_rounded,
            size: Responsive.w(72),
            color: AppColors.danger,
          ),
          SizedBox(height: Responsive.h(18)),
          Text(
            'Gagal Mengambil Nomor Antrian',
            style: TextStyle(
              fontSize: Responsive.sp(21),
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          SizedBox(height: Responsive.h(8)),
          Text(
            state.errorMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: Responsive.sp(15),
              color: AppColors.textMuted,
            ),
          ),
          SizedBox(height: Responsive.h(24)),
          AppButton(
            label: 'Coba Lagi',
            icon: Icons.refresh_rounded,
            onPressed: _ambilNomor,
          ),
        ],
      ),
    );
  }

  Widget _buildTicketDetailView(TicketState state) {
    final nomorBerjalan = state.queueInfo?.currentServing ?? '-';
    final sisaAntrian = state.queueInfo?.waitingCount ?? 0;
    final estimasiMenit = sisaAntrian * state.estimatePerPerson;
    final hasTicket = state.ticket != null;
    final nomorTiket = state.ticket?.queueCode ?? '-';
    final cardWidth = Responsive.w(440);

    return ScaleTransition(
      scale: _scaleAnim,
      child: FittedBox(
        fit: BoxFit.contain,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Panel(
              width: cardWidth,
              padding: EdgeInsets.zero,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Layanan yang dipilih.
                  Padding(
                    padding: EdgeInsets.all(Responsive.w(18)),
                    child: Row(
                      children: [
                        CodeAvatar(
                          code: widget.counter.code,
                          size: Responsive.w(52),
                          fontSize: Responsive.sp(24),
                        ),
                        SizedBox(width: Responsive.w(14)),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.counter.name,
                                style: TextStyle(
                                  fontSize: Responsive.sp(13),
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textMuted,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: Responsive.h(2)),
                              Text(
                                widget.counter.description,
                                style: TextStyle(
                                  fontSize: Responsive.sp(18),
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        if (widget.counter.isPriority) ...[
                          SizedBox(width: Responsive.w(8)),
                          const StatusBadge(
                            label: 'Layanan prioritas',
                            color: AppColors.orange,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Divider(),
                  // Dua angka utama: yang sedang dilayani, dan nomor
                  // pengunjung (atau sisa antrian sebelum ambil nomor).
                  Padding(
                    padding: EdgeInsets.all(Responsive.w(12)),
                    child: Row(
                      children: [
                        Expanded(
                          child: _NumberBlock(
                            label: 'Sedang dilayani',
                            value: nomorBerjalan,
                          ),
                        ),
                        SizedBox(width: Responsive.w(12)),
                        Expanded(
                          child: _NumberBlock(
                            label: hasTicket
                                ? 'Nomor antrian Anda'
                                : 'Sisa antrian',
                            value: hasTicket ? nomorTiket : '$sisaAntrian',
                            caption: hasTicket
                                ? 'Harap simpan nomor ini'
                                : 'orang',
                            // Emas menandai "milik Anda", sama dengan penanda
                            // nomor aktif di layar petugas Loket.
                            background: hasTicket
                                ? AppColors.goldSoft
                                : AppColors.navySoft,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  IntrinsicHeight(
                    child: Row(
                      children: [
                        Expanded(
                          child: _InfoItem(
                            icon: Icons.people_outline_rounded,
                            label: hasTicket
                                ? 'Antrian sebelum Anda'
                                : 'Antrian saat ini',
                            value: '$sisaAntrian orang',
                          ),
                        ),
                        const VerticalDivider(width: 1),
                        Expanded(
                          child: _InfoItem(
                            icon: Icons.schedule_rounded,
                            label: 'Estimasi waktu tunggu',
                            value: '± $estimasiMenit menit',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: Responsive.h(20)),
            SizedBox(
              width: cardWidth,
              child: hasTicket
                  ? AppButton(
                      label: 'Cetak Tiket Antrian',
                      icon: Icons.print_outlined,
                      large: true,
                      onPressed: _mulaiCetak,
                    )
                  : AppButton(
                      label: 'Ambil Tiket',
                      large: true,
                      onPressed: _ambilNomor,
                    ),
            ),
            SizedBox(height: Responsive.h(12)),
            SizedBox(
              width: cardWidth,
              child: Text(
                hasTicket
                    ? 'Perhatikan papan informasi antrian dan pastikan nomor Anda terdengar'
                    : 'Nomor antrian akan diberikan setelah Anda menekan tombol di atas',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: Responsive.sp(13),
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrintedView(TicketState state) => _buildTicketResultView(
    state,
    icon: Icons.check_rounded,
    accent: AppColors.success,
    title: 'Tiket Berhasil Dicetak',
    subtitle: 'Ambil tiket dari mesin pencetak di bawah layar ini',
    footnote: 'Simpan tiket ini hingga nomor Anda dipanggil',
  );

  /// Kartu tiket yang sama dipakai buat hasil berhasil MAUPUN gagal.
  ///
  /// Waktu cetak gagal, layar inilah satu-satunya bukti nomor antrian yang
  /// dipegang pengunjung — jadi nomornya harus sebesar dan sejelas versi
  /// yang tercetak, biar bisa difoto. Kartunya meniru kertas tiket: pita
  /// identitas di atas, logo + nama kantor, lalu nomor besar.
  Widget _buildTicketResultView(
    TicketState state, {
    required IconData icon,
    required Color accent,
    required String title,
    required String subtitle,
    required String footnote,
  }) {
    final nomorTiket = state.ticket?.queueCode ?? '-';
    final sisaAntrian = state.queueInfo?.waitingCount ?? 0;
    final now = DateTime.now();
    final tanggal = '${now.day}/${now.month}/${now.year}';
    final pukul =
        '${now.hour.toString().padLeft(2, '0')}.${now.minute.toString().padLeft(2, '0')} WIB';
    final cardWidth = Responsive.w(380);

    return FittedBox(
      fit: BoxFit.contain,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CodeAvatar(
            icon: icon,
            size: Responsive.w(64),
            color: accent,
            shape: BoxShape.circle,
            fontSize: Responsive.sp(34),
          ),
          SizedBox(height: Responsive.h(14)),
          Text(
            title,
            style: TextStyle(
              fontSize: Responsive.sp(24),
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          SizedBox(height: Responsive.h(4)),
          SizedBox(
            width: cardWidth * 1.3,
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: Responsive.sp(15),
                color: AppColors.textMuted,
              ),
            ),
          ),
          SizedBox(height: Responsive.h(20)),
          Panel(
            width: cardWidth,
            padding: EdgeInsets.zero,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const BrandStripe(),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.w(18),
                    vertical: Responsive.w(14),
                  ),
                  child: Row(
                    children: [
                      BrandLogo(size: Responsive.w(34)),
                      SizedBox(width: Responsive.w(10)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Kantor Pertanahan Kab. Karawang',
                              style: TextStyle(
                                fontSize: Responsive.sp(12),
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMuted,
                              ),
                            ),
                            Text(
                              widget.counter.description,
                              style: TextStyle(
                                fontSize: Responsive.sp(16),
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.w(18),
                    vertical: Responsive.w(18),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SectionLabel('Nomor antrian Anda'),
                      SizedBox(height: Responsive.h(4)),
                      Text(
                        nomorTiket,
                        style: TextStyle(
                          fontFamily: AppTheme.numberFamily,
                          fontSize: Responsive.sp(52),
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                          height: 1.1,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.w(18),
                    vertical: Responsive.w(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTicketInfoRow('Tanggal', tanggal),
                      SizedBox(height: Responsive.h(6)),
                      _buildTicketInfoRow('Pukul', pukul),
                      SizedBox(height: Responsive.h(6)),
                      _buildTicketInfoRow(
                        'Antrian sebelum Anda',
                        '$sisaAntrian orang',
                        valueColor: AppColors.navy,
                      ),
                    ],
                  ),
                ),
                Container(
                  color: AppColors.background,
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.w(18),
                    vertical: Responsive.w(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: Responsive.sp(15),
                        color: AppColors.textMuted,
                      ),
                      SizedBox(width: Responsive.w(6)),
                      Flexible(
                        child: Text(
                          footnote,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: Responsive.sp(12.5),
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: Responsive.h(20)),
          SizedBox(
            width: cardWidth,
            child: AppButton(label: 'Selesai', large: true, onPressed: _selesai),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketInfoRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: Responsive.sp(13.5),
            color: AppColors.textMuted,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: Responsive.sp(14),
            fontWeight: FontWeight.w700,
            color: valueColor ?? AppColors.textDark,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

/// Blok angka besar di kartu konfirmasi. Tanpa [background] tampil polos
/// di atas putih; dengan [background] jadi kotak sorotan warna tipis.
class _NumberBlock extends StatelessWidget {
  final String label;
  final String value;
  final String? caption;
  final Color? background;

  const _NumberBlock({
    required this.label,
    required this.value,
    this.caption,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.w(12),
        vertical: Responsive.w(14),
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SectionLabel(
            label,
            color: background == null ? AppColors.textMuted : AppColors.navy,
          ),
          SizedBox(height: Responsive.h(4)),
          Text(
            value,
            style: TextStyle(
              fontFamily: AppTheme.numberFamily,
              fontSize: Responsive.sp(34),
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
              height: 1.1,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          SizedBox(height: Responsive.h(4)),
          Text(
            caption ?? ' ',
            style: TextStyle(
              fontSize: Responsive.sp(12.5),
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Satu keterangan kecil berikon di kaki kartu konfirmasi.
class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.w(18),
        vertical: Responsive.w(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: Responsive.sp(20), color: AppColors.navy),
          SizedBox(width: Responsive.w(10)),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: Responsive.sp(12.5),
                    color: AppColors.textMuted,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: Responsive.sp(15),
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
