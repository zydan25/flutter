# Server-Driven Flutter Runtime Platform — Implementation Status

Branch: `server-driven-runtime-v2`  
PR: `#2`  
Flutter: **3.44.8 stable**  
Dart: **3.12.2**  
STAC: **1.5.0**

## Latest verified CI milestone

**PASS — Runtime CI Run 70**

- `flutter pub get` ✅
- Drift/build_runner generation ✅
- `dart format` ✅
- `flutter analyze` ✅
- `flutter test` ✅
- `flutter build apk --debug` ✅
- APK artifact upload ✅

Android baseline: Kotlin `2.2.20`, AGP `8.11.1`, Gradle `8.14`, Java 17 in CI.

> Note: Run 70 predates the latest task-board/conflict-test commits; those changes are queued for the next CI verification and are not marked green yet.

## Current implementation status

### Runtime architecture
✅ Layered runtime architecture and bootstrap/rendering separation.  
✅ Legacy `/api/app-config` migration fallback.

### STAC Runtime
✅ STAC 1.5.0.  
✅ Full server-supplied screen tree via `screen.stac`.  
✅ Legacy component-to-STAC bridge.  
✅ Dynamic theme foundation.  
✅ STAC-native form/validation reference.  
✅ Dynamic form schema/validation runtime (`lib/runtime/form_runtime.dart`).  
🟡 Dynamic form runtime tests and richer state/options are in progress.  
⬜ Full manifest-driven navigation controller/drawer/tabs.  
⬜ Complex resource/data binding in STAC trees.  
⬜ Custom component registry for STAC gaps.

### API / Actions / Workflows
✅ Full HTTP method/parameter/auth/retry foundation.  
✅ Action engine and server-data interpolation.  
✅ Conditional workflow steps, result capture and error branches.  
⬜ Typed response/error mapping.  
⬜ Upload/download abstraction.  
⬜ Durable state mutation/transaction semantics.

### Local / Offline
✅ Drift + SQLite runtime store.  
✅ Resource snapshots and sync queue.  
✅ Offline-first `ResourceRepository` foundation.  
⬜ Complete repository-first data-source binding.  
⬜ Cache TTL/stale/invalidation policy.

### Sync / Realtime / Auth
✅ First-install-only bootstrap and manual-only Sync Now.  
✅ Version/checksum metadata.  
✅ WebSocket/event boundary independent of full sync.  
✅ Secure auth/session foundation and permission boundary.  
🟡 Explicit conflict resolution policy model added (`lib/sync/conflict_resolver.dart`).  
⬜ Server acknowledgement/conflict/partial-resource protocol.  
⬜ WebSocket reconnect/ack lifecycle.  
⬜ Token refresh/401 interception and complete permission gating.

### Forms
✅ Schema parsing.  
✅ Required validation.  
✅ Regex validation.  
✅ Numeric min/max validation.  
✅ Conditional visibility.  
⬜ Remote options.  
⬜ Field-state binding.  
⬜ Submit/payload mapping.

### Testing / Release
✅ Green baseline CI: analyze + test + debug APK.  
🟡 Conflict resolver unit coverage added in `test/conflict_resolver_test.dart`; awaiting next green CI.  
⬜ Repository/Drift/sync acknowledgement tests.  
⬜ STAC malformed-screen/widget/integration tests.  
⬜ Auth/WebSocket/notification integration tests.  
⬜ Signed APK/AAB release pipeline.

### Backend
✅ Formal client contract and legacy endpoint compatibility.  
⬜ Actual Flask `/runtime/bootstrap`, `/manifest`, `/resources`, `/sync`, `/events/ack`, WebSocket rollout.

## Master task board

See `SERVER_DRIVEN_TASKS.md` for the complete machine-readable-by-humans checklist of completed, partial and remaining work.

## Next execution order

1. Bind manifest resources to `ResourceRepository` for offline-first dynamic screens.
2. Finish dynamic forms: remote options, state binding and submit mapping.
3. Implement sync acknowledgement, conflict resolution and partial resources.
4. Harden WebSocket reconnect/ACK and notification action routing.
5. Complete auth refresh/401 and permission gating.
6. Expand tests and release automation.
7. Migrate Flask backend progressively from `/api/app-config` to `/runtime/*`.

## Quality gate

No item is marked complete solely because code exists; the milestone must keep `flutter analyze`, `flutter test`, and Android debug build green.
