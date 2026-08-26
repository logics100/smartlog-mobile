import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'student_logbook_detail_screen.dart';

class StudentLogbooksScreen extends StatefulWidget {
  const StudentLogbooksScreen({super.key});

  @override
  State<StudentLogbooksScreen> createState() =>
      _StudentLogbooksScreenState();
}

class _StudentLogbooksScreenState
    extends State<StudentLogbooksScreen> {
  late Future<List<dynamic>> logbooksFuture;

  @override
  void initState() {
    super.initState();
    logbooksFuture = ApiService.getStudentLogbooks();
  }

  Future<void> refreshLogbooks() async {
    setState(() {
      logbooksFuture = ApiService.getStudentLogbooks();
    });

    await logbooksFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Logbooks'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: logbooksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 50,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Unable to load logbooks.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: refreshLogbooks,
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          }

          final logbooks = snapshot.data ?? [];

          if (logbooks.isEmpty) {
            return RefreshIndicator(
              onRefresh: refreshLogbooks,
              child: ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 200),
                  Center(
                    child: Text(
                      'No logbooks have been assigned yet.',
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: refreshLogbooks,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: logbooks.length,
              itemBuilder: (context, index) {
                final logbook = logbooks[index];

                final completion =
                    double.tryParse(
                      logbook['completion_percentage']
                              ?.toString() ??
                          '0',
                    ) ??
                    0;

                final templateName =
                    logbook['template_name'] ??
                        'Clinical Logbook';

                final unitCode =
                    logbook['unit_code'] ?? '';

                final unitName =
                    logbook['unit_name'] ?? '';

                final status =
                    logbook['status'] ?? 'UNKNOWN';

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
                        Text(
                          templateName.toString(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          '$unitCode - $unitName',
                        ),

                        const SizedBox(height: 8),

                        Text(
                          'Status: $status',
                        ),

                        const SizedBox(height: 12),

                        LinearProgressIndicator(
                          value:
                              (completion / 100)
                                  .clamp(0.0, 1.0),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          '${completion.toStringAsFixed(0)}% complete',
                        ),

                        const SizedBox(height: 12),

                        Align(
                          alignment:
                              Alignment.centerRight,
                          child: ElevatedButton(
  onPressed: () {
    final logbookId =
        int.parse(logbook['id'].toString());

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            StudentLogbookDetailScreen(
          logbookId: logbookId,
        ),
      ),
    );
  },
  child: const Text(
    'Open Logbook',
  ),
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