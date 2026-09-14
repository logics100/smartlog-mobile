import 'package:flutter/material.dart';
import '../services/api_service.dart';

class HodUnitProgressScreen extends StatefulWidget {
  final int unitId;

  const HodUnitProgressScreen({
    super.key,
    required this.unitId,
  });

  @override
  State<HodUnitProgressScreen> createState() =>
      _HodUnitProgressScreenState();
}

class _HodUnitProgressScreenState
    extends State<HodUnitProgressScreen> {
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
      final result =
          await ApiService.getHodUnitProgress(
        widget.unitId,
      );

      if (!mounted) return;

      setState(() {
        data = result;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage =
            'Unable to load unit progress.';
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unit Progress'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: loading ? null : loadProgress,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
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
            const Icon(
              Icons.error_outline,
              size: 52,
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
            ),
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
    final result = data ?? {};

    final unit = mapOf(result['unit']);
    final summary = mapOf(result['summary']);
    final access = mapOf(result['access']);

    final students =
        listOf(result['students']);

    final logbooks =
        mapOf(summary['logbooks']);

    final clinicalEntries =
        mapOf(summary['clinical_entries']);

    final yearLevel =
        mapOf(unit['year_level']);

    final unitCode =
        unit['unit_code']?.toString() ?? 'UNIT';

    final unitName =
        unit['unit_name']?.toString() ?? 'Unit';

    final yearName =
        yearLevel['year_name']?.toString() ??
            'Year Level Not Set';

    final averageCompletion = toDouble(
      logbooks['average_completion_percentage'],
    );

    final progress =
        (averageCompletion / 100)
            .clamp(0.0, 1.0);

    final isReadOnly =
        access['mode']?.toString() ==
            'READ_ONLY';

    return RefreshIndicator(
      onRefresh: loadProgress,
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          buildUnitHeader(
            unitCode: unitCode,
            unitName: unitName,
            yearName: yearName,
            requiresLogbook:
                unit['requires_logbook'] == true ||
                    unit['requires_logbook'] == 1,
            isReadOnly: isReadOnly,
          ),

          const SizedBox(height: 16),

          buildOverallProgressCard(
            averageCompletion:
                averageCompletion,
            progress: progress,
            summary: summary,
            logbooks: logbooks,
          ),

          const SizedBox(height: 16),

          buildClinicalEntryCard(
            clinicalEntries,
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              const Expanded(
                child: Text(
                  'Enrolled Students',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '${students.length}',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (students.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 48,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'No students are enrolled in this unit.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ...students.map((item) {
              return buildStudentCard(
                mapOf(item),
              );
            }),

          const SizedBox(height: 8),

          buildReadOnlyNotice(),
        ],
      ),
    );
  }

  Widget buildUnitHeader({
    required String unitCode,
    required String unitName,
    required String yearName,
    required bool requiresLogbook,
    required bool isReadOnly,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  child: Icon(
                    Icons.menu_book_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        unitCode,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        unitName,
                        style: const TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: const Icon(
                    Icons.school_outlined,
                    size: 17,
                  ),
                  label: Text(yearName),
                ),
                if (isReadOnly)
                  const Chip(
                    avatar: Icon(
                      Icons.visibility_outlined,
                      size: 17,
                    ),
                    label: Text('Read Only'),
                  ),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Icon(
                  requiresLogbook
                      ? Icons
                          .assignment_turned_in_outlined
                      : Icons.assignment_outlined,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    requiresLogbook
                        ? 'Clinical logbook required'
                        : 'No clinical logbook required',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildOverallProgressCard({
    required double averageCompletion,
    required double progress,
    required Map<String, dynamic> summary,
    required Map<String, dynamic> logbooks,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Overall Unit Progress',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Text(
                    'Average Completion',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
                Text(
                  '${averageCompletion.toStringAsFixed(2)}%',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            LinearProgressIndicator(
              value: progress,
              minHeight: 9,
            ),

            const SizedBox(height: 20),

            Wrap(
              spacing: 24,
              runSpacing: 16,
              children: [
                buildStat(
                  'Students',
                  summary['enrolled_students'] ??
                      0,
                  Icons.people_outline,
                ),
                buildStat(
                  'Logbooks',
                  logbooks['total'] ?? 0,
                  Icons.assignment_outlined,
                ),
                buildStat(
                  'Active',
                  logbooks['active'] ?? 0,
                  Icons.pending_actions_outlined,
                ),
                buildStat(
                  'Completed',
                  logbooks['completed'] ?? 0,
                  Icons.check_circle_outline,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildClinicalEntryCard(
    Map<String, dynamic> entries,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Clinical Entries',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            Wrap(
              spacing: 24,
              runSpacing: 16,
              children: [
                buildStat(
                  'Total',
                  entries['total'] ?? 0,
                  Icons.list_alt_outlined,
                ),
                buildStat(
                  'Verified',
                  entries['verified'] ?? 0,
                  Icons.verified_outlined,
                ),
                buildStat(
                  'Pending',
                  entries[
                          'pending_verification'] ??
                      0,
                  Icons.hourglass_empty,
                ),
                buildStat(
                  'Rejected',
                  entries['rejected'] ?? 0,
                  Icons.cancel_outlined,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildStudentCard(
    Map<String, dynamic> item,
  ) {
    final student =
        mapOf(item['student']);

    final enrollment =
        mapOf(item['enrollment']);

    final progressData =
        mapOf(item['progress']);

    final yearLevel =
        mapOf(student['year_level']);

    final clinicalEntries = mapOf(
      progressData['clinical_entries'],
    );

    final logbooks =
        listOf(item['logbooks']);

    final name =
        student['name']?.toString() ??
            'Student';

    final dwuId =
        student['dwu_id']?.toString() ?? '-';

    final yearName =
        yearLevel['year_name']?.toString() ??
            'Year Level Not Set';

    final enrollmentStatus =
        enrollment['status']?.toString() ??
            'UNKNOWN';

    final averageCompletion = toDouble(
      progressData[
          'average_completion_percentage'],
    );

    final studentProgress =
        (averageCompletion / 100)
            .clamp(0.0, 1.0);

    return Card(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  child: Icon(
                    Icons.person_outline,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        '$dwuId • $yearName',
                        style: TextStyle(
                          color:
                              Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                Chip(
                  label: Text(
                    enrollmentStatus,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Text(
                    'Logbook Completion',
                    style: TextStyle(
                      color:
                          Colors.grey.shade700,
                    ),
                  ),
                ),
                Text(
                  '${averageCompletion.toStringAsFixed(2)}%',
                  style: const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            LinearProgressIndicator(
              value: studentProgress,
              minHeight: 8,
            ),

            const SizedBox(height: 16),

            Wrap(
              spacing: 22,
              runSpacing: 14,
              children: [
                buildSmallStat(
                  'Logbooks',
                  progressData[
                          'logbook_count'] ??
                      0,
                ),
                buildSmallStat(
                  'Verified',
                  clinicalEntries[
                          'verified'] ??
                      0,
                ),
                buildSmallStat(
                  'Pending',
                  clinicalEntries[
                          'pending_verification'] ??
                      0,
                ),
                buildSmallStat(
                  'Rejected',
                  clinicalEntries[
                          'rejected'] ??
                      0,
                ),
              ],
            ),

            if (logbooks.isNotEmpty) ...[
              const SizedBox(height: 18),
              const Divider(),
              const SizedBox(height: 8),

              const Text(
                'Logbook Details',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              ...logbooks.map((logbookItem) {
                return buildLogbook(
                  mapOf(logbookItem),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget buildLogbook(
    Map<String, dynamic> logbook,
  ) {
    final templateName =
        logbook['template_name']
                ?.toString() ??
            'Clinical Logbook';

    final status =
        logbook['status']?.toString() ??
            'UNKNOWN';

    final completion = toDouble(
      logbook['completion_percentage'],
    );

    final minimum = toDouble(
      logbook[
          'minimum_completion_percentage'],
    );

    final requirementMet =
        logbook[
                'completion_requirement_met'] ==
            true;

    final progress =
        (completion / 100)
            .clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey.shade300,
        ),
        borderRadius:
            BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            templateName,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 8),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                label: Text(status),
              ),
              Chip(
                avatar: Icon(
                  requirementMet
                      ? Icons.check_circle_outline
                      : Icons.timelapse_outlined,
                  size: 17,
                ),
                label: Text(
                  requirementMet
                      ? 'Requirement Met'
                      : 'In Progress',
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: Text(
                  'Completion',
                  style: TextStyle(
                    color:
                        Colors.grey.shade700,
                  ),
                ),
              ),
              Text(
                '${completion.toStringAsFixed(2)}%',
                style: const TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          LinearProgressIndicator(
            value: progress,
            minHeight: 7,
          ),

          const SizedBox(height: 8),

          Text(
            'Required: '
            '${minimum.toStringAsFixed(2)}%',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildStat(
    String label,
    dynamic value,
    IconData icon,
  ) {
    return SizedBox(
      width: 120,
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  value.toString(),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSmallStat(
    String label,
    dynamic value,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget buildReadOnlyNotice() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.visibility_outlined,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'HOD monitoring is read only. '
                'Clinical verification, student '
                'enrollment, and logbook changes '
                'are handled by the appropriate '
                'lecturer or student workflow.',
                style: TextStyle(
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> mapOf(
    dynamic value,
  ) {
    if (value is Map) {
      return Map<String, dynamic>.from(
        value,
      );
    }

    return <String, dynamic>{};
  }

  List<dynamic> listOf(
    dynamic value,
  ) {
    if (value is List) {
      return value;
    }

    return <dynamic>[];
  }

  double toDouble(
    dynamic value,
  ) {
    if (value == null) {
      return 0;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value.toString(),
        ) ??
        0;
  }
}