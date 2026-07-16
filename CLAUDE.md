# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A Flutter kiosk app for taking queue tickets ("BPN Karawang" — ambil nomor antrian). It talks to a PocketBase backend over the `pocketbase` Dart SDK; there is no local database or offline storage.

The backend lives in a separate repo (`bpn_karawang_ticket_server`, PocketBase), not necessarily present on disk alongside this one. This file embeds a snapshot of the schema this app actually consumes so it's self-contained — if the backend repo *is* checked out as a sibling directory, its `COLLECTIONS.md` is the fuller, authoritative source (full field list, API rules, other collections like `calls`/`users`) and should win on any conflict.

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
- **`data/`** — implementation: `models/` (PocketBase record ↔ entity mapping), `datasources/` (`*_remote_datasource.dart`, direct PocketBase SDK calls), `repositories/` (implements the domain interfaces using the datasources).
- **`presentation/`** — `cubits/` (flutter_bloc state management, one cubit+state pair per feature) and `screens/`/`widgets/` (UI).

Data flow: `screen` → `cubit` → `usecase` → `repository` (interface) → `repository_impl` → `remote_datasource` → PocketBase SDK.

**Dependency injection is manual**, not a package like `get_it`: `lib/injection.dart` is a singleton (`Injection.instance`) that wires datasource → repository → usecase → cubit-factory by hand. New features should follow the same wiring pattern there rather than introducing a DI package.

**PocketBase connection**: `lib/core/services/pocketbase_service.dart` is a singleton holding the `PocketBase` client. The base URL is currently hardcoded (`10.10.10.89:8090`, a LAN IP for the kiosk hardware, not localhost) — when developing against a local `pocketbase serve` instance, this needs to point at `127.0.0.1:8090` instead.

Realtime updates (e.g. live queue status) go through `lib/core/services/realtime_service.dart`, which subscribes via the PocketBase SDK's realtime API rather than polling.

## Backend schema (collections used by this app)

Snapshot as of 2026-07-16. The backend also has `calls` and `users` collections, not consumed here (likely used by a separate admin/display app).

### `counters` (base)
| Field | Type | Required |
|---|---|---|
| `code` | text | yes |
| `name` | text | yes |
| `description` | text | no |
| `color` | text | no |
| `is_priority` | bool | no |
| `is_active` | bool | no |
| `sort_order` | number | no |

### `queues` (base)
| Field | Type | Required |
|---|---|---|
| `counter` | relation → `counters` | yes |
| `queue_number` | number | yes |
| `queue_code` | text | yes |
| `status` | select: `waiting`\|`called`\|`serving`\|`completed`\|`skipped` | yes |
| `date` | date | yes |
| `taken_at` | date | yes |
| `called_at` | date | no |
| `completed_at` | date | no |
| `desk_number` | number | no |
| `called_by` | relation → `users` | no |

Create rule is public (no auth) — this app can create queue records without logging in. Update/delete require auth, which this app doesn't do — those are handled by the admin/display side.

### `settings` (base)
| Field | Type | Required |
|---|---|---|
| `key` | text | yes (unique) |
| `value` | text | yes |
| `description` | text | no |

All three collections have PocketBase's standard `id`, `created`, `updated` fields.
