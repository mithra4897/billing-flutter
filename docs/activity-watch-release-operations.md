# Activity Watch release, installation, and removal operations

## Purpose and scope

Use this guide to build and publish the Windows and macOS Activity Watch
installers, install an internally approved development build from Downloads,
remove an existing agent, and run agent service commands. The public backend
download folder is:

```text
billing-api/public/downloads/activity-watch
```

The backend exposes these exact stable filenames:

| Platform | Published filename |
| --- | --- |
| Windows | `BillingActivityWatch-windows.exe` |
| macOS | `BillingActivityWatch-macos.pkg` |

Do not put pairing tokens, device credentials, database keys, or decrypted
activity data into commands, screenshots, or build logs.

## Windows release build and publish

Build on Windows from PowerShell. The current SQLCipher build requires the
MSYS2 UCRT64 GCC toolchain; see
[Windows developer setup](activity-watch-windows-developer-setup.md) for its
installation.

```powershell
cd "C:\path\to\billing-flutter\activity-watch-agent"
$env:Path = "C:\msys64\ucrt64\bin;C:\Program Files\Go\bin;$env:Path"
$env:CGO_ENABLED = "1"
$env:CC = "gcc"

go test ./...
go vet ./...
.\packaging\windows\build-exe.ps1
```

Move the verified result into the API download folder:

```powershell
$source = ".\packaging\windows\BillingActivityWatch-windows.exe"
$destination = "..\..\billing-api\public\downloads\activity-watch\BillingActivityWatch-windows.exe"

New-Item -ItemType Directory -Force (Split-Path -Parent $destination) | Out-Null
Copy-Item -LiteralPath $source -Destination $destination -Force
Get-FileHash -Algorithm SHA256 $destination
```

For production, code-sign the final EXE and verify its Authenticode signature
before publishing. An unsigned EXE is only appropriate for approved internal
development testing.

## macOS release build and publish

Build on macOS with Go, a C compiler for the SQLCipher CGO dependency, Xcode
Command Line Tools, and the AppKit framework.

```bash
cd "/path/to/billing-flutter/activity-watch-agent"
go test ./...
go vet ./...

stage_dir="$(mktemp -d)"
app="$stage_dir/BillingActivityWatch.app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"

go build -o "$app/Contents/Resources/activity-watch-agent" ./cmd/activity-watch-agent
swiftc -parse-as-library -framework AppKit packaging/macos/PairingLauncher.swift \
  -o "$app/Contents/MacOS/BillingActivityWatch"
chmod 755 "$app/Contents/Resources/activity-watch-agent" \
  "$app/Contents/MacOS/BillingActivityWatch"
```

Create an `Info.plist` for the application bundle with a unique bundle ID and
a `.billingawpair` document type before packaging. Replace the example bundle
identifier with the organization's real identifier.

```bash
plist="$app/Contents/Info.plist"
plutil -create xml1 "$plist"
/usr/libexec/PlistBuddy -c 'Add :CFBundleName string BillingActivityWatch' "$plist"
/usr/libexec/PlistBuddy -c 'Add :CFBundleDisplayName string BillingActivityWatch' "$plist"
/usr/libexec/PlistBuddy -c 'Add :CFBundleIdentifier string com.example.billing.activitywatch' "$plist"
/usr/libexec/PlistBuddy -c 'Add :CFBundleVersion string 1' "$plist"
/usr/libexec/PlistBuddy -c 'Add :CFBundleShortVersionString string 1.0.0' "$plist"
/usr/libexec/PlistBuddy -c 'Add :CFBundlePackageType string APPL' "$plist"
/usr/libexec/PlistBuddy -c 'Add :CFBundleExecutable string BillingActivityWatch' "$plist"
/usr/libexec/PlistBuddy -c 'Add :CFBundleDocumentTypes array' "$plist"
/usr/libexec/PlistBuddy -c 'Add :CFBundleDocumentTypes:0 dict' "$plist"
/usr/libexec/PlistBuddy -c 'Add :CFBundleDocumentTypes:0:CFBundleTypeName string "Activity Watch pairing file"' "$plist"
/usr/libexec/PlistBuddy -c 'Add :CFBundleDocumentTypes:0:CFBundleTypeRole string Editor' "$plist"
/usr/libexec/PlistBuddy -c 'Add :CFBundleDocumentTypes:0:CFBundleTypeExtensions array' "$plist"
/usr/libexec/PlistBuddy -c 'Add :CFBundleDocumentTypes:0:CFBundleTypeExtensions:0 string billingawpair' "$plist"
```

The pairing launcher requires the Go binary to remain at
`BillingActivityWatch.app/Contents/Resources/activity-watch-agent`.
Both bundled executables must be mode `755`: `pkgbuild` installs the app as
`root`, and the enrolled desktop user must be able to start the launcher and
read the bundled agent before it is copied into that user's protected
Application Support directory.

Package the app for the backend's required macOS filename:

```bash
package="$(pwd)/packaging/macos/BillingActivityWatch-macos.pkg"
pkgbuild --install-location /Applications --component "$app" "$package"

mkdir -p ../../billing-api/public/downloads/activity-watch
cp "$package" ../../billing-api/public/downloads/activity-watch/BillingActivityWatch-macos.pkg
shasum -a 256 ../../billing-api/public/downloads/activity-watch/BillingActivityWatch-macos.pkg
```

For production, sign the app with a Developer ID Application certificate, sign
the package with a Developer ID Installer certificate, notarize it, and staple
the notarization ticket. Do not distribute an unsigned build outside the
approved internal development environment.

## macOS unsigned-development install from Downloads

Use this only after verifying the package hash from a trusted internal release.
Do not disable Gatekeeper globally.

First try Finder: Control-click the package in **Downloads**, choose **Open**,
then confirm the one-time warning. If Gatekeeper still blocks the known internal
package, remove only that package's quarantine attribute and install it:

```bash
package="$HOME/Downloads/BillingActivityWatch-macos.pkg"
shasum -a 256 "$package"
xattr -dr com.apple.quarantine "$package"
sudo installer -pkg "$package" -target /
```

This does not bypass signing for other applications. It only removes the
download-quarantine attribute from the exact package path provided. After
installation, open ERP, create a fresh pairing file, and open that file before
it expires.

## macOS pairing recovery when file association fails

If Finder reports that the pairing-file format cannot be opened, or the app
opens without pairing, do not reveal the pairing-file contents. Use the
installed agent directly with the fresh downloaded file:

```bash
agent="$HOME/Library/Application Support/BillingActivityWatch/activity-watch-agent"
config="$HOME/Library/Application Support/BillingActivityWatch/activity-watch-agent.config.json"
bundle="$HOME/Downloads/<fresh-pairing-file>.billingawpair"

"$agent" pair --config "$config" --bundle "$bundle"
"$agent" status --config "$config"
```

On success, the command prints `Activity Watch connected: <device-id>` and
removes the one-time pairing file. If it returns an error, share only the error
message with support—never the pairing file or configuration file. This command
is a pairing fallback, not a security bypass.

## Backend download configuration and verification

Set the backend configuration to the public URL containing the files above:

```text
ACTIVITY_WATCH_AGENT_API_BASE_URL=https://erp.example.com/api/v1
ACTIVITY_WATCH_INSTALLER_BASE_URL=https://erp.example.com/downloads/activity-watch
```

The backend adds a file-modification-time `v` parameter to the returned
installer URL. Verify both published artifacts after every release:

```bash
curl -I "https://erp.example.com/downloads/activity-watch/BillingActivityWatch-windows.exe"
curl -I "https://erp.example.com/downloads/activity-watch/BillingActivityWatch-macos.pkg"
```

## Agent command reference

Every command requires an absolute configuration path. `pair` additionally
requires an absolute path to a fresh `.billingawpair` file.

```text
activity-watch-agent bootstrap --config /absolute/path/config.json
activity-watch-agent provision --config /absolute/path/config.json
activity-watch-agent pair --config /absolute/path/config.json --bundle /absolute/path/device.billingawpair
activity-watch-agent install --config /absolute/path/config.json
activity-watch-agent start --config /absolute/path/config.json
activity-watch-agent stop --config /absolute/path/config.json
activity-watch-agent restart --config /absolute/path/config.json
activity-watch-agent status --config /absolute/path/config.json
activity-watch-agent uninstall --config /absolute/path/config.json
activity-watch-agent run --config /absolute/path/config.json
activity-watch-agent signal-logout --config /absolute/path/config.json
```

`bootstrap` creates an unpaired configuration. `provision` creates a new local
encrypted database/key pair and must not be used over an existing paired store.
`pair` consumes its one-time pairing file, provisions storage if required, and
activates the service. `signal-logout` is the ERP-triggered synchronization
boundary; it is not an employee command. `run` is for foreground development.

## Remove an existing Windows agent

Run these commands as the enrolled Windows user. The service commands stop and
unregister the agent; deleting the installation root permanently removes the
encrypted local queue and requires a new ERP pairing.

```powershell
$root = Join-Path $env:LOCALAPPDATA 'BillingActivityWatch'
$agent = Join-Path $root 'activity-watch-agent.exe'
$config = Join-Path $root 'activity-watch-agent.config.json'

if (Test-Path -LiteralPath $agent) {
  & $agent stop --config $config
  & $agent uninstall --config $config
}
schtasks.exe /Delete /TN "BillingActivityWatch" /F
Remove-Item -LiteralPath $root -Recurse -Force
reg.exe delete "HKCU\Software\Classes\.billingawpair" /f
reg.exe delete "HKCU\Software\Classes\BillingActivityWatch.PairingFile" /f
```

`schtasks.exe` or `reg.exe` may report that a value does not exist on a partial
installation; confirm the agent directory is gone before reinstalling.

## Remove an existing macOS agent

Run these commands as the enrolled macOS user. The first two commands ask the
agent's service manager to stop and unregister the service. Removing the
Application Support directory permanently removes its encrypted local queue and
requires a new ERP pairing.

```bash
root="$HOME/Library/Application Support/BillingActivityWatch"
agent="$root/activity-watch-agent"
config="$root/activity-watch-agent.config.json"

if [ -x "$agent" ]; then
  "$agent" stop --config "$config" || true
  "$agent" uninstall --config "$config" || true
fi
rm -rf "$root"
sudo rm -rf "/Applications/BillingActivityWatch.app"
```

Remove only the exact paths above. Do not delete the broader `~/Library` or
`/Applications` directories. A production-managed Mac may require an
administrator to remove the application package.

## Acceptance and support checks

- Windows and macOS artifacts use the backend's exact public filenames.
- The API download folder contains the new artifact before the corresponding
  pairing flow is tested.
- Internal unsigned macOS testing verifies the trusted SHA-256 before applying
  the per-package `xattr` command.
- A clean reinstall creates a new pairing file; an old pairing file is never
  reused.
- Removing a paired agent is treated as destructive local data removal and is
  confirmed before the installation root is deleted.
