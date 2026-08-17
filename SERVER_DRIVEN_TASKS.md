# Server-Driven Flutter Runtime — Master Task Board

Branch: `server-driven-runtime-v2`
PR: #2

Legend: ✅ complete and verified | 🟡 implemented foundation / needs production hardening | ⬜ not complete

## 1. Foundation
- ✅ Layered runtime architecture
- ✅ Flutter 3.44.8 stable / Dart 3.12.2 baseline
- ✅ STAC 1.5.0
- ✅ Android Kotlin 2.2.20 / AGP 8.11.1 / Gradle 8.14
- ✅ CI: analyze + test + debug APK + artifact

## 2. STAC Runtime
- ✅ Full screen `screen.stac` contract
- ✅ Legacy component-to-STAC compatibility bridge
- ✅ Dynamic theme foundation
- ✅ STAC-native form/reference manifest
- 🟡 Dynamic form schema/validation runtime (required, regex, ranges, conditional visibility)
- ⬜ Form state binding to STAC widgets
- ⬜ Remote dropdown/autocomplete options
- ⬜ Form submit mapping and server-defined validation actions
- ⬜ Manifest-driven drawer/bottom navigation/tabs/deep links
- ⬜ Resource/data binding for lists/cards/grids
- ⬜ Custom component registry for STAC gaps

## 3. API Engine
- ✅ GET/POST/PUT/PATCH/DELETE
- ✅ headers/query/path/body
- ✅ bearer authentication injection
- ✅ timeout/retry
- ⬜ typed response/error mapping
- ⬜ upload/download abstraction
- ⬜ server-defined data sources/repositories

## 4. Action Engine
- ✅ navigation/API/dialog/snackbar/refresh/logout/open URL/device/workflow
- ✅ template interpolation
- ✅ workflow `when`, `save_as`, `on_error`
- ⬜ durable local state mutation contract
- ⬜ transactional workflow rollback/compensation
- ⬜ notification-originated action routing with live navigation context

## 5. Local Data / Offline First
- ✅ Drift + SQLite
- ✅ runtime/resource metadata
- ✅ persisted sync queue
- ✅ offline-first ResourceRepository foundation
- ⬜ typed application entity repositories
- ⬜ cache TTL / stale-while-revalidate / invalidation policy
- ⬜ repository-first dynamic screen integration

## 6. Manual Sync
- ✅ first-launch bootstrap only when no snapshot exists
- ✅ no startup/onResume/timer/background sync
- ✅ Settings → Sync Now
- ✅ queue persistence
- ✅ versions/checksums
- 🟡 explicit conflict policy model
- ⬜ server acknowledgement parsing per operation
- ⬜ partial success handling
- ⬜ conflict persistence and resolution UI
- ⬜ durable retry/backoff/error states
- ⬜ partial resource synchronization

## 7. Realtime / Notifications
- ✅ WebSocket/event boundary
- ✅ event routing categories
- ✅ event path independent from full sync
- 🟡 Firebase Messaging boundary
- ⬜ reconnect/backoff
- ⬜ event ACK protocol
- ⬜ notification token/permission lifecycle
- ⬜ cold-start notification action routing

## 8. Authentication / Permissions
- ✅ secure token storage boundary
- ✅ access/refresh session model
- ✅ logout
- ✅ roles/permissions/feature flags boundary
- ⬜ refresh-token execution
- ⬜ 401 interception/re-authentication
- ⬜ login/re-auth UX
- ⬜ manifest-wide permission gating
- ⬜ live permission-change application

## 9. Device Capabilities
- ✅ camera/gallery/files/share/clipboard/biometric/location/QR/browser/deep-link boundaries
- ⬜ production permission/error audit
- ⬜ upload/download integration

## 10. Settings / Diagnostics
- ✅ settings shell
- ✅ sync status / last sync / pending count
- ✅ runtime/manifest/database/cache/API/WebSocket/auth metadata
- ⬜ live API/WebSocket health probes
- ⬜ functional account/security/appearance/cache controls
- ⬜ detailed error history

## 11. Versioning / Backend Contract
- ✅ schema_version
- ✅ runtime/manifest/resource versions
- ✅ checksum concepts
- ✅ migration fallback for `/api/app-config`
- ✅ `/runtime/*` contract documentation
- ⬜ machine-readable JSON Schema package
- ⬜ compatibility matrix / migration policy
- ⬜ real Flask `/runtime/bootstrap`
- ⬜ real Flask `/runtime/manifest`
- ⬜ real Flask `/runtime/resources`
- ⬜ real Flask `/runtime/sync`
- ⬜ real Flask `/runtime/events/ack`
- ⬜ real WebSocket `/runtime/events`

## 12. Testing
- ✅ contract tests
- ✅ action template tests
- ✅ dynamic form validation tests
- ✅ CI green through debug APK
- ⬜ Drift/repository tests
- ⬜ sync acknowledgement tests
- ⬜ conflict tests
- ⬜ malformed STAC tests
- ⬜ auth/401 tests
- ⬜ WebSocket tests
- ⬜ notification tests
- ⬜ full integration suite

## 13. Release / Security
- ✅ HTTPS/server-side authority foundations
- ✅ secure storage foundation
- ✅ modern Android toolchain
- ⬜ release signing
- ⬜ AAB/release automation
- ⬜ payload-size and logging hardening audit
- ⬜ auth token rotation/security review

## Execution priority
1. Dynamic forms state/options/submit.
2. Repository/data-source binding into dynamic screens.
3. Sync response/ACK/conflict/partial-resource protocol.
4. WebSocket reconnect + ACK + notification routing.
5. Auth refresh/401 + permission gating.
6. Comprehensive tests.
7. Release AAB/signing.
8. Flask `/runtime/*` implementation and progressive migration.

## Quality Gate
A task becomes ✅ only after implementation plus `flutter analyze`, `flutter test`, and Android debug build remain green for the relevant CI revision.
