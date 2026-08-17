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

Android compatibility baseline now uses:

- Kotlin Gradle Plugin `2.2.20`
- Android Gradle Plugin `8.11.1`
- Gradle `8.14`
- Java 17 in CI

## Implementation status

### 1. Runtime architecture — FOUNDATION COMPLETE
✅ Layered runtime/data/action/sync/event/auth/device/settings structure.  
✅ Bootstrap separated from rendering.  
⬜ Dependency injection/runtime registry hardening.

### 2. STAC Server-Driven UI — PARTIAL
✅ STAC `1.5.0`.  
✅ Entire screen can be supplied as `screen.stac`.  
✅ Legacy component schema migration bridge.  
✅ Dynamic theme foundation.  
⬜ Dynamic navigation contract.  
⬜ Server-driven forms/validation.  
⬜ Resource/data binding for complex STAC trees.  
⬜ Reusable custom component registry where STAC needs extensions.

### 3. API Engine — FOUNDATION COMPLETE
✅ GET/POST/PUT/PATCH/DELETE.  
✅ Headers/query/path/body.  
✅ Bearer authentication injection.  
✅ Timeout/retry.  
⬜ Formal response/error mapping.  
⬜ Upload/download abstraction.  
⬜ Server-defined data sources/repositories.

### 4. Action Engine — FOUNDATION COMPLETE
✅ navigation/API/dialog/snackbar/refresh/logout/open URL/device/workflow boundaries.  
⬜ Complete parameter interpolation and typed action context.  
⬜ Server-defined state mutations.  
⬜ Notification action integration.

### 5. Workflow Engine — FOUNDATION COMPLETE
✅ Sequential workflow steps.  
⬜ Conditions/branches.  
⬜ Validation steps.  
⬜ Local transaction steps.  
⬜ Retry/rollback/error branches.

### 6. Drift + SQLite — RUNTIME STORE COMPLETE
✅ Runtime metadata/resource snapshots/sync queue.  
⬜ Typed domain repository layer.  
⬜ Explicit migration strategy/versioning.

### 7. Offline First — PARTIAL
✅ Local runtime snapshot.  
✅ Offline startup path.  
✅ Legacy endpoint fallback.  
⬜ Repository-first UI data access.  
⬜ Resource stale policies.

### 8. Manual-only Sync — FOUNDATION COMPLETE
✅ Initial sync only when no local snapshot exists.  
✅ No startup/onResume/timer/background periodic sync.  
✅ Manual Sync Now.  
✅ Queue persistence.  
✅ Version/checksum fields.  
⬜ Server acknowledgement contract.  
⬜ Conflict resolution.  
⬜ Partial resource sync.  
⬜ Retry/backoff and durable failure states.

### 9. WebSocket/Event Engine — FOUNDATION COMPLETE
✅ WebSocket boundary/event routing.  
✅ Event types for config/entity/permission/feature/notification/logout.  
✅ Events are independent from full sync.  
⬜ Production reconnect/backoff.  
⬜ Event acknowledgement endpoint.  
⬜ Durable event handling/resource handlers.

### 10. Push Notifications — FOUNDATION
✅ Firebase Messaging integration boundary.  
✅ Notification-to-action routing boundary.  
⬜ Firebase project configuration.  
⬜ Background/cold-start handling.  
⬜ Production token/permission lifecycle.

### 11. Authentication — PARTIAL
✅ Secure storage boundary.  
✅ Session/access/refresh token model.  
✅ Logout.  
⬜ Refresh-token execution.  
⬜ 401 interception.  
⬜ Login UI/server contract.  
⬜ Session expiry/re-auth UX.

### 12. Permissions — FOUNDATION
✅ Role/permission service boundary.  
✅ Feature flag boundary.  
⬜ Manifest-driven gating on every screen/action.  
⬜ Permission change event behavior.

### 13. Dynamic Forms — NEXT MAJOR MILESTONE
⬜ Field schema/runtime for text, number, email, phone, password, date, datetime, dropdown, radio, checkbox, switch, file, image, autocomplete, textarea.  
⬜ Required/min/max/regex.  
⬜ Conditional visibility/dependencies.  
⬜ Remote options.  
⬜ State binding/submit mapping.

### 14. Device Capability Bridge — FOUNDATION
✅ camera/gallery/files/share/clipboard/biometric/location/QR/deep-link/browser boundaries.  
⬜ Production permission/error handling.  
⬜ Upload/download integration.

### 15. Cache — FOUNDATION
✅ Persistent resource metadata/checksum/version.  
⬜ Memory cache.  
⬜ TTL/stale policies.  
⬜ Explicit invalidation/resource cache policy.

### 16. Settings — FOUNDATION
✅ Account/security/notifications/appearance/storage/sync/diagnostics sections.  
✅ Last sync/pending operations/Sync Now.  
⬜ Functional account/security/appearance/cache controls.

### 17. Diagnostics — FOUNDATION
✅ Runtime/schema/manifest/DB/sync/cache/API/WebSocket/auth metadata.  
⬜ Live API reachability.  
⬜ Live WebSocket state.  
⬜ Package/binary version.  
⬜ Detailed error history.

### 18. Versioning — PARTIAL
✅ Runtime/schema/resource version/checksum concepts.  
✅ Legacy API migration fallback.  
⬜ Compatibility matrix.  
⬜ DB migration/version enforcement.  
⬜ API negotiation/resource compatibility policies.

### 19. Backend Contract — CLIENT FOUNDATION
✅ Contract shape defined: bootstrap/manifest/resources/sync/events/ack.  
✅ Legacy `https://flutter.alattab.site/api/app-config` preserved.  
⬜ Actual Flask `/runtime/*` implementation.  
⬜ Formal JSON Schemas.  
⬜ Sync response/conflict protocol.  
⬜ Event acknowledgement contract and rollout.

### 20. Tests — FOUNDATION
✅ CI analyze/test/build pipeline.  
✅ Basic runtime tests.  
⬜ API/repository tests.  
⬜ Drift tests.  
⬜ Sync/offline/conflict tests.  
⬜ Action/workflow tests.  
⬜ malformed manifest/STAC tests.  
⬜ WebSocket/auth expiry tests.  
⬜ widget/integration tests.

### 21. CI/CD — DEBUG PIPELINE COMPLETE
✅ Flutter setup, dependency install, generation, formatting, analyze, tests, debug APK and artifact upload.  
⬜ Release signing.  
⬜ AAB/release artifacts.  
⬜ Versioned release automation.  
⬜ Optional Web pipeline.

### 22. Security — FOUNDATION
✅ Secure token storage boundary.  
✅ HTTPS endpoints.  
✅ No runtime secrets in source/config.  
✅ Backend remains authority for permissions.  
⬜ Logging/payload hardening audit.  
⬜ Auth refresh/rotation.  
⬜ Platform security review.

## Next execution order

1. Dynamic Form Runtime + validation + field state.
2. Action templating + typed action context + workflow branching.
3. Resource/data binding and repository-first offline access.
4. Manual sync protocol, acknowledgements, conflicts and partial resources.
5. Formal runtime schemas and migration-safe backend contract.
6. Event acknowledgement/reconnect and notification lifecycle.
7. Production auth/permissions.
8. Full unit/widget/integration coverage.
9. Release APK/AAB pipeline.

## Quality gate

No milestone is marked complete until its implementation is exercised by automated tests and `flutter analyze` + `flutter test` + Android debug build remain green.
