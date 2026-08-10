# Activity Watch `bill.local` HTTP development exception

Status: Implemented (2026-08-10)

## Objective

Allow the development Activity Watch build to pair with and upload to the
approved internal development servers at `http://bill.local/...` and
`http://192.168.31.83:8000/...` before internal HTTPS is available.

## Scope and security requirements

- Accept HTTP only when the parsed hostname is exactly `bill.local` or
  `192.168.31.83`.
- Apply the exception to both pairing-bundle URLs and the paired sync endpoint.
- Continue to allow loopback HTTP and require HTTPS for every other hostname.
- Do not change pairing tokens, credentials, storage encryption, API routes, or
  server authorization.
- This is a development-only exception. HTTP exposes pairing tokens and device
  credentials to parties able to observe the local network; replace it with
  HTTPS before wider deployment.

## Acceptance criteria

- `http://bill.local/...` and `http://192.168.31.83:8000/...` pass pairing and
  sync URL validation.
- Another remote HTTP hostname continues to fail validation.
- HTTPS endpoints and loopback HTTP remain compatible.

## Verification

- Run the focused configuration and pairing Go tests, then the complete Go
  test suite and vet check.
- Build the Windows agent on Windows with its required CGO/SQLCipher toolchain
  before manual installation testing.

## Verification

- Focused configuration and pairing tests passed.
- `go test ./...` and `go vet ./...` passed on macOS.
- A Windows x64 build was attempted but cannot be produced on this macOS host:
  the required Windows CGO headers/toolchain (including `windows.h`) are not
  installed. Build the release EXE on Windows with a compatible C compiler and
  SQLCipher dependencies, then package it with `packaging/windows/install.ps1`.
