import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../widgets/admin_ui.dart';

class AdminEditDepartmentScreen extends StatefulWidget {
  final Map<String, dynamic> department;

  const AdminEditDepartmentScreen({super.key, required this.department});

  @override
  State<AdminEditDepartmentScreen> createState() =>
      _AdminEditDepartmentScreenState();
}

class _AdminEditDepartmentScreenState extends State<AdminEditDepartmentScreen> {
  final formKey = GlobalKey<FormState>();

  late final TextEditingController departmentCodeController;

  late final TextEditingController departmentNameController;

  bool loading = false;
  late bool isActive;

  @override
  void initState() {
    super.initState();

    departmentCodeController = TextEditingController(
      text: widget.department['department_code']?.toString() ?? '',
    );

    departmentNameController = TextEditingController(
      text: widget.department['department_name']?.toString() ?? '',
    );

    isActive = widget.department['is_active'] == true;
  }

  @override
  void dispose() {
    departmentCodeController.dispose();
    departmentNameController.dispose();

    super.dispose();
  }

  Future<void> updateDepartment() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      final result = await ApiService.updateAdminDepartment(
        departmentId: widget.department['id'] as int,
        departmentCode: departmentCodeController.text.trim(),
        departmentName: departmentNameController.text.trim(),
        isActive: isActive,
      );

      if (!mounted) return;

      final message = result['message'] ?? 'Department updated successfully.';

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      final message = e.toString().replaceFirst('Exception: ', '');

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final statistics = Map<String, dynamic>.from(
      widget.department['statistics'] ?? {},
    );

    return Theme(
      data: AdminUi.theme(context),
      child: Scaffold(
        appBar: AppBar(title: const Text('Edit Department')),
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
                        const CircleAvatar(child: Icon(Icons.business)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Edit SmartLog Department',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                widget.department['department_name']
                                        ?.toString() ??
                                    'Department',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current Usage',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Students: '
                          '${statistics['students'] ?? 0}',
                        ),
                        Text(
                          'Lecturers: '
                          '${statistics['lecturers'] ?? 0}',
                        ),
                        Text(
                          'HODs: '
                          '${statistics['hods'] ?? 0}',
                        ),
                        Text(
                          'Units: '
                          '${statistics['units'] ?? 0}',
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: departmentCodeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Department Code',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.badge),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Department code is required.';
                    }

                    if (value.trim().length > 50) {
                      return 'Department code is too long.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: departmentNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Department Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.business),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Department name is required.';
                    }

                    if (value.trim().length > 255) {
                      return 'Department name is too long.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                Card(
                  child: SwitchListTile(
                    title: const Text('Active Department'),
                    subtitle: Text(
                      isActive
                          ? 'Department is currently active.'
                          : 'Department is currently inactive.',
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

                const SizedBox(height: 12),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'A department with active users or active units may not be allowed to be deactivated. SmartLog will tell you what must be handled first.',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: loading ? null : updateDepartment,
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
