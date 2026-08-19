# Server-Driven Flutter Runtime — Implementation Status

Branch: `server-driven-runtime-v2`
PR: `#2`
Flutter: **3.44.8 stable**
Dart: **3.12.2**
STAC: **1.5.0**

## Current quality gate

The branch was deliberately reset to the last verified Android build baseline (`03788247`) before introducing API-profile routing changes. The new API contract is documented in `docs/API.md` and the only subsequent runtime-code change is the control-plane endpoint alignment in `lib/core/runtime_config.dart`.

A fresh CI run on the current head is required before the branch is declared green. No Backend deployment is allowed before this gate passes.

## Verified baseline

The known-good milestone contains:

- `flutter pub get` ✅
- Drift/build_runner generation ✅
- `dart format` ✅
- `flutter analyze` ✅
- `flutter test` ✅
- `flutter build apk --debug` ✅
- `flutter build appbundle --debug` ✅
- `flutter build appbundle --release` ✅

## Runtime capabilities already implemented

### STAC / UI

- ✅ STAC 1.5.0 runtime
- ✅ Full server-supplied `screen.stac` trees
- ✅ Legacy component → STAC compatibility bridge
- ✅ Dynamic theme foundation
- ✅ Resource binding/interpolation
- ✅ Manifest/navigation foundation
- ✅ Dynamic form schema/validation foundation
- ✅ Remote-option and form-controller foundations
- ✅ Custom runtime component registry

### Actions / Workflows

- ✅ Navigation
- ✅ HTTP/network actions
- ✅ Dialog/snackbar
- ✅ Sync/refresh
- ✅ Logout
- ✅ Open URL
- ✅ Device capabilities
- ✅ Upload/download boundary
- ✅ Local state transaction/rollback foundation
- ✅ Workflow conditions/result capture/error branch
- ✅ Permission gating

### API / Data

- ✅ Dio API engine
- ✅ GET/POST/PUT/PATCH/DELETE
- ✅ query/path/header/body mapping
- ✅ Bearer token support
- ✅ retry and timeout
- ✅ typed API error/result models
- ✅ Drift + SQLite local store
- ✅ Resource snapshots/version/checksum
- ✅ typed runtime repository foundation
- ✅ cache policy/coordinator

### Offline / Sync

- ✅ first-install-only bootstrap rule
- ✅ no startup/resume/timer/background periodic sync
- ✅ manual Sync Now
- ✅ local sync queue
- ✅ retry/backoff
- ✅ conflict persistence/resolution model
- ✅ partial sync protocol foundation

### Realtime / Auth / Notifications

- ✅ WebSocket event boundary independent of full sync
- ✅ event categories and ACK contract foundation
- ✅ secure access/refresh token storage
- ✅ 401 refresh service foundation
- ✅ permission/feature-flag boundary
- ✅ Firebase notification boundary/action router
- ✅ device capability bridge

### Diagnostics / Release

- ✅ settings/diagnostics screens
- ✅ runtime self-test foundation
- ✅ cache/DB diagnostics foundation
- ✅ Android debug APK pipeline
- ✅ debug AAB pipeline
- ✅ release AAB pipeline
- ✅ release signing path/documentation

## Remaining Flutter-only integration work

These items are implementation/integration hardening rather than a new architecture:

- 🟡 fresh CI on the current API-contract head
- 🟡 end-to-end API Profile routing tests
- 🟡 end-to-end refresh/401 tests against a live Runtime API
- 🟡 WebSocket reconnect/ACK integration tests
- 🟡 push notification cold-start integration test
- 🟡 malformed STAC/render fallback integration tests
- 🟡 full offline → manual Sync Now → conflict integration test
- 🟡 signed production artifact using real deployment secrets

## Outside Flutter

The following belong to the Flask control plane and must not require APK rebuilds for ordinary application changes:

- screens and STAC definitions
- API profiles and business API endpoints
- actions and workflows
- data models/records
- runtime releases
- permissions/roles/feature flags
- server-side sync/conflict handling
- WebSocket event generation/ACK persistence
- admin/control-plane UI

## Authoritative API contract

See `docs/API.md`. The backend must implement that contract exactly before the new Flask runtime is deployed behind `flutter.alattab.site`.
