import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminEditUserScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const AdminEditUserScreen({
    super.key,
    required this.user,
  });

  @override
  State<AdminEditUserScreen> createState() =>
      _AdminEditUserScreenState();
}

class _AdminEditUserScreenState
    extends State<AdminEditUserScreen> {
  final formKey = GlobalKey<FormState>();

  late final TextEditingController dwuIdController;
  late final TextEditingController nameController;
  late final TextEditingController emailController;
  late final TextEditingController phoneController;
  late final TextEditingController passwordController;
  late final TextEditingController confirmPasswordController;

  bool loading = false;
  bool loadingOptions = true;
  bool isActive = true;

  String selectedRole = 'STUDENT';
  int? selectedDepartmentId;
  int? selectedYearLevelId;

  List<dynamic> departments = [];
  List<dynamic> yearLevels = [];

  final List<String> roles = [
    'STUDENT',
    'LECTURER',
    'HOD',
    'ICT_ADMIN',
  ];

  @override
  void initState() {
    super.initState();

    dwuIdController = TextEditingController(
      text: widget.user['dwu_id']?.toString() ?? '',
    );

    nameController = TextEditingController(
      text: widget.user['name']?.toString() ?? '',
    );

    emailController = TextEditingController(
      text: widget.user['email']?.toString() ?? '',
    );

    phoneController = TextEditingController(
      text: widget.user['phone']?.toString() ?? '',
    );

    passwordController = TextEditingController();

    confirmPasswordController =
        TextEditingController();

    selectedRole =
        widget.user['role']?.toString() ?? 'STUDENT';

    isActive =
        widget.user['is_active'] == true;

    final department = widget.user['department'];

    if (department is Map) {
      selectedDepartmentId =
          department['id'] as int?;
    }

    final yearLevel = widget.user['year_level'];

    if (yearLevel is Map) {
      selectedYearLevelId =
          yearLevel['id'] as int?;
    }

    loadOptions();
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

  Future<void> loadOptions() async {
    setState(() {
      loadingOptions = true;
    });

    try {
      final result =
          await ApiService.getAdminUsers();

      if (!mounted) return;

      final options =
          Map<String, dynamic>.from(
        result['options'] ?? {},
      );

      final loadedDepartments =
          List<dynamic>.from(
        options['departments'] ?? [],
      );

      /*
      |--------------------------------------------------------------------------
      | Load Year Levels
      |--------------------------------------------------------------------------
      |
      | Current Admin users endpoint does not return year-level options,
      | so we reuse the known SmartLog year-level records currently used
      | by the project.
      |
      */

      final loadedYearLevels = [
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

      setState(() {
        departments = loadedDepartments;
        yearLevels = loadedYearLevels;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        departments = [];
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
      });
    } finally {
      if (mounted) {
        setState(() {
          loadingOptions = false;
        });
      }
    }
  }

  Future<void> updateUser() async {
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
          await ApiService.updateAdminUser(
        userId: widget.user['id'] as int,
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
            passwordController.text.isEmpty
                ? null
                : passwordController.text,
        passwordConfirmation:
            confirmPasswordController.text.isEmpty
                ? null
                : confirmPasswordController.text,
        isActive: isActive,
      );

      if (!mounted) return;

      final message =
          result['message'] ??
              'User account updated successfully.';

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
          'Edit User',
        ),
      ),
      body: SafeArea(
        child: loadingOptions
            ? const Center(
                child:
                    CircularProgressIndicator(),
              )
            : Form(
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
                                    .manage_accounts,
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
                                children: [
                                  const Text(
                                    'Edit SmartLog User',
                                    style:
                                        TextStyle(
                                      fontSize:
                                          20,
                                      fontWeight:
                                          FontWeight
                                              .bold,
                                    ),
                                  ),

                                  const SizedBox(
                                    height: 6,
                                  ),

                                  Text(
                                    widget.user[
                                                'name']
                                            ?.toString() ??
                                        'User',
                                  ),
                                ],
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
                                } else if (
                                    value !=
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
                        border:
                            OutlineInputBorder(),
                        prefixIcon:
                            Icon(
                          Icons.badge_outlined,
                        ),
                      ),
                      validator: (value) {
                        if (value == null ||
                            value
                                .trim()
                                .isEmpty) {
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
                          TextCapitalization
                              .words,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Full Name',
                        border:
                            OutlineInputBorder(),
                        prefixIcon:
                            Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null ||
                            value
                                .trim()
                                .isEmpty) {
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
                            value
                                .trim()
                                .isEmpty) {
                          return 'Email is required.';
                        }

                        if (!value
                            .contains('@')) {
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
                              Icon(
                            Icons.business,
                          ),
                        ),
                        items: departments.map(
                          (item) {
                            final department =
                                Map<String,
                                    dynamic>.from(
                              item,
                            );

                            return DropdownMenuItem<
                                int>(
                              value:
                                  department[
                                          'id']
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
                              Icon(
                            Icons.school,
                          ),
                        ),
                        items: yearLevels.map(
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
                      height: 20,
                    ),

                    const Divider(),

                    const SizedBox(
                      height: 12,
                    ),

                    const Text(
                      'Password Reset',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 6,
                    ),

                    const Text(
                      'Leave both password fields blank to keep the current password.',
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    TextFormField(
                      controller:
                          passwordController,
                      obscureText: true,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'New Password (optional)',
                        border:
                            OutlineInputBorder(),
                        prefixIcon:
                            Icon(Icons.lock),
                      ),
                      validator: (value) {
                        if (value != null &&
                            value.isNotEmpty &&
                            value.length <
                                8) {
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
                            'Confirm New Password',
                        border:
                            OutlineInputBorder(),
                        prefixIcon:
                            Icon(
                          Icons.lock_outline,
                        ),
                      ),
                      validator: (value) {
                        final password =
                            passwordController
                                .text;

                        if (password
                                .isNotEmpty &&
                            value != password) {
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
                              ? 'User can log in.'
                              : 'User cannot log in.',
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
                                : updateUser,
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
                                Icons.save,
                              ),
                        label: Text(
                          loading
                              ? 'Saving...'
                              : 'Save Changes',
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