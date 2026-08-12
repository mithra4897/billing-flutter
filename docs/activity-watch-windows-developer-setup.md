# Activity Watch Windows developer setup

## Purpose

This guide prepares a Windows development computer to build, package, publish,
install, and pair the standalone Activity Watch agent. It covers the native Go
agent only; building the Flutter ERP application is a separate workflow.

## Toolchain overview

The Windows agent combines several tools:

| Tool | Responsibility |
| --- | --- |V
| Go | Builds the Activity Watch application and service logic. |
| CGO | Connects Go to the embedded native SQLCipher implementation. |
| MSYS2 UCRT64 GCC | Compiles SQLCipher and other CGO C sources for 64-bit Windows. |
| .NET Framework C# compiler | Creates the single self-contained Windows installer EXE. |

Visual Studio C++ is not the compiler used by the current agent build. MSVC's
`cl.exe` rejects GCC-style flags emitted by the SQLCipher/CGO build, including
`-Werror`. The supported Windows build therefore uses
`C:\msys64\ucrt64\bin\gcc.exe`.

MSYS2 is the installed development environment. UCRT64 is its 64-bit Windows
GCC toolchain and runtime. The “MSYS2 UCRT64” window is a terminal that starts
with this toolchain already on `PATH`.

## Prerequisites

Install:

1. 64-bit Windows 10 or Windows 11.
2. Go matching the version supported by `activity-watch-agent/go.mod`.
3. MSYS2 with the UCRT64 GCC package.
4. Windows .NET Framework C# compiler.
5. Git and PowerShell.

Go and MSYS2 can be installed with Windows Package Manager:

```powershell
winget install -e --id GoLang.Go
winget install -e --id MSYS2.MSYS2
```

Close and reopen terminals after installation.

## Install UCRT64 GCC

Open **MSYS2 UCRT64** from the Start menu, or launch it from PowerShell:

```powershell
C:\msys64\ucrt64.exe
```

Inside the UCRT64 terminal, update MSYS2:

```bash
pacman -Syu
```

If MSYS2 asks to close the terminal, close it, reopen **MSYS2 UCRT64**, and run:

```bash
pacman -Syu
pacman -S --needed mingw-w64-ucrt-x86_64-gcc
gcc --version
```

`pacman` is available only inside an MSYS2 terminal unless its executable is
manually added to another shell's `PATH`.

## Verify the toolchain in PowerShell

The build can run in normal PowerShell after adding Go and UCRT64 GCC to the
current process:

```powershell
$env:Path = "C:\msys64\ucrt64\bin;C:\Program Files\Go\bin;$env:Path"
$env:CGO_ENABLED = "1"
$env:CC = "gcc"

go version
gcc --version
go env CGO_ENABLED CC
Test-Path "$env:WINDIR\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
```

Expected results:

- `go version` reports `windows/amd64`;
- `gcc --version` reports the MSYS2 UCRT64 build;
- `CGO_ENABLED` is `1`;
- `CC` is `gcc`; and
- the C# compiler path check returns `True`.

These environment values affect only the current PowerShell process. Set them
again in a new terminal or add the required `bin` directories to the developer's
user `PATH`.

## Build and test the agent

Open PowerShell in the agent module, not the `billing-flutter` repository root:

```powershell
cd "C:\path\to\billing software\billing-flutter\activity-watch-agent"

$env:Path = "C:\msys64\ucrt64\bin;C:\Program Files\Go\bin;$env:Path"
$env:CGO_ENABLED = "1"
$env:CC = "gcc"

go test ./...
go vet ./...
go build -o .\activity-watch-agent.exe .\cmd\activity-watch-agent
```

SQLCipher may emit compiler warnings from its generated `sqlite3.c`. Warnings
alone do not mean the build failed. A successful `go build` returns to the
prompt with exit code zero and creates `activity-watch-agent.exe`.

## Build the Windows installer

From `billing-flutter/activity-watch-agent`, run:

```powershell
$env:Path = "C:\msys64\ucrt64\bin;C:\Program Files\Go\bin;$env:Path"
$env:CGO_ENABLED = "1"
$env:CC = "gcc"

.\packaging\windows\build-exe.ps1
```

The script:

1. builds the SQLCipher-enabled Go agent;
2. embeds the agent and `install.ps1` in a small .NET Framework launcher;
3. creates one employee-facing installer; and
4. reports the output path.

Output:

```text
activity-watch-agent\packaging\windows\BillingActivityWatch-windows.exe
```

The current package does not use IExpress or MakeCAB.

Verify the artifact before publishing:

```powershell
$artifact = ".\packaging\windows\BillingActivityWatch-windows.exe"
Get-Item $artifact | Select-Object FullName, Length, LastWriteTime
Get-FileHash -Algorithm SHA256 $artifact
Get-AuthenticodeSignature $artifact
```

Development artifacts may show `NotSigned`. Production artifacts must be code
signed before employee distribution.

## Publish through the API

Copy the verified artifact to the backend's stable public filename:

```powershell
$source = ".\packaging\windows\BillingActivityWatch-windows.exe"
$target = "..\..\billing-api\public\downloads\activity-watch\BillingActivityWatch-windows.exe"
Copy-Item -LiteralPath $source -Destination $target -Force
Get-FileHash -Algorithm SHA256 $target
```

Upload that backend file to the corresponding production directory:

```text
public/downloads/activity-watch/BillingActivityWatch-windows.exe
```

Configure the backend:

```text
ACTIVITY_WATCH_AGENT_API_BASE_URL=https://erp.example.com/api/v1
ACTIVITY_WATCH_INSTALLER_BASE_URL=https://erp.example.com/downloads/activity-watch
```

`ActivityWatchController` appends the published file modification time as a
`v` query parameter. This gives browsers and CDNs a new cache key when the
stable installer file is replaced.

Verify the live file's size and hash rather than relying on its filename:

```powershell
curl.exe -I "https://erp.example.com/downloads/activity-watch/BillingActivityWatch-windows.exe"
```

If a browser still downloads an old file, add a temporary version query such
as `?v=<release-hash-prefix>` and clear the browser/CDN cache.

## Employee installation and pairing

The Windows installer:

1. copies the agent to `%LOCALAPPDATA%\BillingActivityWatch`;
2. registers `.billingawpair` for the current user; and
3. instructs the employee to return to ERP.

The installer does not display a normal application window after completion.
Activity Watch is a background agent.

In ERP:

1. open **Settings → Activity Watch**;
2. accept consent and click **Connect this computer**;
3. download a new pairing file;
4. open the `.billingawpair` file within its displayed expiry time; and
5. refresh the Devices card and confirm **Connected**.

Opening the pairing file automatically bootstraps encrypted local storage when
needed, exchanges the one-time token, deletes the consumed pairing file, saves
the protected device credential, enables collection, and starts the background
agent.

Expired pairing rows cannot be reused. Create a new pairing session and open
only its newest downloaded pairing file.

## Current Windows scheduled-task limitation

The current agent registers `BillingActivityWatch` with Windows Task Scheduler
after pairing. Some Windows policies deny standard users permission to create
this task and return:

```text
create Windows Activity Watch task: exit status 1: ERROR: Access is denied.
```

The server exchange and local configuration may already be complete before
this final startup step fails. Do not create another pairing session solely for
this error. Open PowerShell as Administrator and run:

```powershell
$agent = "$env:LOCALAPPDATA\BillingActivityWatch\activity-watch-agent.exe"
$config = "$env:LOCALAPPDATA\BillingActivityWatch\activity-watch-agent.config.json"
$action = "`"$agent`" run --config `"$config`""

schtasks.exe /Create `
  /TN "BillingActivityWatch" `
  /SC ONLOGON `
  /TR $action `
  /RL LIMITED `
  /F

schtasks.exe /Run /TN "BillingActivityWatch"
schtasks.exe /Query /TN "BillingActivityWatch" /FO LIST /V
```

This elevation requirement is a known release limitation. Before broad
employee distribution, replace it with a verified non-admin per-user startup
mechanism or document administrator-assisted installation as an explicit
deployment requirement.

## Verification

Verify the installation without reading or printing secret files:

```powershell
Test-Path "$env:LOCALAPPDATA\BillingActivityWatch\activity-watch-agent.exe"
reg.exe query "HKCU\Software\Classes\.billingawpair" /ve
reg.exe query "HKCU\Software\Classes\BillingActivityWatch.PairingFile\shell\open\command" /ve
schtasks.exe /Query /TN "BillingActivityWatch" /FO LIST /V
```

In ERP, confirm:

- the device state is **Connected**;
- `last_seen_at` begins updating;
- daily summaries appear after collection/synchronization; and
- selecting an employee filters to that employee's assigned devices.

Never print pairing tokens, device credentials, SQLCipher keys, decrypted
payloads, URLs visited by employees, or personal activity content during
verification.

## Troubleshooting

### `go: go.mod file not found`

The terminal is in the wrong directory. Change to:

```text
billing-flutter\activity-watch-agent
```

### `go: command not found`

Add Go to the current shell:

```bash
export PATH="/c/Program Files/Go/bin:$PATH"
```

or in PowerShell:

```powershell
$env:Path = "C:\Program Files\Go\bin;$env:Path"
```

### `pacman` is not recognized

Open the **MSYS2 UCRT64** terminal. `pacman` is not a normal PowerShell command.

### `C compiler "cl" not found` or invalid `/Werror`

Do not set `CC=cl`. Use UCRT64 GCC:

```powershell
$env:Path = "C:\msys64\ucrt64\bin;$env:Path"
$env:CGO_ENABLED = "1"
$env:CC = "gcc"
```

### IExpress or MakeCAB errors

The current packaging script no longer uses IExpress. Ensure the checkout has
the current `packaging/windows/build-exe.ps1` and rebuild.

### Installer runs but no application window opens

This is expected. Verify the installed binary and pairing-file association,
then pair through ERP.

### Pairing-session API returns HTTP 500

Confirm the deployed Lumen controller uses:

```php
base_path('public/downloads/activity-watch/' . $file)
```

It must not call Laravel's unavailable `public_path()` helper.

### Device remains `Pairing expired`

That row represents an old one-time token. Create a fresh pairing session and
open its newest pairing file before the displayed expiration time.

## Release checklist

- Run `go test ./...` and `go vet ./...` with CGO enabled.
- Build the agent and self-contained installer on Windows.
- Record installer size, SHA-256, and build source revision.
- Test installation and pairing on a clean standard-user account.
- Verify current-user file association and login startup.
- Verify encrypted database creation and background synchronization.
- Confirm the backend serves the new artifact and cache-versioned URL.
- Code-sign the installer and verify its Authenticode signature.
- Retain no pairing token, device credential, or database key in build logs.

