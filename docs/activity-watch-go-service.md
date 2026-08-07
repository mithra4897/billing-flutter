# Activity Watch Go desktop service

## Status

The consent-gated service implements Windows, macOS, and Linux collection,
encrypted local persistence, durable synchronization, daily summaries,
inventory deduplication, lifecycle inference, and 90-day cleanup. Foreground
and idle APIs are best effort: a missing OS capability produces `unknown`
rather than stopping the service.

## Runtime model

`activity-watch-agent` runs in the enrolled desktop user's session so native
idle and foreground-application APIs see the correct interactive desktop. The
service manager starts it when that user signs in. ERP logout closes the local
collection session, prepares the daily summary, and requests an immediate
sync. At OS/service shutdown it uses a bounded final summary/flush and then
closes the encrypted database.

After enrollment, the native Flutter page updates the conventional protected
credential/configuration files automatically when they exist. It also stores
the installed executable/configuration paths through
`ActivityWatchServiceControl.configure`. Native ERP logout then emits
`signal-logout`; web and unconfigured installations remain safe no-ops.

## Commands

```text
activity-watch-agent install --config /absolute/path/config.json
activity-watch-agent provision --config /absolute/path/config.json
activity-watch-agent start --config /absolute/path/config.json
activity-watch-agent status --config /absolute/path/config.json
activity-watch-agent stop --config /absolute/path/config.json
activity-watch-agent uninstall --config /absolute/path/config.json
activity-watch-agent run --config /absolute/path/config.json
```

`run` keeps the worker in the foreground for development. Native release
packaging must install it in the enrolled user's login context; service-manager
verification is required on every target OS.

## Configuration

Copy `activity-watch-agent/config.example.json` to an administrator-controlled
absolute path. The file contains no secrets. Secret providers supply the raw
32-byte SQLCipher key and device credential at runtime.

For a fresh, authorized machine installation, configure three new absolute
paths: `database.path`, `database.key_file`, and
`control.logout_request_path`. Then run `provision` once. It creates the parent
directories, an encrypted version-1 database, and a mode-`0600` hex-encoded
256-bit key file. It does not print the key and refuses to overwrite an
existing database or key. Provisioning does not start the service or enable
synchronization.

Do not use `provision` for an existing Flutter-managed database: it creates a
new independent database/key pair. Use it only after Activity Watch enrollment
and consent have been approved for that installation.

Before enrollment use `collection.disabled: true` and `sync.enabled: false`.
After enrollment the Flutter desktop page sets the server-issued `device_id`,
writes the one-time credential to `sync.credential_file`, enables sync, and
sets `collection.disabled: false` when the conventional service files exist.

Collection defaults are:

- activity/foreground sample: 15 seconds;
- idle threshold: 5 minutes;
- process inventory: 5 minutes;
- service inventory: 15 minutes;
- daily-summary revision: 15 minutes, plus immediate logout/shutdown revisions;
- local/server retention: 90 days.

The agent consolidates unchanged samples rather than inserting one event per
tick. Process and service inventories are canonically sorted, capped, hashed,
and stored only when their contents change.

## Build prerequisites

- Go toolchain;
- CGO-compatible C compiler;
- platform signing and installer tools; and
- administrator-controlled machine credential/ACL provisioning.

The embedded Go SQLCipher driver is compatibility-4. Platform release builds
must verify database interoperability with the Flutter SQLCipher runtime.
The raw key is applied once through the driver before any database access; the
tested connection then uses encrypted WAL.

## Privacy

The service records active/idle/locked/unknown duration, overlapping offline
duration, foreground executable name/category, and bounded process/service name
inventories. Cross-midnight segments are apportioned to the correct local date.
It never records
keystrokes, clipboard data, screenshots, pointer coordinates, window/tab
titles, URLs, page/form content, or process command lines. Browser activity is
category-only through the browser executable; raw tab collection is not
implemented.
