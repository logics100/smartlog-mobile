import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'hod_student_progress_screen.dart';

class HodStudentsScreen extends StatefulWidget {
  const HodStudentsScreen({super.key});

  @override
  State<HodStudentsScreen> createState() => _HodStudentsScreenState();
}

class _HodStudentsScreenState extends State<HodStudentsScreen> {
  bool loading = true;
  String? errorMessage;

  List<dynamic> students = [];
  List<dynamic> yearLevels = [];

  String searchText = '';
  int? selectedYearLevelId;

  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadInitialData();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadInitialData() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final results = await Future.wait([
        ApiService.getHodYearLevels(),
        ApiService.getHodStudents(),
      ]);

      if (!mounted) return;

      setState(() {
        yearLevels = results[0];
        students = results[1];
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'Unable to load department students.';
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> loadStudents() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final result = await ApiService.getHodStudents(
        search: searchText,
        yearLevelId: selectedYearLevelId,
      );

      if (!mounted) return;

      setState(() {
        students = result;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'Unable to load department students.';
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> clearFilters() async {
    searchController.clear();

    setState(() {
      searchText = '';
      selectedYearLevelId = null;
    });

    await loadStudents();
  }

  Future<void> openStudentProgress(Map<String, dynamic> student) async {
    final studentId = student['id'];

    if (studentId == null) {
      return;
    }

    final id = studentId is int
        ? studentId
        : int.tryParse(studentId.toString());

    if (id == null) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => HodStudentProgressScreen(studentId: id),
      ),
    );

    if (mounted) {
      await loadStudents();
    }
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
        title: const Text('Department Students'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: loading ? null : loadStudents,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          buildFilters(),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage != null
                ? buildErrorState()
                : buildStudentList(),
          ),
        ],
      ),
    );
  }

  Widget buildFilters() {
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
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Search Student',
                hintText: 'Name or DWU ID',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();

                          setState(() {
                            searchText = '';
                          });

                          loadStudents();
                        },
                      )
                    : null,
              ),
              textInputAction: TextInputAction.search,
              onChanged: (value) {
                setState(() {
                  searchText = value;
                });
              },
              onSubmitted: (_) {
                loadStudents();
              },
            ),

            const SizedBox(height: 14),

            DropdownButtonFormField<int?>(
              key: ValueKey(selectedYearLevelId),
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
                    child: Text(year['year_name']?.toString() ?? 'Year Level'),
                  );
                }),
              ],
              onChanged: loading
                  ? null
                  : (value) {
                      setState(() {
                        selectedYearLevelId = value;
                      });

                      loadStudents();
                    },
            ),

            const SizedBox(height: 14),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: loading ? null : clearFilters,
                icon: const Icon(Icons.filter_alt_off),
                label: const Text('Clear Filters'),
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
              onPressed: loadStudents,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildStudentList() {
    return RefreshIndicator(
      onRefresh: loadStudents,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${students.length} '
                  'Student'
                  '${students.length == 1 ? '' : 's'}',
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

          if (students.isEmpty)
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
                    Icon(Icons.person_search_outlined, size: 48),
                    SizedBox(height: 12),
                    Text('No students found.', textAlign: TextAlign.center),
                  ],
                ),
              ),
            )
          else
            ...students.map((item) {
              final student = Map<String, dynamic>.from(item as Map);

              return buildStudentCard(student);
            }),
        ],
      ),
    );
  }

  Widget buildStudentCard(Map<String, dynamic> student) {
    final yearLevel = Map<String, dynamic>.from(student['year_level'] ?? {});

    final statistics = Map<String, dynamic>.from(
      student['statistics'] ?? student['progress'] ?? {},
    );

    final name = student['name']?.toString() ?? 'Student';

    final dwuId = student['dwu_id']?.toString() ?? '';

    final yearName =
        yearLevel['year_name']?.toString() ??
        student['year_name']?.toString() ??
        'Year Level Not Set';

    final enrollmentCount =
        statistics['enrollment_count'] ?? student['enrollment_count'] ?? 0;

    final logbookCount =
        statistics['logbook_count'] ?? student['logbook_count'] ?? 0;

    final completedLogbooks =
        statistics['completed_logbooks'] ?? student['completed_logbooks'] ?? 0;

    final averageCompletion = toDouble(
      statistics['average_completion_percentage'] ??
          student['average_completion_percentage'],
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
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          openStudentProgress(student);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(child: Icon(Icons.person_outline)),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        if (dwuId.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text('DWU ID: $dwuId'),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Chip(label: Text(yearName)),
                      const Icon(Icons.chevron_right),
                    ],
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
                  buildSmallStat('Enrollments', enrollmentCount),
                  buildSmallStat('Logbooks', logbookCount),
                  buildSmallStat('Completed', completedLogbooks),
                ],
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  Icon(
                    Icons.touch_app_outlined,
                    size: 17,
                    color: Colors.grey.shade700,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Tap to view progress',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
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
