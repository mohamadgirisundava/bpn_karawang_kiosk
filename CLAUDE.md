# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A Flutter kiosk app for taking queue tickets ("BPN Karawang" — ambil nomor antrian). It talks to Cloud Firestore (Firebase project `bpn-karawang-antrian`) via the `cloud_firestore` SDK; there is no local database or offline storage. The app never logs in — Firestore rules deliberately allow the paths it needs (taking a ticket, queueing a print job, Reset Antrian) without auth, validating the shape of what's written instead of who wrote it.

Three other apps share the same Firebase project: `bpn_karawang_loket` (admin/petugas, the only one with login), `bpn_karawang_display` (TV call screen), and `bpn_karawang_print_relay` (Windows helper that drives the thermal printer).

**Full backend schema lives in `bpn_karawang_loket/COLLECTIONS.md`** — that's the authoritative source for all 11 collections, their fields, and the reasoning behind the rules. This file no longer duplicates it.

`bpn_karawang_ticket_server` is the retired PocketBase backend. It is not used by any app and its `COLLECTIONS.md` describes a schema that no longer exists — ignore it.

## Commands

```bash
flutter pub get              # install dependencies
flutter run -d macos         # run on macOS (also: -d chrome, -d windows, -d linux)
flutter analyze              # lint (flutter_lints, default rules, see analysis_options.yaml)
flutter test                 # run tests
flutter test test/widget_test.dart   # run a single test file
```

The project targets android/ios/linux/macos/web/windows (all platform folders present), but as a kiosk app it's realistically run on whichever platform the physical kiosk hardware uses.

## Architecture

Clean Architecture, three layers under `lib/`:

- **`domain/`** — pure business logic: `entities/`, `repositories/` (abstract interfaces), `usecases/` (one class per action, e.g. `CreateQueue`, `GetActiveCounters`).
- **`data/`** — implementation: `models/` (Firestore document ↔ entity mapping via `fromFirestore`), `datasources/` (`*_remote_datasource.dart`, direct `cloud_firestore` calls), `repositories/` (implements the domain interfaces using the datasources).
- **`presentation/`** — `cubits/` (flutter_bloc state management, one cubit+state pair per feature) and `screens/`/`widgets/` (UI).

Data flow: `screen` → `cubit` → `usecase` → `repository` (interface) → `repository_impl` → `remote_datasource` → `cloud_firestore`.

**Dependency injection is manual**, not a package like `get_it`: `lib/injection.dart` is a singleton (`Injection.instance`) that wires datasource → repository → usecase → cubit-factory by hand. New features should follow the same wiring pattern there rather than introducing a DI package.

**Firebase connection**: initialized in `lib/main.dart` via `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` — config comes from `firebase_options.dart`, so there is no hardcoded host to switch between dev and prod.

Realtime updates (e.g. live queue status) go through `lib/core/services/realtime_service.dart`, which uses Firestore `snapshots()` streams rather than polling.

**Taking a ticket is a transaction.** `QueueRemoteDatasource.createQueue` increments `queue_counters/{counterId}_{date}.lastNumber` and writes the `queues` doc inside one `runTransaction`, so simultaneous presses can't produce duplicate numbers. Printing is deliberately decoupled: a `print_jobs` doc is only created when the user presses "Cetak Tiket Antrian", not when the number is taken.

## Backend schema

See **`bpn_karawang_loket/COLLECTIONS.md`** — the single authoritative description of all 11 Firestore collections. Don't re-embed a copy here; the last snapshot in this file went stale through the Firebase migration and actively misled.

Collections this app touches: `counters`, `queues`, `queue_counters`, `print_jobs`, `calls`, `settings`, `announcements`, `voice_announcements`, `audio_schedules`, `prayer_schedule`.

Two traps worth knowing before you write a query here:

- **`date` and `dateKey` hold the same `"YYYY-MM-DD"` string.** Every query filters on `dateKey`; `date` is a PocketBase leftover that's still written. New docs must set both — the rules require it.
- **`audio_schedules` uses camelCase** (`audioUrl`, `isActive`, `repeatType`, `lastPlayedAt`), unlike every other collection.

## Security rules

`firestore.rules` in this repo is the maintained copy, mirrored in `bpn_karawang_loket`. Both deploy to the same project, so **whichever is deployed last wins — edit both together.** A collection with no `match` block is denied by default, which is how the stale copy in the loket repo silently disabled printing, scheduled audio, and voice announcements until they were resynced on 2026-07-31.
