import 'admin_appearance_screen.dart';

import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'login_screen.dart';
import 'admin_users_screen.dart';
import 'admin_departments_screen.dart';
import 'admin_units_screen.dart';
import 'admin_enrollments_screen.dart';
import '../widgets/admin_ui.dart';

class AdminHomeScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const AdminHomeScreen({super.key, required this.user});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  bool loading = true;
  String? errorMessage;

  Map<String, dynamic>? dashboard;

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final result = await ApiService.getAdminDashboard();

      if (!mounted) return;

      setState(() {
        dashboard = result;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'Unable to load ICT Admin dashboard.';
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> logout() async {
    try {
      await ApiService.logout();
    } catch (_) {}

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> openUserManagement() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminUsersScreen()),
    );

    if (mounted) {
      await loadDashboard();
    }
  }

  Future<void> openDepartmentManagement() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminDepartmentsScreen()),
    );

    if (mounted) {
      await loadDashboard();
    }
  }

  Future<void> openEnrollmentMonitoring() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminEnrollmentsScreen()),
    );
  }

  Future<void> openUnitManagement() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminUnitsScreen()),
    );

    if (mounted) {
      await loadDashboard();
    }
  }

  final GlobalKey overviewKey = GlobalKey();

  Future<void> openOverview() async {
    final target = overviewKey.currentContext;
    if (target != null) {
      await Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    }
  }

  void openAppearanceWeb() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminAppearanceScreen()),
    );
  }

  Widget _portalTile(
    IconData icon,
    String title,
    String description,
    VoidCallback action,
  ) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: action,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F4FE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AdminUi.royalBlue, size: 25),
              ),
              const SizedBox(height: 9),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AdminUi.navy,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11.5, color: AdminUi.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AdminUi.theme(context),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('ICT Admin Dashboard'),
          actions: [
            IconButton(
              tooltip: 'Refresh',
              onPressed: loading ? null : loadDashboard,
              icon: const Icon(Icons.refresh),
            ),
            IconButton(
              tooltip: 'Logout',
              onPressed: logout,
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: loadDashboard,
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : errorMessage != null
              ? ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    const SizedBox(height: 80),
                    const Icon(Icons.error_outline, size: 60),
                    const SizedBox(height: 16),
                    Text(errorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: loadDashboard,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                    ),
                  ],
                )
              : buildDashboard(),
        ),
      ),
    );
  }

  Widget buildDashboard() {
    final data = dashboard ?? {};

    final admin = Map<String, dynamic>.from(data['admin'] ?? {});

    final summary = Map<String, dynamic>.from(data['summary'] ?? {});

    final users = Map<String, dynamic>.from(data['users'] ?? {});

    final units = Map<String, dynamic>.from(data['units'] ?? {});

    final enrollments = Map<String, dynamic>.from(data['enrollments'] ?? {});

    final logbooks = Map<String, dynamic>.from(data['logbooks'] ?? {});

    final clinicalEntries = Map<String, dynamic>.from(
      data['clinical_entries'] ?? {},
    );

    final departments = Map<String, dynamic>.from(data['departments'] ?? {});

    final departmentItems = List<dynamic>.from(departments['items'] ?? []);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 28,
                  child: Icon(Icons.admin_panel_settings, size: 30),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, '
                        '${admin['name'] ?? widget.user['name'] ?? 'ICT Admin'}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(admin['email'] ?? widget.user['email'] ?? ''),

                      const SizedBox(height: 4),

                      Text(
                        'DWU ID: '
                        '${admin['dwu_id'] ?? widget.user['dwu_id'] ?? '-'}',
                      ),

                      const SizedBox(height: 4),

                      Text(
                        'Role: '
                        '${admin['role'] ?? 'ICT_ADMIN'}',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        const Text(
          'ICT ADMIN PORTAL',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AdminUi.royalBlue,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Navigation',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            return GridView.count(
              crossAxisCount: constraints.maxWidth >= 600 ? 3 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              mainAxisExtent: constraints.maxWidth >= 600 ? 160 : 180,
              children: [
                _portalTile(
                  Icons.dashboard_rounded,
                  'Dashboard',
                  'Refresh overview',
                  loadDashboard,
                ),
                _portalTile(
                  Icons.manage_accounts_rounded,
                  'User Management',
                  'Accounts and access',
                  openUserManagement,
                ),
                _portalTile(
                  Icons.apartment_rounded,
                  'Departments',
                  'Manage departments',
                  openDepartmentManagement,
                ),
                _portalTile(
                  Icons.menu_book_rounded,
                  'Units',
                  'Manage clinical units',
                  openUnitManagement,
                ),
                _portalTile(
                  Icons.school_outlined,
                  'Enrollments',
                  'Monitor student enrollment',
                  openEnrollmentMonitoring,
                ),
                _portalTile(
                  Icons.palette_rounded,
                  'Appearance & Images',
                  'Open web settings',
                  openAppearanceWeb,
                ),
                _portalTile(
                  Icons.insights_rounded,
                  'System Overview',
                  'View activity below',
                  openOverview,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        Text(
          'System Overview',
          key: overviewKey,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 12),

        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.15,
          children: [
            buildSummaryCard(
              title: 'Departments',
              value: '${summary['departments'] ?? 0}',
              icon: Icons.business,
              onTap: openDepartmentManagement,
            ),

            buildSummaryCard(
              title: 'Users',
              value: '${summary['users'] ?? 0}',
              icon: Icons.people,
              onTap: openUserManagement,
            ),

            buildSummaryCard(
              title: 'Students',
              value: '${summary['students'] ?? 0}',
              icon: Icons.school,
            ),

            buildSummaryCard(
              title: 'Lecturers',
              value: '${summary['lecturers'] ?? 0}',
              icon: Icons.person_outline,
            ),

            buildSummaryCard(
              title: 'HODs',
              value: '${summary['hods'] ?? 0}',
              icon: Icons.admin_panel_settings,
            ),

            buildSummaryCard(
              title: 'Units',
              value: '${summary['units'] ?? 0}',
              icon: Icons.menu_book,
              onTap: openUnitManagement,
            ),

            buildSummaryCard(
              title: 'Enrollments',
              value: '${summary['enrollments'] ?? 0}',
              icon: Icons.assignment_ind,
            ),

            buildSummaryCard(
              title: 'ICT Admins',
              value: '${summary['ict_admins'] ?? 0}',
              icon: Icons.settings,
            ),
          ],
        ),

        const SizedBox(height: 24),

        const Text(
          'User Accounts',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 12),

        Card(
          child: Column(
            children: [
              buildInfoRow(
                'Total Users',
                users['total'],
                onTap: openUserManagement,
              ),

              buildInfoRow(
                'Active Users',
                users['active'],
                onTap: openUserManagement,
              ),

              buildInfoRow(
                'Inactive Users',
                users['inactive'],
                onTap: openUserManagement,
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        const Text(
          'Logbook Activity',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 12),

        Card(
          child: Column(
            children: [
              buildInfoRow('Total Logbooks', logbooks['total']),

              buildInfoRow('Active', logbooks['active']),

              buildInfoRow('Completed', logbooks['completed']),

              buildInfoRow('Submitted', logbooks['submitted']),

              buildInfoRow('Archived', logbooks['archived']),

              buildInfoRow(
                'Average Completion',
                '${logbooks['average_completion_percentage'] ?? 0}%',
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        const Text(
          'Clinical Entries',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 12),

        Card(
          child: Column(
            children: [
              buildInfoRow('Total Entries', clinicalEntries['total']),

              buildInfoRow('Draft', clinicalEntries['draft']),

              buildInfoRow(
                'Pending Verification',
                clinicalEntries['pending_verification'],
              ),

              buildInfoRow('Verified', clinicalEntries['verified']),

              buildInfoRow('Rejected', clinicalEntries['rejected']),
            ],
          ),
        ),

        const SizedBox(height: 24),

        const Text(
          'System Setup',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 12),

        Card(
          child: Column(
            children: [
              buildInfoRow(
                'Active Units',
                units['active'],
                onTap: openUnitManagement,
              ),

              buildInfoRow(
                'Logbook Units',
                units['requiring_logbook'],
                onTap: openUnitManagement,
              ),

              buildInfoRow('Enrollments', enrollments['total']),
            ],
          ),
        ),

        const SizedBox(height: 24),

        Row(
          children: [
            const Expanded(
              child: Text(
                'Departments',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),

            TextButton.icon(
              onPressed: openDepartmentManagement,
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('Manage'),
            ),
          ],
        ),

        const SizedBox(height: 12),

        ...departmentItems.map((item) {
          final department = Map<String, dynamic>.from(item);

          final statistics = Map<String, dynamic>.from(
            department['statistics'] ?? {},
          );

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: openDepartmentManagement,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            department['department_name'] ?? 'Department',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        const Icon(Icons.chevron_right),
                      ],
                    ),

                    const SizedBox(height: 4),

                    Text(
                      'Code: '
                      '${department['department_code'] ?? '-'}',
                    ),

                    const Divider(height: 24),

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
          );
        }),

        const SizedBox(height: 20),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline),

                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    'ICT Admin manages system accounts, departments, '
                    'units and system setup. Clinical verification '
                    'decisions remain the responsibility of lecturers.',
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 30),
      ],
    );
  }

  Widget buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 30),

              const SizedBox(height: 8),

              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 4),

              Text(title, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildInfoRow(String label, dynamic value, {VoidCallback? onTap}) {
    return ListTile(
      dense: true,
      title: Text(label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${value ?? 0}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),

          if (onTap != null) ...[
            const SizedBox(width: 6),

            const Icon(Icons.chevron_right, size: 20),
          ],
        ],
      ),
      onTap: onTap,
    );
  }
}
