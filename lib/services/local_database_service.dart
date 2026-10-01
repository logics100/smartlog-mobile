import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart' as mobile_sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class LocalDatabaseService {
  static Database? _database;

  // ===========================================================================
  // DATABASE VERSION
  // ===========================================================================

  static const int _databaseVersion = 4;

  // ===========================================================================
  // DATABASE ACCESS
  // ===========================================================================

  static Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();

    return _database!;
  }

  static Future<Database> _initDatabase() async {
    if (Platform.isWindows || Platform.isLinux) {
      // Windows/Linux desktop SQLite.
      sqfliteFfiInit();

      databaseFactory = databaseFactoryFfi;

      final databasePath = await databaseFactory.getDatabasesPath();

      final path = join(databasePath, 'smartlog_local.db');

      return databaseFactory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: _databaseVersion,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        ),
      );
    }

    // Android/iOS SQLite.
    final databasePath = await mobile_sqflite.getDatabasesPath();

    final path = join(databasePath, 'smartlog_local.db');

    return mobile_sqflite.openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // ===========================================================================
  // DATABASE CREATION
  // ===========================================================================

  static Future<void> _onCreate(Database db, int version) async {
    await _createOfflineAttendanceTable(db);

    await _createOfflineClinicalEntriesTable(db);

    await _createStudentLogbooksCacheTable(db);

    await _createLogbookDetailsCacheTable(db);

    await _createAttendanceRecordsCacheTable(db);

    await _createClinicalEntriesCacheTable(db);
  }

  // ===========================================================================
  // TABLE CREATION HELPERS
  // ===========================================================================

  static Future<void> _createOfflineAttendanceTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS offline_attendance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id INTEGER,
        logbook_id INTEGER NOT NULL,
        attendance_date TEXT NOT NULL,
        facility_name TEXT NOT NULL,
        clinical_unit TEXT NOT NULL,
        start_time TEXT NOT NULL,
        finish_time TEXT NOT NULL,
        total_hours REAL,
        sync_status TEXT NOT NULL DEFAULT 'PENDING_SYNC',
        sync_error TEXT,
        created_at TEXT NOT NULL
      )
      ''');
  }

  static Future<void> _createOfflineClinicalEntriesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS offline_clinical_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id INTEGER,
        logbook_id INTEGER NOT NULL,
        logbook_item_id INTEGER NOT NULL,
        requirement_id INTEGER,
        activity_date TEXT NOT NULL,
        activity_time TEXT,
        facility_name TEXT NOT NULL,
        clinical_area TEXT,
        activity_details TEXT,
        sync_status TEXT NOT NULL DEFAULT 'PENDING_SYNC',
        sync_error TEXT,
        created_at TEXT NOT NULL
      )
      ''');
  }

  static Future<void> _createStudentLogbooksCacheTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cached_student_logbooks (
        id INTEGER PRIMARY KEY,
        data TEXT NOT NULL,
        cached_at TEXT NOT NULL
      )
      ''');
  }

  static Future<void> _createLogbookDetailsCacheTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cached_logbook_details (
        logbook_id INTEGER PRIMARY KEY,
        data TEXT NOT NULL,
        cached_at TEXT NOT NULL
      )
      ''');
  }

  static Future<void> _createAttendanceRecordsCacheTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cached_attendance_records (
        server_id INTEGER PRIMARY KEY,
        logbook_id INTEGER NOT NULL,
        data TEXT NOT NULL,
        cached_at TEXT NOT NULL
      )
      ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS
      idx_cached_attendance_logbook
      ON cached_attendance_records(logbook_id)
      ''');
  }

  static Future<void> _createClinicalEntriesCacheTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cached_clinical_entries (
        server_id INTEGER PRIMARY KEY,
        logbook_id INTEGER NOT NULL,
        data TEXT NOT NULL,
        cached_at TEXT NOT NULL
      )
      ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS
      idx_cached_clinical_entries_logbook
      ON cached_clinical_entries(logbook_id)
      ''');
  }

  // ===========================================================================
  // DATABASE UPGRADES
  // ===========================================================================

  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    /*
    |--------------------------------------------------------------------------
    | Existing development installations
    |--------------------------------------------------------------------------
    |
    | Earlier SmartLog versions may already contain some tables while others
    | may be missing. CREATE TABLE IF NOT EXISTS is therefore used so that
    | upgrading does not delete existing offline records or cached logbooks.
    |
    */

    if (oldVersion < 3) {
      await _createStudentLogbooksCacheTable(db);

      await _createLogbookDetailsCacheTable(db);

      await _createOfflineAttendanceTable(db);

      await _createOfflineClinicalEntriesTable(db);
    }

    /*
    |--------------------------------------------------------------------------
    | Version 4
    |--------------------------------------------------------------------------
    |
    | Version 4 adds dedicated caches for records downloaded from Laravel.
    |
    | These tables are deliberately separate from:
    |
    |   offline_attendance
    |   offline_clinical_entries
    |
    | because those two tables are synchronization queues for records created
    | while offline.
    |
    | Server records cached here must never become PENDING_SYNC records.
    |
    */

    if (oldVersion < 4) {
      await _createAttendanceRecordsCacheTable(db);

      await _createClinicalEntriesCacheTable(db);
    }
  }

  // ===========================================================================
  // OFFLINE ATTENDANCE
  // ===========================================================================

  static Future<int> saveOfflineAttendance({
    required int logbookId,
    required String attendanceDate,
    required String facilityName,
    required String clinicalUnit,
    required String startTime,
    required String finishTime,
    double? totalHours,
  }) async {
    final db = await database;

    return db.insert('offline_attendance', {
      'server_id': null,
      'logbook_id': logbookId,
      'attendance_date': attendanceDate,
      'facility_name': facilityName,
      'clinical_unit': clinicalUnit,
      'start_time': startTime,
      'finish_time': finishTime,
      'total_hours': totalHours,
      'sync_status': 'PENDING_SYNC',
      'sync_error': null,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<List<Map<String, dynamic>>> getPendingAttendance() async {
    final db = await database;

    return db.query(
      'offline_attendance',
      where: 'sync_status = ?',
      whereArgs: ['PENDING_SYNC'],
      orderBy: 'id ASC',
    );
  }

  static Future<List<Map<String, dynamic>>> getAllOfflineAttendance() async {
    final db = await database;

    return db.query('offline_attendance', orderBy: 'id DESC');
  }

  static Future<void> markAttendanceSynced({
    required int localId,
    required int serverId,
  }) async {
    final db = await database;

    await db.update(
      'offline_attendance',
      {'server_id': serverId, 'sync_status': 'SYNCED', 'sync_error': null},
      where: 'id = ?',
      whereArgs: [localId],
    );
  }

  static Future<void> markAttendanceSyncFailed({
    required int localId,
    required String error,
  }) async {
    final db = await database;

    await db.update(
      'offline_attendance',
      {'sync_status': 'PENDING_SYNC', 'sync_error': error},
      where: 'id = ?',
      whereArgs: [localId],
    );
  }

  // ===========================================================================
  // OFFLINE CLINICAL ENTRIES
  // ===========================================================================

  static Future<int> saveOfflineClinicalEntry({
    required int logbookId,
    required int logbookItemId,
    int? requirementId,
    required String activityDate,
    String? activityTime,
    required String facilityName,
    String? clinicalArea,
    String? activityDetails,
  }) async {
    final db = await database;

    return db.insert('offline_clinical_entries', {
      'server_id': null,
      'logbook_id': logbookId,
      'logbook_item_id': logbookItemId,
      'requirement_id': requirementId,
      'activity_date': activityDate,
      'activity_time': activityTime,
      'facility_name': facilityName,
      'clinical_area': clinicalArea,
      'activity_details': activityDetails,
      'sync_status': 'PENDING_SYNC',
      'sync_error': null,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<List<Map<String, dynamic>>> getPendingClinicalEntries() async {
    final db = await database;

    return db.query(
      'offline_clinical_entries',
      where: 'sync_status = ?',
      whereArgs: ['PENDING_SYNC'],
      orderBy: 'id ASC',
    );
  }

  static Future<List<Map<String, dynamic>>>
  getAllOfflineClinicalEntries() async {
    final db = await database;

    return db.query('offline_clinical_entries', orderBy: 'id DESC');
  }

  static Future<void> markClinicalEntrySynced({
    required int localId,
    required int serverId,
  }) async {
    final db = await database;

    await db.update(
      'offline_clinical_entries',
      {'server_id': serverId, 'sync_status': 'SYNCED', 'sync_error': null},
      where: 'id = ?',
      whereArgs: [localId],
    );
  }

  static Future<void> markClinicalEntrySyncFailed({
    required int localId,
    required String error,
  }) async {
    final db = await database;

    await db.update(
      'offline_clinical_entries',
      {'sync_status': 'PENDING_SYNC', 'sync_error': error},
      where: 'id = ?',
      whereArgs: [localId],
    );
  }

  // ===========================================================================
  // STUDENT LOGBOOK CACHE
  // ===========================================================================

  static Future<void> cacheStudentLogbooks(List<dynamic> logbooks) async {
    final db = await database;

    await db.transaction((txn) async {
      await txn.delete('cached_student_logbooks');

      for (final rawLogbook in logbooks) {
        if (rawLogbook is! Map) {
          continue;
        }

        final logbook = Map<String, dynamic>.from(rawLogbook);

        final id = int.tryParse(logbook['id']?.toString() ?? '');

        if (id == null) {
          continue;
        }

        await txn.insert('cached_student_logbooks', {
          'id': id,
          'data': jsonEncode(logbook),
          'cached_at': DateTime.now().toIso8601String(),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  static Future<List<dynamic>> getCachedStudentLogbooks() async {
    final db = await database;

    final rows = await db.query('cached_student_logbooks', orderBy: 'id ASC');

    final List<dynamic> logbooks = [];

    for (final row in rows) {
      final rawData = row['data']?.toString();

      if (rawData == null || rawData.isEmpty) {
        continue;
      }

      try {
        final decoded = jsonDecode(rawData);

        if (decoded is Map) {
          logbooks.add(Map<String, dynamic>.from(decoded));
        }
      } catch (_) {
        // Ignore invalid cached record.
      }
    }

    return logbooks;
  }

  // ===========================================================================
  // LOGBOOK DETAIL CACHE
  // ===========================================================================

  static Future<void> cacheLogbookDetails({
    required int logbookId,
    required Map<String, dynamic> data,
  }) async {
    final db = await database;

    await db.insert('cached_logbook_details', {
      'logbook_id': logbookId,
      'data': jsonEncode(data),
      'cached_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<Map<String, dynamic>?> getCachedLogbookDetails(
    int logbookId,
  ) async {
    final db = await database;

    final rows = await db.query(
      'cached_logbook_details',
      where: 'logbook_id = ?',
      whereArgs: [logbookId],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    final rawData = rows.first['data']?.toString();

    if (rawData == null || rawData.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(rawData);

      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  // ===========================================================================
  // ATTENDANCE SERVER CACHE
  // ===========================================================================

  static Future<void> cacheAttendanceRecords({
    required int logbookId,
    required List<dynamic> records,
  }) async {
    final db = await database;

    final cachedAt = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      /*
        Delete only the cached server records belonging
        to this logbook.

        This does NOT touch offline_attendance.
        */
      await txn.delete(
        'cached_attendance_records',
        where: 'logbook_id = ?',
        whereArgs: [logbookId],
      );

      for (final rawRecord in records) {
        if (rawRecord is! Map) {
          continue;
        }

        final record = Map<String, dynamic>.from(rawRecord);

        final serverId = int.tryParse(record['id']?.toString() ?? '');

        if (serverId == null) {
          continue;
        }

        await txn.insert('cached_attendance_records', {
          'server_id': serverId,
          'logbook_id': logbookId,
          'data': jsonEncode(record),
          'cached_at': cachedAt,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  static Future<List<dynamic>> getCachedAttendanceRecords(int logbookId) async {
    final db = await database;

    final rows = await db.query(
      'cached_attendance_records',
      where: 'logbook_id = ?',
      whereArgs: [logbookId],
      orderBy: 'server_id DESC',
    );

    final List<dynamic> records = [];

    for (final row in rows) {
      final rawData = row['data']?.toString();

      if (rawData == null || rawData.isEmpty) {
        continue;
      }

      try {
        final decoded = jsonDecode(rawData);

        if (decoded is Map) {
          final record = Map<String, dynamic>.from(decoded);

          /*
          This record came from the Laravel server,
          even though it is currently being read
          from the local SQLite cache.
          */
          record['is_local'] = false;

          records.add(record);
        }
      } catch (_) {
        // Ignore invalid cached record.
      }
    }

    return records;
  }

  // ===========================================================================
  // CLINICAL ENTRIES SERVER CACHE
  // ===========================================================================

  static Future<void> cacheClinicalEntries({
    required int logbookId,
    required List<dynamic> entries,
  }) async {
    final db = await database;

    final cachedAt = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      /*
        Delete only server-cache records for
        this particular logbook.

        This does NOT touch offline_clinical_entries.
        */
      await txn.delete(
        'cached_clinical_entries',
        where: 'logbook_id = ?',
        whereArgs: [logbookId],
      );

      for (final rawEntry in entries) {
        if (rawEntry is! Map) {
          continue;
        }

        final entry = Map<String, dynamic>.from(rawEntry);

        final serverId = int.tryParse(entry['id']?.toString() ?? '');

        if (serverId == null) {
          continue;
        }

        await txn.insert('cached_clinical_entries', {
          'server_id': serverId,
          'logbook_id': logbookId,
          'data': jsonEncode(entry),
          'cached_at': cachedAt,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  static Future<List<dynamic>> getCachedClinicalEntries(int logbookId) async {
    final db = await database;

    final rows = await db.query(
      'cached_clinical_entries',
      where: 'logbook_id = ?',
      whereArgs: [logbookId],
      orderBy: 'server_id DESC',
    );

    final List<dynamic> entries = [];

    for (final row in rows) {
      final rawData = row['data']?.toString();

      if (rawData == null || rawData.isEmpty) {
        continue;
      }

      try {
        final decoded = jsonDecode(rawData);

        if (decoded is Map) {
          final entry = Map<String, dynamic>.from(decoded);

          /*
          Although this record is being read from
          SQLite, it is still a real server record.

          Keeping is_local = false preserves the
          existing verification rules.
          */
          entry['is_local'] = false;

          entries.add(entry);
        }
      } catch (_) {
        // Ignore invalid cached record.
      }
    }

    return entries;
  }

  // ===========================================================================
  // OPTIONAL CACHE HELPERS
  // ===========================================================================

  static Future<void> clearCachedAttendanceRecords({
    required int logbookId,
  }) async {
    final db = await database;

    await db.delete(
      'cached_attendance_records',
      where: 'logbook_id = ?',
      whereArgs: [logbookId],
    );
  }

  static Future<void> clearCachedClinicalEntries({
    required int logbookId,
  }) async {
    final db = await database;

    await db.delete(
      'cached_clinical_entries',
      where: 'logbook_id = ?',
      whereArgs: [logbookId],
    );
  }

  // ===========================================================================
  // SYNC STATUS
  // ===========================================================================

  static Future<int> countPendingRecords() async {
    final db = await database;

    /*
    IMPORTANT:

    Only the offline-created synchronization queues
    are counted here.

    cached_attendance_records and
    cached_clinical_entries are deliberately excluded.
    */

    final attendanceResult = await db.rawQuery('''
      SELECT COUNT(*) AS total
      FROM offline_attendance
      WHERE sync_status = 'PENDING_SYNC'
      ''');

    final clinicalResult = await db.rawQuery('''
      SELECT COUNT(*) AS total
      FROM offline_clinical_entries
      WHERE sync_status = 'PENDING_SYNC'
      ''');

    final attendanceCount = _readCount(attendanceResult);

    final clinicalCount = _readCount(clinicalResult);

    return attendanceCount + clinicalCount;
  }

  static int _readCount(List<Map<String, Object?>> result) {
    if (result.isEmpty) {
      return 0;
    }

    final value = result.first['total'];

    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '0') ?? 0;
  }

  // ===========================================================================
  // OPTIONAL DEVELOPMENT HELPERS
  // ===========================================================================

  static Future<void> closeDatabase() async {
    if (_database == null) {
      return;
    }

    await _database!.close();

    _database = null;
  }
}
