import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_button_styles.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/services/sound_service.dart';
import '../../core/utils/audio_feedback.dart';
import '../../core/utils/error_snackbar.dart';
import '../../core/utils/responsive.dart';
import '../../domain/entities/counter_entity.dart';
import '../../injection.dart';
import '../cubits/ticket/ticket_cubit.dart';
import '../cubits/ticket/ticket_state.dart';
import '../widgets/app_footer.dart';

/// Ticket Screen - Halaman konfirmasi & cetak tiket setelah memilih counter.
class TicketScreen extends StatefulWidget {
  final CounterEntity counter;

  const TicketScreen({super.key, required this.counter});

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
            backgroundColor: AppColors.background.withValues(alpha: 0.4),
            body: Column(
              children: [
                Container(
                  width: double.infinity,
                  height: 100,
                  padding: EdgeInsets.only(
                    left: Responsive.w(8),
                    right: Responsive.w(14),
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.navy,
                    border: Border(
                      bottom: BorderSide(
                        color: AppColors.gold,
                        width: Responsive.h(3),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${widget.counter.name} - ${widget.counter.description}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'NunitoSans',
                            fontSize: Responsive.sp(16),
                            fontWeight: FontWeight.bold,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.w(20),
                      vertical: Responsive.h(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: () {
                            AudioFeedback.tap();
                            Navigator.of(context).pop();
                          },
                          borderRadius: BorderRadius.circular(Responsive.r(4)),
                          enableFeedback: false,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: Responsive.w(8),
                              vertical: Responsive.h(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.arrow_back,
                                  size: Responsive.sp(15),
                                  color: AppColors.navy,
                                ),
                                SizedBox(width: Responsive.w(6)),
                                Text(
                                  'Kembali ke pilihan loket',
                                  style: TextStyle(
                                    fontSize: Responsive.sp(13),
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.navy,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: Responsive.w(560),
                                maxHeight: Responsive.h(680),
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
                      ],
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

  Widget _buildLoadingView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: Responsive.w(56),
          height: Responsive.w(56),
          child: CircularProgressIndicator(
            strokeWidth: Responsive.w(5),
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.navy),
          ),
        ),
        SizedBox(height: Responsive.h(18)),
        Text(
          'Memproses nomor antrian...',
          style: TextStyle(
            fontSize: Responsive.sp(16),
            color: AppColors.navy,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPrintingView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: Responsive.w(56),
          height: Responsive.w(56),
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                strokeWidth: Responsive.w(5),
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
              ),
              Icon(Icons.print, size: Responsive.sp(20), color: AppColors.navy),
            ],
          ),
        ),
        SizedBox(height: Responsive.h(18)),
        Text(
          'Tiket Sedang Dicetak...',
          style: TextStyle(
            fontSize: Responsive.sp(16),
            color: AppColors.navy,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPrintFailedView(TicketState state) {
    final nomorTiket = state.ticket?.queueCode ?? '-';
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.print_disabled,
            size: Responsive.sp(48),
            color: Colors.red.shade300,
          ),
          SizedBox(height: Responsive.h(12)),
          Text(
            'Tiket Gagal Dicetak',
            style: TextStyle(
              fontSize: Responsive.sp(18),
              fontWeight: FontWeight.bold,
              color: AppColors.navy,
            ),
          ),
          SizedBox(height: Responsive.h(6)),
          Text(
            'Nomor antrian Anda tetap $nomorTiket dan sudah tercatat. Silakan hubungi petugas jika membutuhkan tiket fisik.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: Responsive.sp(13),
              color: AppColors.textMuted,
            ),
          ),
          SizedBox(height: Responsive.h(16)),
          ElevatedButton(
            onPressed: _selesai,
            style: AppButtonStyles.elevated(),
            child: const Text('Selesai'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(TicketState state) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off,
            size: Responsive.sp(48),
            color: Colors.red.shade300,
          ),
          SizedBox(height: Responsive.h(12)),
          Text(
            'Gagal Mengambil Nomor Antrian',
            style: TextStyle(
              fontSize: Responsive.sp(18),
              fontWeight: FontWeight.bold,
              color: AppColors.navy,
            ),
          ),
          SizedBox(height: Responsive.h(6)),
          Text(
            state.errorMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: Responsive.sp(13),
              color: AppColors.textMuted,
            ),
          ),
          SizedBox(height: Responsive.h(16)),
          ElevatedButton.icon(
            onPressed: _ambilNomor,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
            style: AppButtonStyles.elevated(),
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
    const cardWidth = 420.0;

    return ScaleTransition(
      scale: _scaleAnim,
      child: FittedBox(
        fit: BoxFit.contain,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: Responsive.w(cardWidth),
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.w(16),
                vertical: Responsive.h(14),
              ),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: AppColors.border, width: 2),
              ),
              child: Row(
                children: [
                  Container(
                    width: Responsive.w(52),
                    height: Responsive.w(52),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.navy,
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                    ),
                    child: Text(
                      widget.counter.code,
                      style: TextStyle(
                        fontSize: Responsive.sp(20),
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  SizedBox(width: Responsive.w(14)),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.counter.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: Responsive.sp(10),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: AppColors.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: Responsive.h(2)),
                        Text(
                          widget.counter.description,
                          style: TextStyle(
                            fontSize: Responsive.sp(15),
                            fontWeight: FontWeight.bold,
                            color: AppColors.navy,
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
            SizedBox(height: Responsive.h(12)),
            Container(
              width: Responsive.w(cardWidth),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: AppColors.border, width: 2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: Responsive.w(12),
                            vertical: Responsive.h(16),
                          ),
                          color: AppColors.white,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'SEDANG DILAYANI',
                                style: TextStyle(
                                  fontSize: Responsive.sp(9.5),
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.4,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              SizedBox(height: Responsive.h(6)),
                              Text(
                                nomorBerjalan,
                                style: TextStyle(
                                  fontSize: Responsive.sp(26),
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.navy,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                              SizedBox(height: Responsive.h(6)),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: Responsive.w(6),
                                    height: Responsive.w(6),
                                    decoration: const BoxDecoration(
                                      color: AppColors.green,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  SizedBox(width: Responsive.w(5)),
                                  Text(
                                    'Aktif',
                                    style: TextStyle(
                                      fontSize: Responsive.sp(10),
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          margin: EdgeInsets.fromLTRB(
                            0,
                            Responsive.h(10),
                            Responsive.w(10),
                            Responsive.h(10),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: Responsive.w(12),
                            vertical: Responsive.h(16),
                          ),
                          decoration: BoxDecoration(
                            color: hasTicket
                                ? AppColors.gold.withValues(alpha: 0.28)
                                : AppColors.lightBlue.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(AppRadius.chip),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                hasTicket ? 'NOMOR TIKET ANDA' : 'SISA ANTRIAN',
                                style: TextStyle(
                                  fontSize: Responsive.sp(9.5),
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.4,
                                  color: AppColors.navy,
                                ),
                              ),
                              SizedBox(height: Responsive.h(6)),
                              Text(
                                hasTicket ? nomorTiket : '$sisaAntrian',
                                style: TextStyle(
                                  fontSize: Responsive.sp(26),
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.navy,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                              SizedBox(height: Responsive.h(6)),
                              Text(
                                hasTicket ? 'Harap simpan nomor ini' : 'orang',
                                style: TextStyle(
                                  fontSize: Responsive.sp(9.5),
                                  color: AppColors.navy.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Container(height: 2, color: AppColors.border),
                  IntrinsicHeight(
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.fromLTRB(
                              Responsive.w(12),
                              Responsive.h(10),
                              Responsive.w(12),
                              Responsive.h(14),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  size: Responsive.sp(14),
                                  color: AppColors.lightBlue,
                                ),
                                SizedBox(width: Responsive.w(6)),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      hasTicket
                                          ? 'Antrian sebelum Anda'
                                          : 'Antrian saat ini',
                                      style: TextStyle(
                                        fontSize: Responsive.sp(9.5),
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    Text(
                                      '$sisaAntrian orang',
                                      style: TextStyle(
                                        fontSize: Responsive.sp(11.5),
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textDark,
                                        fontFeatures: const [
                                          FontFeature.tabularFigures(),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const VerticalDivider(
                          width: 2,
                          thickness: 2,
                          color: AppColors.border,
                        ),
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.fromLTRB(
                              Responsive.w(12),
                              Responsive.h(10),
                              Responsive.w(12),
                              Responsive.h(14),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: Responsive.sp(14),
                                  color: AppColors.navy,
                                ),
                                SizedBox(width: Responsive.w(6)),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Estimasi waktu tunggu',
                                      style: TextStyle(
                                        fontSize: Responsive.sp(9.5),
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    Text(
                                      '± $estimasiMenit menit',
                                      style: TextStyle(
                                        fontSize: Responsive.sp(11.5),
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textDark,
                                        fontFeatures: const [
                                          FontFeature.tabularFigures(),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (widget.counter.isPriority) ...[
              SizedBox(height: Responsive.h(12)),
              Container(
                width: Responsive.w(cardWidth),
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.w(16),
                  vertical: Responsive.h(8),
                ),
                decoration: BoxDecoration(
                  color: AppColors.navy.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                  border: Border.all(color: AppColors.navy, width: 2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.warning_amber,
                      color: AppColors.navy,
                      size: Responsive.sp(18),
                    ),
                    SizedBox(width: Responsive.w(8)),
                    Text(
                      'Layanan Prioritas',
                      style: TextStyle(
                        fontSize: Responsive.sp(12.5),
                        color: AppColors.navy,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: Responsive.h(16)),
            SizedBox(
              width: Responsive.w(cardWidth),
              child: hasTicket
                  ? ElevatedButton.icon(
                      onPressed: _mulaiCetak,
                      icon: const Icon(Icons.print),
                      label: const Text('Cetak Tiket Antrian'),
                      style: AppButtonStyles.elevated(),
                    )
                  : ElevatedButton.icon(
                      onPressed: _ambilNomor,
                      icon: null,
                      label: const Text('Ambil Tiket'),
                      style: AppButtonStyles.elevated(),
                    ),
            ),
            SizedBox(height: Responsive.h(8)),
            Text(
              hasTicket
                  ? 'Perhatikan papan informasi antrian dan pastikan nomor Anda terdengar'
                  : 'Nomor antrian akan diberikan setelah Anda menekan tombol di atas',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: Responsive.sp(11),
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrintedView(TicketState state) {
    final nomorTiket = state.ticket?.queueCode ?? '-';
    final sisaAntrian = state.queueInfo?.waitingCount ?? 0;
    final now = DateTime.now();
    final tanggal = '${now.day}/${now.month}/${now.year}';
    final pukul =
        '${now.hour.toString().padLeft(2, '0')}.${now.minute.toString().padLeft(2, '0')} WIB';
    const cardWidth = 340.0;

    return FittedBox(
      fit: BoxFit.contain,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: Responsive.w(64),
            height: Responsive.w(64),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_outline,
              size: Responsive.sp(36),
              color: AppColors.green,
            ),
          ),
          SizedBox(height: Responsive.h(14)),
          Text(
            'Tiket Berhasil Dicetak',
            style: TextStyle(
              fontSize: Responsive.sp(20),
              fontWeight: FontWeight.bold,
              color: AppColors.navy,
            ),
          ),
          SizedBox(height: Responsive.h(4)),
          Text(
            'Ambil tiket dari mesin pencetak di bawah layar ini',
            style: TextStyle(
              fontSize: Responsive.sp(12.5),
              color: AppColors.textMuted,
            ),
          ),
          SizedBox(height: Responsive.h(18)),
          Container(
            width: Responsive.w(cardWidth),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.border, width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.w(16),
                    vertical: Responsive.h(10),
                  ),
                  color: AppColors.navy,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'KANTOR PERTANAHAN',
                        style: TextStyle(
                          fontFamily: 'NunitoSans',
                          fontSize: Responsive.sp(9),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: AppColors.goldLight,
                        ),
                      ),
                      Text(
                        widget.counter.description,
                        style: TextStyle(
                          fontFamily: 'NunitoSans',
                          fontSize: Responsive.sp(14),
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.w(16),
                    vertical: Responsive.h(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'NOMOR ANTRIAN ANDA',
                        style: TextStyle(
                          fontSize: Responsive.sp(10),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                      SizedBox(height: Responsive.h(6)),
                      Text(
                        nomorTiket,
                        style: TextStyle(
                          fontSize: Responsive.sp(36),
                          fontWeight: FontWeight.bold,
                          color: AppColors.navy,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(height: 2, color: AppColors.border),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.w(16),
                    vertical: Responsive.h(10),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTicketInfoRow('Tanggal', tanggal),
                      SizedBox(height: Responsive.h(4)),
                      _buildTicketInfoRow('Pukul', pukul),
                      SizedBox(height: Responsive.h(4)),
                      _buildTicketInfoRow(
                        'Antrian sebelum Anda',
                        '$sisaAntrian orang',
                        valueColor: AppColors.navy,
                      ),
                    ],
                  ),
                ),
                Container(height: 2, color: AppColors.border),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.w(16),
                    vertical: Responsive.h(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: Responsive.sp(13),
                        color: AppColors.textMuted,
                      ),
                      SizedBox(width: Responsive.w(6)),
                      Flexible(
                        child: Text(
                          'Simpan tiket ini hingga nomor Anda dipanggil',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: Responsive.sp(11),
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
            width: Responsive.w(cardWidth),
            child: ElevatedButton(
              onPressed: _selesai,
              style: AppButtonStyles.elevated(),
              child: const Text('Selesai'),
            ),
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
            fontSize: Responsive.sp(12),
            color: AppColors.textMuted,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: Responsive.sp(12.5),
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppColors.textDark,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
