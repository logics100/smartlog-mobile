import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../services/api_service.dart';

class StudentLogbookProgressScreen extends StatefulWidget {
  final int logbookId;

  const StudentLogbookProgressScreen({super.key, required this.logbookId});

  @override
  State<StudentLogbookProgressScreen> createState() =>
      _StudentLogbookProgressScreenState();
}

class _StudentLogbookProgressScreenState
    extends State<StudentLogbookProgressScreen> {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  late Future<Map<String, dynamic>> progressFuture;

  bool _usingOfflineCache = false;

  String get _cacheKey => 'student_logbook_progress_${widget.logbookId}';

  @override
  void initState() {
    super.initState();

    progressFuture = _loadProgress();
  }

  Future<Map<String, dynamic>> _loadProgress() async {
    try {
      final data = await ApiService.getStudentLogbookProgress(widget.logbookId);

      await _storage.write(key: _cacheKey, value: jsonEncode(data));

      if (mounted) {
        setState(() {
          _usingOfflineCache = false;
        });
      }

      return data;
    } catch (networkError) {
      final cachedJson = await _storage.read(key: _cacheKey);

      if (cachedJson != null && cachedJson.trim().isNotEmpty) {
        try {
          final decoded = jsonDecode(cachedJson);

          if (decoded is Map) {
            if (mounted) {
              setState(() {
                _usingOfflineCache = true;
              });
            }

            return Map<String, dynamic>.from(decoded);
          }
        } catch (_) {
          // Cached data is invalid.
          // Continue to the normal error below.
        }
      }

      throw Exception(
        'No cached logbook progress is available on '
        'this device yet. Connect to SmartLog once '
        'and open this progress screen while online. '
        'After that, the progress will also be '
        'available offline.',
      );
    }
  }

  Future<void> refreshProgress() async {
    final nextFuture = _loadProgress();

    setState(() {
      progressFuture = nextFuture;
    });

    await nextFuture;
  }

  double _toDouble(dynamic value) {
    return double.tryParse(value?.toString() ?? '0') ?? 0;
  }

  int _toInt(dynamic value) {
    return int.tryParse(value?.toString() ?? '0') ?? 0;
  }

  String _displayProgressStatus(String status) {
    switch (status) {
      case 'COMPLETION_REQUIREMENT_MET':
        return 'COMPLETION REQUIREMENT MET';

      case 'IN_PROGRESS':
        return 'IN PROGRESS';

      case 'NOT_STARTED':
        return 'NOT STARTED';

      default:
        return status.replaceAll('_', ' ');
    }
  }

  Widget _informationRow({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(value, textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _offlineBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.cloud_off, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Offline mode — showing last saved '
              'logbook progress.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorView(Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 52),
            const SizedBox(height: 16),
            const Text(
              'Unable to load logbook progress.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(error.toString(), textAlign: TextAlign.center),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: refreshProgress,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Logbook Progress')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: progressFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _errorView(snapshot.error);
          }

          if (!snapshot.hasData) {
            return _errorView('No logbook progress data is available.');
          }

          final data = snapshot.data!;

          final logbook = Map<String, dynamic>.from(data['logbook'] ?? {});

          final progress = Map<String, dynamic>.from(data['progress'] ?? {});

          final summary = Map<String, dynamic>.from(data['summary'] ?? {});

          final unit = Map<String, dynamic>.from(data['unit'] ?? {});

          final completionPercentage = _toDouble(
            progress['completion_percentage'],
          );

          final requiredPercentage = _toDouble(
            progress['minimum_completion_percentage'],
          );

          final completedRequirements = _toInt(
            progress['completed_requirements'],
          );

          final totalRequirements = _toInt(progress['total_requirements']);

          final remainingRequirements = _toInt(
            progress['remaining_requirements'],
          );

          final completionStatus =
              progress['completion_status']?.toString() ?? 'NOT_STARTED';

          final requirementMet = progress['completion_requirement_met'] == true;

          final logbookStatus = logbook['status']?.toString() ?? 'UNKNOWN';

          final templateName =
              logbook['template_name']?.toString() ?? 'Clinical Logbook';

          final unitCode = unit['unit_code']?.toString() ?? '';

          final unitName = unit['unit_name']?.toString() ?? '';

          return RefreshIndicator(
            onRefresh: refreshProgress,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                if (_usingOfflineCache) _offlineBanner(),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          templateName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$unitCode - $unitName',
                          style: const TextStyle(fontSize: 15),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.menu_book_outlined),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Logbook Status: '
                                '$logbookStatus',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Logbook Completion',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Completed '
                          '${completionPercentage.toStringAsFixed(2)}%',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 14),
                        LinearProgressIndicator(
                          value: (completionPercentage / 100).clamp(0.0, 1.0),
                          minHeight: 10,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${completionPercentage.toStringAsFixed(2)}% '
                          'of logbook requirements completed',
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Required completion: '
                          '${requiredPercentage.toStringAsFixed(0)}%',
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              requirementMet
                                  ? Icons.check_circle
                                  : Icons.hourglass_bottom,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Completion Status: '
                                '${_displayProgressStatus(completionStatus)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Requirements Progress',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _informationRow(
                          label: 'Requirements Completed',
                          value: '$completedRequirements',
                        ),
                        _informationRow(
                          label: 'Total Requirements',
                          value: '$totalRequirements',
                        ),
                        _informationRow(
                          label: 'Requirements Remaining',
                          value: '$remainingRequirements',
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Clinical Entries',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _informationRow(
                          label: 'Total Entries',
                          value: '${_toInt(summary['total_entries'])}',
                        ),
                        _informationRow(
                          label: 'Verified',
                          value: '${_toInt(summary['verified_entries'])}',
                        ),
                        _informationRow(
                          label: 'Pending Verification',
                          value: '${_toInt(summary['pending_entries'])}',
                        ),
                        _informationRow(
                          label: 'Rejected',
                          value: '${_toInt(summary['rejected_entries'])}',
                        ),
                        _informationRow(
                          label: 'Draft',
                          value: '${_toInt(summary['draft_entries'])}',
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Completion Requirement',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _informationRow(
                          label: 'Completed',
                          value: '${completionPercentage.toStringAsFixed(2)}%',
                        ),
                        _informationRow(
                          label: 'Required',
                          value: '${requiredPercentage.toStringAsFixed(0)}%',
                        ),
                        _informationRow(
                          label: 'Requirement',
                          value: requirementMet ? 'MET' : 'NOT YET MET',
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}
