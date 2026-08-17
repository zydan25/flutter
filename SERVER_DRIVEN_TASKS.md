# Flutter Server-Driven Runtime — Master Task Board

Branch: `server-driven-runtime-v2`
PR: #2
Current code head: `83157a41c69fac112f1e3fe54af05b9b720d2f4f`
Current CI: Run 175 on the same head; in progress at the time this file was updated.

Legend: ✅ implementation exists and has passed a relevant test/CI baseline | 🟡 implemented but awaiting current CI or real integration | ⬜ intentionally outside the Flutter-only boundary or not yet complete

## Completed inside Flutter

### Foundation
- ✅ Layered runtime architecture
- ✅ Flutter 3.44.8 stable / Dart 3.12.2
- ✅ STAC 1.5.0
- ✅ Modern Android toolchain
- ✅ CI with Drift generation, formatting, analyze, tests, APK, debug AAB and release AAB build stages
- ✅ Legacy `/api/app-config` fallback

### STAC Runtime
- ✅ Full-screen `screen.stac` contract
- ✅ Legacy component → STAC bridge
- ✅ Dynamic theme foundation
- ✅ Resource binding with interpolation and `for_each/item_template`
- ✅ Resource binding applied before actual `Stac.fromJson` rendering
- ✅ Manifest navigation shell foundations: drawer, bottom navigation, deep links
- ✅ Runtime Action parser registered in STAC
- ✅ Runtime custom component registry integrated into screen expansion
- ✅ Built-in `info_card` and `action_card` runtime components

### Forms
- ✅ Dynamic form controller/state
- ✅ required/regex/range validation
- ✅ conditional visibility
- ✅ submission mapping
- ✅ remote option provider
- ✅ cached remote option controller
- ✅ end-to-end form submission service with optional local resource persistence

### API / Actions
- ✅ CRUD HTTP methods
- ✅ headers/query/path/body mapping
- ✅ bearer authentication
- ✅ retry/timeout foundation
- ✅ typed success/error model foundation
- ✅ 401 recovery hook + refresh service contract
- ✅ upload/download service
- ✅ upload/download runtime actions
- ✅ navigation/dialog/snackbar/sync/logout/open-url/device/workflow actions
- ✅ interpolation, conditions, `save_as`, error branch
- ✅ permission checks before runtime actions
- ✅ local action transaction/rollback foundation
- ✅ notification Action routing foundation

### Local / Offline / Sync
- ✅ Drift + SQLite
- ✅ runtime resource metadata/version/checksum
- ✅ RuntimeRepository<T>
- ✅ persisted sync queue
- ✅ first-install-only bootstrap
- ✅ manual-only Sync Now policy
- ✅ explicit sync outcomes: acknowledged/conflict/rejected/retry/pending
- ✅ per-operation parsing and partial-success handling
- ✅ conflict persistence/resolution foundation
- ✅ retry/backoff persistence
- ✅ cache coordinator with cache-first/network-first/SWR/network-only policies
- ✅ real resource invalidation (delete)

### Realtime / Auth / Permissions / Device
- ✅ WebSocket event boundary
- ✅ reconnect/backoff foundation
- ✅ event ACK client API
- ✅ event routing independent from full sync
- ✅ secure access/refresh session storage
- ✅ refresh service implementation
- ✅ route/action permission guards
- ✅ live permission change application from realtime events
- ✅ camera/gallery/files/share/clipboard/biometric/location/QR/browser/deep-link capability bridge

### Settings / Diagnostics / Security
- ✅ Settings shell with manual Sync Now
- ✅ sync/pending/conflict status
- ✅ live diagnostics snapshot
- ✅ local runtime self-test
- ✅ SQLite error-history storage primitives
- ✅ HTTPS-first runtime security policy
- ✅ sensitive log field redaction policy
- ✅ optional secure Android release signing configuration
- ✅ release-signing documentation

## Remaining Flutter-only work

### Requires current clean CI / integration verification
- 🟡 Current expanded stack must pass `flutter analyze`, `flutter test`, debug APK/AAB and release AAB on the same HEAD.
- 🟡 Verify new typed repository, cache, remote-form, diagnostics, custom-component and security tests on the current HEAD.
- 🟡 Add/finish integration-level tests for Sync ACK/partial success, malformed STAC, 401 refresh, WebSocket reconnect/ACK, notifications and device capabilities.

### Production UX / hardening
- 🟡 Complete user-facing login/re-auth UX around the existing AuthService.
- 🟡 Complete functional account/security/appearance/storage Settings controls where product behavior is known.
- 🟡 Finish detailed error-history UI/export.
- 🟡 Finish capability-specific permission/error audit.
- 🟡 Finish compatibility/version migration enforcement and release-channel checks.
- 🟡 Add deterministic workflow idempotency/duplicate-submit protection and mixed remote/local compensation semantics.
- 🟡 Expand typed business repositories and typed list/card/grid bindings when the server entity schema is available.

## Backend boundary — not Flutter work

These cannot be honestly marked complete in this repository alone:
- ⬜ Flask `/runtime/bootstrap`
- ⬜ Flask `/runtime/manifest`
- ⬜ Flask `/runtime/resources`
- ⬜ Flask `/runtime/sync`
- ⬜ Flask `/runtime/events/ack`
- ⬜ WebSocket `/runtime/events`
- ⬜ Real server-side authorization/permission enforcement
- ⬜ Real end-to-end notification provider configuration

## Quality gate

A Flutter task becomes ✅ only after its implementation exists and the relevant current CI revision passes. Backend-dependent tasks stay outside the Flutter completion gate until the backend is implemented and validated end-to-end.
