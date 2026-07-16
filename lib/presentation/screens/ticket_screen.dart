import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
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
          borderRadius: BorderRadius.circular(Responsive.r(20)),
        ),
        title: Row(
          children: [
            Icon(
              Icons.help_outline,
              color: widget.counter.color,
              size: Responsive.sp(28 * 0.8),
            ),
            SizedBox(width: Responsive.w(8)),
            Expanded(
              child: Text(
                'Anda yakin ingin mengambil nomor antrian?',
                style: TextStyle(
                  fontSize: Responsive.sp(18 * 0.8),
                  color: AppColors.navy,
                ),
              ),
            ),
          ],
        ),
        content: Container(
          padding: EdgeInsets.all(Responsive.w(16)),
          decoration: BoxDecoration(
            color: widget.counter.color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(Responsive.r(12)),
          ),
          child: Row(
            children: [
              Icon(
                widget.counter.icon,
                color: widget.counter.color,
                size: Responsive.sp(40 * 0.8),
              ),
              SizedBox(width: Responsive.w(16)),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.counter.name,
                    style: TextStyle(
                      fontSize: Responsive.sp(20 * 0.8),
                      fontWeight: FontWeight.bold,
                      color: widget.counter.color,
                    ),
                  ),
                  Text(
                    widget.counter.description,
                    style: TextStyle(
                      fontSize: Responsive.sp(14 * 0.8),
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
            child: Text(
              'Batal',
              style: TextStyle(fontSize: Responsive.sp(16 * 0.8)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _ambilNomor();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.counter.color,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Responsive.r(12)),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.w(24),
                vertical: Responsive.h(12),
              ),
            ),
            child: Text(
              'Ya, Ambil Nomor',
              style: TextStyle(
                fontSize: Responsive.sp(16 * 0.8),
                fontWeight: FontWeight.bold,
              ),
            ),
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
          borderRadius: BorderRadius.circular(Responsive.r(20)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.print,
              size: Responsive.sp(64 * 0.8),
              color: AppColors.green,
            ),
            SizedBox(height: Responsive.h(16)),
            Text(
              'Tiket Sedang Dicetak...',
              style: TextStyle(
                fontSize: Responsive.sp(20 * 0.8),
                fontWeight: FontWeight.bold,
                color: AppColors.navy,
              ),
            ),
            SizedBox(height: Responsive.h(8)),
            Text(
              'Nomor Antrian: $nomorAntrian',
              style: TextStyle(
                fontSize: Responsive.sp(16 * 0.8),
                color: AppColors.textMuted,
              ),
            ),
            SizedBox(height: Responsive.h(24)),
            Text(
              'Silakan ambil tiket Anda',
              style: TextStyle(
                fontSize: Responsive.sp(14 * 0.8),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navy,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Responsive.r(12)),
                ),
                padding: EdgeInsets.symmetric(vertical: Responsive.h(14)),
              ),
              child: Text(
                'Selesai',
                style: TextStyle(fontSize: Responsive.sp(16 * 0.8)),
              ),
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
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + Responsive.h(12),
                    bottom: Responsive.h(12),
                    left: Responsive.w(8),
                    right: Responsive.w(16),
                  ),
                  decoration: BoxDecoration(
                    color: widget.counter.color,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(Responsive.r(20)),
                      bottomRight: Radius.circular(Responsive.r(20)),
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
                            fontSize: Responsive.sp(14),
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
                      padding: EdgeInsets.all(Responsive.w(32)),
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
          width: Responsive.w(80),
          height: Responsive.w(80),
          child: CircularProgressIndicator(
            strokeWidth: Responsive.w(6),
            valueColor: AlwaysStoppedAnimation<Color>(widget.counter.color),
          ),
        ),
        SizedBox(height: Responsive.h(32)),
        Text(
          'Memproses nomor antrian...',
          style: TextStyle(
            fontSize: Responsive.sp(20 * 0.8),
            color: widget.counter.color,
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

    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: Responsive.w(120),
            height: Responsive.w(120),
            decoration: BoxDecoration(
              color: widget.counter.color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              widget.counter.icon,
              color: widget.counter.color,
              size: Responsive.sp(60 * 0.8),
            ),
          ),
          SizedBox(height: Responsive.h(32)),
          Text(
            widget.counter.name,
            style: TextStyle(
              fontSize: Responsive.sp(36 * 0.8),
              fontWeight: FontWeight.bold,
              color: widget.counter.color,
            ),
          ),
          SizedBox(height: Responsive.h(8)),
          Text(
            widget.counter.description,
            style: TextStyle(
              fontSize: Responsive.sp(18 * 0.8),
              color: AppColors.textMuted,
            ),
          ),
          SizedBox(height: Responsive.h(20)),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.w(24),
              vertical: Responsive.h(14),
            ),
            decoration: BoxDecoration(
              color: widget.counter.color.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(Responsive.r(16)),
              border: Border.all(
                color: widget.counter.color.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  children: [
                    Text(
                      'Sedang Dilayani',
                      style: TextStyle(
                        fontSize: Responsive.sp(12 * 0.8),
                        color: widget.counter.color,
                      ),
                    ),
                    SizedBox(height: Responsive.h(4)),
                    Text(
                      nomorBerjalan,
                      style: TextStyle(
                        fontSize: Responsive.sp(24 * 0.8),
                        fontWeight: FontWeight.bold,
                        color: widget.counter.color,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 1,
                  height: Responsive.h(40),
                  margin: EdgeInsets.symmetric(horizontal: Responsive.w(20)),
                  color: widget.counter.color.withValues(alpha: 0.3),
                ),
                Column(
                  children: [
                    Text(
                      'Sisa Antrian',
                      style: TextStyle(
                        fontSize: Responsive.sp(12 * 0.8),
                        color: AppColors.textMuted,
                      ),
                    ),
                    SizedBox(height: Responsive.h(4)),
                    Text(
                      '$sisaAntrian orang',
                      style: TextStyle(
                        fontSize: Responsive.sp(20 * 0.8),
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 1,
                  height: Responsive.h(40),
                  margin: EdgeInsets.symmetric(horizontal: Responsive.w(20)),
                  color: widget.counter.color.withValues(alpha: 0.3),
                ),
                Column(
                  children: [
                    Text(
                      'Estimasi',
                      style: TextStyle(
                        fontSize: Responsive.sp(12 * 0.8),
                        color: AppColors.textMuted,
                      ),
                    ),
                    SizedBox(height: Responsive.h(4)),
                    Text(
                      '~$estimasiMenit mnt',
                      style: TextStyle(
                        fontSize: Responsive.sp(20 * 0.8),
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
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
                borderRadius: BorderRadius.circular(Responsive.r(12)),
                border: Border.all(color: AppColors.orange),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.warning_amber,
                    color: AppColors.orange,
                    size: Responsive.sp(20 * 0.8),
                  ),
                  SizedBox(width: Responsive.w(8)),
                  Text(
                    'Layanan Prioritas (Lansia, Disabilitas, Ibu Hamil)',
                    style: TextStyle(
                      fontSize: Responsive.sp(14 * 0.8),
                      color: AppColors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: Responsive.h(48)),
          SizedBox(
            width: Responsive.w(280),
            height: Responsive.h(64),
            child: ElevatedButton(
              onPressed: _showConfirmDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.counter.color,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Responsive.r(20)),
                ),
                elevation: 4,
              ),
              child: Text(
                'Ambil Nomor Antrian',
                style: TextStyle(
                  fontSize: Responsive.sp(20 * 0.8),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(height: Responsive.h(16)),
          TextButton(
            onPressed: () {
              AudioFeedback.tap();
              Navigator.of(context).pop();
            },
            child: Text(
              'Kembali',
              style: TextStyle(
                fontSize: Responsive.sp(16 * 0.8),
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketView(String nomorAntrian) {
    final qrData =
        'LOKET:${widget.counter.id}|NOMOR:$nomorAntrian|WAKTU:${DateTime.now().toIso8601String()}';

    return ScaleTransition(
      scale: _scaleAnim,
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              color: AppColors.green,
              size: Responsive.sp(80 * 0.8),
            ),
            SizedBox(height: Responsive.h(24)),
            Text(
              'Nomor Antrian Anda',
              style: TextStyle(
                fontSize: Responsive.sp(20 * 0.8),
                color: AppColors.textMuted,
              ),
            ),
            SizedBox(height: Responsive.h(16)),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.w(32),
                vertical: Responsive.h(24),
              ),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(Responsive.r(24)),
                border: Border.all(color: widget.counter.color, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: widget.counter.color.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    widget.counter.name,
                    style: TextStyle(
                      fontSize: Responsive.sp(18 * 0.8),
                      color: widget.counter.color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: Responsive.h(8)),
                  Text(
                    nomorAntrian,
                    style: TextStyle(
                      fontSize: Responsive.sp(48),
                      fontWeight: FontWeight.bold,
                      color: widget.counter.color,
                    ),
                  ),
                  SizedBox(height: Responsive.h(8)),
                  Text(
                    widget.counter.description,
                    style: TextStyle(
                      fontSize: Responsive.sp(14 * 0.8),
                      color: AppColors.textMuted,
                    ),
                  ),
                  SizedBox(height: Responsive.h(16)),
                  Container(
                    padding: EdgeInsets.all(Responsive.w(8)),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(Responsive.r(12)),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: QrImageView(
                      data: qrData,
                      version: QrVersions.auto,
                      size: Responsive.w(100),
                      eyeStyle: QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: widget.counter.color,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: AppColors.navy,
                      ),
                    ),
                  ),
                  SizedBox(height: Responsive.h(8)),
                  Text(
                    'Scan QR di loket',
                    style: TextStyle(
                      fontSize: Responsive.sp(11 * 0.8),
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: Responsive.h(32)),
            SizedBox(
              width: Responsive.w(280),
              height: Responsive.h(64),
              child: ElevatedButton.icon(
                onPressed: () => _cetakTiket(nomorAntrian),
                icon: Icon(Icons.print, size: Responsive.sp(24 * 0.8)),
                label: Text(
                  'Cetak Tiket',
                  style: TextStyle(
                    fontSize: Responsive.sp(20 * 0.8),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.navy,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Responsive.r(20)),
                  ),
                  elevation: 4,
                ),
              ),
            ),
            SizedBox(height: Responsive.h(16)),
            TextButton(
              onPressed: () {
                AudioFeedback.tap();
                Navigator.of(context).pop();
              },
              child: Text(
                'Kembali ke Menu Utama',
                style: TextStyle(
                  fontSize: Responsive.sp(16 * 0.8),
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
