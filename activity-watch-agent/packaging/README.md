# Activity Watch employee installers

These assets turn the tested Go binary into a per-user installation. A release
pipeline must compile the SQLCipher-enabled binary on each target OS, place it
beside the platform installer asset, sign the result, and publish it under the
ERP's `ACTIVITY_WATCH_INSTALLER_BASE_URL`.

Each installer performs only these actions in the current user's profile:

1. copy the agent binary;
2. run `bootstrap` to create disabled encrypted storage and register the user
   service;
3. register `.billingawpair` with the pairing handler; and
4. start the disabled service, which collects nothing until pairing succeeds.

Opening a pairing file executes:

```text
activity-watch-agent pair --config <user-config> --bundle <downloaded-file>
```

The agent exchanges the ten-minute token, removes the consumed file, writes the
credential/config with user-only permissions, enables collection, and restarts
the service. Pairing files never contain permanent credentials.

Release signing and native installer construction must run on the target OS:

- macOS: package/notarize the app bundle and installer with Developer ID.
- Windows: wrap `windows/install.ps1` and the binary in a signed MSI.
- Linux: wrap `linux/install.sh`, desktop entry, MIME XML, and binary in signed
  DEB/RPM packages.

For macOS, compile the document handler before packaging:

```bash
swiftc -framework AppKit macos/PairingLauncher.swift \
  -o macos/BillingActivityWatchPair
```
