import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'student_logbook_detail_screen.dart';
import '../services/local_database_service.dart';

class StudentLogbooksScreen extends StatefulWidget {
  const StudentLogbooksScreen({super.key});

  @override
  State<StudentLogbooksScreen> createState() => _StudentLogbooksScreenState();
}

class _StudentLogbooksScreenState extends State<StudentLogbooksScreen> {
  late Future<List<dynamic>> logbooksFuture;

  @override
  void initState() {
    super.initState();
    logbooksFuture = loadLogbooks();
  }

  Future<List<dynamic>> loadLogbooks() async {
    try {
      final logbooks = await ApiService.getStudentLogbooks();

      await LocalDatabaseService.cacheStudentLogbooks(logbooks);

      return logbooks;
    } catch (_) {
      final cached = await LocalDatabaseService.getCachedStudentLogbooks();

      if (cached.isNotEmpty) {
        return cached;
      }

      rethrow;
    }
  }

  Future<void> refreshLogbooks() async {
    setState(() {
      logbooksFuture = loadLogbooks();
    });

    await logbooksFuture;
  }

  String formatCompletionStatus(String status) {
    switch (status) {
      case 'COMPLETION_REQUIREMENT_MET':
        return 'COMPLETION REQUIREMENT MET';

      case 'IN_PROGRESS':
        return 'IN PROGRESS';

      case 'NOT_STARTED':
        return 'NOT STARTED';

      default:
        return status.replaceAll('_', ' ').toUpperCase();
    }
  }

  Color getCompletionStatusColor(String status) {
    switch (status) {
      case 'COMPLETION_REQUIREMENT_MET':
        return Colors.green;

      case 'IN_PROGRESS':
        return Colors.orange;

      case 'NOT_STARTED':
        return Colors.grey;

      default:
        return Colors.grey;
    }
  }

  Color getLogbookStatusColor(String status) {
    switch (status) {
      case 'COMPLETED':
        return Colors.green;

      case 'ACTIVE':
        return Colors.blue;

      case 'SUBMITTED':
        return Colors.orange;

      case 'ARCHIVED':
        return Colors.grey;

      default:
        return Colors.grey;
    }
  }

  Widget buildStatusBadge({required String text, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.40)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Logbooks')),
      body: FutureBuilder<List<dynamic>>(
        future: logbooksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return RefreshIndicator(
              onRefresh: refreshLogbooks,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 140),
                  const Icon(Icons.error_outline, size: 50),
                  const SizedBox(height: 16),
                  const Text(
                    'Unable to load logbooks.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(snapshot.error.toString(), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  Center(
                    child: ElevatedButton(
                      onPressed: refreshLogbooks,
                      child: const Text('Try Again'),
                    ),
                  ),
                ],
              ),
            );
          }

          final logbooks = snapshot.data ?? [];

          if (logbooks.isEmpty) {
            return RefreshIndicator(
              onRefresh: refreshLogbooks,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 200),
                  Center(child: Text('No logbooks have been assigned yet.')),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: refreshLogbooks,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: logbooks.length,
              itemBuilder: (context, index) {
                final Map<String, dynamic> logbook = Map<String, dynamic>.from(
                  logbooks[index],
                );

                final completion =
                    double.tryParse(
                      logbook['completion_percentage']?.toString() ?? '0',
                    ) ??
                    0;

                final requiredCompletion =
                    double.tryParse(
                      logbook['minimum_completion_percentage']?.toString() ??
                          '100',
                    ) ??
                    100;

                final templateName =
                    logbook['template_name']?.toString() ?? 'Clinical Logbook';

                final unitCode = logbook['unit_code']?.toString() ?? '';

                final unitName = logbook['unit_name']?.toString() ?? '';

                final logbookStatus =
                    logbook['status']?.toString() ?? 'UNKNOWN';

                final completionStatus =
                    logbook['completion_status']?.toString() ?? 'NOT_STARTED';

                final completionMet =
                    logbook['completion_requirement_met'] == true;

                final progressValue = (completion / 100)
                    .clamp(0.0, 1.0)
                    .toDouble();

                final completionColor = getCompletionStatusColor(
                  completionStatus,
                );

                final logbookColor = getLogbookStatusColor(logbookStatus);

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          templateName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Row(
                          children: [
                            const Icon(Icons.book_outlined, size: 18),
                            const SizedBox(width: 6),
                            Expanded(child: Text('$unitCode - $unitName')),
                          ],
                        ),

                        const SizedBox(height: 14),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Logbook Progress',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '${completion.toStringAsFixed(2)}%',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        LinearProgressIndicator(
                          value: progressValue,
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(8),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          '${completion.toStringAsFixed(2)}% of logbook requirements completed',
                        ),

                        const SizedBox(height: 4),

                        Text(
                          'Required completion: ${requiredCompletion.toStringAsFixed(0)}%',
                        ),

                        const SizedBox(height: 14),

                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            buildStatusBadge(
                              text: logbookStatus,
                              color: logbookColor,
                            ),
                            buildStatusBadge(
                              text: formatCompletionStatus(completionStatus),
                              color: completionColor,
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Icon(
                              completionMet
                                  ? Icons.check_circle_outline
                                  : Icons.pending_outlined,
                              size: 20,
                              color: completionMet
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                completionMet
                                    ? 'Completion requirement met'
                                    : 'Completion requirement not yet met',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: completionMet
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final logbookId = int.parse(
                                logbook['id'].toString(),
                              );

                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => StudentLogbookDetailScreen(
                                    logbookId: logbookId,
                                  ),
                                ),
                              );

                              if (!mounted) {
                                return;
                              }

                              await refreshLogbooks();
                            },
                            icon: const Icon(Icons.open_in_new),
                            label: const Text('Open Logbook'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
