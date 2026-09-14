import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminCreateUserScreen extends StatefulWidget {
  const AdminCreateUserScreen({
    super.key,
  });

  @override
  State<AdminCreateUserScreen> createState() =>
      _AdminCreateUserScreenState();
}

class _AdminCreateUserScreenState
    extends State<AdminCreateUserScreen> {
  final formKey = GlobalKey<FormState>();

  final dwuIdController =
      TextEditingController();

  final nameController =
      TextEditingController();

  final emailController =
      TextEditingController();

  final phoneController =
      TextEditingController();

  final passwordController =
      TextEditingController();

  final confirmPasswordController =
      TextEditingController();

  bool loading = false;
  bool isActive = true;

  String selectedRole = 'STUDENT';

  int? selectedDepartmentId;
  int? selectedYearLevelId;

  List<dynamic> departments = [];

  final List<Map<String, dynamic>>
      yearLevels = [
    {
      'id': 1,
      'name': 'Year 2',
    },
    {
      'id': 2,
      'name': 'Year 3',
    },
    {
      'id': 3,
      'name': 'Year 4',
    },
    {
      'id': 4,
      'name': 'Year 5',
    },
  ];

  final List<String> roles = [
    'STUDENT',
    'LECTURER',
    'HOD',
    'ICT_ADMIN',
  ];

  @override
  void initState() {
    super.initState();
    loadDepartments();
  }

  @override
  void dispose() {
    dwuIdController.dispose();
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();

    super.dispose();
  }

  Future<void> loadDepartments() async {
    try {
      final result =
          await ApiService.getAdminUsers();

      final options =
          Map<String, dynamic>.from(
        result['options'] ?? {},
      );

      if (!mounted) return;

      setState(() {
        departments =
            List<dynamic>.from(
          options['departments'] ?? [],
        );
      });
    } catch (_) {}
  }

  Future<void> createUser() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    if (
        selectedRole != 'ICT_ADMIN' &&
        selectedDepartmentId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a department.',
          ),
        ),
      );

      return;
    }

    if (
        selectedRole == 'STUDENT' &&
        selectedYearLevelId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a year level.',
          ),
        ),
      );

      return;
    }

    setState(() {
      loading = true;
    });

    try {
      final result =
          await ApiService.createAdminUser(
        dwuId:
            dwuIdController.text.trim(),
        name:
            nameController.text.trim(),
        email:
            emailController.text.trim(),
        phone:
            phoneController.text.trim(),
        role: selectedRole,
        departmentId:
            selectedRole == 'ICT_ADMIN'
                ? null
                : selectedDepartmentId,
        yearLevelId:
            selectedRole == 'STUDENT'
                ? selectedYearLevelId
                : null,
        password:
            passwordController.text,
        passwordConfirmation:
            confirmPasswordController.text,
        isActive: isActive,
      );

      if (!mounted) return;

      final message =
          result['message'] ??
              'User created successfully.';

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

      final message = e
          .toString()
          .replaceFirst(
            'Exception: ',
            '',
          );

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(message),
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

  @override
  Widget build(BuildContext context) {
    final requiresDepartment =
        selectedRole != 'ICT_ADMIN';

    final requiresYearLevel =
        selectedRole == 'STUDENT';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create User',
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
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons
                                .person_add_alt_1,
                            size: 32,
                          ),
                          SizedBox(
                            width: 12,
                          ),
                          Expanded(
                            child: Text(
                              'Create SmartLog User Account',
                              style:
                                  TextStyle(
                                fontSize: 20,
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      Text(
                        'Create Student, Lecturer, HOD or ICT Admin accounts.',
                        style: TextStyle(
                          color: Colors
                              .grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(
                height: 16,
              ),

              DropdownButtonFormField<
                  String>(
                initialValue:
                    selectedRole,
                decoration:
                    const InputDecoration(
                  labelText: 'Role',
                  border:
                      OutlineInputBorder(),
                  prefixIcon:
                      Icon(Icons.badge),
                ),
                items: roles.map(
                  (role) {
                    return DropdownMenuItem<
                        String>(
                      value: role,
                      child: Text(
                        roleLabel(role),
                      ),
                    );
                  },
                ).toList(),
                onChanged: loading
                    ? null
                    : (value) {
                        if (value ==
                            null) {
                          return;
                        }

                        setState(() {
                          selectedRole =
                              value;

                          if (value ==
                              'ICT_ADMIN') {
                            selectedDepartmentId =
                                null;
                            selectedYearLevelId =
                                null;
                          } else if (value !=
                              'STUDENT') {
                            selectedYearLevelId =
                                null;
                          }
                        });
                      },
              ),

              const SizedBox(
                height: 16,
              ),

              TextFormField(
                controller:
                    dwuIdController,
                textCapitalization:
                    TextCapitalization
                        .characters,
                decoration:
                    const InputDecoration(
                  labelText: 'DWU ID',
                  hintText:
                      'Example: STU010',
                  border:
                      OutlineInputBorder(),
                  prefixIcon:
                      Icon(Icons.badge_outlined),
                ),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'DWU ID is required.';
                  }

                  return null;
                },
              ),

              const SizedBox(
                height: 16,
              ),

              TextFormField(
                controller:
                    nameController,
                textCapitalization:
                    TextCapitalization.words,
                decoration:
                    const InputDecoration(
                  labelText: 'Full Name',
                  border:
                      OutlineInputBorder(),
                  prefixIcon:
                      Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Name is required.';
                  }

                  return null;
                },
              ),

              const SizedBox(
                height: 16,
              ),

              TextFormField(
                controller:
                    emailController,
                keyboardType:
                    TextInputType
                        .emailAddress,
                decoration:
                    const InputDecoration(
                  labelText: 'Email',
                  border:
                      OutlineInputBorder(),
                  prefixIcon:
                      Icon(Icons.email),
                ),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Email is required.';
                  }

                  if (!value.contains('@')) {
                    return 'Enter a valid email.';
                  }

                  return null;
                },
              ),

              const SizedBox(
                height: 16,
              ),

              TextFormField(
                controller:
                    phoneController,
                keyboardType:
                    TextInputType.phone,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Phone (optional)',
                  border:
                      OutlineInputBorder(),
                  prefixIcon:
                      Icon(Icons.phone),
                ),
              ),

              if (requiresDepartment) ...[
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
                  items: departments
                      .map(
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
                           overflow: TextOverflow.ellipsis,
                        ),
                      );
                    },
                  ).toList(),
                  onChanged: loading
                      ? null
                      : (value) {
                          setState(() {
                            selectedDepartmentId =
                                value;
                          });
                        },
                ),
              ],

              if (requiresYearLevel) ...[
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
                  items: yearLevels
                      .map(
                    (item) {
                      return DropdownMenuItem<
                          int>(
                        value:
                            item['id']
                                as int,
                        child: Text(
                          item['name']
                              .toString(),
                        ),
                      );
                    },
                  ).toList(),
                  onChanged: loading
                      ? null
                      : (value) {
                          setState(() {
                            selectedYearLevelId =
                                value;
                          });
                        },
                ),
              ],

              const SizedBox(
                height: 16,
              ),

              TextFormField(
                controller:
                    passwordController,
                obscureText: true,
                decoration:
                    const InputDecoration(
                  labelText: 'Password',
                  border:
                      OutlineInputBorder(),
                  prefixIcon:
                      Icon(Icons.lock),
                ),
                validator: (value) {
                  if (value == null ||
                      value.isEmpty) {
                    return 'Password is required.';
                  }

                  if (value.length < 8) {
                    return 'Password must be at least 8 characters.';
                  }

                  return null;
                },
              ),

              const SizedBox(
                height: 16,
              ),

              TextFormField(
                controller:
                    confirmPasswordController,
                obscureText: true,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Confirm Password',
                  border:
                      OutlineInputBorder(),
                  prefixIcon:
                      Icon(Icons.lock_outline),
                ),
                validator: (value) {
                  if (value !=
                      passwordController.text) {
                    return 'Passwords do not match.';
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
                    'Active Account',
                  ),
                  subtitle: Text(
                    isActive
                        ? 'User can log in immediately.'
                        : 'User account will be created but cannot log in.',
                  ),
                  value: isActive,
                  onChanged: loading
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
                          : createUser,
                  icon: loading
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
                          Icons
                              .person_add_alt_1,
                        ),
                  label: Text(
                    loading
                        ? 'Creating...'
                        : 'Create User Account',
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

  String roleLabel(
    String role,
  ) {
    switch (role) {
      case 'STUDENT':
        return 'Student';

      case 'LECTURER':
        return 'Lecturer';

      case 'HOD':
        return 'HOD';

      case 'ICT_ADMIN':
        return 'ICT Admin';

      default:
        return role;
    }
  }
}