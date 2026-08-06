import 'dart:typed_data';

import 'package:sqlite3/sqlite3.dart';

import 'activity_watch_schema.dart';

enum ActivityWatchDatabaseErrorCode {
  invalidKey,
  cipherUnavailable,
  openFailed,
  integrityCheckFailed,
  unsupportedSchema,
  migrationFailed,
  closed,
}

final class ActivityWatchDatabaseException implements Exception {
  const ActivityWatchDatabaseException(this.code, this.message);

  final ActivityWatchDatabaseErrorCode code;
  final String message;

  @override
  String toString() => 'ActivityWatchDatabaseException($code): $message';
}

final class ActivityWatchDatabase {
  ActivityWatchDatabase._(this._database, this.cipherVersion);

  final Database _database;
  final String cipherVersion;
  bool _closed = false;

  static ActivityWatchDatabase open({
    required String path,
    required List<int> key,
  }) {
    return _open(sqlite3.open(path), key);
  }

  static ActivityWatchDatabase openInMemory({required List<int> key}) {
    return _open(sqlite3.openInMemory(), key);
  }

  static ActivityWatchDatabase _open(Database database, List<int> key) {
    if (key.length != 32) {
      database.close();
      throw const ActivityWatchDatabaseException(
        ActivityWatchDatabaseErrorCode.invalidKey,
        'The database encryption key must contain exactly 32 bytes.',
      );
    }

    final keyCopy = Uint8List.fromList(key);
    try {
      final keyHex = _toHex(keyCopy);
      database.execute('PRAGMA key = "x\'$keyHex\'"');
      database.execute('PRAGMA cipher_compatibility = 4');

      final cipherRows = database.select('PRAGMA cipher_version');
      final cipherVersion = cipherRows.isEmpty
          ? ''
          : cipherRows.first.values.first?.toString().trim() ?? '';
      if (cipherVersion.isEmpty) {
        throw const ActivityWatchDatabaseException(
          ActivityWatchDatabaseErrorCode.cipherUnavailable,
          'The bundled SQLite runtime does not provide SQLCipher.',
        );
      }

      // This read authenticates an existing database before any migration.
      database.select('SELECT count(*) FROM sqlite_master');
      database.execute('PRAGMA foreign_keys = ON');
      database.execute('PRAGMA secure_delete = ON');
      database.execute('PRAGMA synchronous = FULL');
      database.execute('PRAGMA busy_timeout = 5000');
      database.execute('PRAGMA journal_mode = WAL');

      if (database.userVersion > 0) {
        _verifyIntegrity(database);
      }
      _migrate(database);
      return ActivityWatchDatabase._(database, cipherVersion);
    } on ActivityWatchDatabaseException {
      database.close();
      rethrow;
    } on SqliteException {
      database.close();
      throw const ActivityWatchDatabaseException(
        ActivityWatchDatabaseErrorCode.openFailed,
        'The encrypted Activity Watch database could not be opened.',
      );
    } on Object {
      database.close();
      throw const ActivityWatchDatabaseException(
        ActivityWatchDatabaseErrorCode.openFailed,
        'Activity Watch database initialization failed.',
      );
    } finally {
      keyCopy.fillRange(0, keyCopy.length, 0);
    }
  }

  static void _verifyIntegrity(Database database) {
    final rows = database.select('PRAGMA cipher_integrity_check');
    if (rows.isEmpty) {
      return;
    }
    final results = rows
        .expand((row) => row.values)
        .whereType<Object>()
        .map((value) => value.toString().toLowerCase())
        .toList(growable: false);
    if (results.any((value) => value != 'ok')) {
      throw const ActivityWatchDatabaseException(
        ActivityWatchDatabaseErrorCode.integrityCheckFailed,
        'The encrypted Activity Watch database failed its integrity check.',
      );
    }
  }

  static void _migrate(Database database) {
    final currentVersion = database.userVersion;
    if (currentVersion > ActivityWatchSchema.version) {
      throw ActivityWatchDatabaseException(
        ActivityWatchDatabaseErrorCode.unsupportedSchema,
        'Database schema version $currentVersion is newer than supported '
        'version ${ActivityWatchSchema.version}.',
      );
    }
    if (currentVersion == ActivityWatchSchema.version) {
      return;
    }

    database.execute('BEGIN IMMEDIATE');
    try {
      if (currentVersion == 0) {
        for (final statement in ActivityWatchSchema.createStatements) {
          database.execute(statement);
        }
      }
      database.userVersion = ActivityWatchSchema.version;
      database.execute('COMMIT');
    } on Object {
      if (!database.autocommit) {
        database.execute('ROLLBACK');
      }
      throw const ActivityWatchDatabaseException(
        ActivityWatchDatabaseErrorCode.migrationFailed,
        'The Activity Watch database schema migration failed.',
      );
    }
  }

  ResultSet select(String sql, [List<Object?> parameters = const <Object?>[]]) {
    _assertOpen();
    return _database.select(sql, parameters);
  }

  void execute(String sql, [List<Object?> parameters = const <Object?>[]]) {
    _assertOpen();
    _database.execute(sql, parameters);
  }

  T transaction<T>(T Function(Database database) operation) {
    _assertOpen();
    _database.execute('BEGIN IMMEDIATE');
    try {
      final result = operation(_database);
      _database.execute('COMMIT');
      return result;
    } on Object {
      if (!_database.autocommit) {
        _database.execute('ROLLBACK');
      }
      rethrow;
    }
  }

  int get schemaVersion {
    _assertOpen();
    return _database.userVersion;
  }

  void close() {
    if (_closed) {
      return;
    }
    _closed = true;
    _database.close();
  }

  void _assertOpen() {
    if (_closed) {
      throw const ActivityWatchDatabaseException(
        ActivityWatchDatabaseErrorCode.closed,
        'The Activity Watch database is closed.',
      );
    }
  }

  static String _toHex(List<int> bytes) =>
      bytes.map((value) => value.toRadixString(16).padLeft(2, '0')).join();
}
