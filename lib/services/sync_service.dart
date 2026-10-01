import 'api_service.dart';
import 'local_database_service.dart';

class SyncService {
  static Future<Map<String, dynamic>> syncPendingRecords() async {
    int synced = 0;
    int failed = 0;

    int attendanceSynced = 0;
    int clinicalSynced = 0;

    // =========================================================
    // CHECK THE ACTUAL SMARTLOG SERVER
    // =========================================================

    final serverOnline = await ApiService.isServerReachable();

    if (!serverOnline) {
      return {
        'success': false,
        'message': 'SmartLog server is unavailable.',
        'synced': 0,
        'failed': 0,
        'attendance_synced': 0,
        'clinical_synced': 0,
      };
    }

    // =========================================================
    // SYNC ATTENDANCE
    // =========================================================

    final pendingAttendance = await LocalDatabaseService.getPendingAttendance();

    for (final record in pendingAttendance) {
      final localId = int.tryParse(record['id']?.toString() ?? '');

      final logbookId = int.tryParse(record['logbook_id']?.toString() ?? '');

      if (localId == null || logbookId == null) {
        failed++;
        continue;
      }

      try {
        final result = await ApiService.createStudentAttendance(
          logbookId: logbookId,
          attendanceDate: record['attendance_date']?.toString() ?? '',
          facilityName: record['facility_name']?.toString() ?? '',
          clinicalUnit: record['clinical_unit']?.toString() ?? '',
          startTime: record['start_time']?.toString() ?? '',
          finishTime: record['finish_time']?.toString() ?? '',
        );

        final serverId = int.tryParse(
          result['attendance_record_id']?.toString() ?? '',
        );

        if (serverId == null) {
          await LocalDatabaseService.markAttendanceSyncFailed(
            localId: localId,
            error:
                'Server did not return '
                'attendance_record_id.',
          );

          failed++;
          continue;
        }

        await LocalDatabaseService.markAttendanceSynced(
          localId: localId,
          serverId: serverId,
        );

        synced++;
        attendanceSynced++;
      } catch (e) {
        await LocalDatabaseService.markAttendanceSyncFailed(
          localId: localId,
          error: e.toString(),
        );

        failed++;
      }
    }

    // =========================================================
    // SYNC CLINICAL ENTRIES
    // =========================================================

    final pendingClinicalEntries =
        await LocalDatabaseService.getPendingClinicalEntries();

    for (final record in pendingClinicalEntries) {
      final localId = int.tryParse(record['id']?.toString() ?? '');

      final logbookId = int.tryParse(record['logbook_id']?.toString() ?? '');

      final logbookItemId = int.tryParse(
        record['logbook_item_id']?.toString() ?? '',
      );

      final requirementId = record['requirement_id'] == null
          ? null
          : int.tryParse(record['requirement_id'].toString());

      if (localId == null || logbookId == null || logbookItemId == null) {
        failed++;
        continue;
      }

      try {
        final result = await ApiService.createClinicalEntry(
          logbookId: logbookId,
          logbookItemId: logbookItemId,
          requirementId: requirementId,
          activityDate: record['activity_date']?.toString() ?? '',
          activityTime: record['activity_time']?.toString(),
          facilityName: record['facility_name']?.toString() ?? '',
          clinicalArea: record['clinical_area']?.toString(),
          activityDetails: record['activity_details']?.toString(),
        );

        final serverId = int.tryParse(
          result['clinical_entry_id']?.toString() ?? '',
        );

        if (serverId == null) {
          await LocalDatabaseService.markClinicalEntrySyncFailed(
            localId: localId,
            error:
                'Server did not return '
                'clinical_entry_id.',
          );

          failed++;
          continue;
        }

        await LocalDatabaseService.markClinicalEntrySynced(
          localId: localId,
          serverId: serverId,
        );

        synced++;
        clinicalSynced++;
      } catch (e) {
        await LocalDatabaseService.markClinicalEntrySyncFailed(
          localId: localId,
          error: e.toString(),
        );

        failed++;
      }
    }

    // =========================================================
    // RESULT
    // =========================================================

    return {
      'success': failed == 0,
      'message': failed == 0
          ? 'Sync completed successfully.'
          : 'Sync completed with some failures.',
      'synced': synced,
      'failed': failed,
      'attendance_synced': attendanceSynced,
      'clinical_synced': clinicalSynced,
    };
  }
}
