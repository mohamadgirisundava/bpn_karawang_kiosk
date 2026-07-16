import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../domain/entities/counter_entity.dart';
import '../../injection.dart';
import '../cubits/queue/queue_cubit.dart';
import '../cubits/queue/queue_state.dart';

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
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + Responsive.h(12),
                bottom: Responsive.h(12),
                left: Responsive.w(8),
                right: Responsive.w(16),
              ),
              decoration: BoxDecoration(
                color: AppColors.navy,
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
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text(
                      'Informasi Antrian',
                      textAlign: TextAlign.center,
                      style: TextStyle(
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
                padding: EdgeInsets.all(Responsive.w(24)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          Text(
                            'Nomor Antrian Berjalan',
                            style: TextStyle(
                              fontSize: Responsive.sp(24 * 0.8),
                              fontWeight: FontWeight.bold,
                              color: AppColors.navy,
                            ),
                          ),
                          SizedBox(height: Responsive.h(4)),
                          Text(
                            'Update secara real-time',
                            style: TextStyle(
                              fontSize: Responsive.sp(14 * 0.8),
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
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

                          if (state.counters.isEmpty) {
                            return Center(
                              child: Text(
                                'Tidak ada data loket',
                                style: TextStyle(
                                  fontSize: Responsive.sp(14 * 0.8),
                                  color: AppColors.textMuted,
                                ),
                              ),
                            );
                          }

                          return ListView.separated(
                            itemCount: state.counters.length,
                            separatorBuilder: (_, __) =>
                                SizedBox(height: Responsive.h(16)),
                            itemBuilder: (context, index) {
                              final counter = state.counters[index];
                              return _buildQueueCard(counter, state);
                            },
                          );
                        },
                      ),
                    ),
                    SizedBox(height: Responsive.h(16)),
                    SizedBox(
                      width: double.infinity,
                      height: Responsive.h(56),
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.navy,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              Responsive.r(16),
                            ),
                          ),
                        ),
                        child: Text(
                          'Kembali ke Menu Utama',
                          style: TextStyle(fontSize: Responsive.sp(16 * 0.8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
      padding: EdgeInsets.all(Responsive.w(20)),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(Responsive.r(16)),
        border: Border.all(
          color: counter.color.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: Responsive.w(56),
            height: Responsive.w(56),
            decoration: BoxDecoration(
              color: counter.color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              counter.icon,
              color: counter.color,
              size: Responsive.sp(28 * 0.8),
            ),
          ),
          SizedBox(width: Responsive.w(16)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      counter.name,
                      style: TextStyle(
                        fontSize: Responsive.sp(18 * 0.8),
                        fontWeight: FontWeight.bold,
                        color: counter.color,
                      ),
                    ),
                    if (counter.isPriority) ...[
                      SizedBox(width: Responsive.w(8)),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: Responsive.w(8),
                          vertical: Responsive.h(2),
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.orange,
                          borderRadius: BorderRadius.circular(Responsive.r(8)),
                        ),
                        child: Text(
                          'PRIORITAS',
                          style: TextStyle(
                            fontSize: Responsive.sp(9 * 0.8),
                            fontWeight: FontWeight.bold,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: Responsive.h(4)),
                Text(
                  counter.description,
                  style: TextStyle(
                    fontSize: Responsive.sp(13 * 0.8),
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.w(14),
                  vertical: Responsive.h(8),
                ),
                decoration: BoxDecoration(
                  color: counter.color,
                  borderRadius: BorderRadius.circular(Responsive.r(12)),
                ),
                child: Text(
                  nomorSekarang,
                  style: TextStyle(
                    fontSize: Responsive.sp(20 * 0.8),
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
              ),
              SizedBox(height: Responsive.h(8)),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.people,
                    size: Responsive.sp(14 * 0.8),
                    color: AppColors.textMuted,
                  ),
                  SizedBox(width: Responsive.w(4)),
                  Text(
                    '$sisaAntrian antrian',
                    style: TextStyle(
                      fontSize: Responsive.sp(12 * 0.8),
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              SizedBox(height: Responsive.h(2)),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time,
                    size: Responsive.sp(14 * 0.8),
                    color: AppColors.textMuted,
                  ),
                  SizedBox(width: Responsive.w(4)),
                  Text(
                    '~$estimasiMenit menit',
                    style: TextStyle(
                      fontSize: Responsive.sp(12 * 0.8),
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
