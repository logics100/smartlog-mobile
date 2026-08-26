import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'supervisor_verification_screen.dart';

class ClinicalEntriesScreen extends StatefulWidget {
  final int logbookId;

  const ClinicalEntriesScreen({
    super.key,
    required this.logbookId,
  });

  @override
  State<ClinicalEntriesScreen> createState() =>
      _ClinicalEntriesScreenState();
}

class _ClinicalEntriesScreenState
    extends State<ClinicalEntriesScreen> {
  late Future<List<dynamic>> entriesFuture;

  @override
  void initState() {
    super.initState();
    entriesFuture =
        ApiService.getClinicalEntries(widget.logbookId);
  }

  Future<void> refreshEntries() async {
    setState(() {
      entriesFuture =
          ApiService.getClinicalEntries(widget.logbookId);
    });

    await entriesFuture;
  }

  IconData statusIcon(String status) {
    switch (status) {
      case 'VERIFIED':
        return Icons.verified;
      case 'REJECTED':
        return Icons.cancel;
      default:
        return Icons.pending_actions;
    }
  }

  String readableStatus(String status) {
    switch (status) {
      case 'VERIFIED':
        return 'Verified';
      case 'REJECTED':
        return 'Rejected';
      case 'PENDING_VERIFICATION':
        return 'Pending Verification';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Clinical Entries'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: entriesFuture,
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
                      'Unable to load clinical entries.',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: refreshEntries,
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          }

          final entries = snapshot.data ?? [];

          if (entries.isEmpty) {
            return RefreshIndicator(
              onRefresh: refreshEntries,
              child: ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 200),
                  Center(
                    child: Text(
                      'No clinical entries recorded yet.',
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: refreshEntries,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry =
                    entries[index] as Map<String, dynamic>;

                final status =
                    entry['status']?.toString() ?? '';

                final verificationStatus =
                    entry['verification_status']
                        ?.toString();

                final supervisorName =
                    entry['supervisor_name']
                        ?.toString();

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
                          children: [
                            Icon(
                              statusIcon(status),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                entry['item_name']
                                        ?.toString() ??
                                    'Clinical Activity',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Text(
                          'Date: ${entry['activity_date'] ?? ''}',
                        ),

                        const SizedBox(height: 4),

                        Text(
                          'Facility: ${entry['facility_name'] ?? ''}',
                        ),

                        if (entry['clinical_area'] != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Clinical Area: ${entry['clinical_area']}',
                          ),
                        ],

                        if (entry['competency_level'] != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Level: ${entry['competency_level']}',
                          ),
                        ],

                        const SizedBox(height: 10),

                        Text(
                          'Status: ${readableStatus(status)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        if (verificationStatus != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Verification: $verificationStatus',
                          ),
                        ],

                        if (supervisorName != null &&
                            supervisorName.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Supervisor: $supervisorName',
                          ),
                        ],

                        if (entry['activity_details'] != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            entry['activity_details']
                                .toString(),
                          ),
                        ],

                        // Supervisor verification button
                        if (status ==
                            'PENDING_VERIFICATION') ...[
                          const SizedBox(height: 16),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final entryId = int.parse(
                                  entry['id'].toString(),
                                );

                                final result =
                                    await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        SupervisorVerificationScreen(
                                      entryId: entryId,
                                      procedureName:
                                          entry['item_name']
                                                  ?.toString() ??
                                              'Clinical Activity',
                                      facilityName:
                                          entry['facility_name']
                                              ?.toString(),
                                    ),
                                  ),
                                );

                                if (result == true) {
                                  refreshEntries();
                                }
                              },
                              icon: const Icon(
                                Icons.verified_user,
                              ),
                              label: const Text(
                                'Supervisor Verification',
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
          );
        },
      ),
    );
  }
}