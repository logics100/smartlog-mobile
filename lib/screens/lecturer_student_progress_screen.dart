import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'lecturer_clinical_entry_detail_screen.dart';

class LecturerStudentProgressScreen extends StatefulWidget {
  final int unitId;
  final int studentId;
  final String studentName;

  const LecturerStudentProgressScreen({
    super.key,
    required this.unitId,
    required this.studentId,
    required this.studentName,
  });

  @override
  State<LecturerStudentProgressScreen> createState() =>
      _LecturerStudentProgressScreenState();
}

class _LecturerStudentProgressScreenState
    extends State<LecturerStudentProgressScreen> {
  bool isLoading = true;
  String? errorMessage;

  Map<String, dynamic>? progressData;

  @override
  void initState() {
    super.initState();
    loadProgress();
  }

  Future<void> loadProgress() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final data = await ApiService.getLecturerStudentProgress(
        unitId: widget.unitId,
        studentId: widget.studentId,
      );

      if (!mounted) return;

      setState(() {
        progressData = data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  void openClinicalEntry(int entryId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LecturerClinicalEntryDetailScreen(
          unitId: widget.unitId,
          studentId: widget.studentId,
          entryId: entryId,
        ),
      ),
    ).then((_) {
      loadProgress();
    });
  }

  double getCompletionPercentage(Map<String, dynamic>? logbook) {
    if (logbook == null) {
      return 0;
    }

    final rawValue = logbook['completion_percentage'];

    final percentage = double.tryParse(rawValue?.toString() ?? '0') ?? 0;

    return percentage.clamp(0, 100).toDouble();
  }

  double getMinimumCompletionPercentage(Map<String, dynamic>? logbook) {
    if (logbook == null) {
      return 100;
    }

    final rawValue = logbook['minimum_completion_percentage'];

    final percentage = double.tryParse(rawValue?.toString() ?? '100') ?? 100;

    return percentage.clamp(0, 100).toDouble();
  }

  String getCompletionStatus(
    Map<String, dynamic>? logbook,
    double completionPercentage,
    double minimumPercentage,
  ) {
    final backendStatus = logbook?['completion_status']
        ?.toString()
        .toUpperCase();

    if (backendStatus != null && backendStatus.isNotEmpty) {
      return backendStatus;
    }

    if (completionPercentage >= minimumPercentage) {
      return 'COMPLETION_REQUIREMENT_MET';
    }

    if (completionPercentage > 0) {
      return 'IN_PROGRESS';
    }

    return 'NOT_STARTED';
  }

  String formatPercentage(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(2);
  }

  Widget buildSummaryCard({
    required String title,
    required dynamic value,
    required IconData icon,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 32),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 16))),
            Text(
              value?.toString() ?? '0',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildEntryStatusBadge(String status) {
    final normalized = status.toUpperCase().trim();

    Color backgroundColor;
    Color foregroundColor;
    IconData icon;
    String label;

    switch (normalized) {
      case 'VERIFIED':
        backgroundColor = Colors.green.shade100;
        foregroundColor = Colors.green.shade800;
        icon = Icons.verified;
        label = 'VERIFIED';
        break;

      case 'PENDING_VERIFICATION':
        backgroundColor = Colors.orange.shade100;
        foregroundColor = Colors.orange.shade900;
        icon = Icons.pending_actions;
        label = 'PENDING';
        break;

      case 'REJECTED':
        backgroundColor = Colors.red.shade100;
        foregroundColor = Colors.red.shade800;
        icon = Icons.cancel_outlined;
        label = 'REJECTED';
        break;

      case 'DRAFT':
        backgroundColor = Colors.grey.shade200;
        foregroundColor = Colors.grey.shade800;
        icon = Icons.edit_note;
        label = 'DRAFT';
        break;

      default:
        backgroundColor = Colors.grey.shade200;
        foregroundColor = Colors.grey.shade800;
        icon = Icons.info_outline;
        label = normalized.replaceAll('_', ' ');
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: foregroundColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: foregroundColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCompletionStatusBadge(String status) {
    final normalized = status.toUpperCase();

    Color backgroundColor;
    Color foregroundColor;
    IconData icon;
    String label;

    switch (normalized) {
      case 'COMPLETION_REQUIREMENT_MET':
        backgroundColor = Colors.green.shade100;
        foregroundColor = Colors.green.shade800;
        icon = Icons.check_circle;
        label = 'COMPLETION REQUIREMENT MET';
        break;

      case 'IN_PROGRESS':
        backgroundColor = Colors.orange.shade100;
        foregroundColor = Colors.orange.shade900;
        icon = Icons.timelapse;
        label = 'IN PROGRESS';
        break;

      default:
        backgroundColor = Colors.grey.shade200;
        foregroundColor = Colors.grey.shade800;
        icon = Icons.hourglass_empty;
        label = 'NOT STARTED';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: foregroundColor),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: foregroundColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clinical Progress')),
      body: RefreshIndicator(onRefresh: loadProgress, child: buildBody()),
    );
  }

  Widget buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 80),
          const Icon(Icons.error_outline, size: 60),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Unable to load student progress.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          Center(child: Text(errorMessage!, textAlign: TextAlign.center)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: loadProgress,
            child: const Text('Try Again'),
          ),
        ],
      );
    }

    final data = progressData ?? {};

    final student = data['student'] as Map<String, dynamic>? ?? {};

    final unit = data['unit'] as Map<String, dynamic>? ?? {};

    final logbook = data['logbook'] as Map<String, dynamic>?;

    final summary = data['summary'] as Map<String, dynamic>? ?? {};

    final clinicalEntries = data['clinical_entries'] as List<dynamic>? ?? [];

    final completionPercentage = getCompletionPercentage(logbook);

    final minimumPercentage = getMinimumCompletionPercentage(logbook);

    final completionStatus = getCompletionStatus(
      logbook,
      completionPercentage,
      minimumPercentage,
    );

    final progressValue = completionPercentage / 100;

    final completionText = formatPercentage(completionPercentage);

    final minimumText = formatPercentage(minimumPercentage);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student['name']?.toString() ?? widget.studentName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'DWU ID: '
                  '${student['dwu_id'] ?? '-'}',
                ),
                const SizedBox(height: 4),
                Text(
                  'Email: '
                  '${student['email'] ?? '-'}',
                ),
                const SizedBox(height: 12),
                Text(
                  '${unit['unit_code'] ?? ''} - '
                  '${unit['unit_name'] ?? ''}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        const Text(
          'Logbook Completion',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 8),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: logbook == null
                ? const Row(
                    children: [
                      Icon(Icons.menu_book_outlined),
                      SizedBox(width: 12),
                      Expanded(child: Text('No logbook assigned.')),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.menu_book_outlined, size: 30),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              logbook['template_name']?.toString() ??
                                  'Clinical Logbook',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Completed',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '$completionText%',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      LinearProgressIndicator(
                        value: progressValue,
                        minHeight: 10,
                        borderRadius: BorderRadius.circular(10),
                      ),

                      const SizedBox(height: 12),

                      Text(
                        '$completionText% of logbook requirements completed',
                        style: const TextStyle(fontSize: 13),
                      ),

                      const Divider(height: 28),

                      Row(
                        children: [
                          const Expanded(child: Text('Required completion')),
                          Text(
                            '$minimumText%',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        'Completion Status',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),

                      const SizedBox(height: 8),

                      buildCompletionStatusBadge(completionStatus),
                    ],
                  ),
          ),
        ),

        const SizedBox(height: 16),

        const Text(
          'Progress Summary',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 8),

        buildSummaryCard(
          title: 'Total Entries',
          value: summary['total_entries'],
          icon: Icons.list_alt,
        ),

        buildSummaryCard(
          title: 'Verified',
          value: summary['verified_entries'],
          icon: Icons.verified,
        ),

        buildSummaryCard(
          title: 'Pending Verification',
          value: summary['pending_entries'],
          icon: Icons.pending_actions,
        ),

        buildSummaryCard(
          title: 'Rejected',
          value: summary['rejected_entries'],
          icon: Icons.cancel_outlined,
        ),

        buildSummaryCard(
          title: 'Draft',
          value: summary['draft_entries'],
          icon: Icons.edit_note,
        ),

        const SizedBox(height: 16),

        const Text(
          'Logbook Information',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 8),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: logbook == null
                ? const Text('No logbook assigned.')
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status: '
                        '${logbook['status'] ?? '-'}',
                      ),

                      const SizedBox(height: 6),

                      Text(
                        'Completion: '
                        '$completionText%',
                      ),

                      const SizedBox(height: 6),

                      Text(
                        'Required: '
                        '$minimumText%',
                      ),

                      const SizedBox(height: 6),

                      Text(
                        'Completion Requirement: '
                        '${completionStatus == 'COMPLETION_REQUIREMENT_MET' ? 'MET' : 'NOT YET MET'}',
                      ),

                      const SizedBox(height: 6),

                      Text(
                        'Assigned: '
                        '${logbook['assigned_date'] ?? '-'}',
                      ),

                      const SizedBox(height: 6),

                      Text(
                        'Due Date: '
                        '${logbook['due_date'] ?? '-'}',
                      ),
                    ],
                  ),
          ),
        ),

        const SizedBox(height: 16),

        Text(
          'Clinical Entries '
          '(${clinicalEntries.length})',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 8),

        if (clinicalEntries.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No clinical entries recorded yet.'),
            ),
          ),

        ...clinicalEntries.map((entryData) {
          final entry = Map<String, dynamic>.from(entryData as Map);

          final rawEntryId = entry['id'];

          final entryId = int.tryParse(rawEntryId?.toString() ?? '');

          final entryStatus = entry['status']?.toString() ?? 'UNKNOWN';

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: entryId == null
                  ? null
                  : () {
                      openClinicalEntry(entryId);
                    },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.medical_information_outlined,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            entry['activity_details']?.toString() ??
                                'Clinical Activity',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    buildEntryStatusBadge(entryStatus),

                    const SizedBox(height: 12),

                    Text(
                      'Date: '
                      '${entry['activity_date'] ?? '-'}',
                    ),

                    const SizedBox(height: 4),

                    Text(
                      'Facility: '
                      '${entry['facility_name'] ?? '-'}',
                    ),

                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: entryId == null
                            ? null
                            : () {
                                openClinicalEntry(entryId);
                              },
                        icon: const Icon(Icons.visibility),
                        label: const Text('View Details'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),

        const SizedBox(height: 20),
      ],
    );
  }
}
