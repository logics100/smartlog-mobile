import 'package:flutter/material.dart';

import '../services/api_service.dart';

class LecturerEnrollStudentScreen extends StatefulWidget {
  final int unitId;
  final String unitCode;
  final String unitName;

  const LecturerEnrollStudentScreen({
    super.key,
    required this.unitId,
    required this.unitCode,
    required this.unitName,
  });

  @override
  State<LecturerEnrollStudentScreen> createState() =>
      _LecturerEnrollStudentScreenState();
}

class _LecturerEnrollStudentScreenState
    extends State<LecturerEnrollStudentScreen> {
  final TextEditingController searchController =
      TextEditingController();

  bool isSearching = false;
  bool isEnrolling = false;

  String? errorMessage;

  List<dynamic> students = [];

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> searchStudents() async {
    final search = searchController.text.trim();

    if (search.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Enter a student name or DWU ID.',
          ),
        ),
      );
      return;
    }

    setState(() {
      isSearching = true;
      errorMessage = null;
      students = [];
    });

    try {
      final result =
          await ApiService.searchStudentsForUnit(
        unitId: widget.unitId,
        search: search,
      );

      if (!mounted) return;

      setState(() {
        students = result;
        isSearching = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString();
        isSearching = false;
      });
    }
  }

  Future<void> enrollStudent(
    Map<String, dynamic> student,
  ) async {
    final rawStudentId =
        student['student_id'] ?? student['id'];

    final studentId =
        int.tryParse(rawStudentId.toString());

    if (studentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Student ID is missing.',
          ),
        ),
      );
      return;
    }

    final studentName =
        student['name']?.toString() ??
            student['student_name']?.toString() ??
            'this student';

    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Enroll Student',
          ),
          content: Text(
            'Enroll $studentName into '
            '${widget.unitCode} - ${widget.unitName}?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'Enroll',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      isEnrolling = true;
    });

    try {
      await ApiService.enrollStudentInUnit(
        unitId: widget.unitId,
        studentId: studentId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$studentName enrolled successfully.',
          ),
        ),
      );

      Navigator.pop(
        context,
        true,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isEnrolling = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Enroll Student',
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.unitCode} - ${widget.unitName}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'Search for a student using their name or DWU ID.',
              ),

              const SizedBox(height: 20),

              TextField(
                controller: searchController,
                textInputAction:
                    TextInputAction.search,
                onSubmitted: (_) {
                  searchStudents();
                },
                decoration: InputDecoration(
                  labelText:
                      'Student name or DWU ID',
                  hintText:
                      'Example: STU001',
                  prefixIcon: const Icon(
                    Icons.search,
                  ),
                  border:
                      const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    tooltip: 'Search',
                    onPressed: isSearching
                        ? null
                        : searchStudents,
                    icon: const Icon(
                      Icons.search,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              if (isSearching)
                const Expanded(
                  child: Center(
                    child:
                        CircularProgressIndicator(),
                  ),
                )
              else if (errorMessage != null)
                Expanded(
                  child: Center(
                    child: Padding(
                      padding:
                          const EdgeInsets.all(20),
                      child: Text(
                        errorMessage!,
                        textAlign:
                            TextAlign.center,
                      ),
                    ),
                  ),
                )
              else if (students.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text(
                      'Search for a student to enroll.',
                      textAlign:
                          TextAlign.center,
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: students.length,
                    itemBuilder:
                        (context, index) {
                      final student =
                          Map<String, dynamic>.from(
                        students[index] as Map,
                      );

                      final name =
                          student['name']
                                  ?.toString() ??
                              student[
                                      'student_name']
                                  ?.toString() ??
                              'Unknown Student';

                      final dwuId =
                          student['dwu_id']
                                  ?.toString() ??
                              student[
                                      'student_dwu_id']
                                  ?.toString() ??
                              '-';

                      final email =
                          student['email']
                              ?.toString();

                      final yearLevel =
    student['year_name']
            ?.toString() ??
        student['year_level']
            ?.toString() ??
        student['year_level_name']
            ?.toString();

final alreadyEnrolled =
    student['already_enrolled'] == true ||
    student['already_enrolled'] == 1 ||
    student['already_enrolled'] == '1';

                      return Card(
                        margin:
                            const EdgeInsets.only(
                          bottom: 10,
                        ),
                        child: ListTile(
                          leading:
                              const CircleAvatar(
                            child: Icon(
                              Icons.person,
                            ),
                          ),
                          title: Text(
                            name,
                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              const SizedBox(
                                height: 4,
                              ),
                              Text(
                                'DWU ID: $dwuId',
                              ),
                              if (email !=
                                  null) ...[
                                const SizedBox(
                                  height: 3,
                                ),
                                Text(
                                  'Email: $email',
                                ),
                              ],
                              if (yearLevel !=
                                  null) ...[
                                const SizedBox(
                                  height: 3,
                                ),
                                Text(
                                  'Year Level: '
                                  '$yearLevel',
                                ),
                              ],
                            ],
                          ),
                          trailing: alreadyEnrolled
    ? const Chip(
        avatar: Icon(
          Icons.check_circle,
          size: 18,
        ),
        label: Text(
          'Enrolled',
        ),
      )
    : ElevatedButton(
        onPressed: isEnrolling
            ? null
            : () {
                enrollStudent(
                  student,
                );
              },
        child: const Text(
          'Enroll',
        ),
      ),
                        ),
                      );
                    },
                  ),
                ),

              if (isEnrolling)
                const Padding(
                  padding:
                      EdgeInsets.only(top: 10),
                  child: LinearProgressIndicator(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}