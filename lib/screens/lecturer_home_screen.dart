import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'lecturer_units_screen.dart';
import 'lecturer_students_screen.dart';
import 'lecturer_verifications_screen.dart';
import 'lecturer_logbooks_screen.dart';
import 'login_screen.dart';

class LecturerHomeScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const LecturerHomeScreen({super.key, required this.user});
  @override
  State<LecturerHomeScreen> createState() => _LecturerHomeScreenState();
}

class _LecturerHomeScreenState extends State<LecturerHomeScreen> {
  bool loading = true;
  String? error;
  int units = 0, students = 0, pending = 0;
  @override
  void initState() {
    super.initState();
    load();
  }

  int n(dynamic v) =>
      v is num ? v.toInt() : int.tryParse(v?.toString() ?? '') ?? 0;
  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final d = await ApiService.getLecturerDashboard();
      final s = Map<String, dynamic>.from(d['summary'] ?? {});
      if (mounted) {
        setState(() {
          units = n(s['my_units']);
          students = n(s['enrolled_students']);
          pending = n(s['pending_verifications']);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> open(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (mounted) await load();
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

  Widget stat(String label, int value, IconData icon) => Expanded(
    child: Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        child: Column(
          children: [
            Icon(icon, size: 26),
            const SizedBox(height: 6),
            Text(
              '$value',
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
      ),
    ),
  );
  Widget action(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback tap,
  ) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      leading: CircleAvatar(child: Icon(icon)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: tap,
    ),
  );
  @override
  Widget build(BuildContext context) {
    final name = (widget.user['name'] ?? 'Lecturer').toString(),
        id = (widget.user['dwu_id'] ?? '-').toString();
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SMARTLOG', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Lecturer Portal', style: TextStyle(fontSize: 11)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: loading ? null : load,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(onPressed: logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'DWU ID: $id',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (error != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(error!),
                ),
              )
            else
              Row(
                children: [
                  stat('My Units', units, Icons.class_outlined),
                  stat('Students', students, Icons.groups_outlined),
                  stat('Pending', pending, Icons.fact_check_outlined),
                ],
              ),
            const SizedBox(height: 20),
            const Text(
              'Quick Access',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            action(
              'My Units',
              'Assigned clinical units and enrollment',
              Icons.class_outlined,
              () => open(const LecturerUnitsScreen()),
            ),
            action(
              'Students',
              'Enrolled students and individual progress',
              Icons.groups_outlined,
              () => open(const LecturerStudentsScreen()),
            ),
            action(
              'Student Progress',
              'Select a unit and student to view clinical progress',
              Icons.analytics_outlined,
              () => open(const LecturerStudentsScreen()),
            ),
            action(
              'Pending Verifications',
              '$pending waiting for lecturer review',
              Icons.fact_check_outlined,
              () => open(const LecturerVerificationsScreen()),
            ),
            action(
              'Clinical Logbooks',
              'Create, structure and assign clinical logbooks',
              Icons.menu_book_outlined,
              () => open(const LecturerLogbooksScreen()),
            ),
            const SizedBox(height: 14),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(Icons.verified_user_outlined),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Supervisor evidence supports verification. Final approval remains with the lecturer.',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Center(
              child: Text(
                'Divine Word University • SmartLog',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
