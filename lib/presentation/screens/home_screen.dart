import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/realtime_service.dart';
import '../../core/utils/audio_feedback.dart';
import '../../core/utils/responsive.dart';
import '../../domain/entities/counter_entity.dart';
import '../../injection.dart';
import '../cubits/counter/counter_cubit.dart';
import '../cubits/counter/counter_state.dart';
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings, color: AppColors.navy),
            SizedBox(width: 8),
            Text('Menu Admin', style: TextStyle(color: AppColors.navy)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Masukkan PIN untuk mengakses pengaturan',
              style: TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 8),
              decoration: InputDecoration(
                hintText: '••••••',
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: AppColors.navy, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navy,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        title: const Row(
          children: [
            Icon(Icons.settings, color: AppColors.navy),
            SizedBox(width: 8),
            Text('Pengaturan', style: TextStyle(color: AppColors.navy)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: Colors.red),
              title: const Text('Keluar Aplikasi'),
              subtitle: const Text('Tutup aplikasi kiosk'),
              onTap: () {
                Navigator.of(dialogContext).pop();
                _confirmExit();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.refresh, color: AppColors.navy),
              title: const Text('Restart ke Idle'),
              subtitle: const Text('Kembali ke layar awal'),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        title: const Text('Keluar Aplikasi?'),
        content: const Text(
          'Aplikasi kiosk akan ditutup. Pastikan ini memang diperlukan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              SystemNavigator.pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
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
                    padding: EdgeInsets.all(Responsive.w(16)),
                    child: Column(
                      children: [
                        Text(
                          'Pilih Jenis Layanan',
                          style: TextStyle(
                            fontSize: Responsive.sp(22),
                            fontWeight: FontWeight.bold,
                            color: AppColors.navy,
                          ),
                        ),
                        SizedBox(height: Responsive.h(6)),
                        Text(
                          'Sentuh salah satu loket untuk mengambil nomor antrian',
                          style: TextStyle(
                            fontSize: Responsive.sp(13),
                            color: AppColors.textMuted,
                          ),
                        ),
                        SizedBox(height: Responsive.h(20)),
                        Expanded(child: _buildCounterGrid()),
                        SizedBox(height: Responsive.h(12)),
                        _buildInfoAntrianButton(),
                      ],
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

  Widget _buildHeader() {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: topPadding + Responsive.h(12),
        bottom: Responsive.h(12),
        left: Responsive.w(16),
        right: Responsive.w(16),
      ),
      decoration: BoxDecoration(
        color: AppColors.navy,
        border: Border(
          bottom: BorderSide(color: AppColors.gold, width: Responsive.h(4)),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onLongPress: _showAdminMenu,
            child: Image.asset(
              'assets/images/bpn_karawang_logo.png',
              width: Responsive.w(40),
              height: Responsive.w(40),
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.account_balance,
                color: AppColors.white,
                size: Responsive.w(40),
              ),
            ),
          ),
          SizedBox(width: Responsive.w(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kantor Pertanahan Kabupaten Karawang',
                  style: TextStyle(
                    fontSize: Responsive.sp(14),
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
                Text(
                  'Sistem Antrian Digital',
                  style: TextStyle(
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
                  icon: Icon(Icons.refresh, size: Responsive.sp(20)),
                  label: Text(
                    'Coba Lagi',
                    style: TextStyle(fontSize: Responsive.sp(15)),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Responsive.r(4)),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.w(28),
                      vertical: Responsive.sp(16),
                    ),
                  ),
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
                    fontSize: Responsive.sp(18),
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
        borderRadius: BorderRadius.circular(Responsive.r(4)),
        child: Container(
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
          child: Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: Responsive.h(8),
                    horizontal: Responsive.w(6),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        counter.name,
                        style: TextStyle(
                          fontSize: Responsive.sp(14),
                          fontWeight: FontWeight.bold,
                          color: AppColors.navy,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: Responsive.h(2)),
                      Text(
                        counter.description,
                        style: TextStyle(
                          fontSize: Responsive.sp(10),
                          color: AppColors.textMuted,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: Responsive.h(8)),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: Responsive.w(10),
                          vertical: Responsive.h(4),
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(Responsive.r(4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.play_arrow,
                              size: Responsive.sp(12),
                              color: AppColors.textMuted,
                            ),
                            SizedBox(width: Responsive.w(3)),
                            Text(
                              nomorBerjalan,
                              style: TextStyle(
                                fontSize: Responsive.sp(11),
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                            SizedBox(width: Responsive.w(8)),
                            Icon(
                              Icons.people,
                              size: Responsive.sp(12),
                              color: AppColors.textMuted,
                            ),
                            SizedBox(width: Responsive.w(3)),
                            Text(
                              '$sisaAntrian antrian',
                              style: TextStyle(
                                fontSize: Responsive.sp(10),
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (counter.isPriority)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.w(8),
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.orange,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(Responsive.r(4)),
                        bottomLeft: Radius.circular(Responsive.r(4)),
                      ),
                    ),
                    child: Text(
                      'PRIORITAS',
                      style: TextStyle(
                        fontSize: Responsive.sp(8),
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
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
        icon: Icon(Icons.info_outline, size: Responsive.sp(18)),
        label: Text(
          'Lihat Informasi Antrian Berjalan',
          style: TextStyle(fontSize: Responsive.sp(13)),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.navy,
          side: const BorderSide(color: AppColors.navy, width: 2),
          padding: EdgeInsets.symmetric(vertical: Responsive.sp(14)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Responsive.r(4)),
          ),
        ),
      ),
    );
  }
}
