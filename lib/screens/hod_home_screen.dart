import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'hod_students_screen.dart';
import 'hod_units_screen.dart';
import 'hod_year_levels_screen.dart';
import 'hod_lecturers_screen.dart';

class HodHomeScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const HodHomeScreen({
    super.key,
    required this.user,
  });

  @override
  State<HodHomeScreen> createState() =>
      _HodHomeScreenState();
}

class _HodHomeScreenState
    extends State<HodHomeScreen> {
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
      final result =
          await ApiService.getHodDashboard();

      if (!mounted) return;

      setState(() {
        dashboard = result;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage =
            'Unable to load HOD dashboard.';
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> openStudents() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const HodStudentsScreen(),
      ),
    );

    if (mounted) {
      await loadDashboard();
    }
  }

  Future<void> openLecturers() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const HodLecturersScreen(),
      ),
    );

    if (mounted) {
      await loadDashboard();
    }
  }

  Future<void> openUnits() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const HodUnitsScreen(),
      ),
    );

    if (mounted) {
      await loadDashboard();
    }
  }

  Future<void> openYearLevels() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const HodYearLevelsScreen(),
      ),
    );

    if (mounted) {
      await loadDashboard();
    }
  }

  Future<void> logout() async {
    try {
      await ApiService.logout();
    } catch (_) {}

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const LoginScreen(),
      ),
      (route) => false,
    );
  }

  Map<String, dynamic> mapOf(
    dynamic value,
  ) {
    if (value is Map) {
      return Map<String, dynamic>.from(
        value,
      );
    }

    return {};
  }

  List<dynamic> listOf(dynamic value) {
    if (value is List) {
      return value;
    }

    return [];
  }

  double toDouble(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value.toString(),
        ) ??
        0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('HOD Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed:
                loading ? null : loadDashboard,
            icon:
                const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: logout,
            icon:
                const Icon(Icons.logout),
          ),
        ],
      ),
      body: loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : errorMessage != null
              ? buildErrorState()
              : buildDashboard(),
    );
  }

  Widget buildErrorState() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(24),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 52,
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage!,
              textAlign:
                  TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: loadDashboard,
              icon:
                  const Icon(Icons.refresh),
              label:
                  const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildDashboard() {
    final hod =
        mapOf(dashboard?['hod']);

    final department =
        mapOf(dashboard?['department']);

    final summary =
        mapOf(dashboard?['summary']);

    final logbooks =
        mapOf(dashboard?['logbooks']);

    final clinicalEntries =
        mapOf(
      dashboard?['clinical_entries'],
    );

    final yearLevels =
        listOf(
      dashboard?['year_levels'],
    );

    return RefreshIndicator(
      onRefresh: loadDashboard,
      child: ListView(
        padding:
            const EdgeInsets.all(16),
        children: [
          buildHeader(
            hod: hod,
            department: department,
          ),

          const SizedBox(height: 20),

          buildReadOnlyBanner(),

          const SizedBox(height: 24),

          const Text(
            'Quick Access',
            style: TextStyle(
              fontSize: 20,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'View department students, '
            'teaching staff, units and '
            'year-level progress.',
            style: TextStyle(
              color:
                  Colors.grey.shade700,
            ),
          ),

          const SizedBox(height: 14),

          buildQuickAccessGrid(),

          const SizedBox(height: 28),

          const Text(
            'Department Overview',
            style: TextStyle(
              fontSize: 20,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          buildSummaryGrid(summary),

          const SizedBox(height: 24),

          buildProgressCard(logbooks),

          const SizedBox(height: 24),

          buildClinicalEntrySection(
            clinicalEntries,
          ),

          const SizedBox(height: 24),

          buildYearLevelSection(
            yearLevels,
          ),

          const SizedBox(height: 24),

          buildReadOnlyNotice(),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget buildHeader({
    required Map<String, dynamic> hod,
    required Map<String, dynamic>
        department,
  }) {
    final hodName =
        hod['name']?.toString() ??
            'HOD';

    final dwuId =
        hod['dwu_id']?.toString() ??
            '';

    final departmentCode =
        department['department_code']
                ?.toString() ??
            '';

    final departmentName =
        department['department_name']
                ?.toString() ??
            'Department';

    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              radius: 30,
              child: Icon(
                Icons
                    .admin_panel_settings,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  const Text(
                    'Welcome',
                    style: TextStyle(
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(
                    height: 3,
                  ),
                  Text(
                    hodName,
                    style:
                        const TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  if (dwuId
                      .isNotEmpty) ...[
                    const SizedBox(
                      height: 4,
                    ),
                    Text(
                      'DWU ID: $dwuId',
                    ),
                  ],
                  const SizedBox(
                    height: 8,
                  ),
                  Text(
                    departmentCode
                            .isEmpty
                        ? departmentName
                        : '$departmentCode - '
                            '$departmentName',
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildReadOnlyBanner() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(12),
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest,
      ),
      child: const Row(
        children: [
          Icon(
            Icons.visibility_outlined,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Department Monitoring • '
              'Read-Only Access',
              style: TextStyle(
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildQuickAccessGrid() {
    final items = [
      {
        'title': 'Students',
        'subtitle':
            'Student progress',
        'icon': Icons.school_outlined,
        'onTap': openStudents,
      },
      {
        'title': 'Teaching Staff',
        'subtitle':
            'Lecturer progress',
        'icon': Icons
            .people_outline,
        'onTap': openLecturers,
      },
      {
        'title': 'Units',
        'subtitle':
            'Unit progress',
        'icon': Icons
            .menu_book_outlined,
        'onTap': openUnits,
      },
      {
        'title': 'Year Levels',
        'subtitle':
            'Year progress',
        'icon': Icons
            .bar_chart_outlined,
        'onTap': openYearLevels,
      },
    ];

    return LayoutBuilder(
      builder: (
        context,
        constraints,
      ) {
        final columns =
            constraints.maxWidth >= 700
                ? 4
                : 2;

        final spacing = 12.0;

        final width =
            (constraints.maxWidth -
                    spacing *
                        (columns - 1)) /
                columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: items.map((item) {
            return SizedBox(
              width: width,
              child:
                  buildQuickAccessCard(
                title:
                    item['title']
                        .toString(),
                subtitle:
                    item['subtitle']
                        .toString(),
                icon:
                    item['icon']
                        as IconData,
                onTap:
                    item['onTap']
                        as VoidCallback,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget buildQuickAccessCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius:
            BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding:
              const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 30,
              ),
              const SizedBox(
                height: 12,
              ),
              Text(
                title,
                style:
                    const TextStyle(
                  fontSize: 15,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
              const SizedBox(
                height: 3,
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color:
                      Colors.grey.shade700,
                ),
              ),
              const SizedBox(
                height: 8,
              ),
              const Align(
                alignment:
                    Alignment.centerRight,
                child: Icon(
                  Icons.chevron_right,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildSummaryGrid(
    Map<String, dynamic> summary,
  ) {
    final items = [
      {
        'title': 'Students',
        'value':
            summary['total_students'] ??
                0,
        'icon': Icons.school,
        'onTap': openStudents,
      },
      {
        'title': 'Lecturers',
        'value':
            summary[
                    'total_lecturers'] ??
                0,
        'icon':
            Icons.person_outline,
        'onTap': openLecturers,
      },
      {
        'title': 'Units',
        'value':
            summary['total_units'] ??
                0,
        'icon': Icons
            .menu_book_outlined,
        'onTap': openUnits,
      },
      {
        'title': 'Enrollments',
        'value':
            summary[
                    'total_enrollments'] ??
                0,
        'icon': Icons
            .assignment_ind_outlined,
        'onTap': null,
      },
    ];

    return LayoutBuilder(
      builder: (
        context,
        constraints,
      ) {
        final isWide =
            constraints.maxWidth >= 700;

        final cardWidth = isWide
            ? (constraints.maxWidth -
                    16) /
                2
            : constraints.maxWidth;

        return Wrap(
          spacing: 16,
          runSpacing: 12,
          children: items.map((item) {
            return SizedBox(
              width: cardWidth,
              child:
                  buildStatisticCard(
                title:
                    item['title']
                        .toString(),
                value:
                    item['value']
                        .toString(),
                icon:
                    item['icon']
                        as IconData,
                onTap:
                    item['onTap']
                        as VoidCallback?,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget buildStatisticCard({
    required String title,
    required String value,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return Card(
      child: InkWell(
        borderRadius:
            BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding:
              const EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(
                icon,
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      value,
                      style:
                          const TextStyle(
                        fontSize: 24,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    Text(title),
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(
                  Icons.chevron_right,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildProgressCard(
    Map<String, dynamic> logbooks,
  ) {
    final average = toDouble(
      logbooks[
          'average_completion_percentage'],
    );

    final progress =
        (average / 100)
            .clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons
                      .fact_check_outlined,
                ),
                SizedBox(width: 10),
                Text(
                  'Logbook Progress',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            Row(
              children: [
                Expanded(
                  child: Text(
                    'Average Department '
                    'Completion',
                    style: TextStyle(
                      color:
                          Colors.grey.shade700,
                    ),
                  ),
                ),
                Text(
                  '${average.toStringAsFixed(2)}%',
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            LinearProgressIndicator(
              value: progress,
              minHeight: 10,
            ),

            const SizedBox(height: 18),

            Wrap(
              spacing: 20,
              runSpacing: 12,
              children: [
                buildSmallStat(
                  'Total',
                  logbooks['total'] ?? 0,
                ),
                buildSmallStat(
                  'Active',
                  logbooks['active'] ?? 0,
                ),
                buildSmallStat(
                  'Completed',
                  logbooks[
                          'completed'] ??
                      0,
                ),
                buildSmallStat(
                  'Submitted',
                  logbooks[
                          'submitted'] ??
                      0,
                ),
                buildSmallStat(
                  'Archived',
                  logbooks[
                          'archived'] ??
                      0,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildClinicalEntrySection(
    Map<String, dynamic> entries,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Clinical Activity',
          style: TextStyle(
            fontSize: 20,
            fontWeight:
                FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        Card(
          child: Padding(
            padding:
                const EdgeInsets.all(18),
            child: Wrap(
              spacing: 24,
              runSpacing: 18,
              children: [
                buildSmallStat(
                  'Total',
                  entries['total'] ?? 0,
                ),
                buildSmallStat(
                  'Verified',
                  entries[
                          'verified'] ??
                      0,
                ),
                buildSmallStat(
                  'Pending',
                  entries[
                          'pending_verification'] ??
                      0,
                ),
                buildSmallStat(
                  'Rejected',
                  entries[
                          'rejected'] ??
                      0,
                ),
                buildSmallStat(
                  'Draft',
                  entries['draft'] ?? 0,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget buildYearLevelSection(
    List<dynamic> yearLevels,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Card(
          margin: EdgeInsets.zero,
          child: InkWell(
            borderRadius:
                BorderRadius.circular(
              12,
            ),
            onTap: openYearLevels,
            child: const Padding(
              padding:
                  EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons
                        .school_outlined,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Year Level Progress',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    'View All',
                    style: TextStyle(
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right,
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        if (yearLevels.isEmpty)
          const Card(
            child: Padding(
              padding:
                  EdgeInsets.all(18),
              child: Text(
                'No year-level data '
                'available.',
              ),
            ),
          )
        else
          ...yearLevels.map((item) {
            final data =
                mapOf(item);

            final average =
                toDouble(
              data[
                  'average_completion_percentage'],
            );

            final progress =
                (average / 100)
                    .clamp(
              0.0,
              1.0,
            );

            return Card(
              margin:
                  const EdgeInsets.only(
                bottom: 12,
              ),
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            data['year_name']
                                    ?.toString() ??
                                'Year Level',
                            style:
                                const TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                          ),
                        ),
                        Text(
                          '${average.toStringAsFixed(2)}%',
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    Wrap(
                      spacing: 24,
                      runSpacing: 10,
                      children: [
                        buildSmallStat(
                          'Students',
                          data[
                                  'student_count'] ??
                              0,
                        ),
                        buildSmallStat(
                          'Units',
                          data[
                                  'unit_count'] ??
                              0,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget buildSmallStat(
    String label,
    dynamic value,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      mainAxisSize:
          MainAxisSize.min,
      children: [
        Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight:
                FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color:
                Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget buildReadOnlyNotice() {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons
                  .visibility_outlined,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  const Text(
                    'Read-Only Department '
                    'Access',
                    style: TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  Text(
                    'HODs can monitor '
                    'department progress and '
                    'statistics but cannot '
                    'approve verifications, '
                    'enroll students, assign '
                    'units, or modify clinical '
                    'records.',
                    style: TextStyle(
                      color: Colors
                          .grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}