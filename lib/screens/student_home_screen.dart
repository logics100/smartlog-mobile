import 'dart:async';

import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/local_database_service.dart';
import '../services/sync_service.dart';

import 'login_screen.dart';
import 'student_attendance_screen.dart';
import 'student_logbooks_screen.dart';
import 'student_sync_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const StudentHomeScreen({
    super.key,
    required this.user,
  });

  @override
  State<StudentHomeScreen> createState() =>
      _StudentHomeScreenState();
}

class _StudentHomeScreenState
    extends State<StudentHomeScreen> {
  Timer? serverCheckTimer;

  bool automaticSyncRunning = false;
  bool isOnline = false;
  bool isCheckingServer = true;

  bool? previousServerStatus;

  int pendingSyncCount = 0;

  @override
  void initState() {
    super.initState();

    // Check immediately when dashboard opens.
    checkServerAndSync();

    // Check Laravel every 5 seconds.
    serverCheckTimer = Timer.periodic(
      const Duration(
        seconds: 5,
      ),
      (_) {
        checkServerAndSync();
      },
    );
  }

  // ============================================================
  // CHECK SMARTLOG LARAVEL SERVER
  // ============================================================

  Future<void> checkServerAndSync() async {
    final serverOnline =
        await ApiService.isServerReachable();

    final pending =
        await LocalDatabaseService
            .countPendingRecords();

    if (!mounted) {
      return;
    }

    final firstCheck =
        previousServerStatus == null;

    final becameOnline =
        previousServerStatus == false &&
            serverOnline;

    previousServerStatus =
        serverOnline;

    setState(() {
      isOnline = serverOnline;
      pendingSyncCount = pending;
      isCheckingServer = false;
    });

    // Laravel is unavailable.
    if (!serverOnline) {
      return;
    }

    // Nothing waiting to sync.
    if (pending == 0) {
      return;
    }

    // Prevent multiple sync processes.
    if (automaticSyncRunning) {
      return;
    }

    // Automatically sync:
    //
    // 1. when dashboard first opens and
    //    pending records already exist;
    //
    // 2. when Laravel changes from
    //    unavailable to available.
    if (!firstCheck &&
        !becameOnline) {
      return;
    }

    await runAutomaticSync();
  }

  // ============================================================
  // AUTOMATIC SYNC
  // ============================================================

  Future<void> runAutomaticSync() async {
    if (automaticSyncRunning) {
      return;
    }

    automaticSyncRunning = true;

    try {
      final result =
          await SyncService
              .syncPendingRecords();

      final newPending =
          await LocalDatabaseService
              .countPendingRecords();

      if (!mounted) {
        return;
      }

      setState(() {
        pendingSyncCount =
            newPending;
      });

      final synced =
          result['synced']
                  ?.toString() ??
              '0';

      final failed =
          result['failed']
                  ?.toString() ??
              '0';

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Automatic sync completed. '
            'Synced: $synced, '
            'Failed: $failed',
          ),
        ),
      );
    } catch (_) {
      // Keep the records pending.
      //
      // The student can still use
      // the manual Sync screen.
    } finally {
      automaticSyncRunning = false;
    }
  }

  // ============================================================
  // REFRESH PENDING COUNT
  // ============================================================

  Future<void> refreshPendingCount() async {
    final pending =
        await LocalDatabaseService
            .countPendingRecords();

    if (!mounted) {
      return;
    }

    setState(() {
      pendingSyncCount =
          pending;
    });
  }

  // ============================================================
  // MANUAL DASHBOARD REFRESH
  // ============================================================

  Future<void> refreshDashboard() async {
    await checkServerAndSync();
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> logout() async {
    try {
      await ApiService.logout();
    } catch (_) {
      // Even if Laravel is unavailable,
      // allow the student to return
      // to the login screen.
    }

    if (!mounted) {
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const LoginScreen(),
      ),
      (_) => false,
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    serverCheckTimer?.cancel();

    super.dispose();
  }

  // ============================================================
  // BUILD SCREEN
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final name =
        widget.user['name']
                ?.toString() ??
            'Student';

    final dwuId =
        widget.user['dwu_id']
                ?.toString() ??
            '-';

    final role =
        widget.user['role']
                ?.toString() ??
            'STUDENT';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SmartLog',
        ),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: logout,
            icon: const Icon(
              Icons.logout,
            ),
          ),
        ],
      ),

      body: SafeArea(
        child: RefreshIndicator(
          onRefresh:
              refreshDashboard,
          child: ListView(
            physics:
                const AlwaysScrollableScrollPhysics(),
            padding:
                const EdgeInsets.all(
              20,
            ),
            children: [
              // ==================================================
              // STUDENT INFORMATION
              // ==================================================

              Text(
                'Welcome, $name',
                style:
                    const TextStyle(
                  fontSize: 24,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              Text(
                'DWU ID: $dwuId',
              ),

              const SizedBox(
                height: 4,
              ),

              Text(
                'Role: $role',
              ),

              const SizedBox(
                height: 18,
              ),

              // ==================================================
              // SMARTLOG SERVER STATUS
              // ==================================================

              Container(
                width:
                    double.infinity,
                padding:
                    const EdgeInsets.all(
                  14,
                ),
                decoration:
                    BoxDecoration(
                  color: isCheckingServer
                      ? Colors.grey
                          .withValues(
                          alpha: 0.08,
                        )
                      : isOnline
                          ? Colors.green
                              .withValues(
                              alpha: 0.08,
                            )
                          : Colors.orange
                              .withValues(
                              alpha: 0.10,
                            ),
                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                  border:
                      Border.all(
                    color: isCheckingServer
                        ? Colors.grey
                            .withValues(
                            alpha: 0.30,
                          )
                        : isOnline
                            ? Colors.green
                                .withValues(
                                alpha: 0.30,
                              )
                            : Colors.orange
                                .withValues(
                                alpha: 0.35,
                              ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isCheckingServer
                          ? Icons.sync
                          : isOnline
                              ? Icons.cloud_done
                              : Icons.cloud_off,
                      color:
                          isCheckingServer
                              ? Colors.grey
                              : isOnline
                                  ? Colors.green
                                  : Colors.orange,
                    ),

                    const SizedBox(
                      width: 12,
                    ),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Text(
                            isCheckingServer
                                ? 'Checking SmartLog Server'
                                : isOnline
                                    ? 'Online'
                                    : 'Offline',
                            style:
                                TextStyle(
                              fontWeight:
                                  FontWeight
                                      .bold,
                              color:
                                  isCheckingServer
                                      ? Colors.grey
                                      : isOnline
                                          ? Colors.green
                                          : Colors.orange,
                            ),
                          ),

                          const SizedBox(
                            height: 2,
                          ),

                          Text(
                            isCheckingServer
                                ? 'Checking connection to the SmartLog server...'
                                : isOnline
                                    ? 'Connected to the SmartLog server. Records can sync.'
                                    : 'SmartLog server is unavailable. Records can still be saved offline.',
                            style:
                                const TextStyle(
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 26,
              ),

              const Text(
                'Student Dashboard',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 16,
              ),

              // ==================================================
              // MY LOGBOOKS
              // ==================================================

              Card(
                child: ListTile(
                  leading:
                      const Icon(
                    Icons.menu_book,
                  ),
                  title:
                      const Text(
                    'My Logbooks',
                  ),
                  subtitle:
                      const Text(
                    'View your assigned clinical logbooks',
                  ),
                  trailing:
                      const Icon(
                    Icons
                        .arrow_forward_ios,
                    size: 18,
                  ),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const StudentLogbooksScreen(),
                      ),
                    );

                    await checkServerAndSync();
                  },
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              // ==================================================
              // ATTENDANCE
              // ==================================================

              Card(
                child: ListTile(
                  leading:
                      const Icon(
                    Icons.access_time,
                  ),
                  title:
                      const Text(
                    'Attendance',
                  ),
                  subtitle:
                      const Text(
                    'Record clinical placement attendance',
                  ),
                  trailing:
                      const Icon(
                    Icons
                        .arrow_forward_ios,
                    size: 18,
                  ),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const StudentAttendanceScreen(),
                      ),
                    );

                    await checkServerAndSync();
                  },
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              // ==================================================
              // SYNC
              // ==================================================

              Card(
                child: ListTile(
                  leading: Stack(
                    clipBehavior:
                        Clip.none,
                    children: [
                      const Icon(
                        Icons.sync,
                        size: 28,
                      ),

                      if (pendingSyncCount >
                          0)
                        Positioned(
                          right: -10,
                          top: -10,
                          child:
                              Container(
                            constraints:
                                const BoxConstraints(
                              minWidth: 20,
                              minHeight: 20,
                            ),
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration:
                                BoxDecoration(
                              color:
                                  Colors.red,
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                20,
                              ),
                            ),
                            child: Text(
                              pendingSyncCount >
                                      99
                                  ? '99+'
                                  : pendingSyncCount
                                      .toString(),
                              textAlign:
                                  TextAlign
                                      .center,
                              style:
                                  const TextStyle(
                                color:
                                    Colors.white,
                                fontSize: 11,
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),

                  title:
                      const Text(
                    'Sync',
                  ),

                  subtitle: Text(
                    pendingSyncCount == 0
                        ? 'All offline records are synced'
                        : '$pendingSyncCount record(s) waiting to sync',
                  ),

                  trailing:
                      const Icon(
                    Icons
                        .arrow_forward_ios,
                    size: 18,
                  ),

                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const StudentSyncScreen(),
                      ),
                    );

                    await checkServerAndSync();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}