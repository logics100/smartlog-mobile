import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/local_database_service.dart';

class StudentCreateAttendanceScreen
    extends StatefulWidget {
  final int logbookId;

  const StudentCreateAttendanceScreen({
    super.key,
    required this.logbookId,
  });

  @override
  State<StudentCreateAttendanceScreen>
      createState() =>
          _StudentCreateAttendanceScreenState();
}

class _StudentCreateAttendanceScreenState
    extends State<StudentCreateAttendanceScreen> {
  final formKey = GlobalKey<FormState>();

  final facilityController =
      TextEditingController();

  final clinicalUnitController =
      TextEditingController();

  DateTime selectedDate =
      DateTime.now();

  TimeOfDay? startTime;
  TimeOfDay? finishTime;

  bool saving = false;

  String formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  String formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:00';
  }

  Future<void> chooseDate() async {
    final result = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (result != null) {
      setState(() {
        selectedDate = result;
      });
    }
  }

  Future<void> chooseStartTime() async {
    final result = await showTimePicker(
      context: context,
      initialTime:
          startTime ??
              const TimeOfDay(
                hour: 8,
                minute: 0,
              ),
    );

    if (result != null) {
      setState(() {
        startTime = result;
      });
    }
  }

  Future<void> chooseFinishTime() async {
    final result = await showTimePicker(
      context: context,
      initialTime:
          finishTime ??
              const TimeOfDay(
                hour: 16,
                minute: 0,
              ),
    );

    if (result != null) {
      setState(() {
        finishTime = result;
      });
    }
  }

  
  Future<void> saveAttendance() async {
  if (!formKey.currentState!.validate()) {
    return;
  }

  if (startTime == null || finishTime == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Please select start and finish times.',
        ),
      ),
    );

    return;
  }

  final startMinutes =
      startTime!.hour * 60 + startTime!.minute;

  final finishMinutes =
      finishTime!.hour * 60 + finishTime!.minute;

  if (finishMinutes <= startMinutes) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Finish time must be after start time.',
        ),
      ),
    );

    return;
  }

  final attendanceDate =
      formatDate(selectedDate);

  final facilityName =
      facilityController.text.trim();

  final clinicalUnit =
      clinicalUnitController.text.trim();

  final formattedStartTime =
      formatTime(startTime!);

  final formattedFinishTime =
      formatTime(finishTime!);

  final totalHours =
      (finishMinutes - startMinutes) / 60.0;

  setState(() {
    saving = true;
  });

  try {
    // ---------------------------------------------------------
    // FIRST TRY TO SAVE DIRECTLY TO LARAVEL
    // ---------------------------------------------------------
    final result =
        await ApiService.createStudentAttendance(
      logbookId: widget.logbookId,
      attendanceDate: attendanceDate,
      facilityName: facilityName,
      clinicalUnit: clinicalUnit,
      startTime: formattedStartTime,
      finishTime: formattedFinishTime,
    );

    if (!mounted) return;

    final message =
        result['message']?.toString() ??
            'Attendance recorded successfully.';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );

    Navigator.pop(
      context,
      true,
    );
  } catch (e) {
    // ---------------------------------------------------------
    // LARAVEL / NETWORK FAILED
    // SAVE LOCALLY IN SQLITE INSTEAD
    // ---------------------------------------------------------
    try {
      await LocalDatabaseService.saveOfflineAttendance(
        logbookId: widget.logbookId,
        attendanceDate: attendanceDate,
        facilityName: facilityName,
        clinicalUnit: clinicalUnit,
        startTime: formattedStartTime,
        finishTime: formattedFinishTime,
        totalHours: totalHours,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No connection to SmartLog server. '
            'Attendance saved offline and will '
            'be synced later.',
          ),
        ),
      );

      Navigator.pop(
        context,
        true,
      );
    } catch (localError) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to save attendance: '
            '$localError',
          ),
        ),
      );
    }
  } finally {
    if (mounted) {
      setState(() {
        saving = false;
      });
    }
  }
}

  @override
  void dispose() {
    facilityController.dispose();
    clinicalUnitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add Attendance',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.all(20),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Clinical Placement Attendance',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 24),

                ListTile(
                  contentPadding:
                      EdgeInsets.zero,
                  leading:
                      const Icon(
                    Icons.calendar_today,
                  ),
                  title:
                      const Text('Date'),
                  subtitle: Text(
                    formatDate(
                      selectedDate,
                    ),
                  ),
                  trailing:
                      const Icon(
                    Icons.edit_calendar,
                  ),
                  onTap: chooseDate,
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller:
                      facilityController,
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Facility Name',
                    border:
                        OutlineInputBorder(),
                    prefixIcon: Icon(
                      Icons.local_hospital,
                    ),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value
                            .trim()
                            .isEmpty) {
                      return 'Enter the facility name.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller:
                      clinicalUnitController,
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Clinical Unit / Ward',
                    border:
                        OutlineInputBorder(),
                    prefixIcon: Icon(
                      Icons.medical_services,
                    ),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value
                            .trim()
                            .isEmpty) {
                      return 'Enter the clinical unit.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 20),

                Card(
                  child: ListTile(
                    leading:
                        const Icon(
                      Icons.login,
                    ),
                    title:
                        const Text(
                      'Start Time',
                    ),
                    subtitle: Text(
                      startTime == null
                          ? 'Select start time'
                          : formatTime(
                              startTime!,
                            ),
                    ),
                    onTap:
                        chooseStartTime,
                  ),
                ),

                const SizedBox(height: 10),

                Card(
                  child: ListTile(
                    leading:
                        const Icon(
                      Icons.logout,
                    ),
                    title:
                        const Text(
                      'Finish Time',
                    ),
                    subtitle: Text(
                      finishTime == null
                          ? 'Select finish time'
                          : formatTime(
                              finishTime!,
                            ),
                    ),
                    onTap:
                        chooseFinishTime,
                  ),
                ),

                const SizedBox(height: 30),

                SizedBox(
                  width:
                      double.infinity,
                  height: 52,
                  child:
                      ElevatedButton.icon(
                    onPressed:
                        saving
                            ? null
                            : saveAttendance,
                    icon: saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child:
                                CircularProgressIndicator(
                              strokeWidth:
                                  2,
                            ),
                          )
                        : const Icon(
                            Icons.save,
                          ),
                    label: Text(
                      saving
                          ? 'Saving...'
                          : 'Save Attendance',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}