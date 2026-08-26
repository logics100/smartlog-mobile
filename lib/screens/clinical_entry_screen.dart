import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ClinicalEntryScreen extends StatefulWidget {
  final int logbookId;
  final Map<String, dynamic> item;

  const ClinicalEntryScreen({
    super.key,
    required this.logbookId,
    required this.item,
  });

  @override
  State<ClinicalEntryScreen> createState() =>
      _ClinicalEntryScreenState();
}

class _ClinicalEntryScreenState
    extends State<ClinicalEntryScreen> {
  final facilityController = TextEditingController();
  final clinicalAreaController = TextEditingController();
  final detailsController = TextEditingController();

  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();

  int? selectedRequirementId;
  bool submitting = false;

  List<dynamic> get requirements =>
      (widget.item['requirements'] as List<dynamic>?) ?? [];

  String get formattedDate {
    final year = selectedDate.year.toString();
    final month =
        selectedDate.month.toString().padLeft(2, '0');
    final day =
        selectedDate.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  String get formattedTime {
    final hour =
        selectedTime.hour.toString().padLeft(2, '0');
    final minute =
        selectedTime.minute.toString().padLeft(2, '0');

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
        const SnackBar(
          content: Text('Please enter the facility name.'),
        ),
      );
      return;
    }

    setState(() {
      submitting = true;
    });

    try {
      final result =
          await ApiService.createClinicalEntry(
        logbookId: widget.logbookId,
        logbookItemId:
            int.parse(widget.item['id'].toString()),
        requirementId: selectedRequirementId,
        activityDate: formattedDate,
        activityTime: formattedTime,
        facilityName: facilityController.text.trim(),
        clinicalArea:
            clinicalAreaController.text.trim().isEmpty
                ? null
                : clinicalAreaController.text.trim(),
        activityDetails:
            detailsController.text.trim().isEmpty
                ? null
                : detailsController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message'] ??
                'Clinical entry created successfully.',
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to save entry: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          submitting = false;
        });
      }
    }
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
      appBar: AppBar(
        title: const Text('Clinical Entry'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.item['item_name'] ?? 'Procedure',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Activity Date',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
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
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
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
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              DropdownButtonFormField<int>(
                initialValue: selectedRequirementId,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Select requirement',
                ),
                items: requirements.map((requirement) {
                  final requirementMap =
                      requirement as Map<String, dynamic>;

                  final id = int.parse(
                    requirementMap['id'].toString(),
                  );

                  final code =
                      requirementMap['requirement_code']
                          ?.toString() ??
                          '';

                  final label =
                      requirementMap['requirement_label']
                          ?.toString() ??
                          '';

                  return DropdownMenuItem<int>(
                    value: id,
                    child: Text(
                      label.isEmpty
                          ? code
                          : '$code - $label',
                    ),
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
              child: ElevatedButton(
                onPressed:
                    submitting ? null : submitEntry,
                child: submitting
                    ? const CircularProgressIndicator()
                    : const Text('Save Clinical Entry'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}