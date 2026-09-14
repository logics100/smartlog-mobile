import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/local_database_service.dart';
import 'student_create_attendance_screen.dart';
import 'supervisor_verification_screen.dart';

class StudentAttendanceRecordsScreen
    extends StatefulWidget {
  final int logbookId;
  final String logbookName;

  const StudentAttendanceRecordsScreen({
    super.key,
    required this.logbookId,
    required this.logbookName,
  });

  @override
  State<StudentAttendanceRecordsScreen>
      createState() =>
          _StudentAttendanceRecordsScreenState();
}

class _StudentAttendanceRecordsScreenState
    extends State<StudentAttendanceRecordsScreen> {
  bool isLoading = true;
  bool usingOfflineData = false;

  String? errorMessage;

  List<dynamic> attendanceRecords = [];

  @override
  void initState() {
    super.initState();
    loadAttendance();
  }

  Future<void> loadAttendance() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      usingOfflineData = false;
    });

    try {
      // =====================================================
      // TRY SERVER FIRST
      // =====================================================

      final serverRecords =
          await ApiService
              .getStudentAttendanceRecords(
        widget.logbookId,
      );

      // =====================================================
      // CACHE SERVER RECORDS FOR OFFLINE USE
      // =====================================================

      await LocalDatabaseService
          .cacheAttendanceRecords(
        logbookId: widget.logbookId,
        records: serverRecords,
      );

      // =====================================================
      // ALSO LOAD LOCAL SQLITE RECORDS
      // =====================================================

      final allLocalRecords =
          await LocalDatabaseService
              .getAllOfflineAttendance();

      final localRecords =
          allLocalRecords.where(
        (record) {
          final localLogbookId =
              int.tryParse(
            record['logbook_id']
                    ?.toString() ??
                '',
          );

          return localLogbookId ==
              widget.logbookId;
        },
      ).toList();

      // Only include records that have NOT synced yet.
      final pendingLocalRecords =
          localRecords.where(
        (record) {
          return record['sync_status']
                  ?.toString() ==
              'PENDING_SYNC';
        },
      ).map(
        (record) {
          return {
            'id': null,
            'local_id': record['id'],
            'attendance_date':
                record['attendance_date'],
            'facility_name':
                record['facility_name'],
            'clinical_unit':
                record['clinical_unit'],
            'start_time':
                record['start_time'],
            'finish_time':
                record['finish_time'],
            'total_hours':
                record['total_hours'],
            'status': 'PENDING_SYNC',
            'sync_status':
                record['sync_status'],
            'is_local': true,
          };
        },
      ).toList();

      final combinedRecords = [
        ...pendingLocalRecords,
        ...serverRecords,
      ];

      if (!mounted) return;

      setState(() {
        attendanceRecords =
            combinedRecords;

        isLoading = false;

        usingOfflineData = false;
      });
    } catch (_) {
      // =====================================================
      // SERVER FAILED - LOAD SQLITE CACHE + LOCAL RECORDS
      // =====================================================

      try {
        final cachedServerRecords =
            await LocalDatabaseService
                .getCachedAttendanceRecords(
          widget.logbookId,
        );

        final cachedServerIds =
            cachedServerRecords
                .map(
                  (record) =>
                      int.tryParse(
                    record['id']
                            ?.toString() ??
                        '',
                  ),
                )
                .whereType<int>()
                .toSet();

        final allLocalRecords =
            await LocalDatabaseService
                .getAllOfflineAttendance();

        final localRecords =
            allLocalRecords.where(
          (record) {
            final localLogbookId =
                int.tryParse(
              record['logbook_id']
                      ?.toString() ??
                  '',
            );

            return localLogbookId ==
                widget.logbookId;
          },
        ).where(
          (record) {
            final syncStatus =
                record['sync_status']
                        ?.toString() ??
                    'PENDING_SYNC';

            // Always keep records still waiting to sync.
            if (syncStatus ==
                'PENDING_SYNC') {
              return true;
            }

            /*
            A synced offline-created record may now
            also exist in the server cache.

            If its server ID is already cached, skip
            the local copy so the same attendance
            record is not displayed twice.
            */
            final serverId =
                int.tryParse(
              record['server_id']
                      ?.toString() ??
                  '',
            );

            if (serverId != null &&
                cachedServerIds
                    .contains(serverId)) {
              return false;
            }

            /*
            Keep a synced local record when the
            corresponding server record has not yet
            been cached. This prevents a successfully
            synced attendance record from disappearing
            while the device is offline.
            */
            return true;
          },
        ).map(
          (record) {
            final syncStatus =
                record['sync_status']
                        ?.toString() ??
                    'PENDING_SYNC';

            return {
              'id': record['server_id'],
              'local_id': record['id'],
              'attendance_date':
                  record['attendance_date'],
              'facility_name':
                  record['facility_name'],
              'clinical_unit':
                  record['clinical_unit'],
              'start_time':
                  record['start_time'],
              'finish_time':
                  record['finish_time'],
              'total_hours':
                  record['total_hours'],
              'status': syncStatus,
              'sync_status':
                  syncStatus,
              'is_local': true,
            };
          },
        ).toList();

        final combinedRecords = [
          ...localRecords,
                    ...cachedServerRecords,
        ];

        if (!mounted) return;

        setState(() {
          attendanceRecords =
              combinedRecords;

          isLoading = false;

          usingOfflineData = true;
        });
      } catch (localError) {
        if (!mounted) return;

        setState(() {
          errorMessage =
              'Unable to load attendance '
              'from the SmartLog server '
              'or local storage.\n\n'
              '$localError';

          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Attendance Records',
        ),
      ),

      body: RefreshIndicator(
        onRefresh: loadAttendance,
        child: buildBody(),
      ),

      floatingActionButton:
          FloatingActionButton.extended(
        icon: const Icon(
          Icons.add,
        ),
        label: const Text(
          'Add Attendance',
        ),
        onPressed: () async {
          final created =
              await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  StudentCreateAttendanceScreen(
                logbookId:
                    widget.logbookId,
              ),
            ),
          );

          if (created == true) {
            await loadAttendance();
          }
        },
      ),
    );
  }

  Widget buildBody() {
    if (isLoading) {
      return const Center(
        child:
            CircularProgressIndicator(),
      );
    }

    if (errorMessage != null) {
      return ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding:
            const EdgeInsets.all(
          20,
        ),
        children: [
          const SizedBox(
            height: 80,
          ),

          const Icon(
            Icons.error_outline,
            size: 60,
          ),

          const SizedBox(
            height: 16,
          ),

          const Text(
            'Unable to load attendance.',
            textAlign:
                TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          Text(
            errorMessage!,
            textAlign:
                TextAlign.center,
          ),

          const SizedBox(
            height: 20,
          ),

          ElevatedButton.icon(
            onPressed:
                loadAttendance,
            icon: const Icon(
              Icons.refresh,
            ),
            label: const Text(
              'Try Again',
            ),
          ),
        ],
      );
    }

    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      padding:
          const EdgeInsets.fromLTRB(
        12,
        12,
        12,
        90,
      ),
      children: [
        // ===================================================
        // OFFLINE NOTICE
        // ===================================================

        if (usingOfflineData)
          Container(
            margin:
                const EdgeInsets.only(
              bottom: 14,
            ),
            padding:
                const EdgeInsets.all(
              12,
            ),
            decoration:
                BoxDecoration(
              color:
                  Colors.orange
                      .withValues(
                alpha: 0.10,
              ),
              borderRadius:
                  BorderRadius.circular(
                10,
              ),
              border: Border.all(
                color:
                    Colors.orange
                        .withValues(
                  alpha: 0.35,
                ),
              ),
            ),
            child:
                const Row(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Icon(
                  Icons.offline_bolt,
                  color:
                      Colors.orange,
                ),

                SizedBox(
                  width: 10,
                ),

                Expanded(
                  child: Text(
                    'Offline mode: showing attendance records stored on this device.',
                  ),
                ),
              ],
            ),
          ),

        // ===================================================
        // EMPTY STATE
        // ===================================================

        if (attendanceRecords.isEmpty)
          const Padding(
            padding:
                EdgeInsets.only(
              top: 80,
            ),
            child: Column(
              children: [
                Icon(
                  Icons.access_time,
                  size: 70,
                ),

                SizedBox(
                  height: 16,
                ),

                Text(
                  'No Attendance Records',
                  textAlign:
                      TextAlign.center,
                  style:
                      TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                SizedBox(
                  height: 8,
                ),

                Text(
                  'Tap Add Attendance to record your clinical placement attendance.',
                  textAlign:
                      TextAlign.center,
                ),
              ],
                          ),
          ),

        // ===================================================
        // RECORDS
        // ===================================================

        ...attendanceRecords.map(
          (rawRecord) {
            final record =
                Map<String, dynamic>.from(
              rawRecord as Map,
            );

            final attendanceId =
                int.tryParse(
              record['id']
                      ?.toString() ??
                  '',
            );

            final isLocal =
                record['is_local'] ==
                    true;

            final date =
                record['attendance_date']
                        ?.toString() ??
                    '-';

            final facility =
                record['facility_name']
                        ?.toString() ??
                    '-';

            final clinicalUnit =
                record['clinical_unit']
                        ?.toString() ??
                    '-';

            final start =
                record['start_time']
                        ?.toString() ??
                    '-';

            final finish =
                record['finish_time']
                        ?.toString() ??
                    '-';

            final hours =
                record['total_hours']
                        ?.toString() ??
                    '0';

            final status =
                record['status']
                        ?.toString() ??
                    '-';

            IconData statusIcon =
                Icons.hourglass_top;

            if (status ==
                'VERIFIED') {
              statusIcon =
                  Icons.verified;
            } else if (status ==
                'REJECTED') {
              statusIcon =
                  Icons.cancel;
            } else if (status ==
                'PENDING_SYNC') {
              statusIcon =
                  Icons.cloud_upload;
            }

            return Card(
              margin:
                  const EdgeInsets.only(
                bottom: 12,
              ),
              child: Padding(
                padding:
                    const EdgeInsets
                        .all(
                  16,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          statusIcon,
                        ),

                        const SizedBox(
                          width: 10,
                        ),

                        Expanded(
                          child: Text(
                            facility,
                            style:
                                const TextStyle(
                              fontSize:
                                  17,
                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    Text(
                      'Date: $date',
                    ),

                    const SizedBox(
                      height: 5,
                    ),

                    Text(
                      'Clinical Unit: $clinicalUnit',
                    ),

                    const SizedBox(
                      height: 5,
                    ),

                    Text(
                      'Time: $start - $finish',
                    ),

                    const SizedBox(
                      height: 5,
                    ),

                    Text(
                      'Total Hours: $hours',
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    Text(
                      'Status: $status',
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight
                                .bold,
                      ),
                    ),

                    // =======================================
                    // OFFLINE RECORD INFO
                    // =======================================

                    if (status ==
                        'PENDING_SYNC') ...[
                      const SizedBox(
                        height: 8,
                      ),

                      const Text(
                        'This attendance record is stored locally and will be uploaded when SmartLog reconnects.',
                        style:
                            TextStyle(
                          fontSize: 13,
                          fontStyle:
                              FontStyle
                                  .italic,
                        ),
                      ),
                    ],

                    // =======================================
                    // VERIFY SERVER RECORD ONLY
                    // =======================================

                    if (!isLocal &&
                        status ==
                            'PENDING_VERIFICATION') ...[
                      const SizedBox(
                        height: 16,
                      ),

                      SizedBox(
                        width:
                            double.infinity,
                        child:
                            ElevatedButton
                                .icon(
                          onPressed:
                              attendanceId ==
                                      null
                                  ? null
                                  : () async {
                                      final verified =
                                          await Navigator.push<
                                              bool>(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              SupervisorVerificationScreen(
                                            attendanceId:
                                                attendanceId,
                                            procedureName:
                                                'Attendance - $clinicalUnit',
                                            facilityName:
                                                facility,
                                          ),
                                        ),
                                      );

                                      if (verified ==
                                          true) {
                                        await loadAttendance();
                                      }
                                    },
                          icon:
                              const Icon(
                            Icons
                                .verified_user_outlined,
                          ),
                          label:
                              const Text(
                            'Verify Attendance',
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}