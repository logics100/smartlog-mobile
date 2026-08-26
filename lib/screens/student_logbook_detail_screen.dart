import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'clinical_entry_screen.dart';
import 'clinical_entries_screen.dart';

class StudentLogbookDetailScreen extends StatefulWidget {
  final int logbookId;

  const StudentLogbookDetailScreen({
    super.key,
    required this.logbookId,
  });

  @override
  State<StudentLogbookDetailScreen> createState() =>
      _StudentLogbookDetailScreenState();
}


class _StudentLogbookDetailScreenState
    extends State<StudentLogbookDetailScreen> {
  late Future<Map<String, dynamic>> detailFuture;

  @override
  void initState() {
    super.initState();

    detailFuture =
        ApiService.getStudentLogbookDetails(widget.logbookId);
  }

  Future<void> refreshDetails() async {
    setState(() {
      detailFuture =
          ApiService.getStudentLogbookDetails(widget.logbookId);
    });

    await detailFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logbook'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: detailFuture,
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
                      'Unable to load logbook.',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: refreshDetails,
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          }

          final data = snapshot.data!;

          final logbook =
              data['logbook'] as Map<String, dynamic>;

          final sections =
              (data['sections'] as List<dynamic>?) ?? [];

          return RefreshIndicator(
            onRefresh: refreshDetails,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  logbook['template_name'] ??
                      'Clinical Logbook',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  '${logbook['unit_code']} - ${logbook['unit_name']}',
                ),

                const SizedBox(height: 8),

                Text(
                  'Status: ${logbook['status']}',
                ),

                const SizedBox(height: 20),
                SizedBox(
  width: double.infinity,
  child: ElevatedButton.icon(
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ClinicalEntriesScreen(
            logbookId: widget.logbookId,
          ),
        ),
      );
    },
    icon: const Icon(
      Icons.assignment,
    ),
    label: const Text(
      'My Clinical Entries',
    ),
  ),
),

                const Text(
                  'Logbook Sections',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                ...sections.map((section) {
                  final sectionMap =
                      section as Map<String, dynamic>;

                  final items =
                      (sectionMap['items'] as List<dynamic>?) ??
                          [];

                  return Card(
                    margin: const EdgeInsets.only(
                      bottom: 12,
                    ),
                    child: ExpansionTile(
                      title: Text(
                        sectionMap['section_title'] ??
                            'Section',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      subtitle:
                          sectionMap['instructions'] != null
                              ? Text(
                                  sectionMap['instructions']
                                      .toString(),
                                )
                              : null,

                      children: [
                        if (items.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'No procedure items in this section.',
                            ),
                          ),

                        ...items.map((item) {
                          final itemMap =
                              item as Map<String, dynamic>;

                          final requirements =
                              (itemMap['requirements']
                                      as List<dynamic>?) ??
                                  [];

                          return ListTile(
                            leading: const Icon(
                              Icons.check_circle_outline,
                            ),

                            title: Text(
                              itemMap['item_name'] ??
                                  'Procedure',
                            ),

                            subtitle: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),

                                Text(
                                  'Required count: ${itemMap['required_count'] ?? 0}',
                                ),

                                if (requirements.isNotEmpty)
                                  Padding(
                                    padding:
                                        const EdgeInsets.only(
                                      top: 4,
                                    ),
                                    child: Text(
                                      'Requirements: ${requirements.map((r) => r['requirement_code']).join(', ')}',
                                    ),
                                  ),
                              ],
                            ),

                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                            ),

                            onTap: () async {
  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ClinicalEntryScreen(
        logbookId: widget.logbookId,
        item: itemMap,
      ),
    ),
  );

  if (result == true) {
    refreshDetails();
  }
},
                          );
                        }),
                      ],
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}