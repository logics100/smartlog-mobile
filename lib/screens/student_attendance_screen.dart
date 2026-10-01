import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/local_database_service.dart';
import 'student_attendance_records_screen.dart';

class StudentAttendanceScreen extends StatefulWidget {
  const StudentAttendanceScreen({super.key});

  @override
  State<StudentAttendanceScreen> createState() =>
      _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen> {
  bool isLoading = true;
  bool usingOfflineCache = false;

  String? errorMessage;

  List<dynamic> logbooks = [];

  @override
  void initState() {
    super.initState();

    loadLogbooks();
  }

  Future<void> loadLogbooks() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      usingOfflineCache = false;
    });

    try {
      // =====================================================
      // TRY LARAVEL FIRST
      // =====================================================

      final result = await ApiService.getStudentLogbooks();

      // Cache the latest server copy.
      await LocalDatabaseService.cacheStudentLogbooks(result);

      if (!mounted) return;

      setState(() {
        logbooks = result;
        isLoading = false;
        usingOfflineCache = false;
      });
    } catch (serverError) {
      // =====================================================
      // SERVER FAILED - TRY SQLITE CACHE
      // =====================================================

      try {
        final cached = await LocalDatabaseService.getCachedStudentLogbooks();

        if (!mounted) return;

        if (cached.isNotEmpty) {
          setState(() {
            logbooks = cached;
            isLoading = false;
            usingOfflineCache = true;
          });

          return;
        }

        setState(() {
          errorMessage =
              'Unable to load your logbooks. '
              'No offline logbook cache is available yet.';
          isLoading = false;
        });
      } catch (localError) {
        if (!mounted) return;

        setState(() {
          errorMessage =
              'Unable to load logbooks from the '
              'SmartLog server or local storage.\n\n'
              '$localError';

          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance')),
      body: RefreshIndicator(onRefresh: loadLogbooks, child: buildBody()),
    );
  }

  Widget buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 80),

          const Icon(Icons.error_outline, size: 60),

          const SizedBox(height: 16),

          const Text(
            'Unable to load your logbooks.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          Text(errorMessage!, textAlign: TextAlign.center),

          const SizedBox(height: 20),

          ElevatedButton.icon(
            onPressed: loadLogbooks,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      );
    }

    if (logbooks.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: const [
          SizedBox(height: 100),

          Icon(Icons.menu_book_outlined, size: 70),

          SizedBox(height: 16),

          Text(
            'No Logbooks',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          SizedBox(height: 8),

          Text(
            'You need an assigned logbook '
            'before recording attendance.',
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      children: [
        // ===================================================
        // OFFLINE NOTICE
        // ===================================================

        if (usingOfflineCache)
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.35)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.offline_bolt, color: Colors.orange),

                SizedBox(width: 10),

                Expanded(
                  child: Text(
                    'Offline mode: showing cached '
                    'logbooks stored on this device.',
                  ),
                ),
              ],
            ),
          ),

        // ===================================================
        // LOGBOOK LIST
        // ===================================================
        ...logbooks.map((rawLogbook) {
          final logbook = Map<String, dynamic>.from(rawLogbook as Map);

          final rawId = logbook['id'] ?? logbook['student_logbook_id'];

          final logbookId = int.tryParse(rawId?.toString() ?? '');

          final templateName =
              logbook['template_name']?.toString() ??
              logbook['logbook_name']?.toString() ??
              logbook['unit_name']?.toString() ??
              'Clinical Logbook';

          final unitCode = logbook['unit_code']?.toString() ?? '';

          final unitName = logbook['unit_name']?.toString() ?? '';

          final status = logbook['status']?.toString() ?? 'ACTIVE';

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.access_time)),

              title: Text(
                templateName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),

              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (unitCode.isNotEmpty) ...[
                    const SizedBox(height: 4),

                    Text(
                      unitName.isNotEmpty
                          ? 'Unit: $unitCode - $unitName'
                          : 'Unit: $unitCode',
                    ),
                  ],

                  const SizedBox(height: 4),

                  Text('Status: $status'),
                ],
              ),

              trailing: const Icon(Icons.chevron_right),

              onTap: () {
                if (logbookId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Logbook ID is missing.')),
                  );

                  return;
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StudentAttendanceRecordsScreen(
                      logbookId: logbookId,
                      logbookName: templateName,
                    ),
                  ),
                );
              },
            ),
          );
        }),
      ],
    );
  }
}
