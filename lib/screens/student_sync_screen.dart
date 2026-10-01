import 'package:flutter/material.dart';

import '../services/local_database_service.dart';
import '../services/sync_service.dart';

class StudentSyncScreen extends StatefulWidget {
  const StudentSyncScreen({super.key});

  @override
  State<StudentSyncScreen> createState() => _StudentSyncScreenState();
}

class _StudentSyncScreenState extends State<StudentSyncScreen> {
  bool isLoading = true;
  bool isSyncing = false;

  int pendingCount = 0;

  List<Map<String, dynamic>> localAttendance = [];

  List<Map<String, dynamic>> localClinicalEntries = [];

  @override
  void initState() {
    super.initState();
    loadLocalRecords();
  }

  Future<void> loadLocalRecords() async {
    setState(() {
      isLoading = true;
    });

    try {
      final pending = await LocalDatabaseService.countPendingRecords();

      final attendance = await LocalDatabaseService.getAllOfflineAttendance();

      final clinicalEntries =
          await LocalDatabaseService.getAllOfflineClinicalEntries();

      if (!mounted) return;

      setState(() {
        pendingCount = pending;

        localAttendance = attendance;

        localClinicalEntries = clinicalEntries;

        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to load local records: $e')),
      );
    }
  }

  Future<void> syncNow() async {
    setState(() {
      isSyncing = true;
    });

    try {
      final result = await SyncService.syncPendingRecords();

      if (!mounted) return;

      await loadLocalRecords();

      if (!mounted) return;

      final synced = result['synced']?.toString() ?? '0';

      final failed = result['failed']?.toString() ?? '0';

      final attendanceSynced = result['attendance_synced']?.toString() ?? '0';

      final clinicalSynced = result['clinical_synced']?.toString() ?? '0';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${result['message']} '
            'Attendance: $attendanceSynced, '
            'Clinical: $clinicalSynced, '
            'Total synced: $synced, '
            'Failed: $failed',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Sync failed: $e')));
    } finally {
      if (mounted) {
        setState(() {
          isSyncing = false;
        });
      }
    }
  }

  IconData syncIcon(String status) {
    if (status == 'SYNCED') {
      return Icons.cloud_done;
    }

    return Icons.cloud_upload;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SmartLog Sync')),
      body: RefreshIndicator(
        onRefresh: loadLocalRecords,
        child: isLoading
            ? ListView(
                children: const [
                  SizedBox(height: 150),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // =========================================
                  // SYNC SUMMARY
                  // =========================================

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Offline Sync Status',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 12),

                          Text(
                            'Pending records: '
                            '$pendingCount',
                          ),

                          const SizedBox(height: 16),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: isSyncing || pendingCount == 0
                                  ? null
                                  : syncNow,
                              icon: isSyncing
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.sync),
                              label: Text(
                                isSyncing ? 'Syncing...' : 'Sync Now',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // =========================================
                  // ATTENDANCE
                  // =========================================
                  const Text(
                    'Local Attendance Records',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),

                  if (localAttendance.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'No local attendance records.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),

                  ...localAttendance.map((record) {
                    final status = record['sync_status']?.toString() ?? '-';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: Icon(syncIcon(status)),
                        title: Text(record['facility_name']?.toString() ?? '-'),
                        subtitle: Text(
                          'Date: '
                          '${record['attendance_date'] ?? '-'}\n'
                          'Clinical Unit: '
                          '${record['clinical_unit'] ?? '-'}\n'
                          'Status: $status'
                          '${record['sync_error'] != null && record['sync_error'].toString().isNotEmpty ? "\nError: ${record['sync_error']}" : ""}',
                        ),
                        isThreeLine: true,
                      ),
                    );
                  }),

                  const SizedBox(height: 24),

                  // =========================================
                  // CLINICAL ENTRIES
                  // =========================================
                  const Text(
                    'Local Clinical Entries',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),

                  if (localClinicalEntries.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'No local clinical entries.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),

                  ...localClinicalEntries.map((record) {
                    final status = record['sync_status']?.toString() ?? '-';

                    final details =
                        record['activity_details']?.toString() ?? '';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: Icon(syncIcon(status)),
                        title: Text(
                          details.isEmpty ? 'Clinical Entry' : details,
                        ),
                        subtitle: Text(
                          'Date: '
                          '${record['activity_date'] ?? '-'}\n'
                          'Facility: '
                          '${record['facility_name'] ?? '-'}\n'
                          'Status: $status'
                          '${record['sync_error'] != null && record['sync_error'].toString().isNotEmpty ? "\nError: ${record['sync_error']}" : ""}',
                        ),
                        isThreeLine: true,
                      ),
                    );
                  }),

                  const SizedBox(height: 30),
                ],
              ),
      ),
    );
  }
}
