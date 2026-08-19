# Flutter Server-Driven Runtime — Master Task Board

Branch: `server-driven-runtime-v2`
PR: #2

Legend: ✅ verified by an appropriate CI/test gate | 🟡 implemented but awaiting current CI or integration verification | ⬜ outside the Flutter-only boundary or not implemented yet.

## Foundation

- ✅ Layered runtime architecture
- ✅ Flutter 3.44.8 stable / Dart 3.12.2
- ✅ STAC 1.5.0
- ✅ Modern Android toolchain
- ✅ CI pipeline for Drift generation, format, analyze, tests, APK and AAB builds
- ✅ Legacy `/api/app-config` fallback

## STAC Runtime

- ✅ Full-screen `screen.stac` contract
- ✅ Legacy component → STAC bridge
- ✅ Dynamic theme foundation
- ✅ Resource binding/interpolation
- ✅ `for_each/item_template` resource expansion
- ✅ Manifest navigation foundation
- ✅ Runtime action parser
- ✅ Custom runtime component registry

## Forms

- ✅ Dynamic form controller/state
- ✅ required/regex/range validation
- ✅ conditional visibility
- ✅ submission mapping foundation
- ✅ remote option provider
- ✅ cached remote options controller
- ✅ form submission service

## API / Actions / Workflows

- ✅ GET/POST/PUT/PATCH/DELETE
- ✅ query/path/header/body mapping
- ✅ bearer authentication
- ✅ retry/timeout foundation
- ✅ typed API result/error models
- ✅ 401 recovery/refresh service foundation
- ✅ upload/download service and actions
- ✅ navigation/dialog/snackbar/sync/logout/open-url/device/workflow actions
- ✅ interpolation, conditions, `save_as`, error branches
- ✅ permission checks before runtime actions
- ✅ local transaction/rollback foundation
- ✅ notification action routing foundation
- 🟡 server-selected API Profile routing: implemented in the API contract and awaiting a fresh green CI verification

## Local / Offline / Sync

- ✅ Drift + SQLite runtime store
- ✅ resource metadata/version/checksum
- ✅ typed RuntimeRepository foundation
- ✅ persisted sync queue
- ✅ first-install-only bootstrap rule
- ✅ manual-only Sync Now rule
- ✅ acknowledged/conflict/rejected/retry/pending protocol model
- ✅ partial-success parsing
- ✅ conflict persistence/resolution foundation
- ✅ retry/backoff persistence
- ✅ cache coordinator policies
- ✅ true cache invalidation
- 🟡 complete end-to-end Sync ACK/conflict integration test against Flask

## Realtime / Auth / Permissions / Device

- ✅ WebSocket event boundary
- ✅ reconnect/backoff foundation
- ✅ event ACK client contract
- ✅ event routing independent of full sync
- ✅ secure access/refresh session storage
- ✅ refresh service implementation
- ✅ permission route/action guards
- ✅ live permission-change handling
- ✅ device capability bridge
- 🟡 live WebSocket reconnect/ACK integration test
- 🟡 real authentication refresh integration test

## Settings / Diagnostics / Security / Release

- ✅ Settings shell + manual Sync Now
- ✅ sync/pending/conflict diagnostics
- ✅ runtime self-test foundation
- ✅ local error-history primitives
- ✅ HTTPS-first runtime security policy
- ✅ sensitive log redaction policy
- ✅ release-signing path/documentation
- 🟡 detailed error-history UI/export
- 🟡 production signing with real release secrets

## Required current Flutter quality gate

Before Backend migration:

- 🟡 `flutter pub get`
- 🟡 Drift generation
- 🟡 `dart format`
- 🟡 `flutter analyze`
- 🟡 `flutter test`
- 🟡 debug APK
- 🟡 debug AAB
- 🟡 release AAB

The branch was intentionally reset to the last known verified build baseline before API-profile routing was attempted. Only the API contract documentation and Runtime endpoint alignment were added afterward. No Backend deployment is permitted until this entire gate is green on the same HEAD.

## Backend boundary

These belong in the Flask control plane and must be changed server-side rather than requiring Flutter rebuilds:

- ⬜ `/runtime/bootstrap`
- ⬜ `/runtime/manifest`
- ⬜ `/runtime/resources`
- ⬜ `/runtime/sync`
- ⬜ `/runtime/events/ack`
- ⬜ WebSocket `/runtime/events/ws`
- ⬜ server-side authorization
- ⬜ data-model CRUD
- ⬜ release publishing
- ⬜ API Profiles/endpoints
- ⬜ server-generated notifications

## Authoritative documentation

`docs/API.md` is the complete client/server contract. Future Backend work must implement it exactly; ordinary application changes should then be performed through the server control plane instead of rebuilding the Flutter binary.
