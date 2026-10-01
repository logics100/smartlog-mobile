import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'lecturer_enroll_student_screen.dart';
import 'lecturer_student_progress_screen.dart';

class LecturerUnitStudentsScreen extends StatefulWidget {
  final int unitId;
  final String unitCode;
  final String unitName;

  const LecturerUnitStudentsScreen({
    super.key,
    required this.unitId,
    required this.unitCode,
    required this.unitName,
  });

  @override
  State<LecturerUnitStudentsScreen> createState() =>
      _LecturerUnitStudentsScreenState();
}

class _LecturerUnitStudentsScreenState
    extends State<LecturerUnitStudentsScreen> {
  bool isLoading = true;
  String? errorMessage;

  List<dynamic> students = [];

  @override
  void initState() {
    super.initState();
    loadStudents();
  }

  Future<void> loadStudents() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await ApiService.getLecturerUnitStudents(widget.unitId);

      if (!mounted) return;

      setState(() {
        students = result;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> openEnrollStudent() async {
    final enrolled = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => LecturerEnrollStudentScreen(
          unitId: widget.unitId,
          unitCode: widget.unitCode,
          unitName: widget.unitName,
        ),
      ),
    );

    if (!mounted) return;

    if (enrolled == true) {
      await loadStudents();
    }
  }

  double parsePercentage(dynamic value) {
    if (value == null) {
      return 0;
    }

    return double.tryParse(value.toString()) ?? 0;
  }

  Color statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return Colors.green;

      case 'COMPLETED':
        return Colors.blue;

      case 'SUBMITTED':
        return Colors.orange;

      case 'ARCHIVED':
        return Colors.grey;

      case 'INACTIVE':
        return Colors.red;

      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.unitCode} Students'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: isLoading ? null : loadStudents,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: isLoading ? null : openEnrollStudent,
        icon: const Icon(Icons.person_add),
        label: const Text('Enroll Student'),
      ),

      body: RefreshIndicator(onRefresh: loadStudents, child: buildBody()),
    );
  }

  Widget buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 80),

          const Icon(Icons.error_outline, size: 60),

          const SizedBox(height: 16),

          const Text(
            'Unable to load students.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          Text(errorMessage!, textAlign: TextAlign.center),

          const SizedBox(height: 20),

          ElevatedButton.icon(
            onPressed: loadStudents,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
      children: [
        buildUnitSummary(),

        const SizedBox(height: 18),

        Row(
          children: [
            const Expanded(
              child: Text(
                'Enrolled Students',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),

            Text(
              '${students.length}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),

        const SizedBox(height: 12),

        if (students.isEmpty)
          buildEmpty()
        else
          ...students.map((item) {
            final student = Map<String, dynamic>.from(item);

            return buildStudentCard(student);
          }),
      ],
    );
  }

  Widget buildUnitSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(child: Icon(Icons.class_)),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.unitCode,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(widget.unitName),

                  const SizedBox(height: 8),

                  Text(
                    '${students.length} student'
                    '${students.length == 1 ? '' : 's'} enrolled',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildStudentCard(Map<String, dynamic> student) {
    final name = student['name']?.toString() ?? 'Unknown Student';

    final dwuId = student['dwu_id']?.toString() ?? '-';

    final email = student['email']?.toString();

    final rawStudentId = student['id'] ?? student['student_id'];

    final studentId = int.tryParse(rawStudentId?.toString() ?? '');

    final enrollmentStatus = student['enrollment_status']?.toString() ?? '-';

    final logbookStatus = student['logbook_status']?.toString() ?? 'NO LOGBOOK';

    final logbookId = student['student_logbook_id'];

    final completion = parsePercentage(student['completion_percentage']);

    final percentageText = completion.toStringAsFixed(
      completion % 1 == 0 ? 0 : 2,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          if (studentId == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Student ID is missing.')),
            );

            return;
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LecturerStudentProgressScreen(
                unitId: widget.unitId,
                studentId: studentId,
                studentName: name,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(child: Icon(Icons.person)),

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

                        const SizedBox(height: 4),

                        Text('DWU ID: $dwuId'),

                        if (email != null && email.isNotEmpty) ...[
                          const SizedBox(height: 3),

                          Text(email),
                        ],
                      ],
                    ),
                  ),

                  const Icon(Icons.chevron_right),
                ],
              ),

              const Divider(height: 24),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(
                    avatar: Icon(
                      Icons.how_to_reg_outlined,
                      size: 18,
                      color: statusColor(enrollmentStatus),
                    ),
                    label: Text(
                      'Enrollment: '
                      '$enrollmentStatus',
                    ),
                  ),

                  Chip(
                    avatar: Icon(
                      Icons.menu_book_outlined,
                      size: 18,
                      color: statusColor(logbookStatus),
                    ),
                    label: Text(
                      'Logbook: '
                      '$logbookStatus',
                    ),
                  ),
                ],
              ),

              if (logbookId != null) ...[
                const SizedBox(height: 8),

                Text('Logbook ID: $logbookId'),
              ],

              const SizedBox(height: 14),

              Row(
                children: [
                  const Icon(Icons.analytics_outlined, size: 20),

                  const SizedBox(width: 8),

                  const Text(
                    'Completion',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),

                  const Spacer(),

                  Text(
                    '$percentageText%',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              LinearProgressIndicator(
                value: (completion / 100).clamp(0.0, 1.0),
                minHeight: 8,
                borderRadius: BorderRadius.circular(20),
              ),

              const SizedBox(height: 12),

              const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.analytics_outlined, size: 17),

                  SizedBox(width: 5),

                  Text(
                    'Tap to view clinical progress',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildEmpty() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            const Icon(Icons.people_outline, size: 70),

            const SizedBox(height: 16),

            const Text(
              'No Enrolled Students',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Text(
              'No students are currently enrolled in '
              '${widget.unitCode} - '
              '${widget.unitName}.',
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: openEnrollStudent,
              icon: const Icon(Icons.person_add),
              label: const Text('Enroll Student'),
            ),
          ],
        ),
      ),
    );
  }
}
