import 'data/datasources/counter_remote_datasource.dart';
import 'data/datasources/queue_remote_datasource.dart';
import 'data/datasources/settings_remote_datasource.dart';
import 'data/repositories/counter_repository_impl.dart';
import 'data/repositories/queue_repository_impl.dart';
import 'data/repositories/settings_repository_impl.dart';
import 'domain/repositories/counter_repository.dart';
import 'domain/repositories/queue_repository.dart';
import 'domain/repositories/settings_repository.dart';
import 'domain/usecases/create_print_job.dart';
import 'domain/usecases/create_queue.dart';
import 'domain/usecases/get_active_counters.dart';
import 'domain/usecases/get_estimate_per_person.dart';
import 'domain/usecases/get_queue_info.dart';
import 'domain/usecases/watch_print_job_status.dart';
import 'presentation/cubits/counter/counter_cubit.dart';
import 'presentation/cubits/queue/queue_cubit.dart';
import 'presentation/cubits/ticket/ticket_cubit.dart';

/// Dependency injection — instantiate semua layer secara manual.
class Injection {
  Injection._();

  static final Injection instance = Injection._();

  // Datasources
  late final CounterRemoteDatasource _counterDatasource;
  late final QueueRemoteDatasource _queueDatasource;
  late final SettingsRemoteDatasource _settingsDatasource;

  /// Dibuka buat OperatingHoursService — dia baca setting mentah
  /// (jam_buka/jam_tutup/hari_libur) dari layer service, bukan dari cubit,
  /// jadi nggak lewat usecase.
  SettingsRemoteDatasource get settingsDatasource => _settingsDatasource;

  // Repositories
  late final CounterRepository _counterRepository;
  late final QueueRepository _queueRepository;
  late final SettingsRepository _settingsRepository;

  // Usecases
  late final GetActiveCounters _getActiveCounters;
  late final CreateQueue _createQueue;
  late final CreatePrintJob _createPrintJob;
  late final GetQueueInfo _getQueueInfo;
  late final GetEstimatePerPerson _getEstimatePerPerson;
  late final WatchPrintJobStatus _watchPrintJobStatus;

  bool _initialized = false;

  /// Initialize all dependencies.
  void init() {
    if (_initialized) return;

    // Datasources
    _counterDatasource = CounterRemoteDatasource();
    _queueDatasource = QueueRemoteDatasource();
    _settingsDatasource = SettingsRemoteDatasource();

    // Repositories
    _counterRepository = CounterRepositoryImpl(_counterDatasource);
    _queueRepository = QueueRepositoryImpl(_queueDatasource);
    _settingsRepository = SettingsRepositoryImpl(_settingsDatasource);

    // Usecases
    _getActiveCounters = GetActiveCounters(_counterRepository);
    _createQueue = CreateQueue(_queueRepository);
    _createPrintJob = CreatePrintJob(_queueRepository);
    _getQueueInfo = GetQueueInfo(_queueRepository);
    _getEstimatePerPerson = GetEstimatePerPerson(_settingsRepository);
    _watchPrintJobStatus = WatchPrintJobStatus(_queueRepository);

    _initialized = true;
  }

  /// Factory untuk CounterCubit.
  CounterCubit get counterCubit => CounterCubit(
    getActiveCounters: _getActiveCounters,
    getQueueInfo: _getQueueInfo,
  );

  /// Factory untuk TicketCubit.
  TicketCubit get ticketCubit => TicketCubit(
    createQueue: _createQueue,
    createPrintJob: _createPrintJob,
    getQueueInfo: _getQueueInfo,
    getEstimatePerPerson: _getEstimatePerPerson,
    watchPrintJobStatus: _watchPrintJobStatus,
  );

  /// Factory untuk QueueInfoCubit.
  QueueInfoCubit get queueInfoCubit => QueueInfoCubit(
    getActiveCounters: _getActiveCounters,
    getQueueInfo: _getQueueInfo,
    getEstimatePerPerson: _getEstimatePerPerson,
  );
}
