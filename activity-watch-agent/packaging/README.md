# Activity Watch employee installers

These assets turn the tested Go binary into a per-user installation. A release
pipeline must compile the SQLCipher-enabled binary on each target OS, place it
beside the platform installer asset, sign the result, and publish it under the
ERP's `ACTIVITY_WATCH_INSTALLER_BASE_URL`.

The Windows installer performs only these actions in the current user's profile:

1. copy the agent binary;
2. register `.billingawpair` with the pairing handler; and
3. wait for the employee to open a fresh pairing file.

The first `pair` command bootstraps encrypted storage when absent, applies the
server response, and starts the user service. Nothing is collected before
pairing succeeds.

Opening a pairing file executes:

```text
activity-watch-agent pair --config <user-config> --bundle <downloaded-file>
```

The agent exchanges the short-lived token, removes the consumed file, writes the
credential/config with user-only permissions, enables collection, and restarts
the service. Pairing files never contain permanent credentials.

For Windows build-machine setup, publishing, verification, and troubleshooting,
see [`../../docs/activity-watch-windows-developer-setup.md`](../../docs/activity-watch-windows-developer-setup.md).

Release signing and native installer construction must run on the target OS:

- macOS: package/notarize the app bundle and installer with Developer ID.
- Windows: run `packaging/windows/build-exe.ps1`. The resulting installer EXE
  installs the agent per user and associates `.billingawpair`.
  The first pairing automatically creates its local configuration and starts
  the per-user scheduled task. The script builds the Go agent, then uses the
  Windows .NET Framework C# compiler to embed the agent and existing installer
  script in one self-contained launcher EXE. The installer uses Windows
  `reg.exe` to register the `.billingawpair` association in the current user's
  registry view.
- Linux: wrap `linux/install.sh`, desktop entry, MIME XML, and binary in signed
  DEB/RPM packages.

For macOS, compile the document handler before packaging:

```bash
swiftc -parse-as-library -framework AppKit macos/PairingLauncher.swift \
  -o macos/BillingActivityWatchPair
```
