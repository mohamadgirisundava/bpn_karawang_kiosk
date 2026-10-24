import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/services/realtime_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/audio_feedback.dart';
import '../../core/utils/responsive.dart';
import '../../domain/entities/counter_entity.dart';
import '../../injection.dart';
import '../cubits/counter/counter_cubit.dart';
import '../cubits/counter/counter_state.dart';
import '../widgets/app_button.dart';
import '../widgets/app_footer.dart';
import '../widgets/brand.dart';
import '../widgets/clock_widget.dart';
import '../widgets/code_avatar.dart';
import '../widgets/kiosk_settings_menu.dart';
import '../widgets/status_badge.dart';
import 'applicant_type_screen.dart';
import 'queue_info_screen.dart';
import 'ticket_screen.dart';

/// Home Screen - halaman utama untuk memilih layanan.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Duration _idleTimeout = Duration(hours: 1);
  Timer? _idleTimer;
  late final CounterCubit _counterCubit;

  @override
  void initState() {
    super.initState();
    _counterCubit = Injection.instance.counterCubit;
    _resetIdleTimer();
    RealtimeService.instance.subscribe();
    _counterCubit.loadCounters();
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    super.dispose();
  }

  void _resetIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(_idleTimeout, _goToIdle);
  }

  void _goToIdle() {
    if (!mounted) return;
    goToIdleOrBreak(context);
  }

  void _pilihCounter(CounterEntity counter) {
    AudioFeedback.tap();
    if (counter.isPlotting) {
      // Loket Plotting: minta klasifikasi Pemohon Langsung/Prioritas atau
      // Kuasa dulu sebelum ambil tiket — khusus loket ini, nggak untuk
      // loket lain (lihat ApplicantTypeScreen).
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ApplicantTypeScreen(counter: counter),
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => TicketScreen(counter: counter)),
    );
  }

  void _lihatInfoAntrian() {
    AudioFeedback.tap();
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const QueueInfoScreen()));
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);

    return Listener(
      onPointerDown: (_) => _resetIdleTimer(),
      onPointerMove: (_) => _resetIdleTimer(),
      child: BlocProvider.value(
        value: _counterCubit,
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            children: [
              _buildHeader(),
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
                        'Pilih jenis layanan',
                        style: TextStyle(
                          fontSize: Responsive.sp(26),
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      SizedBox(height: Responsive.h(6)),
                      Text(
                        'Sentuh salah satu layanan untuk mengambil nomor antrian.',
                        style: TextStyle(
                          fontSize: Responsive.sp(15),
                          color: AppColors.textMuted,
                        ),
                      ),
                      SizedBox(height: Responsive.h(28)),
                      Expanded(child: _buildCounterGrid()),
                      // _buildInfoBanner(),
                      // SizedBox(height: Responsive.h(8)),
                      // _buildInfoAntrianButton(),
                    ],
                  ),
                ),
              ),
              const AppFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.w(14),
        vertical: Responsive.sp(10),
      ),
      decoration: BoxDecoration(
        color: AppColors.lightBlueSoft,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: Responsive.sp(18),
            color: AppColors.lightBlue,
          ),
          SizedBox(width: Responsive.w(8)),
          Expanded(
            child: Text(
              'Bawa dokumen yang diperlukan. Nomor antrian berlaku hari ini saja.',
              style: TextStyle(
                fontSize: Responsive.sp(13),
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return KioskHeader(
      title: 'Ambil Nomor Antrian',
      onLogoLongPress: () => showKioskSettingsMenu(context),
      trailing: [
        const ClockWidget(),
        Container(
          width: 1,
          height: Responsive.sp(30),
          margin: EdgeInsets.only(
            left: Responsive.w(16),
            right: Responsive.w(4),
          ),
          color: AppColors.border,
        ),
        IconButton(
          onPressed: () => confirmExitKiosk(context),
          tooltip: 'Keluar Aplikasi',
          icon: Icon(
            Icons.logout_rounded,
            color: AppColors.textMuted,
            size: Responsive.sp(22),
          ),
        ),
      ],
    );
  }

  Widget _buildCounterGrid() {
    return BlocBuilder<CounterCubit, CounterState>(
      builder: (context, state) {
        if (state.status == CounterStatus.loading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.navy),
          );
        }

        if (state.status == CounterStatus.error) {
          return _buildMessage(
            icon: Icons.cloud_off_rounded,
            color: AppColors.danger,
            title: 'Gagal memuat data layanan',
            message: state.errorMessage,
            action: AppButton(
              label: 'Coba Lagi',
              icon: Icons.refresh_rounded,
              onPressed: () => _counterCubit.loadCounters(),
            ),
          );
        }

        if (state.counters.isEmpty) {
          return _buildMessage(
            icon: Icons.info_outline_rounded,
            color: AppColors.navy,
            title: 'Belum ada layanan tersedia',
            message: 'Silakan hubungi petugas untuk informasi lebih lanjut.',
          );
        }

        final crossAxisSpacing = Responsive.w(16);
        final mainAxisSpacing = Responsive.h(16);
        final columns = Responsive.gridColumns.clamp(1, state.counters.length);
        final rows = (state.counters.length / columns).ceil();

        return LayoutBuilder(
          builder: (context, constraints) {
            final cellWidth =
                (constraints.maxWidth - crossAxisSpacing * (columns - 1)) /
                columns;
            final cellHeight =
                (constraints.maxHeight - mainAxisSpacing * (rows - 1)) / rows;

            return GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: crossAxisSpacing,
                mainAxisSpacing: mainAxisSpacing,
                childAspectRatio: cellWidth / cellHeight,
              ),
              itemCount: state.counters.length,
              itemBuilder: (context, index) {
                final counter = state.counters[index];
                return _buildCounterCard(counter, state);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildMessage({
    required IconData icon,
    required Color color,
    required String title,
    required String message,
    Widget? action,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CodeAvatar(icon: icon, size: Responsive.w(72), color: color),
          SizedBox(height: Responsive.h(18)),
          Text(
            title,
            style: TextStyle(
              fontSize: Responsive.sp(21),
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          SizedBox(height: Responsive.h(8)),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: Responsive.sp(15),
              color: AppColors.textMuted,
            ),
          ),
          if (action != null) ...[SizedBox(height: Responsive.h(24)), action],
        ],
      ),
    );
  }

  /// Kartu layanan: kode + nama di atas, angka antrian di bawah, dan pita
  /// navy "Ambil nomor" di kaki kartu sebagai penanda bisa disentuh —
  /// tanpa bayangan, sesuai bahasa visual Loket.
  Widget _buildCounterCard(CounterEntity counter, CounterState state) {
    final info = state.queueInfo[counter.id];
    final nomorBerjalan = info?.currentServing ?? '-';
    final sisaAntrian = info?.waitingCount ?? 0;
    final radius = BorderRadius.circular(AppRadius.cardLarge);

    return Material(
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _pilihCounter(counter),
        enableFeedback: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  Responsive.w(20),
                  Responsive.w(20),
                  Responsive.w(20),
                  Responsive.w(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CodeAvatar(
                          code: counter.code,
                          size: Responsive.w(52),
                          fontSize: Responsive.sp(24),
                        ),
                        SizedBox(width: Responsive.w(14)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                counter.name,
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
                                counter.description,
                                style: TextStyle(
                                  fontSize: Responsive.sp(18),
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark,
                                  height: 1.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        if (counter.isPriority) ...[
                          SizedBox(width: Responsive.w(8)),
                          const StatusBadge(
                            label: 'Prioritas',
                            color: AppColors.orange,
                          ),
                        ],
                      ],
                    ),
                    const Spacer(),
                    const Divider(),
                    SizedBox(height: Responsive.h(12)),
                    Row(
                      children: [
                        Expanded(
                          child: _CardStat(
                            label: 'Sedang dilayani',
                            value: nomorBerjalan,
                          ),
                        ),
                        Expanded(
                          child: _CardStat(
                            label: 'Menunggu',
                            value: '$sisaAntrian',
                            unit: 'orang',
                          ),
                        ),
                      ],
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
                children: [
                  Expanded(
                    child: Text(
                      'Ambil nomor',
                      style: TextStyle(
                        fontSize: Responsive.sp(15),
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                  ),
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

  Widget _buildInfoAntrianButton() {
    return SizedBox(
      width: double.infinity,
      child: AppButton(
        label: 'Lihat Informasi Antrian Berjalan',
        icon: Icons.info_outline_rounded,
        variant: AppButtonVariant.secondary,
        onPressed: _lihatInfoAntrian,
      ),
    );
  }
}

/// Satu angka di kaki kartu layanan: label kecil di atas, angka besar
/// (font angka Nunito) di bawah.
class _CardStat extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;

  const _CardStat({required this.label, required this.value, this.unit});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SectionLabel(label, fontSize: Responsive.sp(12.5)),
        SizedBox(height: Responsive.h(2)),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(
                fontFamily: AppTheme.numberFamily,
                fontSize: Responsive.sp(24),
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
                height: 1.1,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            if (unit != null) ...[
              SizedBox(width: Responsive.w(5)),
              Text(
                unit!,
                style: TextStyle(
                  fontSize: Responsive.sp(13),
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
