import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'hod_unit_progress_screen.dart';

class HodUnitsScreen extends StatefulWidget {
  const HodUnitsScreen({super.key});

  @override
  State<HodUnitsScreen> createState() => _HodUnitsScreenState();
}

class _HodUnitsScreenState extends State<HodUnitsScreen> {
  bool loading = true;
  String? errorMessage;

  List<dynamic> units = [];
  List<dynamic> yearLevels = [];

  int? selectedYearLevelId;

  @override
  void initState() {
    super.initState();
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final results = await Future.wait([
        ApiService.getHodYearLevels(),
        ApiService.getHodUnits(),
      ]);

      if (!mounted) return;

      setState(() {
        yearLevels = results[0];
        units = results[1];
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'Unable to load department units.';
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> loadUnits() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final result = await ApiService.getHodUnits(
        yearLevelId: selectedYearLevelId,
      );

      if (!mounted) return;

      setState(() {
        units = result;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'Unable to load department units.';
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> clearFilter() async {
    setState(() {
      selectedYearLevelId = null;
    });

    await loadUnits();
  }

  Future<void> openUnitProgress(Map<String, dynamic> unit) async {
    final unitId = unit['id'];

    if (unitId is! int) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => HodUnitProgressScreen(unitId: unitId)),
    );

    if (!mounted) return;

    await loadUnits();
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
        title: const Text('Department Units'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: loading ? null : loadUnits,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          buildFilterCard(),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage != null
                ? buildErrorState()
                : buildUnitList(),
          ),
        ],
      ),
    );
  }

  Widget buildFilterCard() {
    return Card(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: const Color(0xFFDBE7F2)),
      ),
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<int?>(
              initialValue: selectedYearLevelId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Year Level',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.school_outlined),
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('All Year Levels'),
                ),
                ...yearLevels.map((item) {
                  final year = Map<String, dynamic>.from(item as Map);

                  return DropdownMenuItem<int?>(
                    value: year['id'] as int?,
                    child: Text(
                      year['year_name']?.toString() ?? 'Year Level',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }),
              ],
              onChanged: loading
                  ? null
                  : (value) {
                      setState(() {
                        selectedYearLevelId = value;
                      });

                      loadUnits();
                    },
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: loading ? null : clearFilter,
                icon: const Icon(Icons.filter_alt_off),
                label: const Text('Clear Filter'),
              ),
            ),
          ],
        ),
      ),
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
              onPressed: loadUnits,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildUnitList() {
    return RefreshIndicator(
      onRefresh: loadUnits,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${units.length} Unit'
                  '${units.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Chip(
                avatar: Icon(Icons.visibility_outlined, size: 17),
                label: Text('Read Only'),
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
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.menu_book_outlined, size: 48),
                    SizedBox(height: 12),
                    Text('No units found.', textAlign: TextAlign.center),
                  ],
                ),
              ),
            )
          else
            ...units.map((item) {
              final unit = Map<String, dynamic>.from(item as Map);

              return buildUnitCard(unit);
            }),
        ],
      ),
    );
  }

  Widget buildUnitCard(Map<String, dynamic> unit) {
    final yearLevel = Map<String, dynamic>.from(unit['year_level'] ?? {});

    final statistics = Map<String, dynamic>.from(unit['statistics'] ?? {});

    final unitCode = unit['unit_code']?.toString() ?? 'UNIT';

    final unitName = unit['unit_name']?.toString() ?? 'Unit';

    final yearName = yearLevel['year_name']?.toString() ?? 'Year Level Not Set';

    final requiresLogbook =
        unit['requires_logbook'] == true || unit['requires_logbook'] == 1;

    final enrolledStudents = statistics['enrolled_students'] ?? 0;

    final logbookCount = statistics['logbook_count'] ?? 0;

    final averageCompletion = toDouble(
      statistics['average_completion_percentage'],
    );

    final progress = (averageCompletion / 100).clamp(0.0, 1.0);

    return Card(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: const Color(0xFFDBE7F2)),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => openUnitProgress(unit),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(child: Icon(Icons.menu_book_outlined)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          unitCode,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          unitName,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Chip(label: Text(yearName)),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(
                    requiresLogbook
                        ? Icons.assignment_turned_in_outlined
                        : Icons.assignment_outlined,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      requiresLogbook
                          ? 'Clinical logbook required'
                          : 'No logbook required',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Average Completion',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ),
                  Text(
                    '${averageCompletion.toStringAsFixed(2)}%',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: progress, minHeight: 8),
              const SizedBox(height: 16),
              Wrap(
                spacing: 24,
                runSpacing: 12,
                children: [
                  buildSmallStat('Students', enrolledStudents),
                  buildSmallStat('Logbooks', logbookCount),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'View Unit Progress',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, size: 20),
                ],
              ),
            ],
          ),
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

  double toDouble(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0;
  }
}
