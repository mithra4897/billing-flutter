# Activity Watch Go desktop service

## Status

The service foundation supports Windows, macOS, and Linux desktop packaging.
It stores machine lifecycle events and synchronizes existing encrypted outbox
records. Full interactive idle/application collectors and the ERP ingestion
endpoint are separate required phases.

## Runtime model

`activity-watch-agent` is installed as an administrator-managed machine
service. It starts at boot and remains alive after the ERP or OS user logs out.
Logout requests an immediate sync; it does not terminate the machine service.
The future consent-bound interactive helper will also stop collection at
logout. At shutdown the service uses a bounded final flush and then closes the
encrypted database.

After service enrollment, the Flutter app stores the installed executable and
configuration paths through `ActivityWatchServiceControl.configure`. Native ERP
logout then emits `signal-logout`; web and unconfigured installations do
nothing.

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

Installation and service control require administrator privileges. `run` keeps
the worker in the foreground for development.

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

Keep `sync.enabled` false until the ERP server implements the documented
device enrollment and `POST /api/v1/activity-watch/batches` contract.

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

The initial service records bounded lifecycle/health events. It does not record
keystrokes, clipboard data, screenshots, pointer coordinates, full URLs,
page/form content, or process command lines. Interactive collection must remain
disabled until consent and a platform capability adapter are present.
