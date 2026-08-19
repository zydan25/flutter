# Server-Driven Runtime API Contract

This document is the authoritative contract between the Flutter Runtime and the Flask Runtime Control Plane.

## 1. Base URLs

Flutter Runtime Control Plane:

`https://flutter.alattab.site`

The Runtime API host is fixed for bootstrapping, manifest, resources, sync, authentication, device registration, notifications, health, and WebSocket events.

Application data APIs are **not** required to use the Runtime host. They are selected by the server through `manifest.api.default_profile` or `manifest.api.profiles`.

The client must never receive API passwords, private keys, refresh secrets, or server-side credentials in the manifest.

## 2. Application identity

Default application slug:

`flutter-app`

Every Runtime request identifies the application either by the configured default or with `?app=flutter-app`.

## 3. Bootstrap

### Request

```http
GET /runtime/bootstrap?app=flutter-app
Authorization: Bearer <runtime-token>
```

### Response

```json
{
  "schema_version": 1,
  "app": {
    "slug": "flutter-app",
    "name": "My Application",
    "package_name": "com.example.app"
  },
  "release": {
    "version": 12,
    "checksum": "sha256...",
    "published_at": "2026-08-19T18:00:00Z"
  },
  "manifest_url": "/runtime/manifest?app=flutter-app&version=12",
  "resources_url": "/runtime/resources?app=flutter-app&version=12",
  "sync_url": "/runtime/sync?app=flutter-app",
  "events_ack_url": "/runtime/events/ack",
  "events_ws_url": "/runtime/events/ws?app=flutter-app",
  "client_mode": "server_driven"
}
```

Flutter uses bootstrap only to locate and validate the current Runtime release. It does not treat the bootstrap envelope as the screen manifest.

## 4. Manifest

### Request

```http
GET /runtime/manifest?app=flutter-app
Authorization: Bearer <runtime-token>
```

### Response root

```json
{
  "schema_version": 1,
  "version": 12,
  "checksum": "sha256...",
  "home_screen": "home",
  "app_name": "My Application",
  "screens": [],
  "navigation": {},
  "theme": {},
  "actions": [],
  "workflows": [],
  "permissions": {},
  "feature_flags": {},
  "api": {},
  "data_models": []
}
```

### Screen

A screen can be represented directly by STAC:

```json
{
  "name": "home",
  "route": "/",
  "title": "Home",
  "permission": "home.read",
  "stac": {
    "type": "scaffold",
    "appBar": {
      "type": "appBar",
      "title": {"type": "text", "data": "Home"}
    },
    "body": {
      "type": "column",
      "children": []
    }
  }
}
```

The server is the owner of screen definitions. Flutter renders them and executes permitted runtime actions; it does not hard-code business screens.

## 5. Resources

### Request

```http
GET /runtime/resources?app=flutter-app
Authorization: Bearer <runtime-token>
```

Optional:

`?keys=customers,settings`

### Response

```json
{
  "schema_version": 1,
  "version": 12,
  "resources": {
    "customers": {
      "resource_type": "json",
      "endpoint": "/customers",
      "cache_policy": "stale_while_revalidate",
      "ttl_seconds": 300,
      "version": 4,
      "checksum": "sha256...",
      "payload": {},
      "metadata": {}
    }
  }
}
```

Resources are stored locally in SQLite/Drift. Resource metadata includes version and checksum. Resource invalidation must remove the cached resource rather than overwrite it with an empty payload.

## 6. API Profiles

The Runtime manifest may define one or more external data API profiles.

```json
{
  "api": {
    "default_profile": {
      "slug": "primary",
      "name": "Primary API",
      "base_url": "https://api.example.com",
      "verify_tls": true,
      "timeout_seconds": 20,
      "allowed_hosts": ["api.example.com"],
      "auth": {
        "type": "bearer",
        "token_header": "Authorization",
        "scheme": "Bearer"
      }
    },
    "profiles": []
  }
}
```

Changing `base_url` or selecting another profile must not require a new APK/AAB, provided the Runtime manifest is compatible.

## 7. API Endpoints

A server-defined endpoint describes the business API independently from the Flutter Runtime API:

```json
{
  "slug": "customers.list",
  "profile": "primary",
  "method": "GET",
  "path": "/v1/customers",
  "request_schema": {},
  "response_mapping": {},
  "error_mapping": {}
}
```

Supported methods:

- GET
- POST
- PUT
- PATCH
- DELETE

The Flutter API engine supports query parameters, path parameters, headers, body mapping, typed response mapping, error mapping, retries, timeout, bearer authentication, and one-shot 401 recovery.

## 8. Server-defined API Action

```json
{
  "type": "api",
  "method": "POST",
  "api_profile": "primary",
  "url": "/v1/customers",
  "query": {},
  "path": {"id": "${customer.id}"},
  "headers": {
    "X-Request-Id": "${request_id}"
  },
  "body": {
    "name": "${form.name}",
    "phone": "${form.phone}"
  }
}
```

An absolute URL is allowed:

```json
{"type":"api","method":"GET","url":"https://api.example.com/v1/ping"}
```

Relative URLs use the selected profile.

## 9. Action types

Supported runtime action families:

- `navigate`
- `api`
- `networkRequest`
- `dialog`
- `snackbar`
- `refresh`
- `sync`
- `logout`
- `open_url`
- `device`
- `device_action`
- `set_state`
- `upload`
- `download`
- `workflow`

Every action may include a `permission` requirement.

## 10. Workflows

```json
{
  "type": "workflow",
  "context": {
    "source": "customer_form"
  },
  "steps": [
    {
      "type": "validate"
    },
    {
      "type": "api",
      "method": "POST",
      "api_profile": "primary",
      "url": "/v1/customers",
      "body": "${form}"
    },
    {
      "type": "set_state",
      "key": "last_customer_id",
      "value": "${result.id}"
    },
    {
      "type": "refresh",
      "save_as": "sync_result"
    },
    {
      "type": "navigate",
      "route": "/customers"
    }
  ],
  "on_error": {
    "type": "snackbar",
    "message": "Operation failed"
  }
}
```

`when` supports equality, inequality, existence and truthiness conditions.

## 11. Dynamic Forms

Example:

```json
{
  "type": "form",
  "id": "customer_form",
  "children": [
    {
      "type": "textField",
      "id": "name",
      "label": "Name",
      "required": true
    },
    {
      "type": "textField",
      "id": "phone",
      "label": "Phone",
      "validation": {
        "regex": "^\\+?[0-9]{8,15}$"
      }
    }
  ]
}
```

Supported field classes include text, number, email, phone, password, date, datetime, dropdown, radio, checkbox, switch, file, image, autocomplete and textarea.

Remote options use:

```json
{
  "source": {
    "type": "remote_options",
    "api_profile": "primary",
    "url": "/v1/countries",
    "value_field": "id",
    "label_field": "name"
  }
}
```

## 12. Data API

Runtime-managed application data is exposed separately from the screen engine.

```http
GET    /runtime/data/<model>
POST   /runtime/data/<model>
GET    /runtime/data/<model>/<record>
PUT    /runtime/data/<model>/<record>
PATCH  /runtime/data/<model>/<record>
DELETE /runtime/data/<model>/<record>
```

List parameters:

`page`, `per_page`, `include_deleted`

Create:

```json
{
  "id": "123",
  "data": {
    "name": "Zaidan"
  }
}
```

Update supports optimistic concurrency using:

`If-Match: <base_version>`

or:

```json
{"base_version": 4, "data": {"name": "New"}}
```

A version conflict returns HTTP 409 and the current server record.

## 13. Synchronization

### Manual sync request

```http
POST /runtime/sync?app=flutter-app
Content-Type: application/json
Authorization: Bearer <runtime-token>
```

```json
{
  "operations": [
    {
      "operation_id": "op-123",
      "entity": "customers",
      "entity_id": "123",
      "operation": "update",
      "base_version": 4,
      "payload": {
        "name": "New"
      },
      "retry_count": 0
    }
  ]
}
```

Response:

```json
{
  "schema_version": 1,
  "results": [
    {
      "operation_id": "op-123",
      "status": "acknowledged",
      "server_version": 5
    }
  ],
  "partial": false
}
```

Allowed result statuses:

- acknowledged
- conflict
- rejected
- retry
- pending

Flutter never uploads the local queue automatically. Queue upload occurs only when the user executes `Settings → Sync Now` or a server-defined explicit sync action.

## 14. Initial install and startup rules

First startup without a local manifest:

```text
bootstrap → manifest → resources → SQLite → UI
```

Startup when a local manifest exists:

```text
SQLite → UI
```

No startup sync, periodic timer, `onResume` sync, or background periodic sync is used.

## 15. WebSocket events

Endpoint:

`GET/WS /runtime/events/ws?app=flutter-app`

Events:

- `config.updated`
- `entity.updated`
- `entity.deleted`
- `notification`
- `force_logout`
- `permission.changed`
- `feature_flag.changed`

Event example:

```json
{
  "event_id": "evt-123",
  "type": "permission.changed",
  "payload": {
    "permissions": {
      "customers.read": true
    }
  }
}
```

A WebSocket event never implies a full synchronization automatically.

### ACK

```json
{
  "type": "ack",
  "event_ids": ["evt-123"]
}
```

The server must mark acknowledged events and must not resend them after a successful ACK unless a new event ID is generated.

## 16. Device registration / push notifications

```http
POST /runtime/devices/register
Content-Type: application/json
Authorization: Bearer <runtime-token>
```

```json
{
  "app": "flutter-app",
  "device_id": "device-123",
  "platform": "android",
  "push_token": "<FCM token>",
  "metadata": {
    "app_version": "2.0.0"
  }
}
```

Notification actions use the same runtime action contract. A notification tap must not create a second action language.

## 17. Authentication

Runtime/API authentication supports bearer access tokens.

401 flow:

```text
request
 → 401
 → refresh token
 → save rotated session
 → retry original request once
```

Refresh endpoint:

```http
POST /runtime/auth/refresh
Content-Type: application/json
```

```json
{"refresh_token":"<refresh-token>"}
```

Response:

```json
{
  "access_token": "...",
  "refresh_token": "..."
}
```

No token, password, or secret is stored in the manifest or STAC screen definition.

## 18. Permissions

Manifest permissions may be represented as a key/value map or permission descriptors.

Actions and routes can include a required permission:

```json
{
  "permission": "customers.update"
}
```

Flutter uses permissions only for UI/action gating. Backend authorization remains the source of truth.

## 19. Feature flags

```json
{
  "feature_flags": {
    "new_dashboard": {
      "enabled": true,
      "rules": {}
    }
  }
}
```

Flags may change through a `feature_flag.changed` event, but event receipt does not trigger a full sync.

## 20. Health / diagnostics

```http
GET /runtime/health?app=flutter-app
```

Example:

```json
{
  "status": "ok",
  "app": "flutter-app",
  "runtime_schema": 1,
  "release": 12
}
```

Flutter Diagnostics should also expose local DB version, manifest version, last sync, pending operations, websocket state, API state and authentication state.

## 21. Error contract

Recommended error shape:

```json
{
  "error": "validation_error",
  "message": "One or more fields are invalid",
  "details": {
    "name": ["required"]
  },
  "request_id": "req-123"
}
```

Common HTTP statuses:

- 200 success
- 201 created
- 400 malformed request
- 401 unauthenticated
- 403 forbidden
- 404 not found
- 409 optimistic conflict
- 422 validation error
- 429 rate limited
- 500 server failure
- 503 runtime unavailable

## 22. Versioning

Runtime schema:

`schema_version`

Release:

`version`

Resource:

`version` + `checksum`

Flutter Runtime:

`runtimeVersion`

Breaking API changes must introduce a new schema/API version rather than silently changing existing meanings.

## 23. Compatibility endpoint

During migration the old endpoint may remain available:

`GET /api/app-config`

It is a compatibility fallback only. New deployments should use `/runtime/bootstrap` and `/runtime/manifest`.

## 24. Server-side ownership

The server owns:

- screens
- routes
- navigation definition
- themes
- actions
- workflows
- resources
- API profiles
- API endpoints
- data models
- feature flags
- permissions
- release versions
- resource versions/checksums

Flutter owns:

- rendering
- local state
- SQLite/Drift
- offline queue
- device capabilities
- secure token storage
- Runtime execution
- sync policy enforcement

## 25. Security rules

Never place these in a Runtime manifest:

- database passwords
- API private keys
- FCM server keys
- JWT signing secrets
- refresh-token master secrets
- administrator credentials

The `CodeAsset` system is storage/transport only unless a future isolated execution sandbox is explicitly introduced.

## 26. Release flow

1. Create/edit screens, resources, actions, workflows, API profiles, permissions and data models in the Flask admin/control plane.
2. Build a draft Runtime Release.
3. Validate all referenced routes, actions, profiles and schemas.
4. Calculate checksum.
5. Publish the release.
6. Flutter receives the new release on the next **manual sync** or initial install according to the sync policy.
7. Existing local data remains available offline.

## 27. Example complete screen

```json
{
  "name": "customers",
  "route": "/customers",
  "title": "Customers",
  "permission": "customers.read",
  "stac": {
    "type": "scaffold",
    "appBar": {
      "type": "appBar",
      "title": {"type": "text", "data": "Customers"}
    },
    "body": {
      "type": "column",
      "children": [
        {
          "type": "filledButton",
          "child": {"type": "text", "data": "Add customer"},
          "onPressed": {
            "type": "runtime_action",
            "action": {
              "type": "navigate",
              "route": "/customers/new"
            }
          }
        }
      ]
    }
  }
}
```

## 28. Rule for future development

New application behavior should normally be added to the server contract and control plane first. Flutter should only receive or interpret the resulting Runtime definition. Rebuilding the APK for ordinary screen, API endpoint, workflow, theme, data resource or permission changes is not the intended model.
