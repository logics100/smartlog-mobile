import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../widgets/admin_ui.dart';

class AdminUnitAssignmentsScreen extends StatefulWidget {
  const AdminUnitAssignmentsScreen({super.key});

  @override
  State<AdminUnitAssignmentsScreen> createState() =>
      _AdminUnitAssignmentsScreenState();
}

class _AdminUnitAssignmentsScreenState
    extends State<AdminUnitAssignmentsScreen> {
  bool loading = true;
  bool saving = false;
  String? error;
  List<Map<String, dynamic>> units = [];
  List<Map<String, dynamic>> lecturers = [];
  List<Map<String, dynamic>> assignments = [];
  int? selectedUnitId;
  int? selectedLecturerId;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final results = await Future.wait([
        ApiService.getAdminUnits(),
        ApiService.getAdminUnitAssignments(),
      ]);
      if (!mounted) return;
      final unitData = results[0];
      final assignmentData = results[1];
      setState(() {
        units = (unitData['units'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        lecturers = (assignmentData['lecturers'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        assignments = (assignmentData['assignments'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        if (!units.any((u) => u['id'] == selectedUnitId)) {
          selectedUnitId = null;
        }
        selectedLecturerId = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() => error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> assign() async {
    if (selectedUnitId == null || selectedLecturerId == null || saving) return;
    setState(() => saving = true);
    try {
      await ApiService.assignAdminUnitLecturer(
        unitId: selectedUnitId!,
        lecturerId: selectedLecturerId!,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lecturer assigned successfully.')),
      );
      await load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> unassign(Map<String, dynamic> assignment) async {
    if (saving) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Unassign lecturer?'),
        content: Text(
          'Remove ${assignment['lecturer_name']} from this unit? '
          'Existing student records will remain.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Unassign'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => saving = true);
    try {
      await ApiService.unassignAdminUnitLecturer(
        assignmentId: assignment['id'] as int,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lecturer unassigned successfully.')),
      );
      await load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedUnit = units.where((u) => u['id'] == selectedUnitId).toList();
    final department = selectedUnit.isEmpty
        ? null
        : Map<String, dynamic>.from(selectedUnit.first['department'] ?? {});
    final eligible = lecturers.where((lecturer) {
      return department != null && lecturer['department_id'] == department['id'];
    }).toList();
    final current = assignments
        .where((assignment) => assignment['unit_id'] == selectedUnitId)
        .toList();
    final available = eligible.where((lecturer) {
      return !current.any((assignment) =>
          assignment['lecturer_id'] == lecturer['id']);
    }).toList();

    return Theme(
      data: AdminUi.theme(context),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Assign Lecturers'),
          actions: [
            IconButton(
              tooltip: 'Refresh',
              onPressed: loading || saving ? null : load,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(error!, textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: load,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const Text(
                        'Choose an active unit and a lecturer from its department.',
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<int>(
                        initialValue: selectedUnitId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Unit',
                          border: OutlineInputBorder(),
                        ),
                        items: units
                            .where((unit) => unit['is_active'] == true ||
                                unit['is_active'] == 1)
                            .map((unit) => DropdownMenuItem<int>(
                                  value: unit['id'] as int,
                                  child: Text(
                                    '${unit['unit_code']} - ${unit['unit_name']}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ))
                            .toList(),
                        onChanged: saving
                            ? null
                            : (value) => setState(() {
                                  selectedUnitId = value;
                                  selectedLecturerId = null;
                                }),
                      ),
                      if (selectedUnitId != null) ...[
                        const SizedBox(height: 20),
                        const Text(
                          'Currently assigned',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        if (current.isEmpty)
                          const Text('No lecturers assigned yet.')
                        else
                          ...current.map((item) => ListTile(
                                leading: const Icon(Icons.person),
                                title: Text(
                                  item['lecturer_name']?.toString() ?? 'Lecturer',
                                ),
                                trailing: IconButton(
                                  tooltip: 'Unassign lecturer',
                                  icon: const Icon(Icons.person_remove_outlined),
                                  onPressed: saving ? null : () => unassign(item),
                                ),
                              )),
                        const SizedBox(height: 20),
                        DropdownButtonFormField<int>(
                          initialValue: selectedLecturerId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Available lecturer',
                            border: OutlineInputBorder(),
                          ),
                          items: available
                              .map((lecturer) => DropdownMenuItem<int>(
                                    value: lecturer['id'] as int,
                                    child: Text(
                                      lecturer['name']?.toString() ?? '',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ))
                              .toList(),
                          onChanged: saving || available.isEmpty
                              ? null
                              : (value) => setState(
                                    () => selectedLecturerId = value,
                                  ),
                        ),
                        if (available.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                              'No additional active lecturers are available '
                              'in this department.',
                            ),
                          ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: saving || selectedLecturerId == null
                              ? null
                              : assign,
                          icon: const Icon(Icons.person_add),
                          label: Text(
                            saving ? 'Assigning...' : 'Assign Lecturer',
                          ),
                        ),
                      ],
                    ],
                  ),
      ),
    );
  }
}
