import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'admin_create_user_screen.dart';
import 'admin_edit_user_screen.dart';
import '../widgets/admin_ui.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final TextEditingController searchController = TextEditingController();

  bool loading = true;
  String? errorMessage;

  List<dynamic> users = [];
  List<dynamic> departments = [];

  String? selectedRole;
  String? selectedStatus;
  int? selectedDepartmentId;

  final List<String> roles = ['STUDENT', 'LECTURER', 'HOD', 'ICT_ADMIN'];

  final List<String> statuses = ['active', 'inactive'];

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadUsers() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final result = await ApiService.getAdminUsers(
        search: searchController.text,
        role: selectedRole,
        departmentId: selectedDepartmentId,
        status: selectedStatus,
      );

      if (!mounted) return;

      final options = Map<String, dynamic>.from(result['options'] ?? {});

      setState(() {
        users = List<dynamic>.from(result['users'] ?? []);

        departments = List<dynamic>.from(options['departments'] ?? []);
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'Unable to load user accounts.';
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> openCreateUser() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AdminCreateUserScreen()),
    );

    if (!mounted) return;

    if (created == true) {
      await loadUsers();
    }
  }

  Future<void> openEditUser(Map<String, dynamic> user) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AdminEditUserScreen(user: user)),
    );

    if (!mounted) return;

    if (updated == true) {
      await loadUsers();
    }
  }

  void clearFilters() {
    searchController.clear();

    setState(() {
      selectedRole = null;
      selectedStatus = null;
      selectedDepartmentId = null;
    });

    loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AdminUi.theme(context),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('User Management'),
          actions: [
            IconButton(
              onPressed: loading ? null : openCreateUser,
              tooltip: 'Create User',
              icon: const Icon(Icons.person_add_alt_1),
            ),
          ],
        ),

        floatingActionButton: FloatingActionButton.extended(
          onPressed: loading ? null : openCreateUser,
          icon: const Icon(Icons.person_add_alt_1),
          label: const Text('Create User'),
        ),

        body: RefreshIndicator(
          onRefresh: loadUsers,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            children: [
              buildHeader(),

              const SizedBox(height: 16),

              buildSearch(),

              const SizedBox(height: 12),

              buildFilters(),

              const SizedBox(height: 16),

              if (loading)
                const Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (errorMessage != null)
                buildError()
              else
                buildUsers(),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.manage_accounts, size: 36),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SmartLog User Accounts',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    '${users.length} account${users.length == 1 ? '' : 's'} displayed',
                  ),

                  const SizedBox(height: 4),

                  const Text(
                    'Search, filter and create Students, Lecturers, HODs and ICT Admins.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSearch() {
    return TextField(
      controller: searchController,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        labelText: 'Search users',
        hintText: 'Name, email or DWU ID',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: searchController.text.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  searchController.clear();

                  setState(() {});

                  loadUsers();
                },
                icon: const Icon(Icons.clear),
              ),
        border: const OutlineInputBorder(),
      ),
      onChanged: (_) {
        setState(() {});
      },
      onSubmitted: (_) {
        loadUsers();
      },
    );
  }

  Widget buildFilters() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              initialValue: selectedRole,
              decoration: const InputDecoration(
                labelText: 'Role',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('All Roles'),
                ),
                ...roles.map(
                  (role) => DropdownMenuItem<String>(
                    value: role,
                    child: Text(roleLabel(role)),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  selectedRole = value;
                });

                loadUsers();
              },
            ),

            const SizedBox(height: 12),

            DropdownButtonFormField<int>(
              initialValue: selectedDepartmentId,
              decoration: const InputDecoration(
                labelText: 'Department',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<int>(
                  value: null,
                  child: Text('All Departments'),
                ),
                ...departments.map((item) {
                  final department = Map<String, dynamic>.from(item);

                  return DropdownMenuItem<int>(
                    value: department['id'] as int,
                    child: Text(
                      department['department_code'] ??
                          department['department_name'] ??
                          'Department',
                    ),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  selectedDepartmentId = value;
                });

                loadUsers();
              },
            ),

            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              initialValue: selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Account Status',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('All Statuses'),
                ),
                ...statuses.map(
                  (status) => DropdownMenuItem<String>(
                    value: status,
                    child: Text(status == 'active' ? 'Active' : 'Inactive'),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  selectedStatus = value;
                });

                loadUsers();
              },
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: clearFilters,
                icon: const Icon(Icons.filter_alt_off),
                label: const Text('Clear Filters'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildError() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 50),

            const SizedBox(height: 12),

            Text(errorMessage!, textAlign: TextAlign.center),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: loadUsers,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildUsers() {
    if (users.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(30),
          child: Column(
            children: [
              Icon(Icons.person_search, size: 50),

              SizedBox(height: 12),

              Text(
                'No users found.',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),

              SizedBox(height: 6),

              Text(
                'Try changing your search or filters.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Accounts (${users.length})',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 10),

        ...users.map((item) {
          final user = Map<String, dynamic>.from(item);

          return buildUserCard(user);
        }),
      ],
    );
  }

  Widget buildUserCard(Map<String, dynamic> user) {
    final department = user['department'] != null
        ? Map<String, dynamic>.from(user['department'])
        : <String, dynamic>{};

    final yearLevel = user['year_level'] != null
        ? Map<String, dynamic>.from(user['year_level'])
        : <String, dynamic>{};

    final role = user['role']?.toString() ?? '';

    final isActive = user['is_active'] == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openEditUser(user),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(child: Icon(roleIcon(role))),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user['name'] ?? 'User',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 3),

                        Text(user['dwu_id'] ?? '-'),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Chip(label: Text(isActive ? 'Active' : 'Inactive')),

                      const SizedBox(height: 2),

                      const Icon(Icons.edit_outlined, size: 20),
                    ],
                  ),
                ],
              ),

              const Divider(height: 24),

              buildUserDetail(Icons.badge_outlined, 'Role', roleLabel(role)),

              buildUserDetail(
                Icons.email_outlined,
                'Email',
                user['email'] ?? '-',
              ),

              if (department.isNotEmpty)
                buildUserDetail(
                  Icons.business_outlined,
                  'Department',
                  '${department['code'] ?? ''} - '
                      '${department['name'] ?? ''}',
                ),

              if (yearLevel.isNotEmpty)
                buildUserDetail(
                  Icons.school_outlined,
                  'Year Level',
                  yearLevel['name'] ?? 'Year ${yearLevel['number'] ?? '-'}',
                ),

              if (user['phone'] != null && user['phone'].toString().isNotEmpty)
                buildUserDetail(Icons.phone_outlined, 'Phone', user['phone']),

              const SizedBox(height: 4),

              const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.touch_app_outlined, size: 17),
                  SizedBox(width: 5),
                  Text('Tap to edit', style: TextStyle(fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildUserDetail(IconData icon, String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18),

          const SizedBox(width: 8),

          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),

          Expanded(child: Text('${value ?? '-'}')),
        ],
      ),
    );
  }

  String roleLabel(String role) {
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

  IconData roleIcon(String role) {
    switch (role) {
      case 'STUDENT':
        return Icons.school;

      case 'LECTURER':
        return Icons.person_outline;

      case 'HOD':
        return Icons.admin_panel_settings;

      case 'ICT_ADMIN':
        return Icons.settings;

      default:
        return Icons.person;
    }
  }
}
