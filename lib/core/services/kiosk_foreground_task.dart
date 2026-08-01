import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Jaga proses kiosk tetap hidup pas app-nya di-background (Android nge-
/// suspend/throttle proses biasa kalau nggak di-foreground, yang bikin
/// listener Firestore + pengumuman suara CallAnnouncerService berhenti).
/// Foreground service Android butuh notifikasi permanen selama jalan —
/// itu konsekuensi standar dari mekanisme ini, bukan bug.
///
/// TaskHandler-nya sendiri sengaja nggak ngapa-ngapain (eventAction:
/// nothing()) — kerjaan sebenarnya (dengerin `calls`, mainin chime+TTS)
/// tetap di CallAnnouncerService yang jalan di main isolate; keberadaan
/// foreground service ini cuma buat naikin prioritas PROSES-nya di mata
/// Android biar nggak di-suspend, bukan buat jalanin kerjaan terpisah.
class _KioskTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    debugPrint('KioskForegroundTask: started (starter: ${starter.name})');
  }

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    debugPrint('KioskForegroundTask: destroyed (timeout: $isTimeout)');
  }
}

@pragma('vm:entry-point')
void kioskForegroundTaskStartCallback() {
  FlutterForegroundTask.setTaskHandler(_KioskTaskHandler());
}

/// Minta izin notifikasi (wajib buat nampilin notifikasi foreground
/// service di Android 13+) lalu nyalain service-nya. Aman dipanggil di
/// platform selain Android (no-op).
Future<void> startKioskForegroundTask() async {
  if (!Platform.isAndroid) return;

  FlutterForegroundTask.initCommunicationPort();

  final notificationPermission =
      await FlutterForegroundTask.checkNotificationPermission();
  if (notificationPermission != NotificationPermission.granted) {
    await FlutterForegroundTask.requestNotificationPermission();
  }

  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'kiosk_foreground_service',
      channelName: 'Kiosk Antrian - Layanan Latar Belakang',
      channelDescription:
          'Menjaga aplikasi kiosk tetap aktif di latar belakang biar pengumuman antrian tetap bunyi.',
      onlyAlertOnce: true,
    ),
    iosNotificationOptions: const IOSNotificationOptions(
      showNotification: false,
      playSound: false,
    ),
    foregroundTaskOptions: ForegroundTaskOptions(
      eventAction: ForegroundTaskEventAction.nothing(),
      autoRunOnBoot: true,
      autoRunOnMyPackageReplaced: true,
      allowWakeLock: true,
      allowWifiLock: true,
    ),
  );

  if (await FlutterForegroundTask.isRunningService) {
    await FlutterForegroundTask.restartService();
    return;
  }

  await FlutterForegroundTask.startService(
    serviceId: 501,
    notificationTitle: 'Kiosk Antrian BPN Karawang',
    notificationText:
        'Berjalan di latar belakang — pengumuman antrian tetap aktif.',
    callback: kioskForegroundTaskStartCallback,
  );
}
