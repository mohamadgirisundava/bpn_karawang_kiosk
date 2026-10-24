import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../domain/entities/counter_entity.dart';
import '../../injection.dart';
import '../cubits/queue/queue_cubit.dart';
import '../cubits/queue/queue_state.dart';
import '../widgets/app_button.dart';
import '../widgets/app_footer.dart';
import '../widgets/brand.dart';
import '../widgets/clock_widget.dart';
import '../widgets/code_avatar.dart';
import '../widgets/status_badge.dart';

/// Queue Info Screen - Menampilkan informasi antrian berjalan
/// dan estimasi sisa antrian untuk setiap counter.
class QueueInfoScreen extends StatefulWidget {
  const QueueInfoScreen({super.key});

  @override
  State<QueueInfoScreen> createState() => _QueueInfoScreenState();
}

class _QueueInfoScreenState extends State<QueueInfoScreen> {
  late final QueueInfoCubit _queueInfoCubit;

  @override
  void initState() {
    super.initState();
    _queueInfoCubit = Injection.instance.queueInfoCubit;
    _queueInfoCubit.loadData();
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);

    return BlocProvider.value(
      value: _queueInfoCubit,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            KioskHeader(
              title: 'Informasi Antrian',
              onBack: () => Navigator.of(context).pop(),
              trailing: const [ClockWidget()],
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.w(80),
                  vertical: Responsive.h(40),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nomor antrian berjalan',
                      style: TextStyle(
                        fontSize: Responsive.sp(26),
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    SizedBox(height: Responsive.h(6)),
                    Text(
                      'Diperbarui otomatis setiap ada panggilan.',
                      style: TextStyle(
                        fontSize: Responsive.sp(15),
                        color: AppColors.textMuted,
                      ),
                    ),
                    SizedBox(height: Responsive.h(24)),
                    Expanded(
                      child: BlocBuilder<QueueInfoCubit, QueueInfoState>(
                        builder: (context, state) {
                          if (state.status == QueueInfoStatus.loading) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.navy,
                              ),
                            );
                          }

                          if (state.status == QueueInfoStatus.error) {
                            return Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CodeAvatar(
                                    icon: Icons.cloud_off_rounded,
                                    size: Responsive.w(72),
                                    color: AppColors.danger,
                                  ),
                                  SizedBox(height: Responsive.h(16)),
                                  Text(
                                    state.errorMessage,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: Responsive.sp(15),
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                  SizedBox(height: Responsive.h(20)),
                                  AppButton(
                                    label: 'Coba Lagi',
                                    icon: Icons.refresh_rounded,
                                    onPressed: () => _queueInfoCubit.loadData(),
                                  ),
                                ],
                              ),
                            );
                          }

                          if (state.counters.isEmpty) {
                            return Center(
                              child: Text(
                                'Belum ada loket aktif saat ini',
                                style: TextStyle(
                                  fontSize: Responsive.sp(16),
                                  color: AppColors.textMuted,
                                ),
                              ),
                            );
                          }

                          final crossAxisSpacing = Responsive.w(16);
                          final mainAxisSpacing = Responsive.h(16);
                          final columns = Responsive.gridColumns.clamp(
                            1,
                            state.counters.length,
                          );
                          final rows = (state.counters.length / columns).ceil();

                          return LayoutBuilder(
                            builder: (context, constraints) {
                              final cellWidth =
                                  (constraints.maxWidth -
                                      crossAxisSpacing * (columns - 1)) /
                                  columns;
                              final cellHeight =
                                  (constraints.maxHeight -
                                      mainAxisSpacing * (rows - 1)) /
                                  rows;

                              return GridView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: columns,
                                      crossAxisSpacing: crossAxisSpacing,
                                      mainAxisSpacing: mainAxisSpacing,
                                      childAspectRatio: cellWidth / cellHeight,
                                    ),
                                itemCount: state.counters.length,
                                itemBuilder: (context, index) {
                                  final counter = state.counters[index];
                                  return _buildQueueCard(counter, state);
                                },
                              );
                            },
                          );
                        },
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
    );
  }

  Widget _buildQueueCard(CounterEntity counter, QueueInfoState state) {
    final info = state.queueInfo[counter.id];
    final nomorSekarang = info?.currentServing ?? '-';
    final sisaAntrian = info?.waitingCount ?? 0;
    final estimasiMenit = sisaAntrian * state.estimatePerPerson;
    final mutedStyle = TextStyle(
      fontSize: Responsive.sp(13),
      color: AppColors.textMuted,
    );

    return Container(
      padding: EdgeInsets.all(Responsive.w(18)),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CodeAvatar(code: counter.code, size: Responsive.w(40)),
              SizedBox(width: Responsive.w(12)),
              Expanded(
                child: Text(
                  counter.description,
                  style: TextStyle(
                    fontSize: Responsive.sp(16),
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (counter.isPriority)
                const StatusBadge(label: 'Prioritas', color: AppColors.orange),
            ],
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SectionLabel('Sedang dilayani'),
                  Text(
                    nomorSekarang,
                    style: TextStyle(
                      fontFamily: AppTheme.numberFamily,
                      fontSize: Responsive.sp(40),
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                      height: 1.15,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(),
          SizedBox(height: Responsive.h(10)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$sisaAntrian menunggu', style: mutedStyle),
              Text('± $estimasiMenit menit', style: mutedStyle),
            ],
          ),
        ],
      ),
    );
  }
}
