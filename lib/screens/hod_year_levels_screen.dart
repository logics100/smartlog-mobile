import 'package:flutter/material.dart';
import '../services/api_service.dart';

class HodYearLevelsScreen extends StatefulWidget {
  const HodYearLevelsScreen({super.key});

  @override
  State<HodYearLevelsScreen> createState() =>
      _HodYearLevelsScreenState();
}

class _HodYearLevelsScreenState
    extends State<HodYearLevelsScreen> {
  bool loading = true;
  String? errorMessage;

  List<dynamic> yearLevels = [];

  @override
  void initState() {
    super.initState();
    loadYearLevels();
  }

  Future<void> loadYearLevels() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final result = await ApiService.getHodYearLevels();

      if (!mounted) return;

      setState(() {
        yearLevels = result;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage =
            'Unable to load department year levels.';
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
        title: const Text('Year Level Progress'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: loading ? null : loadYearLevels,
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
              : buildYearLevelList(),
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
              onPressed: loadYearLevels,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildYearLevelList() {
    return RefreshIndicator(
      onRefresh: loadYearLevels,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${yearLevels.length} Year Level'
                  '${yearLevels.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Chip(
                avatar: Icon(
                  Icons.visibility_outlined,
                  size: 17,
                ),
                label: Text('Read Only'),
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (yearLevels.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.school_outlined,
                      size: 48,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'No year-level information found.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ...yearLevels.map((item) {
              final year =
                  Map<String, dynamic>.from(
                item as Map,
              );

              return buildYearLevelCard(year);
            }),
        ],
      ),
    );
  }

  Widget buildYearLevelCard(
    Map<String, dynamic> year,
  ) {
    final yearName =
        year['year_name']?.toString() ??
            'Year Level';

    final studentCount =
        year['student_count'] ?? 0;

    final unitCount =
        year['unit_count'] ?? 0;

    final totalLogbooks =
        year['total_logbooks'] ?? 0;

    final completedLogbooks =
        year['completed_logbooks'] ?? 0;

    final activeLogbooks =
        year['active_logbooks'] ?? 0;

    final averageCompletion = toDouble(
      year['average_completion_percentage'],
    );

    final progress =
        (averageCompletion / 100).clamp(0.0, 1.0);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  child: Icon(
                    Icons.school_outlined,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    yearName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

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
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            LinearProgressIndicator(
              value: progress,
              minHeight: 8,
            ),

            const SizedBox(height: 18),

            Wrap(
              spacing: 26,
              runSpacing: 14,
              children: [
                buildSmallStat(
                  'Students',
                  studentCount,
                ),
                buildSmallStat(
                  'Units',
                  unitCount,
                ),
                buildSmallStat(
                  'Logbooks',
                  totalLogbooks,
                ),
                buildSmallStat(
                  'Active',
                  activeLogbooks,
                ),
                buildSmallStat(
                  'Completed',
                  completedLogbooks,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSmallStat(
    String label,
    dynamic value,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 17,
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

  double toDouble(dynamic value) {
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