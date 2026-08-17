# Flutter Server-Driven Runtime — Master Task Board

Branch: `server-driven-runtime-v2`
PR: #2
Current review head: `3009f0a299553a26d4fa9db61e1782e1684cd66f`

Legend: ✅ complete and previously verified | 🟡 implemented foundation / awaiting CI or backend integration | ⬜ not complete

## CI status and recent failures

- Runs 135–141: older long-running build jobs reported as still progressing in the Android build stage; they are historical revisions and do not represent the current HEAD.
- Run 147: failed at `flutter analyze` after the typed API/Action work.
- Run 148: failed at `flutter analyze` for one concrete error: `ServerDrivenApp` referenced `RuntimeEvent.data`, but `RuntimeEvent` exposes `payload`.
- Fix committed in current HEAD: `event.payload['permissions']` is now used.
- Current HEAD still requires a fresh CI run; do not mark this fix verified until Analyze → Test → APK → AAB pass on the same revision.

## 1. Foundation
- ✅ Layered runtime architecture
- ✅ Flutter 3.44.8 stable / Dart 3.12.2 baseline
- ✅ STAC 1.5.0
- ✅ Android Kotlin 2.2.20 / AGP 8.11.1 / Gradle 8.14
- ✅ CI pipeline with Drift generation, formatting, analyze, test, debug APK and AAB stages
- ✅ Legacy `/api/app-config` compatibility path retained
- 🟡 CI hardened and current expanded stack awaiting a clean green run

## 2. STAC UI Runtime
- ✅ Full-screen `screen.stac` contract
- ✅ Legacy component → STAC compatibility bridge
- ✅ Dynamic theme foundation
- ✅ STAC-native form/sample contract
- 🟡 Dynamic form controller: state, visibility, required/regex/range validation, submission mapping
- 🟡 Remote dropdown/autocomplete provider contract
- 🟡 Manifest-driven navigation shell: drawer/bottom/tabs/deep-link foundations
- 🟡 Resource binding: recursive interpolation and `for_each/item_template`
- 🟡 Resource binding integrated into actual STAC screen rendering
- ⬜ Remote options rendered consistently across every supported STAC input widget
- ⬜ Typed list/card/grid data widgets with resource-level refresh policies
- ⬜ STAC custom component registry for unsupported server components

## 3. API Engine
- ✅ GET/POST/PUT/PATCH/DELETE
- ✅ headers/query/path/body mapping
- ✅ bearer token injection
- ✅ timeout/retry
- 🟡 `ApiResult<T>` / typed success mapping
- 🟡 typed `ApiError` / `ApiException`
- 🟡 401 recovery hook
- 🟡 concrete refresh-session service and refresh endpoint contract
- ✅ upload/download service abstraction
- 🟡 upload/download Action Engine wiring
- ⬜ server-defined repositories/data sources with typed entity models

## 4. Action Engine / Workflows
- ✅ navigation/API/dialog/snackbar/sync/logout/open URL/device/workflow
- ✅ template interpolation
- ✅ workflow conditions / save_as / error handling
- ✅ action permission enforcement
- 🟡 durable local `set_state` mutation
- 🟡 transactional local action/workflow rollback foundation
- 🟡 upload/download actions
- 🟡 notification-originated action routing foundation
- ⬜ full compensation/rollback semantics for mixed remote + local workflows
- ⬜ deterministic workflow idempotency keys / duplicate submission protection

## 5. Local Data / Offline First
- ✅ Drift + SQLite runtime store
- ✅ resource metadata/version/checksum
- ✅ persisted sync queue
- ✅ offline-first ResourceRepository foundation
- 🟡 typed `RuntimeRepository<T>` foundation
- 🟡 cache freshness model and TTL foundation
- ⬜ complete stale-while-revalidate and invalidation implementation
- ⬜ typed application entity repositories for real business entities
- 🟡 repository-first dynamic screen integration

## 6. Manual Sync / Conflicts
- ✅ first-install-only bootstrap rule
- ✅ no startup/onResume/timer/background sync once a snapshot exists
- ✅ Settings → Sync Now
- ✅ persisted queue
- ✅ versions/checksums
- ✅ explicit conflict policy model
- ✅ sync outcomes: acknowledged/conflict/rejected/retry/pending
- ✅ per-operation response parsing
- ✅ partial-success queue state handling
- 🟡 conflict persistence and resolution UI
- ✅ durable retry/backoff primitives
- 🟡 production-grade retry/error history and diagnostics
- 🟡 partial resource payload save/refresh foundation

## 7. Realtime / Notifications
- ✅ WebSocket/event boundary
- ✅ event categories / routing boundary
- ✅ realtime path independent from full sync
- 🟡 exponential reconnect
- 🟡 event ACK client API
- 🟡 Firebase Messaging integration boundary
- 🟡 token/permission lifecycle
- 🟡 cold-start/opened notification routing
- 🟡 notification Action/Workflow bridge
- ⬜ end-to-end realtime integration tests
- ⬜ production WebSocket lifecycle/foreground-background policy

## 8. Authentication / Permissions
- ✅ secure token storage boundary
- ✅ access/refresh session model
- ✅ logout
- ✅ roles/permissions/feature flags model
- 🟡 401 interception hook
- 🟡 refresh session implementation
- 🟡 concrete refresh endpoint execution
- ⬜ production login/re-auth UX
- 🟡 route/action permission guards
- 🟡 manifest-wide permission filtering
- 🟡 live permission-change application from realtime events
- ⬜ token rotation/replay protection review

## 9. Device Capabilities
- ✅ camera/gallery/files/share/clipboard/biometric/location/QR/browser/deep-link capability boundaries
- ✅ transfer service foundation
- ⬜ production permission/error audit per capability
- 🟡 upload/download integration with real server actions

## 10. Settings / Diagnostics
- ✅ Settings shell
- ✅ last sync / pending count / conflict count
- ✅ Diagnostics shell
- 🟡 live API/WebSocket health probes
- 🟡 functional account/security/appearance/storage controls
- 🟡 detailed error history
- ⬜ user-facing runtime self-test / exportable diagnostics bundle

## 11. Versioning / Backend Contract
- ✅ schema_version
- ✅ runtime/manifest/resource versions
- ✅ checksum concepts
- ✅ legacy `/api/app-config` compatibility
- ✅ `/runtime/*` documented contract
- ✅ machine-readable manifest schema
- ⬜ compatibility matrix and migration policy enforcement
- ⬜ real Flask `/runtime/bootstrap`
- ⬜ real Flask `/runtime/manifest`
- ⬜ real Flask `/runtime/resources`
- ⬜ real Flask `/runtime/sync`
- ⬜ real Flask `/runtime/events/ack`
- ⬜ real WebSocket `/runtime/events`

## 12. Testing
- ✅ action template tests
- ✅ dynamic form validation/controller tests
- ✅ resource binding tests
- ✅ navigation/deep-link tests
- ✅ permission tests
- ✅ conflict policy tests
- ✅ retry policy tests
- ✅ Drift/resource persistence tests from earlier green baseline
- ⬜ current expanded stack must pass one clean Analyze/Test/APK/AAB revision
- ⬜ sync acknowledgement/partial-success integration tests
- ⬜ malformed STAC/unsupported widget tests
- ⬜ auth/401 refresh integration tests
- ⬜ WebSocket reconnect/ACK integration tests
- ⬜ notification lifecycle tests
- ⬜ full device-capability integration tests
- ⬜ end-to-end runtime bootstrap test

## 13. Release / Security
- ✅ secure storage foundation
- ✅ HTTPS/server-side authority foundation
- ✅ modern Android toolchain
- 🟡 debug APK/AAB automation
- ⬜ release signing configuration
- ⬜ production AAB automation
- ⬜ payload-size limits and log-sanitization audit
- ⬜ authentication/token security review
- ⬜ release-channel/version compatibility checks

## Flutter-only completion target

Before calling Flutter Runtime “production-ready”, the remaining client-side work is:
1. Make the current expanded CI revision green.
2. Finish typed repositories/cache invalidation and repository-first STAC list/card/grid bindings.
3. Finish remote form options and complete Form → Action → API → local update flows.
4. Finish auth refresh/login UX and manifest-wide/live permission enforcement.
5. Finish notification lifecycle and realtime integration tests.
6. Finish conflict/error-history UX and health diagnostics.
7. Finish malformed-STAC, auth, sync, WebSocket and notification integration suites.
8. Finish release signing and production AAB automation.

## Backend boundary

The Flask `/runtime/*` and WebSocket server are intentionally tracked separately. They are not considered Flutter-complete until implemented in the backend repository and validated end-to-end.

## Quality gate

A task is ✅ only after the implementation exists and the relevant CI revision passes `flutter analyze`, `flutter test`, and Android debug builds (APK/AAB). Backend-dependent tasks remain 🟡 until real end-to-end integration exists.
