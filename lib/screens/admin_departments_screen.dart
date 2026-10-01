import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'admin_create_department_screen.dart';
import 'admin_edit_department_screen.dart';
import '../widgets/admin_ui.dart';

class AdminDepartmentsScreen extends StatefulWidget {
  const AdminDepartmentsScreen({super.key});

  @override
  State<AdminDepartmentsScreen> createState() => _AdminDepartmentsScreenState();
}

class _AdminDepartmentsScreenState extends State<AdminDepartmentsScreen> {
  final searchController = TextEditingController();

  bool loading = true;
  String? errorMessage;

  List<dynamic> departments = [];

  int totalDepartments = 0;
  int activeDepartments = 0;
  int inactiveDepartments = 0;

  String? selectedStatus;

  @override
  void initState() {
    super.initState();
    loadDepartments();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadDepartments() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final result = await ApiService.getAdminDepartments(
        search: searchController.text.trim(),
        status: selectedStatus,
      );

      if (!mounted) return;

      final summary = Map<String, dynamic>.from(result['summary'] ?? {});

      setState(() {
        departments = List<dynamic>.from(result['departments'] ?? []);

        totalDepartments = summary['total'] ?? 0;

        activeDepartments = summary['active'] ?? 0;

        inactiveDepartments = summary['inactive'] ?? 0;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> openCreateDepartment() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AdminCreateDepartmentScreen()),
    );

    if (!mounted) return;

    if (created == true) {
      await loadDepartments();
    }
  }

  Future<void> openEditDepartment(Map<String, dynamic> department) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AdminEditDepartmentScreen(department: department),
      ),
    );

    if (!mounted) return;

    if (updated == true) {
      await loadDepartments();
    }
  }

  void clearFilters() {
    searchController.clear();

    setState(() {
      selectedStatus = null;
    });

    loadDepartments();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AdminUi.theme(context),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Department Management'),
          actions: [
            IconButton(
              tooltip: 'Refresh',
              onPressed: loading ? null : loadDepartments,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),

        floatingActionButton: FloatingActionButton.extended(
          onPressed: loading ? null : openCreateDepartment,
          icon: const Icon(Icons.add_business),
          label: const Text('Add Department'),
        ),

        body: RefreshIndicator(
          onRefresh: loadDepartments,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            children: [
              buildSummary(),

              const SizedBox(height: 20),

              const Text(
                'Search & Filter',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  labelText: 'Search department',
                  hintText: 'Code or department name',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            searchController.clear();

                            setState(() {});

                            loadDepartments();
                          },
                          icon: const Icon(Icons.clear),
                        )
                      : null,
                ),
                textInputAction: TextInputAction.search,
                onChanged: (_) {
                  setState(() {});
                },
                onSubmitted: (_) {
                  loadDepartments();
                },
              ),

              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                initialValue: selectedStatus,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.toggle_on_outlined),
                ),
                items: const [
                  DropdownMenuItem<String>(
                    value: null,
                    child: Text('All Departments'),
                  ),
                  DropdownMenuItem<String>(
                    value: 'active',
                    child: Text('Active Departments'),
                  ),
                  DropdownMenuItem<String>(
                    value: 'inactive',
                    child: Text('Inactive Departments'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedStatus = value;
                  });

                  loadDepartments();
                },
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: clearFilters,
                      icon: const Icon(Icons.filter_alt_off),
                      label: const Text('Clear Filters'),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: loading ? null : loadDepartments,
                      icon: const Icon(Icons.search),
                      label: const Text('Search'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Departments',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  Text('${departments.length} shown'),
                ],
              ),

              const SizedBox(height: 12),

              if (loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 50),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (errorMessage != null)
                buildError()
              else if (departments.isEmpty)
                buildEmpty()
              else
                ...departments.map((item) {
                  final department = Map<String, dynamic>.from(item);

                  return buildDepartmentCard(department);
                }),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.business, size: 28),

                SizedBox(width: 10),

                Expanded(
                  child: Text(
                    'SmartLog Departments',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            const Text('Manage the academic departments using SmartLog.'),

            const SizedBox(height: 18),

            Row(
              children: [
                Expanded(
                  child: buildSummaryItem(
                    'Total',
                    totalDepartments,
                    Icons.business,
                  ),
                ),

                Expanded(
                  child: buildSummaryItem(
                    'Active',
                    activeDepartments,
                    Icons.check_circle_outline,
                  ),
                ),

                Expanded(
                  child: buildSummaryItem(
                    'Inactive',
                    inactiveDepartments,
                    Icons.block,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSummaryItem(String label, int value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 25),

        const SizedBox(height: 6),

        Text(
          '$value',
          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 2),

        Text(label, textAlign: TextAlign.center),
      ],
    );
  }

  Widget buildDepartmentCard(Map<String, dynamic> department) {
    final statistics = Map<String, dynamic>.from(
      department['statistics'] ?? {},
    );

    final isActive = department['is_active'] == true;

    final code = department['department_code']?.toString() ?? '';

    final firstLetter = code.isNotEmpty ? code.substring(0, 1) : 'D';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          openEditDepartment(department);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(child: Text(firstLetter)),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          department['department_name'] ?? 'Department',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          'Code: '
                          '${department['department_code'] ?? '-'}',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Chip(label: Text(isActive ? 'Active' : 'Inactive')),

                      const Icon(Icons.edit_outlined, size: 20),
                    ],
                  ),
                ],
              ),

              const Divider(height: 24),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  buildStatisticChip(
                    Icons.school_outlined,
                    '${statistics['students'] ?? 0} Students',
                  ),

                  buildStatisticChip(
                    Icons.person_outline,
                    '${statistics['lecturers'] ?? 0} Lecturers',
                  ),

                  buildStatisticChip(
                    Icons.admin_panel_settings_outlined,
                    '${statistics['hods'] ?? 0} HODs',
                  ),

                  buildStatisticChip(
                    Icons.menu_book_outlined,
                    '${statistics['units'] ?? 0} Units',
                  ),
                ],
              ),

              const SizedBox(height: 12),

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

  Widget buildStatisticChip(IconData icon, String text) {
    return Chip(avatar: Icon(icon, size: 17), label: Text(text));
  }

  Widget buildError() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 48),

            const SizedBox(height: 12),

            Text(errorMessage!, textAlign: TextAlign.center),

            const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: loadDepartments,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildEmpty() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(30),
        child: Column(
          children: [
            Icon(Icons.business_outlined, size: 50),

            SizedBox(height: 12),

            Text(
              'No departments found.',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 6),

            Text(
              'Try changing the search or filter.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
