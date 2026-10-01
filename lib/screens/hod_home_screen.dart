import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'login_screen.dart';
import 'hod_students_screen.dart';
import 'hod_units_screen.dart';
import 'hod_year_levels_screen.dart';
import 'hod_lecturers_screen.dart';

class HodHomeScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const HodHomeScreen({super.key, required this.user});

  @override
  State<HodHomeScreen> createState() => _HodHomeScreenState();
}

class _HodHomeScreenState extends State<HodHomeScreen> {
  static const Color navy = Color(0xFF062B63);
  static const Color deepBlue = Color(0xFF06499C);
  static const Color blue = Color(0xFF087BEA);
  static const Color cyan = Color(0xFF13B9EF);
  static const Color background = Color(0xFFF5F9FD);
  static const Color paleBlue = Color(0xFFEDF7FF);
  static const Color border = Color(0xFFDBE7F2);
  static const Color text = Color(0xFF17324D);
  static const Color muted = Color(0xFF667D91);
  static const Color success = Color(0xFF16875D);
  static const Color warning = Color(0xFFE99A16);
  static const Color danger = Color(0xFFD94A4A);

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
      final result = await ApiService.getHodDashboard();

      if (!mounted) return;

      setState(() {
        dashboard = result;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'Unable to load HOD dashboard.';
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
      MaterialPageRoute(builder: (_) => const HodStudentsScreen()),
    );

    if (mounted) await loadDashboard();
  }

  Future<void> openLecturers() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HodLecturersScreen()),
    );

    if (mounted) await loadDashboard();
  }

  Future<void> openUnits() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HodUnitsScreen()),
    );

    if (mounted) await loadDashboard();
  }

  Future<void> openYearLevels() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HodYearLevelsScreen()),
    );

    if (mounted) await loadDashboard();
  }

  Future<void> logout() async {
    try {
      await ApiService.logout();
    } catch (_) {}

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Map<String, dynamic> mapOf(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return {};
  }

  List<dynamic> listOf(dynamic value) {
    if (value is List) return value;
    return [];
  }

  double toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: navy,
        titleSpacing: 16,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SmartLog',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                letterSpacing: .2,
              ),
            ),
            Text(
              'HOD Portal',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: Color(0xFFD6E9FF),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: loading ? null : loadDashboard,
            icon: const Icon(Icons.refresh_rounded),
          ),
          PopupMenuButton<String>(
            tooltip: 'Menu',
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) {
              if (value == 'logout') logout();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded),
                    SizedBox(width: 12),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: blue))
          : errorMessage != null
          ? buildErrorState()
          : buildDashboard(),
    );
  }

  Widget buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: cardDecoration(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 28,
                backgroundColor: Color(0xFFFFECEC),
                child: Icon(Icons.cloud_off_rounded, color: danger, size: 30),
              ),
              const SizedBox(height: 16),
              const Text(
                'Dashboard unavailable',
                style: TextStyle(
                  color: text,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: muted),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: blue),
                onPressed: loadDashboard,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildDashboard() {
    final hod = mapOf(dashboard?['hod']);
    final department = mapOf(dashboard?['department']);
    final summary = mapOf(dashboard?['summary']);
    final logbooks = mapOf(dashboard?['logbooks']);
    final clinicalEntries = mapOf(dashboard?['clinical_entries']);
    final yearLevels = listOf(dashboard?['year_levels']);

    return RefreshIndicator(
      color: blue,
      onRefresh: loadDashboard,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
        children: [
          buildHeader(hod: hod, department: department),
          const SizedBox(height: 14),
          buildReadOnlyBanner(),
          const SizedBox(height: 26),

          sectionHeader(
            'Quick Access',
            'Monitor your department from one place.',
          ),
          const SizedBox(height: 14),
          buildQuickAccessGrid(),

          const SizedBox(height: 28),
          sectionHeader(
            'Department Overview',
            'Current department totals and activity.',
          ),
          const SizedBox(height: 14),
          buildSummaryGrid(summary),

          const SizedBox(height: 20),
          buildProgressCard(logbooks),

          const SizedBox(height: 28),
          sectionHeader(
            'Clinical Activity',
            'Clinical entry verification status.',
          ),
          const SizedBox(height: 14),
          buildClinicalEntrySection(clinicalEntries),

          const SizedBox(height: 28),
          buildYearLevelSection(yearLevels),

          const SizedBox(height: 24),
          buildReadOnlyNotice(),
        ],
      ),
    );
  }

  Widget buildHeader({
    required Map<String, dynamic> hod,
    required Map<String, dynamic> department,
  }) {
    final hodName = hod['name']?.toString() ?? 'HOD';
    final dwuId = hod['dwu_id']?.toString() ?? '';
    final departmentCode = department['department_code']?.toString() ?? '';
    final departmentName =
        department['department_name']?.toString() ?? 'Department';

    final departmentLabel = departmentCode.isEmpty
        ? departmentName
        : '$departmentCode - $departmentName';

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [navy, deepBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18062B63),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .18),
                  ),
                ),
                child: const Icon(
                  Icons.account_balance_rounded,
                  color: Colors.white,
                  size: 29,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'WELCOME BACK',
                      style: TextStyle(
                        color: Color(0xFFBDE8FF),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hodName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (dwuId.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        'DWU ID: $dwuId',
                        style: const TextStyle(
                          color: Color(0xFFD9EBFF),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              children: [
                const Icon(Icons.apartment_rounded, size: 18, color: cyan),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    departmentLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildReadOnlyBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: paleBlue,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFCDE9FA)),
      ),
      child: const Row(
        children: [
          Icon(Icons.visibility_outlined, color: deepBlue, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Department Monitoring',
              style: TextStyle(
                color: text,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _ReadOnlyBadge(),
        ],
      ),
    );
  }

  Widget sectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: navy,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: muted, fontSize: 12.5)),
      ],
    );
  }

  Widget buildQuickAccessGrid() {
    final items = [
      {
        'title': 'Students',
        'subtitle': 'Student progress',
        'icon': Icons.school_outlined,
        'color': blue,
        'onTap': openStudents,
      },
      {
        'title': 'Teaching Staff',
        'subtitle': 'Lecturer progress',
        'icon': Icons.people_outline_rounded,
        'color': deepBlue,
        'onTap': openLecturers,
      },
      {
        'title': 'Units',
        'subtitle': 'Unit progress',
        'icon': Icons.menu_book_outlined,
        'color': cyan,
        'onTap': openUnits,
      },
      {
        'title': 'Year Levels',
        'subtitle': 'Year progress',
        'icon': Icons.bar_chart_rounded,
        'color': warning,
        'onTap': openYearLevels,
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 760 ? 4 : 2;
        const spacing = 12.0;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: items.map((item) {
            return SizedBox(
              width: width,
              child: buildQuickAccessCard(
                title: item['title'].toString(),
                subtitle: item['subtitle'].toString(),
                icon: item['icon'] as IconData,
                accent: item['color'] as Color,
                onTap: item['onTap'] as VoidCallback,
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
    required Color accent,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        borderRadius: BorderRadius.circular(17),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 145),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accent, size: 23),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: text,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: muted, fontSize: 11.5),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: muted,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildSummaryGrid(Map<String, dynamic> summary) {
    final items = [
      {
        'title': 'Students',
        'value': summary['total_students'] ?? 0,
        'icon': Icons.school_rounded,
        'accent': blue,
        'onTap': openStudents,
      },
      {
        'title': 'Lecturers',
        'value': summary['total_lecturers'] ?? 0,
        'icon': Icons.co_present_rounded,
        'accent': deepBlue,
        'onTap': openLecturers,
      },
      {
        'title': 'Units',
        'value': summary['total_units'] ?? 0,
        'icon': Icons.menu_book_rounded,
        'accent': cyan,
        'onTap': openUnits,
      },
      {
        'title': 'Enrollments',
        'value': summary['total_enrollments'] ?? 0,
        'icon': Icons.assignment_ind_outlined,
        'accent': warning,
        'onTap': null,
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 12.0;
        final columns = constraints.maxWidth >= 700 ? 4 : 2;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: items.map((item) {
            return SizedBox(
              width: width,
              child: buildStatisticCard(
                title: item['title'].toString(),
                value: item['value'].toString(),
                icon: item['icon'] as IconData,
                accent: item['accent'] as Color,
                onTap: item['onTap'] as VoidCallback?,
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
    required Color accent,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              Container(
                width: 39,
                height: 39,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: accent, size: 21),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        color: navy,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      title,
                      style: const TextStyle(color: muted, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildProgressCard(Map<String, dynamic> logbooks) {
    final average = toDouble(logbooks['average_completion_percentage']);
    final progress = (average / 100).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              _IconBox(icon: Icons.fact_check_outlined, color: blue),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Logbook Progress',
                  style: TextStyle(
                    color: navy,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Expanded(
                child: Text(
                  'Average Department Completion',
                  style: TextStyle(color: muted, fontSize: 12.5),
                ),
              ),
              Text(
                '${average.toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: navy,
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              backgroundColor: paleBlue,
              valueColor: const AlwaysStoppedAnimation<Color>(cyan),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              statusStat('Total', logbooks['total'] ?? 0, deepBlue),
              statusStat('Active', logbooks['active'] ?? 0, blue),
              statusStat('Completed', logbooks['completed'] ?? 0, success),
              statusStat('Submitted', logbooks['submitted'] ?? 0, warning),
              statusStat('Archived', logbooks['archived'] ?? 0, muted),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildClinicalEntrySection(Map<String, dynamic> entries) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: cardDecoration(),
      child: Wrap(
        spacing: 9,
        runSpacing: 9,
        children: [
          statusStat('Total', entries['total'] ?? 0, deepBlue),
          statusStat('Verified', entries['verified'] ?? 0, success),
          statusStat('Pending', entries['pending_verification'] ?? 0, warning),
          statusStat('Rejected', entries['rejected'] ?? 0, danger),
          statusStat('Draft', entries['draft'] ?? 0, muted),
        ],
      ),
    );
  }

  Widget statusStat(String label, dynamic value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: .16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value.toString(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: text,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildYearLevelSection(List<dynamic> yearLevels) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Year Level Progress',
                    style: TextStyle(
                      color: navy,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Average completion by year level.',
                    style: TextStyle(color: muted, fontSize: 12.5),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: openYearLevels,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('View All'),
                  SizedBox(width: 3),
                  Icon(Icons.arrow_forward_rounded, size: 17),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (yearLevels.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: cardDecoration(),
            child: const Column(
              children: [
                Icon(Icons.bar_chart_rounded, color: muted, size: 30),
                SizedBox(height: 9),
                Text(
                  'No year-level data available.',
                  style: TextStyle(color: muted),
                ),
              ],
            ),
          )
        else
          ...yearLevels.map((item) {
            final data = mapOf(item);
            final average = toDouble(data['average_completion_percentage']);
            final progress = (average / 100).clamp(0.0, 1.0);

            return Container(
              margin: const EdgeInsets.only(bottom: 11),
              padding: const EdgeInsets.all(16),
              decoration: cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: paleBlue,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Icon(
                          Icons.school_outlined,
                          color: deepBlue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Text(
                          data['year_name']?.toString() ?? 'Year Level',
                          style: const TextStyle(
                            color: text,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        '${average.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          color: navy,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 7,
                      backgroundColor: paleBlue,
                      valueColor: const AlwaysStoppedAnimation<Color>(cyan),
                    ),
                  ),
                  const SizedBox(height: 13),
                  Row(
                    children: [
                      infoLine(
                        Icons.people_outline,
                        '${data['student_count'] ?? 0} Students',
                      ),
                      const SizedBox(width: 18),
                      infoLine(
                        Icons.menu_book_outlined,
                        '${data['unit_count'] ?? 0} Units',
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget infoLine(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: muted),
        const SizedBox(width: 5),
        Text(value, style: const TextStyle(color: muted, fontSize: 11.5)),
      ],
    );
  }

  Widget buildReadOnlyNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFAED),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF4E2AE)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline_rounded, color: warning, size: 22),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Read-Only Department Access',
                  style: TextStyle(
                    color: text,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'HODs can monitor department progress and statistics but '
                  'cannot approve verifications, enroll students, assign '
                  'units, or modify clinical records.',
                  style: TextStyle(color: muted, fontSize: 11.5, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: border),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0A062B63),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    );
  }
}

class _ReadOnlyBadge extends StatelessWidget {
  const _ReadOnlyBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBFDFF2)),
      ),
      child: const Text(
        'READ ONLY',
        style: TextStyle(
          color: Color(0xFF06499C),
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: .5,
        ),
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _IconBox({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 39,
      height: 39,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(icon, color: color, size: 21),
    );
  }
}
