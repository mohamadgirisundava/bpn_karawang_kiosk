import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_button_styles.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/realtime_service.dart';
import '../../core/utils/audio_feedback.dart';
import '../../core/utils/responsive.dart';
import '../../domain/entities/counter_entity.dart';
import '../../injection.dart';
import '../cubits/counter/counter_cubit.dart';
import '../cubits/counter/counter_state.dart';
import '../widgets/app_footer.dart';
import '../widgets/clock_widget.dart';
import 'idle_screen.dart';
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
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const IdleScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _pilihCounter(CounterEntity counter) {
    AudioFeedback.tap();
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

  /// Menu admin tersembunyi — akses via long-press logo.
  void _showAdminMenu() {
    AudioFeedback.tap();
    final pinController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Responsive.r(4)),
        ),
        title: Row(
          children: [
            Icon(
              Icons.admin_panel_settings,
              color: AppColors.navy,
              size: Responsive.sp(28),
            ),
            SizedBox(width: Responsive.w(8)),
            Text(
              'Menu Admin',
              style: TextStyle(
                fontSize: Responsive.sp(18),
                fontWeight: FontWeight.bold,
                color: AppColors.navy,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Masukkan PIN untuk mengakses pengaturan',
              style: TextStyle(
                fontSize: Responsive.sp(14),
                color: AppColors.textMuted,
              ),
            ),
            SizedBox(height: Responsive.h(16)),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: Responsive.sp(24),
                letterSpacing: Responsive.w(8),
              ),
              decoration: InputDecoration(
                hintText: '••••••',
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Responsive.r(4)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Responsive.r(4)),
                  borderSide: const BorderSide(color: AppColors.navy, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            style: AppButtonStyles.text(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (pinController.text == '123456') {
                Navigator.of(dialogContext).pop();
                _showSettingsDialog();
              } else {
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('PIN salah'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: AppButtonStyles.elevated(),
            child: const Text('Masuk'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Responsive.r(4)),
        ),
        title: Row(
          children: [
            Icon(
              Icons.settings,
              color: AppColors.navy,
              size: Responsive.sp(28),
            ),
            SizedBox(width: Responsive.w(8)),
            Text(
              'Pengaturan',
              style: TextStyle(
                fontSize: Responsive.sp(18),
                fontWeight: FontWeight.bold,
                color: AppColors.navy,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                Icons.exit_to_app,
                color: Colors.red,
                size: Responsive.sp(24),
              ),
              title: Text(
                'Keluar Aplikasi',
                style: TextStyle(fontSize: Responsive.sp(16)),
              ),
              subtitle: Text(
                'Tutup aplikasi kiosk',
                style: TextStyle(
                  fontSize: Responsive.sp(13),
                  color: AppColors.textMuted,
                ),
              ),
              onTap: () {
                Navigator.of(dialogContext).pop();
                _confirmExit();
              },
            ),
            SizedBox(height: Responsive.h(8)),
            Container(height: 1, color: AppColors.border),
            SizedBox(height: Responsive.h(8)),
            ListTile(
              leading: Icon(
                Icons.refresh,
                color: AppColors.navy,
                size: Responsive.sp(24),
              ),
              title: Text(
                'Restart ke Idle',
                style: TextStyle(fontSize: Responsive.sp(16)),
              ),
              subtitle: Text(
                'Kembali ke layar awal',
                style: TextStyle(
                  fontSize: Responsive.sp(13),
                  color: AppColors.textMuted,
                ),
              ),
              onTap: () {
                Navigator.of(dialogContext).pop();
                _goToIdle();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            style: AppButtonStyles.text(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _confirmExit() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Responsive.r(4)),
        ),
        title: Text(
          'Keluar Aplikasi?',
          style: TextStyle(
            fontSize: Responsive.sp(18),
            fontWeight: FontWeight.bold,
            color: AppColors.navy,
          ),
        ),
        content: Text(
          'Aplikasi kiosk akan ditutup. Pastikan ini memang diperlukan.',
          style: TextStyle(
            fontSize: Responsive.sp(14),
            color: AppColors.textMuted,
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
              SystemNavigator.pop();
            },
            style: AppButtonStyles.elevated(background: Colors.red),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);

    return PopScope(
      canPop: false,
      child: Listener(
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
                      horizontal: Responsive.w(100),
                      vertical: Responsive.h(40),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pilih Jenis Layanan',
                          style: TextStyle(
                            fontSize: Responsive.sp(18),
                            fontWeight: FontWeight.bold,
                            color: AppColors.navy,
                          ),
                        ),
                        SizedBox(height: Responsive.h(4)),
                        Text(
                          'Sentuh salah satu loket untuk mengambil nomor antrian',
                          style: TextStyle(
                            fontSize: Responsive.sp(12),
                            color: AppColors.textMuted,
                          ),
                        ),
                        SizedBox(height: Responsive.h(24)),
                        Expanded(child: _buildCounterGrid()),
                        SizedBox(height: Responsive.h(10)),
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
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.w(14),
        vertical: Responsive.h(8),
      ),
      decoration: BoxDecoration(
        color: AppColors.navy.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(Responsive.r(4)),
        border: Border.all(color: AppColors.navy.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: Responsive.sp(16),
            color: AppColors.navy,
          ),
          SizedBox(width: Responsive.w(8)),
          Expanded(
            child: Text(
              'Bawa dokumen yang diperlukan. Nomor antrian berlaku hari ini saja.',
              style: TextStyle(
                fontSize: Responsive.sp(11),
                color: AppColors.textDark,
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
          GestureDetector(
            onLongPress: _showAdminMenu,
            child: Image.asset(
              'assets/images/bpn_karawang_logo.png',
              width: Responsive.w(38),
              height: Responsive.w(38),
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.account_balance,
                color: AppColors.white,
                size: Responsive.w(38),
              ),
            ),
          ),
          SizedBox(width: Responsive.w(10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Kantor Pertanahan Kabupaten Karawang',
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

  Widget _buildCounterGrid() {
    return BlocBuilder<CounterCubit, CounterState>(
      builder: (context, state) {
        if (state.status == CounterStatus.loading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.navy),
          );
        }

        if (state.status == CounterStatus.error) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.cloud_off,
                  size: Responsive.sp(64),
                  color: Colors.red.shade300,
                ),
                SizedBox(height: Responsive.h(16)),
                Text(
                  'Gagal Memuat Data Loket',
                  style: TextStyle(
                    fontSize: Responsive.sp(20),
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),
                SizedBox(height: Responsive.h(8)),
                Text(
                  state.errorMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: Responsive.sp(14),
                    color: AppColors.textMuted,
                  ),
                ),
                SizedBox(height: Responsive.h(24)),
                ElevatedButton.icon(
                  onPressed: () => _counterCubit.loadCounters(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba Lagi'),
                  style: AppButtonStyles.elevated(),
                ),
              ],
            ),
          );
        }

        if (state.counters.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.info_outline,
                  size: Responsive.sp(64),
                  color: AppColors.textMuted.withValues(alpha: 0.6),
                ),
                SizedBox(height: Responsive.h(16)),
                Text(
                  'Belum Ada Layanan Tersedia',
                  style: TextStyle(
                    fontSize: Responsive.sp(20),
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),
                SizedBox(height: Responsive.h(8)),
                Text(
                  'Silakan hubungi petugas untuk informasi lebih lanjut.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: Responsive.sp(14),
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          );
        }

        final crossAxisSpacing = Responsive.w(12);
        final mainAxisSpacing = Responsive.h(12);
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

  Widget _buildCounterCard(CounterEntity counter, CounterState state) {
    final info = state.queueInfo[counter.id];
    final nomorBerjalan = info?.currentServing ?? '-';
    final sisaAntrian = info?.waitingCount ?? 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _pilihCounter(counter),
        borderRadius: BorderRadius.circular(Responsive.r(16)),
        enableFeedback: false,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(Responsive.r(16)),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withValues(alpha: 0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: Container(
                  height: Responsive.h(6),
                  color: AppColors.navy,
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    Responsive.w(16),
                    Responsive.h(18),
                    Responsive.w(16),
                    Responsive.h(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: Responsive.w(52),
                            height: Responsive.w(52),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.navy,
                              borderRadius: BorderRadius.circular(
                                Responsive.r(14),
                              ),
                            ),
                            child: Text(
                              counter.code,
                              style: TextStyle(
                                fontSize: Responsive.sp(20),
                                fontWeight: FontWeight.bold,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: Responsive.w(12),
                              vertical: Responsive.h(6),
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.navy.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Pilih Loket',
                                  style: TextStyle(
                                    fontSize: Responsive.sp(10.5),
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.navy,
                                  ),
                                ),
                                SizedBox(width: Responsive.w(2)),
                                Icon(
                                  Icons.chevron_right,
                                  size: Responsive.sp(13),
                                  color: AppColors.navy,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: Responsive.h(14)),
                      Row(
                        children: [
                          Text(
                            counter.name.toUpperCase(),
                            style: TextStyle(
                              fontSize: Responsive.sp(10),
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                              color: AppColors.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (counter.isPriority) ...[
                            SizedBox(width: Responsive.w(6)),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: Responsive.w(6),
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.orange,
                                borderRadius: BorderRadius.circular(
                                  Responsive.r(4),
                                ),
                              ),
                              child: Text(
                                'PRIORITAS',
                                style: TextStyle(
                                  fontSize: Responsive.sp(7.5),
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: Responsive.h(2)),
                      Text(
                        counter.description,
                        style: TextStyle(
                          fontSize: Responsive.sp(14),
                          fontWeight: FontWeight.bold,
                          color: AppColors.navy,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: Responsive.h(14)),
                      Container(height: 1, color: AppColors.border),
                      SizedBox(height: Responsive.h(12)),
                      Row(
                        children: [
                          Container(
                            width: Responsive.w(7),
                            height: Responsive.w(7),
                            decoration: const BoxDecoration(
                              color: AppColors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: Responsive.w(6)),
                          Expanded(
                            child: Text(
                              'Sedang dilayani',
                              style: TextStyle(
                                fontSize: Responsive.sp(11),
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                          Text(
                            nomorBerjalan,
                            style: TextStyle(
                              fontSize: Responsive.sp(15),
                              fontWeight: FontWeight.bold,
                              color: AppColors.navy,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: Responsive.h(8)),
                      Row(
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: Responsive.sp(13),
                            color: AppColors.textMuted,
                          ),
                          SizedBox(width: Responsive.w(6)),
                          Expanded(
                            child: Text(
                              '$sisaAntrian orang dalam antrian',
                              style: TextStyle(
                                fontSize: Responsive.sp(11),
                                color: AppColors.textMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
      ),
    );
  }

  Widget _buildInfoAntrianButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _lihatInfoAntrian,
        icon: const Icon(Icons.info_outline),
        label: const Text('Lihat Informasi Antrian Berjalan'),
        style: AppButtonStyles.outlined(),
      ),
    );
  }
}
