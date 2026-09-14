import 'package:flutter/material.dart';
import '../services/api_service.dart';

class HodStudentProgressScreen extends StatefulWidget {
  final int studentId;

  const HodStudentProgressScreen({
    super.key,
    required this.studentId,
  });

  @override
  State<HodStudentProgressScreen> createState() =>
      _HodStudentProgressScreenState();
}

class _HodStudentProgressScreenState
    extends State<HodStudentProgressScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await ApiService.getHodStudentProgress(
        widget.studentId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = e
            .toString()
            .replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0.0;
  }

  int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  String _text(dynamic value) {
    final text = value?.toString().trim() ?? '';

    if (text.isEmpty || text == 'null') {
      return 'Not available';
    }

    return text;
  }

  Widget _buildHeaderCard(
    Map<String, dynamic> student,
  ) {
    final yearLevel =
        student['year_level'] as Map<String, dynamic>? ??
            {};

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 28,
                  child: Text(
                    _text(student['name'])
                        .substring(0, 1)
                        .toUpperCase(),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        _text(student['name']),
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _text(student['dwu_id']),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _text(student['email']),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar:
                      const Icon(Icons.school, size: 18),
                  label: Text(
                    _text(yearLevel['year_name']),
                  ),
                ),
                const Chip(
                  avatar: Icon(
                    Icons.visibility_outlined,
                    size: 18,
                  ),
                  label: Text('Read Only'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallProgressCard(
    Map<String, dynamic> summary,
  ) {
    final logbooks =
        summary['logbooks'] as Map<String, dynamic>? ??
            {};

    final clinicalEntries =
        summary['clinical_entries']
                as Map<String, dynamic>? ??
            {};

    final averageCompletion = _toDouble(
      logbooks['average_completion_percentage'],
    );

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overall Progress',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                const Text('Average Completion'),
                Text(
                  '${averageCompletion.toStringAsFixed(2)}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: (averageCompletion / 100)
                  .clamp(0.0, 1.0),
              minHeight: 9,
              borderRadius:
                  BorderRadius.circular(10),
            ),
            const SizedBox(height: 20),
            _buildStatGrid(
              items: [
                _StatItem(
                  label: 'Enrollments',
                  value: _toInt(
                    summary['enrollment_count'],
                  ).toString(),
                  icon: Icons.menu_book_outlined,
                ),
                _StatItem(
                  label: 'Logbooks',
                  value: _toInt(
                    logbooks['total'],
                  ).toString(),
                  icon:
                      Icons.library_books_outlined,
                ),
                _StatItem(
                  label: 'Completed',
                  value: _toInt(
                    logbooks['completed'],
                  ).toString(),
                  icon:
                      Icons.task_alt_outlined,
                ),
                _StatItem(
                  label: 'Active',
                  value: _toInt(
                    logbooks['active'],
                  ).toString(),
                  icon:
                      Icons.pending_actions_outlined,
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            Text(
              'Clinical Entries',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildStatGrid(
              items: [
                _StatItem(
                  label: 'Total',
                  value: _toInt(
                    clinicalEntries['total'],
                  ).toString(),
                  icon:
                      Icons.assignment_outlined,
                ),
                _StatItem(
                  label: 'Verified',
                  value: _toInt(
                    clinicalEntries['verified'],
                  ).toString(),
                  icon: Icons.verified_outlined,
                ),
                _StatItem(
                  label: 'Pending',
                  value: _toInt(
                    clinicalEntries[
                        'pending_verification'],
                  ).toString(),
                  icon:
                      Icons.hourglass_top_outlined,
                ),
                _StatItem(
                  label: 'Rejected',
                  value: _toInt(
                    clinicalEntries['rejected'],
                  ).toString(),
                  icon: Icons.cancel_outlined,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatGrid({
    required List<_StatItem> items,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final itemWidth =
            (availableWidth - 12) / 2;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items.map((item) {
            return SizedBox(
              width: itemWidth,
              child: Container(
                padding:
                    const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context)
                        .dividerColor,
                  ),
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      item.icon,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.value,
                            style: const TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.label,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildUnitCard(
    Map<String, dynamic> record,
  ) {
    final enrollment =
        record['enrollment'] as Map<String, dynamic>? ??
            {};

    final unit =
        record['unit'] as Map<String, dynamic>? ?? {};

    final unitYearLevel =
        unit['year_level'] as Map<String, dynamic>? ??
            {};

    final logbook =
        record['logbook'] as Map<String, dynamic>?;

    final clinicalEntries =
        record['clinical_entries']
                as Map<String, dynamic>? ??
            {};

    final completion = logbook == null
        ? 0.0
        : _toDouble(
            logbook['completion_percentage'],
          );

    final minimumCompletion = logbook == null
        ? 0.0
        : _toDouble(
            logbook[
                'minimum_completion_percentage'],
          );

    final completionMet = logbook == null
        ? false
        : logbook['completion_requirement_met'] ==
            true;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.menu_book_outlined,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_text(unit['unit_code'])} - '
                        '${_text(unit['unit_name'])}',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _text(
                          unitYearLevel['year_name'],
                        ),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(
                    _text(
                      enrollment['status'],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (logbook == null) ...[
              const Text(
                'No logbook has been assigned for this enrollment.',
              ),
            ] else ...[
              Text(
                _text(logbook['template_name']),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Completion'),
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
                value: (completion / 100)
                    .clamp(0.0, 1.0),
                minHeight: 9,
                borderRadius:
                    BorderRadius.circular(10),
              ),
              const SizedBox(height: 8),
              Text(
                'Required: '
                '${minimumCompletion.toStringAsFixed(0)}%',
              ),
              const SizedBox(height: 10),
              Chip(
                avatar: Icon(
                  completionMet
                      ? Icons.check_circle_outline
                      : Icons
                          .radio_button_unchecked,
                  size: 18,
                ),
                label: Text(
                  completionMet
                      ? 'Completion Requirement Met'
                      : 'Completion Requirement Not Met',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Logbook Status: '
                '${_text(logbook['status'])}',
              ),
            ],

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Text(
              'Clinical Entries',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildStatGrid(
              items: [
                _StatItem(
                  label: 'Total',
                  value: _toInt(
                    clinicalEntries['total'],
                  ).toString(),
                  icon:
                      Icons.assignment_outlined,
                ),
                _StatItem(
                  label: 'Verified',
                  value: _toInt(
                    clinicalEntries['verified'],
                  ).toString(),
                  icon: Icons.verified_outlined,
                ),
                _StatItem(
                  label: 'Pending',
                  value: _toInt(
                    clinicalEntries[
                        'pending_verification'],
                  ).toString(),
                  icon:
                      Icons.hourglass_top_outlined,
                ),
                _StatItem(
                  label: 'Rejected',
                  value: _toInt(
                    clinicalEntries['rejected'],
                  ).toString(),
                  icon: Icons.cancel_outlined,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final data = _data!;

    final student =
        data['student'] as Map<String, dynamic>? ??
            {};

    final summary =
        data['summary'] as Map<String, dynamic>? ??
            {};

    final units =
        data['units'] as List<dynamic>? ?? [];

    return RefreshIndicator(
      onRefresh: _loadProgress,
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeaderCard(student),
          const SizedBox(height: 16),
          _buildOverallProgressCard(summary),
          const SizedBox(height: 24),
          Row(
            children: [
              const Icon(Icons.school_outlined),
              const SizedBox(width: 8),
              Text(
                'Units & Logbooks',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(
                      fontWeight:
                          FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (units.isEmpty)
            Card(
              margin: EdgeInsets.zero,
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'This student has no department unit enrollments.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ...units.map(
              (record) => _buildUnitCard(
                Map<String, dynamic>.from(
                  record as Map,
                ),
              ),
            ),

          const SizedBox(height: 16),
          const Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 21,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'This page is for departmental monitoring only. '
                      'The HOD cannot approve verifications, enroll students, '
                      'or modify clinical entries.',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Student Progress',
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed:
                _isLoading ? null : _loadProgress,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize:
                          MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _errorMessage!,
                          textAlign:
                              TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed:
                              _loadProgress,
                          icon: const Icon(
                            Icons.refresh,
                          ),
                          label:
                              const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _buildContent(),
    );
  }
}

class _StatItem {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });
}