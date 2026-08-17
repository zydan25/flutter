# Runtime Backend Contract v2

The Flutter client is a runtime. The server owns application definitions, resources, permissions, feature flags and events.

## Bootstrap

`GET /runtime/bootstrap`

Used only when the device has no local runtime snapshot.

```json
{
  "schema_version": 1,
  "runtime_version": "2.0.0",
  "manifest_version": 1,
  "checksum": "sha256:...",
  "home_screen": "home",
  "theme": {"primary": "#4F46E5"},
  "permissions": {"permissions": [], "feature_flags": {}},
  "screens": [
    {
      "name": "home",
      "stac": {
        "type": "scaffold",
        "body": {"type": "text", "data": "Hello"}
      }
    }
  ],
  "resources": []
}
```

## Manifest

`GET /runtime/manifest`

Returns the current manifest after a manual Sync Now operation. The response uses the same version/checksum contract as bootstrap.

## Resources

`GET /runtime/resources`

Returns only changed resources when the client supplies its current versions/checksums.

Suggested request headers:

```text
If-None-Match: <manifest checksum>
X-Runtime-Version: 2.0.0
X-Schema-Version: 1
```

## Manual Sync

`POST /runtime/sync`

The client sends pending queue operations. No queue is uploaded automatically.

```json
{
  "schema_version": 1,
  "runtime_version": "2.0.0",
  "operations": [
    {
      "operation_id": "op-901",
      "entity": "customer",
      "entity_id": "123",
      "operation": "update",
      "base_version": 5,
      "payload": {"name": "New Name"}
    }
  ],
  "resources": [
    {"resource_id": "home", "version": 27, "checksum": "sha256:..."}
  ]
}
```

Suggested response:

```json
{
  "accepted": ["op-901"],
  "conflicts": [
    {
      "operation_id": "op-902",
      "reason": "version_conflict",
      "server_version": 7,
      "server_data": {}
    }
  ],
  "resources": [],
  "manifest": null
}
```

## Event acknowledgement

`POST /runtime/events/ack`

Acknowledges an event only; it is not a full synchronization request.

```json
{
  "event_id": "evt-123",
  "status": "processed"
}
```

## WebSocket

`WS /runtime/events`

Supported event types:

- `config.updated`
- `entity.updated`
- `entity.deleted`
- `notification`
- `force_logout`
- `permission.changed`
- `feature_flag.changed`

Receiving an event MUST NOT trigger a full synchronization automatically. The event router may update a local resource or mark state stale; full synchronization remains manual.

## Server-driven actions

Actions may interpolate runtime data using `${path.to.value}` templates before execution. Workflows may use `when`, `save_as`, and `on_error` to express branching and error handling.

## STAC screens

A screen can contain a complete STAC widget tree in `screen.stac`. STAC 1.5.0 already provides native forms, form validation, network requests, navigation, dialogs and dynamic views, so the runtime should prefer those primitives rather than reimplementing equivalent widgets.

## Legacy migration

The existing endpoint remains valid during migration:

`GET https://flutter.alattab.site/api/app-config`

The client falls back to it only when the new runtime bootstrap/manifest contract is unavailable.
