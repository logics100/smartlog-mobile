import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../widgets/admin_ui.dart';

class AdminCreateDepartmentScreen extends StatefulWidget {
  const AdminCreateDepartmentScreen({super.key});

  @override
  State<AdminCreateDepartmentScreen> createState() =>
      _AdminCreateDepartmentScreenState();
}

class _AdminCreateDepartmentScreenState
    extends State<AdminCreateDepartmentScreen> {
  final formKey = GlobalKey<FormState>();

  final departmentCodeController = TextEditingController();

  final departmentNameController = TextEditingController();

  bool loading = false;
  bool isActive = true;

  @override
  void dispose() {
    departmentCodeController.dispose();
    departmentNameController.dispose();

    super.dispose();
  }

  Future<void> createDepartment() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      final result = await ApiService.createAdminDepartment(
        departmentCode: departmentCodeController.text.trim(),
        departmentName: departmentNameController.text.trim(),
        isActive: isActive,
      );

      if (!mounted) return;

      final message = result['message'] ?? 'Department created successfully.';

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
    return Theme(
      data: AdminUi.theme(context),
      child: Scaffold(
        appBar: AppBar(title: const Text('Create Department')),
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
                        const CircleAvatar(child: Icon(Icons.add_business)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'New SmartLog Department',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Create a department that can later contain students, lecturers, HODs and units.',
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
                  controller: departmentCodeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Department Code',
                    hintText: 'Example: MBBS',
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
                    hintText: 'Example: Medicine and Surgery',
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
                          ? 'Department can be used in SmartLog.'
                          : 'Department will be created as inactive.',
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
                    onPressed: loading ? null : createDepartment,
                    icon: loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add_business),
                    label: Text(loading ? 'Creating...' : 'Create Department'),
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
