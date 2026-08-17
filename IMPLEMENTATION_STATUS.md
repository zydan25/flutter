# Server-Driven Flutter Runtime Platform — Implementation Status

Branch: `server-driven-runtime-v2`
PR: `#2`
Flutter baseline: **3.44.8 stable**
Dart baseline: **3.12.2**
STAC: **1.5.0**

> This document tracks the implementation against the agreed Server-Driven Runtime Platform plan. It deliberately distinguishes between implemented foundations and production-ready completion.

## Current CI state

The latest completed CI run reached:

- `flutter pub get` — PASS
- Drift/build_runner generation — PASS
- `dart format` — PASS
- `flutter analyze` — PASS (`No issues found!`)
- `flutter test` — PASS (2 tests)
- `flutter build apk --debug` — FAILED at Android Kotlin compilation

### Latest Android build failure

The failure was caused by an outdated Android toolchain in the project:

- Kotlin project plugin: `1.9.24` → plugins were compiled with Kotlin metadata `2.2.0`
- AGP: `8.9.1` → Flutter warned that `8.11.1` is the required near-term baseline
- Gradle wrapper: `8.11.1` → Flutter warned to move to `8.14.0`

The project has now been upgraded on this branch to:

- Kotlin Gradle Plugin: `2.2.20`
- Android Gradle Plugin: `8.11.1`
- Gradle wrapper: `8.14`

A new CI run is required to verify the APK build after these changes.

## Plan status

### 1. Flutter Runtime architecture — DONE (foundation)

- Layered structure under `lib/app`, `lib/core`, `lib/runtime`, `lib/data`, `lib/sync`, `lib/actions`, `lib/events`, `lib/auth`, `lib/permissions`, `lib/device`, `lib/notifications`, `lib/settings`.
- `main.dart` is no longer the only application implementation file.
- Bootstrap/runtime orchestration is separated from rendering.

### 2. STAC Server-Driven UI — PARTIALLY DONE

Implemented:

- STAC 1.5.0 integration.
- Full-screen contract via `screen.stac`.
- Direct server-provided STAC tree support.
- Legacy component schema remains supported as a migration bridge.
- Runtime STAC action parser boundary.
- Theme extraction foundation.

Still needed:

- Complete server-driven navigation contract.
- Dynamic forms and validation driven entirely by server schema.
- Dynamic dialogs and reusable component registry beyond the current core STAC contract.
- Server-driven data binding/resource mapping for complex UI trees.

### 3. API Engine — FOUNDATION DONE

Implemented:

- Dio client.
- GET/POST/PUT/PATCH/DELETE through a generic request method.
- headers.
- query parameters.
- path parameter substitution.
- bearer authentication injection.
- timeout.
- retry policy.

Still needed:

- Formal response mapping/error mapping layer.
- Upload/download abstractions.
- Typed resource repositories and server-defined data sources.

### 4. Action Engine — FOUNDATION DONE

Implemented boundaries for:

- navigation
- API actions
- refresh
- logout
- open URL
- workflow

Still needed:

- Complete action catalog and parameter templating.
- Device capability action integration across all actions.
- Notification-driven actions.
- Server-defined state mutation actions.

### 5. Workflow Engine — FOUNDATION DONE

- Workflow/action boundaries exist.
- Sequential execution model is established.

Still needed:

- Robust conditional steps.
- validation step contracts.
- local transaction steps.
- retry/rollback/error branches.

### 6. Local Data / Drift + SQLite — DONE (runtime store foundation)

- Drift/SQLite dependency and store added.
- Runtime metadata.
- resource snapshots.
- sync queue.
- version/checksum metadata.

Still needed:

- Typed domain tables/entities for application data.
- database migrations with explicit schema versioning.
- repository abstractions over all persistent data.

### 7. Offline First — PARTIALLY DONE

Implemented:

- Local runtime snapshot.
- Local startup path.
- Legacy bootstrap fallback.
- SQLite persistence foundation.

Still needed:

- Full UI data access through repositories/local DB instead of network-bound screens.
- stale-cache policies.
- resource-specific offline behavior.

### 8. Manual-only Sync Engine — FOUNDATION DONE

Implemented rules:

- initial bootstrap when no local snapshot exists.
- no startup sync when local data exists.
- no timer/onResume periodic sync.
- manual `Sync Now` entry point.
- SQLite sync queue.
- resource version/checksum metadata.

Still needed:

- complete sync protocol with server acknowledgements.
- conflict detection/resolution.
- partial resource synchronization.
- retry/backoff for queued operations.

### 9. Realtime WebSocket/Event Engine — FOUNDATION DONE

Implemented:

- WebSocket/event engine boundary.
- event routing.
- event types for configuration/entity/permission/feature/notification/logout scenarios.
- event processing is separate from full synchronization.

Still needed:

- reconnect/backoff strategy hardened for production.
- event acknowledgement endpoint.
- persistent event handling where required.
- precise per-resource event handlers.

### 10. Push Notifications — FOUNDATION ONLY

Implemented:

- Firebase Messaging integration boundary.
- notification-to-action routing boundary.

Still needed:

- Firebase Android/iOS project configuration.
- background message handling.
- robust cold-start/deep-link routing.
- production notification permission/token lifecycle.

### 11. Authentication — PARTIALLY DONE

Implemented:

- secure storage boundary.
- access/refresh token model boundary.
- session management foundation.
- logout.

Still needed:

- full refresh-token flow.
- 401 interception and token refresh.
- login UI and server contract.
- session expiry/re-auth UX.

### 12. Permissions — FOUNDATION DONE

Implemented:

- permissions/roles service boundary.
- feature flag boundary.
- backend remains the source of authority conceptually.

Still needed:

- server manifest permission declarations integrated into every screen/action.
- UI gating helpers.
- permission change event behavior.

### 13. Dynamic Forms — NOT COMPLETE

Needed:

- text/number/email/phone/password/date/datetime/dropdown/radio/checkbox/switch/file/image/autocomplete/textarea.
- required/min/max/regex.
- conditional visibility/dependencies.
- remote options.
- form state binding and submit mapping.

### 14. Device Capability Bridge — FOUNDATION DONE

Implemented boundaries for:

- camera
- gallery
- files
- share
- clipboard
- biometric
- location
- QR
- deep links/browser

Still needed:

- production permission/error handling per capability.
- upload/download capability integration with API Engine.
- platform-specific configuration validation.

### 15. Cache — FOUNDATION DONE

Implemented:

- local runtime/resource persistence.
- manifest/resource checksum/version metadata.

Still needed:

- explicit memory cache layer.
- TTL/stale policies.
- cache invalidation strategy.
- resource-level cache policy definitions.

### 16. Settings UI — FOUNDATION DONE

Implemented:

- account/security/notifications/appearance/storage sections.
- last sync.
- pending operations.
- manual Sync Now.
- diagnostics entry.

Still needed:

- real account/security screens.
- appearance controls.
- cache/storage management actions.
- notification settings.

### 17. Diagnostics — FOUNDATION DONE

Implemented:

- runtime version.
- schema/manifest metadata.
- DB version field.
- last sync.
- pending operations.
- cache state.
- API base URL.
- WebSocket mode.
- auth storage state.

Still needed:

- live API reachability.
- live WebSocket status.
- package/app binary version.
- detailed sync/error diagnostics.

### 18. Versioning / Compatibility — PARTIALLY DONE

Implemented:

- runtime/schema version fields.
- manifest/resource version/checksum concepts.
- migration-compatible legacy API fallback.

Still needed:

- formal schema compatibility matrix.
- DB migration/version mechanism.
- API version negotiation.
- resource compatibility policies.

### 19. Backend Contract — FOUNDATION DEFINED

Defined contract shape:

```text
GET  /runtime/bootstrap
GET  /runtime/manifest
GET  /runtime/resources
POST /runtime/sync
POST /runtime/events/ack
WS   /runtime/events
```

Legacy endpoint preserved:

```text
GET https://flutter.alattab.site/api/app-config
```

Still needed:

- actual backend implementation for the new `/runtime/*` contract.
- formal JSON schemas.
- sync request/response examples.
- event acknowledgement contract.
- migration rollout.

### 20. Testing — FOUNDATION DONE

Current CI tests pass.

Still needed for the agreed plan:

- unit tests for API/repository/sync/action/workflow layers.
- Drift database tests.
- malformed STAC/manifest tests.
- offline startup tests.
- manual-only sync behavior tests.
- conflict tests.
- auth expiry tests.
- WebSocket event routing tests.
- integration tests.
- widget tests for server-driven screens.

### 21. CI/CD — FOUNDATION DONE

CI currently performs:

- Flutter setup.
- dependency install.
- Drift generation.
- formatting.
- analyze.
- tests.
- Android debug APK build.
- APK artifact upload when build succeeds.

Still needed:

- release signing pipeline.
- AAB/release build.
- release artifacts/versioning.
- optional Flutter Web pipeline.

### 22. Security — FOUNDATION DONE

Implemented foundations:

- secure token storage boundary.
- HTTPS endpoint.
- no secrets embedded in runtime config.
- server authority for permissions.

Still needed:

- hardened logging/sanitization audit.
- request/payload limits.
- production auth refresh/rotation.
- platform-specific security review.

## Immediate next milestone

1. Verify Android build after Kotlin/AGP/Gradle upgrade.
2. Fix any remaining Android/Gradle issues.
3. Produce a successful debug APK artifact.
4. Add stronger runtime/UI tests.
5. Implement the actual `/runtime/*` backend contract while retaining the legacy endpoint.
6. Complete dynamic forms/actions/workflows and manual sync conflict handling.
