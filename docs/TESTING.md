# Testing

## Standard commands

Run from `billing-flutter`:

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

## Activity Watch persistence

Focused command:

```bash
flutter test test/core/activity_watch
```

Coverage includes:

- SQLCipher runtime verification;
- exact schema table and index inventory;
- correct-key reopen and wrong-key rejection;
- foreign-key and CHECK constraints;
- transaction commit and rollback;
- key generation and persistence with a fake secure store;
- AES-256-GCM authenticated payload encryption; and
- keyed HMAC stability and key separation.

## Manual/native verification still required

- Build and open the database on Windows, Linux, Android, and iOS hardware or
  supported virtual environments.
- Confirm platform secure-storage behavior and uninstall/reinstall semantics.
- Confirm release signing and SQLCipher artifact licensing.
- Test corrupted database and lost-key operational workflows.
- Verify database directory permissions on every supported OS.

Do not interpret a macOS unit-test pass as proof that every native platform has
been packaged successfully.

