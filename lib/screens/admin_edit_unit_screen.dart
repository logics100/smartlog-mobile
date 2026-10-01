import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../widgets/admin_ui.dart';

class AdminEditUnitScreen extends StatefulWidget {
  final Map<String, dynamic> unit;
  final List<dynamic> departments;
  final List<dynamic> yearLevels;
  final List<dynamic> semesters;

  const AdminEditUnitScreen({
    super.key,
    required this.unit,
    required this.departments,
    required this.yearLevels,
    required this.semesters,
  });

  @override
  State<AdminEditUnitScreen> createState() => _AdminEditUnitScreenState();
}

class _AdminEditUnitScreenState extends State<AdminEditUnitScreen> {
  final formKey = GlobalKey<FormState>();

  late TextEditingController unitCodeController;
  late TextEditingController unitNameController;

  int? selectedDepartmentId;
  int? selectedYearLevelId;
  int? selectedSemesterId;

  bool requiresLogbook = true;
  bool isActive = true;
  bool loading = false;

  @override
  void initState() {
    super.initState();

    unitCodeController = TextEditingController(
      text: widget.unit['unit_code']?.toString() ?? '',
    );

    unitNameController = TextEditingController(
      text: widget.unit['unit_name']?.toString() ?? '',
    );

    final department = widget.unit['department'];
    final yearLevel = widget.unit['year_level'];
    final semester = widget.unit['semester'];

    if (department is Map) {
      selectedDepartmentId = int.tryParse(department['id'].toString());
    }

    if (yearLevel is Map) {
      selectedYearLevelId = int.tryParse(yearLevel['id'].toString());
    }

    if (semester is Map) {
      selectedSemesterId = int.tryParse(semester['id'].toString());
    }

    requiresLogbook = toBool(widget.unit['requires_logbook']);

    isActive = toBool(widget.unit['is_active']);
  }

  bool toBool(dynamic value) {
    return value == true || value == 1 || value == '1';
  }

  @override
  void dispose() {
    unitCodeController.dispose();
    unitNameController.dispose();
    super.dispose();
  }

  Future<void> saveChanges() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    if (selectedDepartmentId == null) {
      showMessage('Please select a department.');
      return;
    }

    if (selectedYearLevelId == null) {
      showMessage('Please select a year level.');
      return;
    }

    if (selectedSemesterId == null) {
      showMessage('Please select a semester.');
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      final result = await ApiService.updateAdminUnit(
        unitId: widget.unit['id'],
        unitCode: unitCodeController.text.trim(),
        unitName: unitNameController.text.trim(),
        departmentId: selectedDepartmentId!,
        yearLevelId: selectedYearLevelId!,
        semesterId: selectedSemesterId!,
        requiresLogbook: requiresLogbook,
        isActive: isActive,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Unit updated successfully.'),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    /*
     * Keep active departments available.
     * Also keep the unit's current department available
     * even if that department was later deactivated.
     */
    final currentDepartmentId = selectedDepartmentId;

    final availableDepartments = widget.departments.where((item) {
      final department = Map<String, dynamic>.from(item);

      final id = int.tryParse(department['id'].toString());

      final active = toBool(department['is_active']);

      return active || id == currentDepartmentId;
    }).toList();

    return Theme(
      data: AdminUi.theme(context),
      child: Scaffold(
        appBar: AppBar(title: const Text('Edit Unit')),
        body: SafeArea(
          child: Form(
            key: formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CircleAvatar(child: Icon(Icons.edit_note)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Edit SmartLog Unit',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Unit ID: '
                                '${widget.unit['id']}',
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Update the unit information below and save your changes.',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                TextFormField(
                  controller: unitCodeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Unit Code',
                    hintText: 'Example: SURG-Y4',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.badge),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Unit code is required.';
                    }

                    if (value.trim().length > 50) {
                      return 'Unit code is too long.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: unitNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Unit Name',
                    hintText: 'Example: Surgery',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.menu_book),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Unit name is required.';
                    }

                    if (value.trim().length > 255) {
                      return 'Unit name is too long.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                DropdownButtonFormField<int>(
                  initialValue: selectedDepartmentId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Department',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.business),
                  ),
                  items: availableDepartments.map((item) {
                    final department = Map<String, dynamic>.from(item);

                    return DropdownMenuItem<int>(
                      value: int.tryParse(department['id'].toString()),
                      child: Text(
                        '${department['department_code']} - '
                        '${department['department_name']}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: loading
                      ? null
                      : (value) {
                          setState(() {
                            selectedDepartmentId = value;
                          });
                        },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a department.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                DropdownButtonFormField<int>(
                  initialValue: selectedYearLevelId,
                  decoration: const InputDecoration(
                    labelText: 'Year Level',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.school),
                  ),
                  items: widget.yearLevels.map((item) {
                    final yearLevel = Map<String, dynamic>.from(item);

                    return DropdownMenuItem<int>(
                      value: int.tryParse(yearLevel['id'].toString()),
                      child: Text(yearLevel['year_name'].toString()),
                    );
                  }).toList(),
                  onChanged: loading
                      ? null
                      : (value) {
                          setState(() {
                            selectedYearLevelId = value;
                          });
                        },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a year level.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                DropdownButtonFormField<int>(
                  initialValue: selectedSemesterId,
                  decoration: const InputDecoration(
                    labelText: 'Semester',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_month),
                  ),
                  items: widget.semesters.map((item) {
                    final semester = Map<String, dynamic>.from(item);

                    return DropdownMenuItem<int>(
                      value: int.tryParse(semester['id'].toString()),
                      child: Text(semester['semester_name'].toString()),
                    );
                  }).toList(),
                  onChanged: loading
                      ? null
                      : (value) {
                          setState(() {
                            selectedSemesterId = value;
                          });
                        },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a semester.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                Card(
                  child: SwitchListTile(
                    title: const Text('Requires Logbook'),
                    subtitle: Text(
                      requiresLogbook
                          ? 'Students enrolled in this unit will use a SmartLog clinical logbook.'
                          : 'This unit does not require a clinical logbook.',
                    ),
                    value: requiresLogbook,
                    onChanged: loading
                        ? null
                        : (value) {
                            setState(() {
                              requiresLogbook = value;
                            });
                          },
                  ),
                ),

                const SizedBox(height: 12),

                Card(
                  child: SwitchListTile(
                    title: const Text('Active Unit'),
                    subtitle: Text(
                      isActive
                          ? 'This unit is currently active.'
                          : 'This unit is currently inactive.',
                    ),
                    value: isActive,
                    onChanged: loading
                        ? null
                        : (value) {
                            setState(() {
                              isActive = value;
                            });
                          },
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: loading ? null : saveChanges,
                    icon: loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(loading ? 'Saving...' : 'Save Changes'),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
