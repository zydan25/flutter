# Server-Driven Flutter Runtime Platform

This repository is becoming a general-purpose Flutter Server-Driven Runtime. Flutter is the execution/runtime layer; the server describes screens, data, actions, workflows, permissions, feature flags, themes and events.

## Runtime contract

The current backend endpoint remains supported during migration:

`GET https://flutter.alattab.site/api/app-config`

The new contract is designed around:

```text
GET  /runtime/bootstrap
GET  /runtime/manifest
GET  /runtime/resources
POST /runtime/sync
POST /runtime/events/ack
WS   /runtime/events
```

A screen can now be delivered as a complete STAC tree under `screen.stac`, not just as a button name or a list of bespoke Flutter components.

Example:

```json
{
  "schema_version": 1,
  "app_name": "My App",
  "manifest_version": 27,
  "checksum": "abc123",
  "home_screen": "home",
  "screens": [
    {
      "name": "home",
      "stac": {
        "type": "scaffold",
        "appBar": {
          "type": "appBar",
          "title": {"type": "text", "data": "الرئيسية"}
        },
        "body": {
          "type": "padding",
          "padding": {"left": 20, "right": 20, "top": 20, "bottom": 20},
          "child": {
            "type": "column",
            "children": [
              {"type": "text", "data": "واجهة كاملة من الخادم"},
              {"type": "textField", "decoration": {"labelText": "اسم العميل"}},
              {
                "type": "elevatedButton",
                "child": {"type": "text", "data": "الإعدادات"},
                "onPressed": {"type": "navigate", "routeName": "/settings"}
              }
            ]
          }
        }
      }
    }
  ]
}
```

## Runtime rules

- First install: if no local snapshot exists, bootstrap once.
- Normal startup: use local data and do not synchronize automatically.
- No timer, `onResume`, or periodic/background sync.
- Manual synchronization is exposed through Settings → Sync Now.
- Local changes are queued in SQLite and are uploaded during manual sync.
- WebSocket events are routed independently and never imply a full synchronization.

## Current runtime layers

```text
lib/
├── app/            bootstrap and application shell
├── actions/        action/workflow engine
├── auth/           secure session/token storage
├── core/           runtime contract/configuration
├── data/            Dio API engine + Drift/SQLite store
├── device/         device capability boundary
├── events/         WebSocket/event routing
├── notifications/  Firebase push routing
├── permissions/    roles/permissions/feature flags
├── runtime/        STAC runtime and custom action parser
├── settings/       settings and diagnostics
└── sync/           snapshot/queue/manual sync engine
```

STAC 1.5.0 is the SDUI foundation used by this runtime. Flutter 3.44.7 is pinned in CI for reproducible builds.
