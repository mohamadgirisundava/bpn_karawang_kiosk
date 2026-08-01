import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/utils/responsive.dart';
import '../../domain/entities/counter_entity.dart';
import '../../injection.dart';
import '../cubits/queue/queue_cubit.dart';
import '../cubits/queue/queue_state.dart';
import '../widgets/app_footer.dart';
import '../widgets/glossy_badge.dart';
import '../widgets/gradient_button.dart';

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
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text(
                      'Informasi Antrian',
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
              child: Padding(
                padding: EdgeInsets.all(Responsive.w(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          Text(
                            'Nomor Antrian Berjalan',
                            style: TextStyle(
                              fontSize: Responsive.sp(18),
                              fontWeight: FontWeight.bold,
                              color: AppColors.navy,
                            ),
                          ),
                          SizedBox(height: Responsive.h(3)),
                          Text(
                            'Update secara real-time',
                            style: TextStyle(
                              fontSize: Responsive.sp(12),
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: Responsive.h(14)),
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
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.cloud_off,
                                    size: Responsive.sp(48),
                                    color: Colors.red.shade300,
                                  ),
                                  SizedBox(height: Responsive.h(12)),
                                  Text(
                                    state.errorMessage,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: Responsive.sp(14),
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                  SizedBox(height: Responsive.h(16)),
                                  GradientButton(
                                    label: 'Coba Lagi',
                                    icon: Icons.refresh,
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
                                  fontSize: Responsive.sp(14),
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
                                padding: EdgeInsets.symmetric(
                                  horizontal: Responsive.w(50),
                                ),
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
                    SizedBox(height: Responsive.h(16)),
                    SizedBox(
                      width: double.infinity,
                      child: GradientButton(
                        label: 'Kembali ke Menu Utama',
                        onPressed: () => Navigator.of(context).pop(),
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

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.w(16),
                vertical: Responsive.h(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    counter.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: Responsive.sp(12),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                      color: AppColors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: Responsive.h(8)),
                  Container(height: 2, color: AppColors.border),
                  Expanded(
                    child: Center(
                      child: Text(
                        nomorSekarang,
                        style: TextStyle(
                          fontSize: Responsive.sp(30),
                          fontWeight: FontWeight.bold,
                          color: AppColors.navy,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
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
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time,
                            size: Responsive.sp(12),
                            color: AppColors.textMuted,
                          ),
                          SizedBox(width: Responsive.w(3)),
                          Text(
                            '~$estimasiMenit menit',
                            style: TextStyle(
                              fontSize: Responsive.sp(10),
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (counter.isPriority)
            Positioned(
              top: Responsive.h(10),
              right: Responsive.w(10),
              child: const GlossyBadge(
                label: 'PRIORITAS',
                color: AppColors.orange,
              ),
            ),
        ],
      ),
    );
  }
}
