import 'package:flutter/material.dart';

import '../services/api_service.dart';

class HodLecturerProgressScreen extends StatefulWidget {
  final int lecturerId;

  const HodLecturerProgressScreen({super.key, required this.lecturerId});

  @override
  State<HodLecturerProgressScreen> createState() =>
      _HodLecturerProgressScreenState();
}

class _HodLecturerProgressScreenState extends State<HodLecturerProgressScreen> {
  bool loading = true;
  String? errorMessage;
  Map<String, dynamic>? data;

  @override
  void initState() {
    super.initState();
    loadProgress();
  }

  Future<void> loadProgress() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final result = await ApiService.getHodLecturerProgress(widget.lecturerId);

      if (!mounted) return;

      setState(() {
        data = result;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'Unable to load lecturer progress.';
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Map<String, dynamic> mapOf(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return {};
  }

  List<dynamic> listOf(dynamic value) {
    if (value is List) {
      return value;
    }

    return [];
  }

  double toDouble(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FD),
      appBar: AppBar(
        backgroundColor: const Color(0xFF062B63),
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        title: const Text('Lecturer Progress'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: loading ? null : loadProgress,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? buildErrorState()
          : buildContent(),
    );
  }

  Widget buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 52),
            const SizedBox(height: 16),
            Text(errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: loadProgress,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildContent() {
    final lecturer = mapOf(data?['lecturer']);

    final summary = mapOf(data?['summary']);

    final summaryLogbooks = mapOf(summary['logbooks']);

    final units = listOf(data?['units']);

    return RefreshIndicator(
      onRefresh: loadProgress,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          buildLecturerHeader(lecturer),

          const SizedBox(height: 20),

          buildOverallSummary(summary, summaryLogbooks),

          const SizedBox(height: 24),

          Row(
            children: [
              const Expanded(
                child: Text(
                  'Assigned Units',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                '${units.length}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (units.isEmpty)
            const Card(
              color: Colors.white,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
                side: BorderSide(color: Color(0xFFDBE7F2)),
              ),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No units are currently assigned '
                  'to this lecturer.',
                ),
              ),
            )
          else
            ...units.map((item) {
              return buildUnitCard(mapOf(item));
            }),

          const SizedBox(height: 12),

          buildReadOnlyNotice(),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget buildLecturerHeader(Map<String, dynamic> lecturer) {
    final phone = lecturer['phone']?.toString() ?? '';

    return Card(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: const Color(0xFFDBE7F2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 28,
                  child: Icon(Icons.person_outline, size: 30),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lecturer['name']?.toString() ?? 'Lecturer',
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'DWU ID: '
                        '${lecturer['dwu_id'] ?? '-'}',
                      ),
                      const SizedBox(height: 4),
                      Text(lecturer['email']?.toString() ?? ''),
                      if (phone.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('Phone: $phone'),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Row(
              children: [
                Chip(
                  avatar: Icon(Icons.visibility_outlined, size: 17),
                  label: Text('Read Only'),
                ),
                SizedBox(width: 8),
                Chip(label: Text('LECTURER')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildOverallSummary(
    Map<String, dynamic> summary,
    Map<String, dynamic> logbooks,
  ) {
    final average = toDouble(logbooks['average_completion_percentage']);

    final progress = (average / 100).clamp(0.0, 1.0);

    return Card(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: const Color(0xFFDBE7F2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Teaching Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 28,
              runSpacing: 16,
              children: [
                buildSmallStat(
                  'Assigned Units',
                  summary['assigned_unit_count'] ?? 0,
                ),
                buildSmallStat(
                  'Students',
                  summary['enrolled_student_count'] ?? 0,
                ),
                buildSmallStat('Logbooks', logbooks['total'] ?? 0),
                buildSmallStat('Active', logbooks['active'] ?? 0),
                buildSmallStat('Completed', logbooks['completed'] ?? 0),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Average Logbook Completion',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ),
                Text(
                  '${average.toStringAsFixed(2)}%',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: progress, minHeight: 9),
          ],
        ),
      ),
    );
  }

  Widget buildUnitCard(Map<String, dynamic> unit) {
    final year = mapOf(unit['year_level']);

    final statistics = mapOf(unit['statistics']);

    final logbooks = mapOf(statistics['logbooks']);

    final entries = mapOf(statistics['clinical_entries']);

    final average = toDouble(logbooks['average_completion_percentage']);

    final progress = (average / 100).clamp(0.0, 1.0);

    final requiresLogbook =
        unit['requires_logbook'] == true || unit['requires_logbook'] == 1;

    return Card(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: const Color(0xFFDBE7F2)),
      ),
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.menu_book_outlined, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${unit['unit_code'] ?? ''} - '
                        '${unit['unit_name'] ?? ''}',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        year['year_name']?.toString() ?? 'Year level not set',
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  label: Text(
                    requiresLogbook
                        ? 'Logbook Required'
                        : 'No Logbook Required',
                  ),
                ),
                if (unit['semester_id'] != null)
                  Chip(
                    label: Text(
                      'Semester '
                      '${unit['semester_id']}',
                    ),
                  ),
              ],
            ),

            const Divider(height: 30),

            const Text(
              'Students & Logbooks',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            Wrap(
              spacing: 24,
              runSpacing: 14,
              children: [
                buildSmallStat(
                  'Enrollments',
                  statistics['enrollment_count'] ?? 0,
                ),
                buildSmallStat(
                  'Students',
                  statistics['enrolled_students'] ?? 0,
                ),
                buildSmallStat('Logbooks', logbooks['total'] ?? 0),
                buildSmallStat('Active', logbooks['active'] ?? 0),
                buildSmallStat('Completed', logbooks['completed'] ?? 0),
              ],
            ),

            const SizedBox(height: 18),

            Row(
              children: [
                const Expanded(child: Text('Average Completion')),
                Text(
                  '${average.toStringAsFixed(2)}%',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const SizedBox(height: 8),

            LinearProgressIndicator(value: progress, minHeight: 8),

            const Divider(height: 30),

            const Text(
              'Clinical Entries',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            Wrap(
              spacing: 24,
              runSpacing: 14,
              children: [
                buildSmallStat('Total', entries['total'] ?? 0),
                buildSmallStat('Verified', entries['verified'] ?? 0),
                buildSmallStat('Pending', entries['pending_verification'] ?? 0),
                buildSmallStat('Rejected', entries['rejected'] ?? 0),
                buildSmallStat('Draft', entries['draft'] ?? 0),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildReadOnlyNotice() {
    return Card(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: const Color(0xFFDBE7F2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.lock_outline),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'HOD Monitoring Only',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'This screen is read-only. '
                    'The HOD can monitor assigned '
                    'units, students, logbooks and '
                    'clinical activity, but cannot '
                    'assign units, enroll students, '
                    'review verifications or modify '
                    'lecturer records.',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSmallStat(String label, dynamic value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value.toString(),
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
      ],
    );
  }
}
