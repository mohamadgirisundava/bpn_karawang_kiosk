import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'core/constants/app_colors.dart';
import 'core/services/adhan_scheduler_service.dart';
import 'core/services/call_announcer_service.dart';
import 'core/services/kiosk_foreground_task.dart';
import 'core/services/ceremony_audio_service.dart';
import 'core/services/scheduled_audio_service.dart';
import 'firebase_options.dart';
import 'injection.dart';
import 'presentation/screens/idle_screen.dart';
import 'presentation/widgets/kiosk_scaler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Kiosk selalu landscape — layar portrait (mis. profil default sebagian
  // emulator/BlueStacks) bikin grid loket jatuh ke mode list satu kolom.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Fullscreen kiosk mode
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Init Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Init dependency injection
  Injection.instance.init();

  // Speaker fisik kiosk-lah yang beneran kepake buat pengumuman "nomor
  // antrian..." (bukan TV Display) — jalanin di sini, global, nggak
  // terikat ke lifecycle satu screen tertentu, biar tetep bunyi walau
  // kiosk lagi di idle screen. Sengaja nggak di-await, sama kayak
  // RealtimeService — jangan sampai nge-block first paint.
  unawaited(CallAnnouncerService.instance.start());

  // Sama alasannya — speaker fisik ada di kiosk, jadi adzan jadwal
  // sholat juga diputar dari sini (bukan app Display, yang browsernya
  // butuh gesture user dulu baru bisa keluar suara).
  unawaited(AdhanSchedulerService.instance.start());

  // Agenda audio custom bikinan admin sendiri (jam berapa, bunyi apa,
  // sekali/tiap hari) — lihat ScheduledAudioService.
  unawaited(ScheduledAudioService.instance.start());

  // Indonesia Raya terjadwal + penerima uji suara dari Admin. Semua suara
  // sistem keluar dari kiosk — Display TV nggak punya speaker.
  unawaited(CeremonyAudioService.instance.start());

  runApp(const MyApp());

  // Minta izin notifikasi + nyalain foreground service setelah frame
  // pertama render — jangan sebelum runApp(), beberapa plugin butuh
  // Activity yang udah attached buat nampilin dialog izin.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(startKioskForegroundTask());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BPN Karawang Kiosk',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Nunito',
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.navy,
          primary: AppColors.navy,
          secondary: AppColors.gold,
          tertiary: AppColors.green,
          surface: AppColors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.navy,
          foregroundColor: AppColors.white,
          elevation: 0,
        ),
        // Material 3 default-nya dialog pakai colorScheme.surfaceContainerHigh
        // (abu-lavender ke-tint dari seedColor navy), bukan colorScheme.surface
        // yang udah di-set putih di atas — beda sendiri dari kartu-kartu lain
        // yang eksplisit putih. Radius/border dialog sendiri diset per-lokasi
        // (butuh Responsive yang belum ready pas ThemeData ini dibangun).
        dialogTheme: const DialogThemeData(
          backgroundColor: AppColors.white,
          elevation: 0,
        ),
        useMaterial3: true,
      ),
      builder: EasyLoading.init(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.0)),
          child: KioskScaler(child: child!),
        ),
      ),
      home: const IdleScreen(),
    );
  }
}
