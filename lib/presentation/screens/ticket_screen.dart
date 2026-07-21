import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_button_styles.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/sound_service.dart';
import '../../core/utils/audio_feedback.dart';
import '../../core/utils/responsive.dart';
import '../../domain/entities/counter_entity.dart';
import '../../injection.dart';
import '../cubits/ticket/ticket_cubit.dart';
import '../cubits/ticket/ticket_state.dart';

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

  void _showConfirmDialog() {
    AudioFeedback.tap();
    _resetTimeout();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Responsive.r(4)),
        ),
        title: Row(
          children: [
            Icon(
              Icons.help_outline,
              color: AppColors.navy,
              size: Responsive.sp(28),
            ),
            SizedBox(width: Responsive.w(8)),
            Expanded(
              child: Text(
                'Anda yakin ingin mengambil nomor antrian?',
                style: TextStyle(
                  fontSize: Responsive.sp(18),
                  color: AppColors.navy,
                ),
              ),
            ),
          ],
        ),
        content: Container(
          padding: EdgeInsets.all(Responsive.w(16)),
          decoration: BoxDecoration(
            color: AppColors.navy.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(Responsive.r(4)),
          ),
          child: Row(
            children: [
              Icon(
                widget.counter.icon,
                color: AppColors.navy,
                size: Responsive.sp(40),
              ),
              SizedBox(width: Responsive.w(16)),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.counter.name,
                    style: TextStyle(
                      fontSize: Responsive.sp(20),
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy,
                    ),
                  ),
                  Text(
                    widget.counter.description,
                    style: TextStyle(
                      fontSize: Responsive.sp(14),
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
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
              _ambilNomor();
            },
            style: AppButtonStyles.elevated(),
            child: const Text('Ya, Ambil Nomor'),
          ),
        ],
      ),
    );
  }

  Future<void> _ambilNomor() async {
    AudioFeedback.action();
    _resetTimeout();

    _ticketCubit.takeTicket(
      counterId: widget.counter.id,
      counterCode: widget.counter.code,
    );
  }

  void _cetakTiket(String nomorAntrian) {
    AudioFeedback.success();
    _timeoutTimer?.cancel();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Responsive.r(4)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.print, size: Responsive.sp(64), color: AppColors.navy),
            SizedBox(height: Responsive.h(16)),
            Text(
              'Tiket Sedang Dicetak...',
              style: TextStyle(
                fontSize: Responsive.sp(20),
                fontWeight: FontWeight.bold,
                color: AppColors.navy,
              ),
            ),
            SizedBox(height: Responsive.h(8)),
            Text(
              'Nomor Antrian: $nomorAntrian',
              style: TextStyle(
                fontSize: Responsive.sp(16),
                color: AppColors.textMuted,
              ),
            ),
            SizedBox(height: Responsive.h(14)),
            Text(
              'Silakan ambil tiket Anda',
              style: TextStyle(
                fontSize: Responsive.sp(14),
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                AudioFeedback.tap();
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop();
              },
              style: AppButtonStyles.elevated(),
              child: const Text('Selesai'),
            ),
          ),
        ],
      ),
    );

    Future.delayed(const Duration(seconds: 10), () {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }
    });
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
              SoundService.playSuccess();
              _animController.forward();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Gagal: ${state.errorMessage}'),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 5),
                ),
              );
            }
          },
          child: Scaffold(
            backgroundColor: AppColors.background,
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
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back,
                          color: AppColors.white,
                          size: Responsive.sp(20),
                        ),
                        onPressed: () {
                          AudioFeedback.tap();
                          Navigator.of(context).pop();
                        },
                      ),
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
                      SizedBox(width: Responsive.w(40)),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(Responsive.w(20)),
                      child: BlocBuilder<TicketCubit, TicketState>(
                        builder: (context, state) {
                          switch (state.status) {
                            case TicketStatus.confirm:
                              return _buildConfirmView(state);
                            case TicketStatus.loading:
                              return _buildLoadingView();
                            case TicketStatus.success:
                              return _buildTicketView(
                                state.ticket?.queueCode ?? '---',
                              );
                            case TicketStatus.error:
                              return _buildTicketView(
                                '${widget.counter.code}---',
                              );
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

  Widget _buildConfirmView(TicketState state) {
    final nomorBerjalan = state.queueInfo?.currentServing ?? '-';
    final sisaAntrian = state.queueInfo?.waitingCount ?? 0;
    final estimasiMenit = sisaAntrian * state.estimatePerPerson;

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: Responsive.w(56),
            height: Responsive.w(56),
            decoration: BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.circular(Responsive.r(4)),
              border: Border(
                bottom: BorderSide(
                  color: AppColors.gold,
                  width: Responsive.h(3),
                ),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              widget.counter.code,
              style: TextStyle(
                fontSize: Responsive.sp(22),
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ),
          ),
          SizedBox(height: Responsive.h(14)),
          Text(
            widget.counter.name,
            style: TextStyle(
              fontSize: Responsive.sp(26),
              fontWeight: FontWeight.bold,
              color: AppColors.navy,
            ),
          ),
          SizedBox(height: Responsive.h(4)),
          Text(
            widget.counter.description,
            style: TextStyle(
              fontSize: Responsive.sp(14),
              color: AppColors.textMuted,
            ),
          ),
          SizedBox(height: Responsive.h(14)),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.w(18),
              vertical: Responsive.sp(10),
            ),
            decoration: BoxDecoration(
              color: AppColors.navy.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(Responsive.r(4)),
              border: Border.all(color: AppColors.navy.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  children: [
                    Text(
                      'Sedang Dilayani',
                      style: TextStyle(
                        fontSize: Responsive.sp(12),
                        color: AppColors.navy,
                      ),
                    ),
                    SizedBox(height: Responsive.h(4)),
                    Text(
                      nomorBerjalan,
                      style: TextStyle(
                        fontSize: Responsive.sp(20),
                        fontWeight: FontWeight.bold,
                        color: AppColors.navy,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 1,
                  height: Responsive.h(32),
                  margin: EdgeInsets.symmetric(horizontal: Responsive.w(14)),
                  color: AppColors.navy.withValues(alpha: 0.3),
                ),
                Column(
                  children: [
                    Text(
                      'Sisa Antrian',
                      style: TextStyle(
                        fontSize: Responsive.sp(12),
                        color: AppColors.textMuted,
                      ),
                    ),
                    SizedBox(height: Responsive.h(4)),
                    Text(
                      '$sisaAntrian orang',
                      style: TextStyle(
                        fontSize: Responsive.sp(20),
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 1,
                  height: Responsive.h(32),
                  margin: EdgeInsets.symmetric(horizontal: Responsive.w(14)),
                  color: AppColors.navy.withValues(alpha: 0.3),
                ),
                Column(
                  children: [
                    Text(
                      'Estimasi',
                      style: TextStyle(
                        fontSize: Responsive.sp(12),
                        color: AppColors.textMuted,
                      ),
                    ),
                    SizedBox(height: Responsive.h(4)),
                    Text(
                      '~$estimasiMenit mnt',
                      style: TextStyle(
                        fontSize: Responsive.sp(20),
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (widget.counter.isPriority) ...[
            SizedBox(height: Responsive.h(16)),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.w(16),
                vertical: Responsive.h(8),
              ),
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(Responsive.r(4)),
                border: Border.all(color: AppColors.orange),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.warning_amber,
                    color: AppColors.orange,
                    size: Responsive.sp(20),
                  ),
                  SizedBox(width: Responsive.w(8)),
                  Text(
                    'Layanan Prioritas (Lansia, Disabilitas, Ibu Hamil)',
                    style: TextStyle(
                      fontSize: Responsive.sp(14),
                      color: AppColors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: Responsive.h(18)),
          SizedBox(
            width: Responsive.w(260),
            child: ElevatedButton(
              onPressed: _showConfirmDialog,
              style: AppButtonStyles.elevated(),
              child: const Text('Ambil Nomor Antrian'),
            ),
          ),
          SizedBox(height: Responsive.h(10)),
          TextButton(
            onPressed: () {
              AudioFeedback.tap();
              Navigator.of(context).pop();
            },
            style: AppButtonStyles.text(),
            child: const Text('Kembali'),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketView(String nomorAntrian) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              color: AppColors.green,
              size: Responsive.sp(48),
            ),
            SizedBox(height: Responsive.h(10)),
            Text(
              'Nomor Antrian Anda',
              style: TextStyle(
                fontSize: Responsive.sp(16),
                color: AppColors.textMuted,
              ),
            ),
            SizedBox(height: Responsive.h(10)),
            Container(
              width: Responsive.w(260),
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.w(22),
                vertical: Responsive.sp(14),
              ),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(Responsive.r(4)),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.navy.withValues(alpha: 0.08),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    widget.counter.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: Responsive.sp(12),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                      color: AppColors.textMuted,
                    ),
                  ),
                  SizedBox(height: Responsive.h(8)),
                  Container(height: 1, color: AppColors.border),
                  SizedBox(height: Responsive.h(10)),
                  Text(
                    nomorAntrian,
                    style: TextStyle(
                      fontSize: Responsive.sp(40),
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  SizedBox(height: Responsive.h(4)),
                  Text(
                    widget.counter.description,
                    style: TextStyle(
                      fontSize: Responsive.sp(13),
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: Responsive.h(14)),
            SizedBox(
              width: Responsive.w(260),
              child: ElevatedButton.icon(
                onPressed: () => _cetakTiket(nomorAntrian),
                icon: const Icon(Icons.print),
                label: const Text('Cetak Tiket'),
                style: AppButtonStyles.elevated(
                  background: AppColors.gold,
                  foreground: AppColors.navy,
                ),
              ),
            ),
            SizedBox(height: Responsive.h(10)),
            TextButton(
              onPressed: () {
                AudioFeedback.tap();
                Navigator.of(context).pop();
              },
              style: AppButtonStyles.text(),
              child: const Text('Kembali ke Menu Utama'),
            ),
          ],
        ),
      ),
    );
  }
}
