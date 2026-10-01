import 'dart:async';

import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/local_database_service.dart';
import '../services/sync_service.dart';
import '../theme/smartlog_theme.dart';

import 'login_screen.dart';
import 'student_attendance_screen.dart';
import 'student_logbooks_screen.dart';
import 'student_sync_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const StudentHomeScreen({super.key, required this.user});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  Timer? serverCheckTimer;

  bool automaticSyncRunning = false;
  bool isOnline = false;
  bool isCheckingServer = true;

  bool? previousServerStatus;

  int pendingSyncCount = 0;

  @override
  void initState() {
    super.initState();

    checkServerAndSync();

    serverCheckTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      checkServerAndSync();
    });
  }

  // ============================================================
  // CHECK SMARTLOG LARAVEL SERVER
  // ============================================================

  Future<void> checkServerAndSync() async {
    final serverOnline = await ApiService.isServerReachable();

    final pending = await LocalDatabaseService.countPendingRecords();

    if (!mounted) {
      return;
    }

    final firstCheck = previousServerStatus == null;

    final becameOnline = previousServerStatus == false && serverOnline;

    previousServerStatus = serverOnline;

    setState(() {
      isOnline = serverOnline;
      pendingSyncCount = pending;
      isCheckingServer = false;
    });

    if (!serverOnline) {
      return;
    }

    if (pending == 0) {
      return;
    }

    if (automaticSyncRunning) {
      return;
    }

    if (!firstCheck && !becameOnline) {
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
      final result = await SyncService.syncPendingRecords();

      final newPending = await LocalDatabaseService.countPendingRecords();

      if (!mounted) {
        return;
      }

      setState(() {
        pendingSyncCount = newPending;
      });

      final synced = result['synced']?.toString() ?? '0';
      final failed = result['failed']?.toString() ?? '0';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Automatic sync completed. '
            'Synced: $synced, Failed: $failed',
          ),
        ),
      );
    } catch (_) {
      // Keep records pending for manual sync.
    } finally {
      automaticSyncRunning = false;
    }
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> refreshPendingCount() async {
    final pending = await LocalDatabaseService.countPendingRecords();

    if (!mounted) {
      return;
    }

    setState(() {
      pendingSyncCount = pending;
    });
  }

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
      // Student may still logout when server is unavailable.
    }

    if (!mounted) {
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  void dispose() {
    serverCheckTimer?.cancel();
    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final name = widget.user['name']?.toString() ?? 'Student';
    final dwuId = widget.user['dwu_id']?.toString() ?? '-';

    return Scaffold(
      backgroundColor: SmartLogColors.background,
      appBar: AppBar(
        toolbarHeight: 68,
        titleSpacing: 18,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SMARTLOG',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                letterSpacing: .8,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Student Portal',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Color(0xFFD8ECFF),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: refreshDashboard,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: logout,
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: refreshDashboard,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
            children: [
              _buildWelcomeCard(name, dwuId),

              const SizedBox(height: 14),

              _buildConnectionCard(),

              const SizedBox(height: 26),

              const Text(
                'Student Dashboard',
                style: TextStyle(
                  color: SmartLogColors.navy,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 5),

              const Text(
                'Manage your clinical placement activities.',
                style: TextStyle(color: SmartLogColors.muted, fontSize: 14),
              ),

              const SizedBox(height: 16),

              _buildActionCard(
                icon: Icons.menu_book_rounded,
                title: 'My Logbooks',
                subtitle: 'View assigned logbooks and record your clinical activities.',
                iconBackground: SmartLogColors.paleBlue,
                iconColor: SmartLogColors.blue,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const StudentLogbooksScreen(),
                    ),
                  );

                  await checkServerAndSync();
                },
              ),

              const SizedBox(height: 12),

              _buildActionCard(
                icon: Icons.access_time_rounded,
                title: 'Attendance',
                subtitle:
                    'Record and review your clinical placement attendance.',
                iconBackground: const Color(0xFFEAF9F7),
                iconColor: SmartLogColors.success,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const StudentAttendanceScreen(),
                    ),
                  );

                  await checkServerAndSync();
                },
              ),

              const SizedBox(height: 12),

              _buildSyncCard(),

              const SizedBox(height: 24),

              _buildOfflineInformation(),

              const SizedBox(height: 22),

              _buildFeatureStrip(),

              const SizedBox(height: 28),

              const Column(
                children: [
                  Text(
                    'Divine Word University',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: SmartLogColors.navy,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'SmartLog Clinical Placement System',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: SmartLogColors.muted, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // WELCOME CARD
  // ============================================================

  Widget _buildWelcomeCard(String name, String dwuId) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            SmartLogColors.navy,
            SmartLogColors.deepBlue,
            SmartLogColors.blue,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: SmartLogColors.navy.withValues(alpha: .16),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -42,
            top: -55,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: SmartLogColors.cyan.withValues(alpha: .16),
              ),
            ),
          ),
          Positioned(
            right: 25,
            bottom: -50,
            child: Container(
              width: 115,
              height: 115,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: .07),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Row(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(19),
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    size: 33,
                    color: SmartLogColors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Welcome back',
                        style: TextStyle(
                          color: Color(0xFFD7EBFF),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .13),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'DWU ID: $dwuId  •  STUDENT',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CONNECTION STATUS
  // ============================================================

  Widget _buildConnectionCard() {
    final Color statusColor;
    final Color backgroundColor;
    final IconData icon;
    final String title;
    final String message;

    if (isCheckingServer) {
      statusColor = SmartLogColors.muted;
      backgroundColor = const Color(0xFFF3F6F8);
      icon = Icons.sync_rounded;
      title = 'Checking connection';
      message = 'Checking the SmartLog server...';
    } else if (isOnline) {
      statusColor = SmartLogColors.success;
      backgroundColor = const Color(0xFFECF8F3);
      icon = Icons.cloud_done_rounded;
      title = 'Online';
      message = 'Connected to SmartLog. Your records can sync.';
    } else {
      statusColor = SmartLogColors.warning;
      backgroundColor = const Color(0xFFFFF6E7);
      icon = Icons.cloud_off_rounded;
      title = 'Offline mode';
      message = 'Server unavailable. You can continue recording clinical work offline.';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: .25)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: statusColor, size: 23),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: const TextStyle(
                    color: SmartLogColors.text,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DASHBOARD ACTION CARD
  // ============================================================

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconBackground,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: iconColor, size: 27),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: SmartLogColors.navy,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: SmartLogColors.muted,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: SmartLogColors.blue,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SYNC CARD
  // ============================================================

  Widget _buildSyncCard() {
    return Card(
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const StudentSyncScreen()),
          );

          await checkServerAndSync();
        },
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF8FE),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.sync_rounded,
                      color: SmartLogColors.cyan,
                      size: 29,
                    ),
                  ),
                  if (pendingSyncCount > 0)
                    Positioned(
                      right: -6,
                      top: -7,
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 21,
                          minHeight: 21,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: SmartLogColors.danger,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Text(
                          pendingSyncCount > 99
                              ? '99+'
                              : pendingSyncCount.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SmartLog Sync',
                      style: TextStyle(
                        color: SmartLogColors.navy,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pendingSyncCount == 0
                          ? 'All offline records are synced.'
                          : '$pendingSyncCount record(s) waiting to sync.',
                      style: const TextStyle(
                        color: SmartLogColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: SmartLogColors.blue,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // OFFLINE INFORMATION
  // ============================================================

  Widget _buildOfflineInformation() {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7FE),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: SmartLogColors.cyan.withValues(alpha: .35)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.offline_bolt_rounded,
            color: SmartLogColors.cyan,
            size: 29,
          ),
          SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Offline Ready',
                  style: TextStyle(
                    color: SmartLogColors.navy,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Clinical records can be saved on this device when the '
                  'server is unavailable and synced when connection returns.',
                  style: TextStyle(
                    color: SmartLogColors.muted,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FEATURE STRIP
  // ============================================================

  Widget _buildFeatureStrip() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: const [
        _FeatureChip(icon: Icons.menu_book_outlined, label: 'Clinical Logbook'),
        _FeatureChip(icon: Icons.verified_outlined, label: 'Verification'),
        _FeatureChip(icon: Icons.sync_rounded, label: 'Offline Sync'),
      ],
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: SmartLogColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: SmartLogColors.blue),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: SmartLogColors.text,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
