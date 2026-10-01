import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'supervisor_verification_screen.dart';
import '../services/local_database_service.dart';

class ClinicalEntryScreen extends StatefulWidget {
  final int logbookId;
  final Map<String, dynamic> item;

  final int? preselectedRequirementId;

  const ClinicalEntryScreen({
    super.key,
    required this.logbookId,
    required this.item,
    this.preselectedRequirementId,
  });

  @override
  State<ClinicalEntryScreen> createState() => _ClinicalEntryScreenState();
}

class _ClinicalEntryScreenState extends State<ClinicalEntryScreen> {
  final facilityController = TextEditingController();

  final clinicalAreaController = TextEditingController();

  final detailsController = TextEditingController();

  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();

  int? selectedRequirementId;

  bool submitting = false;

  List<dynamic> get requirements =>
      (widget.item['requirements'] as List<dynamic>?) ?? [];

  @override
  void initState() {
    super.initState();

    selectedRequirementId = widget.preselectedRequirementId;
  }

  String get formattedDate {
    final year = selectedDate.year.toString();

    final month = selectedDate.month.toString().padLeft(2, '0');

    final day = selectedDate.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  String get formattedTime {
    final hour = selectedTime.hour.toString().padLeft(2, '0');

    final minute = selectedTime.minute.toString().padLeft(2, '0');

    return '$hour:$minute:00';
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

  Future<void> chooseTime() async {
    final result = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );

    if (result != null) {
      setState(() {
        selectedTime = result;
      });
    }
  }

  Future<void> submitEntry() async {
    if (facilityController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the facility name.')),
      );

      return;
    }

    if (requirements.isNotEmpty && selectedRequirementId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a requirement level.')),
      );

      return;
    }

    final logbookItemId = int.parse(widget.item['id'].toString());

    final facilityName = facilityController.text.trim();

    final clinicalArea = clinicalAreaController.text.trim().isEmpty
        ? null
        : clinicalAreaController.text.trim();

    final activityDetails = detailsController.text.trim().isEmpty
        ? null
        : detailsController.text.trim();

    setState(() {
      submitting = true;
    });

    try {
      // Try Laravel first.
      final result = await ApiService.createClinicalEntry(
        logbookId: widget.logbookId,
        logbookItemId: logbookItemId,
        requirementId: selectedRequirementId,
        activityDate: formattedDate,
        activityTime: formattedTime,
        facilityName: facilityName,
        clinicalArea: clinicalArea,
        activityDetails: activityDetails,
      );

      if (!mounted) return;

      final entryId = int.tryParse(
        result['clinical_entry_id']?.toString() ?? '',
      );

      if (entryId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Clinical entry was saved, but the entry ID was not returned.',
            ),
          ),
        );

        Navigator.pop(context, true);
        return;
      }

      // Online entry can immediately continue
      // to supervisor verification.
      await showVerificationChoice(entryId);
    } catch (e) {
      // Laravel/network failed.
      // Save the entry locally instead.
      try {
        await LocalDatabaseService.saveOfflineClinicalEntry(
          logbookId: widget.logbookId,
          logbookItemId: logbookItemId,
          requirementId: selectedRequirementId,
          activityDate: formattedDate,
          activityTime: formattedTime,
          facilityName: facilityName,
          clinicalArea: clinicalArea,
          activityDetails: activityDetails,
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No connection to SmartLog server. '
              'Clinical entry saved offline and will '
              'be synced later.',
            ),
          ),
        );

        Navigator.pop(context, true);
      } catch (localError) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Unable to save clinical entry: '
              '$localError',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          submitting = false;
        });
      }
    }
  }

  Future<void> showVerificationChoice(int entryId) async {
    final choice = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
          title: const Text('Clinical Entry Saved'),
          content: const Text(
            'Your clinical entry has been saved successfully.\n\n'
            'Would you like the clinical supervisor to verify this entry now?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, 'LATER');
              },
              child: const Text('Later'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext, 'VERIFY');
              },
              icon: const Icon(Icons.verified_user),
              label: const Text('Verify Now'),
            ),
          ],
        );
      },
    );

    if (!mounted) {
      return;
    }

    if (choice == 'VERIFY') {
      final verificationResult = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SupervisorVerificationScreen(
            entryId: entryId,
            procedureName:
                widget.item['item_name']?.toString() ?? 'Clinical Activity',
            facilityName: facilityController.text.trim(),
          ),
        ),
      );

      if (!mounted) {
        return;
      }

      if (verificationResult == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Supervisor verification submitted successfully. '
              'The entry is now waiting for lecturer review.',
            ),
          ),
        );
      }

      Navigator.pop(context, true);

      return;
    }

    Navigator.pop(context, true);
  }

  @override
  void dispose() {
    facilityController.dispose();
    clinicalAreaController.dispose();
    detailsController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clinical Entry')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.item['item_name']?.toString() ?? 'Procedure',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            if (widget.preselectedRequirementId != null) ...[
              const SizedBox(height: 12),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.blue.withValues(alpha: 0.25),
                  ),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.touch_app, color: Colors.blue),

                    SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        'The selected logbook requirement has been filled in automatically.',
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            const Text(
              'Activity Date',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: Text(formattedDate),
              trailing: const Icon(Icons.edit),
              onTap: chooseDate,
            ),

            const SizedBox(height: 10),

            const Text(
              'Activity Time',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.access_time),
              title: Text(formattedTime),
              trailing: const Icon(Icons.edit),
              onTap: chooseTime,
            ),

            const SizedBox(height: 16),

            TextField(
              controller: facilityController,
              decoration: const InputDecoration(
                labelText: 'Facility Name',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: clinicalAreaController,
              decoration: const InputDecoration(
                labelText: 'Clinical Area / Ward',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            if (requirements.isNotEmpty) ...[
              const Text(
                'Requirement Level',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              DropdownButtonFormField<int>(
                initialValue: selectedRequirementId,
                isExpanded: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Select requirement',
                ),
                items: requirements.map((requirement) {
                  final requirementMap = Map<String, dynamic>.from(requirement);

                  final id = int.parse(requirementMap['id'].toString());

                  final code =
                      requirementMap['requirement_code']?.toString() ?? '';

                  final label =
                      requirementMap['requirement_label']?.toString() ?? '';

                  final status =
                      requirementMap['requirement_status']?.toString() ?? '';

                  String text;

                  if (label.isEmpty) {
                    text = code;
                  } else {
                    text = '$code - $label';
                  }

                  if (status.isNotEmpty) {
                    text += ' (${status.replaceAll('_', ' ')})';
                  }

                  return DropdownMenuItem<int>(
                    value: id,
                    child: Text(text, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedRequirementId = value;
                  });
                },
              ),

              const SizedBox(height: 16),
            ],

            TextField(
              controller: detailsController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Activity Details / Notes',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: submitting ? null : submitEntry,
                icon: submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(submitting ? 'Saving...' : 'Save Clinical Entry'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
