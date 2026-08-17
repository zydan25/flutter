# Server-Driven Flutter Runtime Platform — Implementation Status

Branch: `server-driven-runtime-v2`  
PR: `#2`  
Flutter: **3.44.8 stable**  
Dart: **3.12.2**  
STAC: **1.5.0**

## Latest verified CI milestone

**PASS — Runtime CI Run 56**

- `flutter pub get` ✅
- Drift/build_runner generation ✅
- `dart format` ✅
- `flutter analyze` ✅
- `flutter test` ✅
- `flutter build apk --debug` ✅
- APK artifact upload ✅

Android baseline: Kotlin `2.2.20`, AGP `8.11.1`, Gradle `8.14`, Java 17 in CI.

## What is now implemented

### Runtime architecture
✅ Layered runtime/app/core/data/sync/actions/events/auth/permissions/device/settings structure.  
✅ Bootstrap separated from STAC rendering.  
✅ Legacy `api/app-config` kept as migration fallback.

### STAC Runtime
✅ STAC `1.5.0`.  
✅ Complete server-provided screen tree through `screen.stac`.  
✅ Legacy component-to-STAC bridge.  
✅ Dynamic theme foundation.  
✅ STAC-native form/validation reference added at `assets/samples/runtime_form.json`.  
✅ STAC-native navigation/network/dialog/form primitives are intentionally preferred instead of duplicating widgets in custom code.  
⬜ Full manifest-driven navigation controller/drawer/tabs contract.  
⬜ Resource/data binding for complex dynamic views.  
⬜ Custom component registry only where STAC does not cover the requirement.

### API Engine
✅ GET/POST/PUT/PATCH/DELETE.  
✅ Headers/query/path/body.  
✅ Bearer authentication injection.  
✅ Timeout/retry.  
⬜ Formal typed response/error mapping.  
⬜ Upload/download abstraction.  
⬜ Server-defined repositories/data sources.

### Action + Workflow Engine
✅ navigation/API/dialog/snackbar/refresh/logout/open URL/device/workflow.  
✅ Server data interpolation using `${path.to.value}` templates.  
✅ Typed action context merge.  
✅ Workflow branching with `when`, result capture via `save_as`, and `on_error`.  
⬜ Full state mutation/resource refresh contract.  
⬜ Durable transaction/rollback semantics.  
⬜ Notification-originated actions wired to a live navigation context.

### Local Data / Offline
✅ Drift + SQLite runtime store.  
✅ Runtime metadata/resource snapshots/sync queue.  
✅ Local startup without automatic sync when a snapshot exists.  
⬜ Typed application entity repositories.  
⬜ Cache TTL/stale/invalidation policies.  
⬜ Full repository-first UI data access.

### Manual-only Sync
✅ First-install bootstrap only when no local snapshot exists.  
✅ No startup/onResume/timer/background periodic sync.  
✅ Manual `Sync Now`.  
✅ Pending queue persistence.  
✅ Versions/checksums.  
✅ Backend sync contract documented in `docs/runtime-contract.md`.  
⬜ Server acknowledgement handling.  
⬜ Conflict resolution.  
⬜ Partial resource synchronization.  
⬜ Retry/backoff and durable conflict/failure states.

### Realtime / Notifications
✅ WebSocket/event boundary.  
✅ Routing for config/entity/permission/feature/notification/logout events.  
✅ Events kept independent from full synchronization.  
✅ Firebase Messaging integration boundary.  
⬜ Production reconnect/backoff and event acknowledgement.  
⬜ Firebase project/background/cold-start configuration.  
⬜ Complete notification token/permission lifecycle.

### Authentication / Permissions
✅ Secure token storage boundary.  
✅ Access/refresh session model.  
✅ Logout.  
✅ Role/permission/feature-flag service boundaries.  
⬜ Refresh-token execution + 401 interception.  
⬜ Login/re-auth UX.  
⬜ Manifest-driven UI gating for every action/screen.  
⬜ Permission-change event application.

### Device Capability Bridge
✅ camera, gallery, files, share, clipboard, biometric, location, QR, browser/deep-link boundaries.  
⬜ Production permission/error handling audit.  
⬜ Upload/download integration.

### Settings / Diagnostics
✅ Real settings shell with sync status, last sync, pending operations and diagnostics.  
✅ Runtime/manifest/DB/cache/API/WebSocket/auth metadata.  
⬜ Live API/WebSocket health.  
⬜ Functional account/security/appearance/cache-management controls.  
⬜ Detailed error history.

### Versioning / Backend Contract
✅ `schema_version`, runtime/manifest/resource version/checksum concepts.  
✅ Migration-safe legacy endpoint.  
✅ Formal contract examples in `docs/runtime-contract.md`.  
⬜ JSON Schema package and compatibility matrix.  
⬜ Actual Flask `/runtime/*` server implementation.  
⬜ API negotiation + conflict/event-ack protocol implementation.

### Testing / CI
✅ CI generation/format/analyze/test/debug-APK pipeline.  
✅ APK artifact upload.  
✅ Manifest validation tests.  
✅ Action-template tests.  
⬜ API/repository/Drift/sync/conflict tests.  
⬜ STAC malformed-screen/widget tests.  
⬜ auth/WebSocket/notification integration tests.  
⬜ full integration suite.

### Release / Security
✅ Secure-storage/HTTPS/server-authority foundations.  
✅ Android toolchain compatible with current dependency set.  
⬜ release signing/AAB automation.  
⬜ payload/logging hardening audit.  
⬜ auth token rotation/security review.

## New implementation artifacts

- `lib/runtime/runtime_contract.dart` — version/schema/resource validation.
- `lib/actions/action_template.dart` — server-data interpolation.
- `assets/samples/runtime_form.json` — native STAC server-driven form reference.
- `docs/runtime-contract.md` — bootstrap/manifest/resources/sync/events contract.

## Next execution order

1. Complete dynamic form field mapping, remote options and conditional visibility around STAC native forms.
2. Build repository/data-source layer so dynamic screens can operate from SQLite offline first.
3. Implement full manual sync acknowledgement/conflict/partial-resource protocol.
4. Harden WebSocket reconnect + event acknowledgement + notification action routing.
5. Complete authentication refresh/401 and permission gating.
6. Add comprehensive unit/widget/integration coverage.
7. Implement signed release APK/AAB and versioned release automation.
8. Add Flask `/runtime/*` implementation and migrate the existing endpoint progressively.

## Quality gate

A milestone is not marked complete until implementation, tests, `flutter analyze`, `flutter test`, and Android debug build remain green.
