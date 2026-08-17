# Flutter Server-Driven Runtime — Master Task Board

Branch: `server-driven-runtime-v2`
PR: #2

Legend: ✅ complete and verified | 🟡 implemented foundation / awaiting final CI or backend integration | ⬜ not complete

## 1. Foundation
- ✅ Layered runtime architecture
- ✅ Flutter 3.44.8 stable / Dart 3.12.2 baseline
- ✅ STAC 1.5.0
- ✅ Android Kotlin 2.2.20 / AGP 8.11.1 / Gradle 8.14
- ✅ CI: analyze + test + debug APK + artifact (Run 70 verified; later runs currently re-validating the expanded stack)
- 🟡 CI hardened with read-only GitHub token and APK+AAB build stages

## 2. STAC Runtime
- ✅ Full screen `screen.stac` contract
- ✅ Legacy component-to-STAC compatibility bridge
- ✅ Dynamic theme foundation
- ✅ STAC-native form/reference manifest
- 🟡 Dynamic form schema/validation runtime (required, regex, ranges, conditional visibility)
- 🟡 Form state/bind mapping and server-defined submission payload mapping
- 🟡 Remote dropdown/autocomplete option source contract
- ⬜ Render remote options directly into every STAC widget type
- ⬜ Manifest-driven drawer/bottom navigation/tabs/deep links
- 🟡 Resource/data binding foundation through `ResourceRepository` and recursive `ResourceBindingEngine`
- ⬜ Full list/card/grid resource bindings and refresh policies
- ⬜ Custom component registry for STAC gaps

## 3. API Engine
- ✅ GET/POST/PUT/PATCH/DELETE
- ✅ headers/query/path/body
- ✅ bearer authentication injection
- ✅ timeout/retry
- 🟡 typed response/error mapping (`ApiResult`)
- 🟡 401 recovery hook for refresh/re-auth integration
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
- ✅ offline-first `ResourceRepository` foundation
- ⬜ typed application entity repositories
- ⬜ cache TTL / stale-while-revalidate / invalidation policy
- ⬜ repository-first dynamic screen integration

## 6. Manual Sync
- ✅ first-launch bootstrap only when no snapshot exists
- ✅ no startup/onResume/timer/background sync
- ✅ Settings → Sync Now
- ✅ queue persistence
- ✅ versions/checksums
- ✅ explicit conflict policy model (`serverWins`, `clientWins`, `merge`, `manual`)
- ✅ sync protocol model for acknowledged/conflict/rejected/retry/pending results
- ✅ per-operation response parsing in `SyncEngine`
- ✅ partial-success outcomes wired to individual queue states
- ⬜ conflict persistence/resolution UI
- ⬜ durable retry/backoff/error-state policy
- ✅ partial resource payload parsing/saving from sync responses

## 7. Realtime / Notifications
- ✅ WebSocket/event boundary
- ✅ event routing categories
- ✅ event path independent of full sync
- 🟡 reconnect with exponential backoff
- 🟡 event acknowledgement client API
- 🟡 Firebase Messaging integration boundary
- ⬜ notification token/permission lifecycle
- ⬜ cold-start notification action routing
- ⬜ notification-originated workflow context

## 8. Authentication / Permissions
- ✅ secure token storage boundary
- ✅ access/refresh session model
- ✅ logout
- ✅ roles/permissions/feature flags boundary
- 🟡 401 interception hook
- 🟡 refresh-session storage lifecycle
- ⬜ concrete refresh endpoint execution
- ⬜ login/re-auth UX
- 🟡 route/action permission guard foundation
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
- ✅ `schema_version`
- ✅ runtime/manifest/resource versions
- ✅ checksum concepts
- ✅ migration fallback for `/api/app-config`
- ✅ `/runtime/*` contract documentation
- ✅ machine-readable runtime manifest schema (`docs/runtime-schema.json`)
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
- ✅ conflict policy tests
- ✅ resource binding tests
- ✅ CI green through debug APK (Run 70 verified baseline)
- ⬜ repository/Drift tests
- ⬜ sync acknowledgement/partial-success integration tests
- ⬜ malformed STAC/widget tests
- ⬜ auth/401 tests
- ⬜ WebSocket/reconnect/ACK tests
- ⬜ notification tests
- ⬜ full integration suite

## 13. Release / Security
- ✅ HTTPS/server-side authority foundations
- ✅ secure storage foundation
- ✅ modern Android toolchain
- 🟡 AAB debug pipeline added; release signing still pending
- ⬜ release signing
- ⬜ production AAB automation
- ⬜ payload-size and logging hardening audit
- ⬜ auth token rotation/security review

## Next execution priority
1. Bind resources into actual STAC lists/cards/grids with refresh policies.
2. Persist conflict metadata and add resolution UI.
3. Complete notification token/permission and cold-start action routing.
4. Complete refresh endpoint execution + manifest-wide permission gating.
5. Add repository/Drift/sync/auth/WebSocket integration tests.
6. Complete navigation/deep-link contract.
7. Release signing/AAB automation.
8. Implement Flask `/runtime/*` endpoints and progressively migrate `/api/app-config`.

## Quality Gate
A task becomes ✅ only after implementation plus `flutter analyze`, `flutter test`, and Android debug build remain green for the relevant CI revision.
