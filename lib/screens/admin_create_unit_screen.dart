import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminCreateUnitScreen extends StatefulWidget {
  final List<dynamic> departments;
  final List<dynamic> yearLevels;
  final List<dynamic> semesters;

  const AdminCreateUnitScreen({
    super.key,
    required this.departments,
    required this.yearLevels,
    required this.semesters,
  });

  @override
  State<AdminCreateUnitScreen> createState() =>
      _AdminCreateUnitScreenState();
}

class _AdminCreateUnitScreenState
    extends State<AdminCreateUnitScreen> {
  final formKey = GlobalKey<FormState>();

  final unitCodeController =
      TextEditingController();

  final unitNameController =
      TextEditingController();

  int? selectedDepartmentId;
  int? selectedYearLevelId;
  int? selectedSemesterId;

  bool requiresLogbook = true;
  bool isActive = true;
  bool loading = false;

  @override
  void dispose() {
    unitCodeController.dispose();
    unitNameController.dispose();
    super.dispose();
  }

  Future<void> createUnit() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    if (selectedDepartmentId == null) {
      showMessage(
        'Please select a department.',
      );
      return;
    }

    if (selectedYearLevelId == null) {
      showMessage(
        'Please select a year level.',
      );
      return;
    }

    if (selectedSemesterId == null) {
      showMessage(
        'Please select a semester.',
      );
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      final result =
          await ApiService.createAdminUnit(
        unitCode:
            unitCodeController.text.trim(),
        unitName:
            unitNameController.text.trim(),
        departmentId:
            selectedDepartmentId!,
        yearLevelId:
            selectedYearLevelId!,
        semesterId:
            selectedSemesterId!,
        requiresLogbook:
            requiresLogbook,
        isActive:
            isActive,
      );

      if (!mounted) return;

      final message =
          result['message'] ??
              'Unit created successfully.';

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );

      Navigator.pop(
        context,
        true,
      );
    } catch (e) {
      if (!mounted) return;

      showMessage(
        e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
      );
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  void showMessage(
    String message,
  ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeDepartments =
    widget.departments.where(
  (item) {
    final department =
        Map<String, dynamic>.from(
      item,
    );

    final status =
        department['is_active'];

    return status == true ||
        status == 1 ||
        status == '1';
  },
).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create Unit',
        ),
      ),
      body: SafeArea(
        child: Form(
          key: formKey,
          child: ListView(
            padding:
                const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(
                    16,
                  ),
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      const CircleAvatar(
                        child: Icon(
                          Icons
                              .library_add,
                        ),
                      ),
                      const SizedBox(
                        width: 12,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: const [
                            Text(
                              'New SmartLog Unit',
                              style:
                                  TextStyle(
                                fontSize: 20,
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),
                            SizedBox(
                              height: 6,
                            ),
                            Text(
                              'Create a practical or clinical unit and assign it to a department, year level and semester.',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              TextFormField(
                controller:
                    unitCodeController,
                textCapitalization:
                    TextCapitalization
                        .characters,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Unit Code',
                  hintText:
                      'Example: SURG-Y4',
                  border:
                      OutlineInputBorder(),
                  prefixIcon:
                      Icon(Icons.badge),
                ),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Unit code is required.';
                  }

                  if (value.trim().length >
                      50) {
                    return 'Unit code is too long.';
                  }

                  return null;
                },
              ),

              const SizedBox(
                height: 16,
              ),

              TextFormField(
                controller:
                    unitNameController,
                textCapitalization:
                    TextCapitalization.words,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Unit Name',
                  hintText:
                      'Example: Surgery',
                  border:
                      OutlineInputBorder(),
                  prefixIcon:
                      Icon(Icons.menu_book),
                ),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Unit name is required.';
                  }

                  if (value.trim().length >
                      255) {
                    return 'Unit name is too long.';
                  }

                  return null;
                },
              ),

              const SizedBox(
                height: 16,
              ),

              DropdownButtonFormField<
                  int>(
                initialValue:
                    selectedDepartmentId,
                isExpanded: true,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Department',
                  border:
                      OutlineInputBorder(),
                  prefixIcon:
                      Icon(Icons.business),
                ),
                items:
                    activeDepartments.map(
                  (item) {
                    final department =
                        Map<String,
                            dynamic>.from(
                      item,
                    );

                    return DropdownMenuItem<
                        int>(
                      value:
                          department['id']
                              as int,
                      child: Text(
                        '${department['department_code']} - '
                        '${department['department_name']}',
                        overflow:
                            TextOverflow
                                .ellipsis,
                      ),
                    );
                  },
                ).toList(),
                onChanged:
                    loading
                        ? null
                        : (value) {
                            setState(() {
                              selectedDepartmentId =
                                  value;
                            });
                          },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a department.';
                  }

                  return null;
                },
              ),

              const SizedBox(
                height: 16,
              ),

              DropdownButtonFormField<
                  int>(
                initialValue:
                    selectedYearLevelId,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Year Level',
                  border:
                      OutlineInputBorder(),
                  prefixIcon:
                      Icon(Icons.school),
                ),
                items:
                    widget.yearLevels.map(
                  (item) {
                    final yearLevel =
                        Map<String,
                            dynamic>.from(
                      item,
                    );

                    return DropdownMenuItem<
                        int>(
                      value:
                          yearLevel['id']
                              as int,
                      child: Text(
                        yearLevel[
                                'year_name']
                            .toString(),
                      ),
                    );
                  },
                ).toList(),
                onChanged:
                    loading
                        ? null
                        : (value) {
                            setState(() {
                              selectedYearLevelId =
                                  value;
                            });
                          },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a year level.';
                  }

                  return null;
                },
              ),

              const SizedBox(
                height: 16,
              ),

              DropdownButtonFormField<
                  int>(
                initialValue:
                    selectedSemesterId,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Semester',
                  border:
                      OutlineInputBorder(),
                  prefixIcon:
                      Icon(
                    Icons.calendar_month,
                  ),
                ),
                items:
                    widget.semesters.map(
                  (item) {
                    final semester =
                        Map<String,
                            dynamic>.from(
                      item,
                    );

                    return DropdownMenuItem<
                        int>(
                      value:
                          semester['id']
                              as int,
                      child: Text(
                        semester[
                                'semester_name']
                            .toString(),
                      ),
                    );
                  },
                ).toList(),
                onChanged:
                    loading
                        ? null
                        : (value) {
                            setState(() {
                              selectedSemesterId =
                                  value;
                            });
                          },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a semester.';
                  }

                  return null;
                },
              ),

              const SizedBox(
                height: 16,
              ),

              Card(
                child: SwitchListTile(
                  title: const Text(
                    'Requires Logbook',
                  ),
                  subtitle: Text(
                    requiresLogbook
                        ? 'Students enrolled in this unit will use a SmartLog clinical logbook.'
                        : 'This unit does not require a clinical logbook.',
                  ),
                  value:
                      requiresLogbook,
                  onChanged:
                      loading
                          ? null
                          : (value) {
                              setState(() {
                                requiresLogbook =
                                    value;
                              });
                            },
                ),
              ),

              const SizedBox(
                height: 12,
              ),

              Card(
                child: SwitchListTile(
                  title: const Text(
                    'Active Unit',
                  ),
                  subtitle: Text(
                    isActive
                        ? 'The unit can be used in SmartLog.'
                        : 'The unit will be created as inactive.',
                  ),
                  value:
                      isActive,
                  onChanged:
                      loading
                          ? null
                          : (value) {
                              setState(() {
                                isActive =
                                    value;
                              });
                            },
                ),
              ),

              const SizedBox(
                height: 24,
              ),

              SizedBox(
                height: 52,
                child:
                    ElevatedButton.icon(
                  onPressed:
                      loading
                          ? null
                          : createUnit,
                  icon: loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.add,
                        ),
                  label: Text(
                    loading
                        ? 'Creating...'
                        : 'Create Unit',
                  ),
                ),
              ),

              const SizedBox(
                height: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}