# Production Verification — 2026-08-05

**Status:** Ready for deployment; not uploaded

## Scope

Verify the lazy master-data startup change, same-session master-data mutation
updates, and the Flutter web production bundle.

## Results

- Live branding API returned HTTP 200 at
  `https://bill.sakthicontroller.com/api/public/api/v1/public/branding`.
- Full Flutter test suite passed: 22 tests.
- Master-data tests verify both insertion and update of models in an already
  loaded cache, and verify that an unloaded cache remains lazy.
- Targeted static analysis passed with no issues.
- Production web build completed successfully using:

  ```bash
  flutter build web --release --no-wasm-dry-run \
    --dart-define=API_BASE_URL=https://bill.sakthicontroller.com/api/public
  ```

- The generated `build/web/main.dart.js` contains the intended production API
  base URL.
- After the sales lookup freshness fix, the full suite and production bundle
  were run again successfully.

## Deployment Handoff

The verified artifact is `billing-flutter/build/web/`. The repository contains
a workspace SFTP configuration at `.vscode/sftp.json` for the authorized
production target. Open `billing-flutter` as the VS Code workspace, build the
web bundle, then use the SFTP extension's **Upload Folder** command for
`build/web`. The configured target is `~/public_html/bill/` on port `65002`.

The configuration never stores a password or private key and leaves automatic
upload disabled. Configure authentication only in the developer's local SFTP
extension settings or SSH agent. After upload, smoke-test login, dashboard
startup, master create/update, browser refresh, Clear Cache, and database
backup download.
