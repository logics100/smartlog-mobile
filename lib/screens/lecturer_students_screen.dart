import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'lecturer_unit_students_screen.dart';

class LecturerStudentsScreen extends StatefulWidget {
  const LecturerStudentsScreen({super.key});
  @override
  State<LecturerStudentsScreen> createState() => _LecturerStudentsScreenState();
}

class _LecturerStudentsScreenState extends State<LecturerStudentsScreen> {
  bool loading = true;
  String? error;
  List<Map<String, dynamic>> units = [];
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final raw = await ApiService.getLecturerUnits();
      if (!mounted) return;
      setState(
        () => units = raw
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
      );
    } catch (e) {
      if (mounted) {
        setState(() => error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Students')),
    body: RefreshIndicator(
      onRefresh: load,
      child: loading
          ? ListView(
              children: const [
                SizedBox(height: 220),
                Center(child: CircularProgressIndicator()),
              ],
            )
          : error != null
          ? ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 80),
                const Icon(Icons.error_outline, size: 54),
                const SizedBox(height: 12),
                Text(error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: load, child: const Text('Try Again')),
              ],
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Students by Unit',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Select a unit to view enrolled students, enroll students, and open individual clinical progress.',
                ),
                const SizedBox(height: 16),
                if (units.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('No assigned units.'),
                    ),
                  )
                else
                  ...units.map((u) {
                    final id = int.tryParse(
                      (u['unit_id'] ?? u['id']).toString(),
                    );
                    final code = (u['unit_code'] ?? '-').toString();
                    final name = (u['unit_name'] ?? 'Unit').toString();
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.groups_outlined),
                        ),
                        title: Text(
                          '$code - $name',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: const Text(
                          'View enrolled students and progress',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: id == null
                            ? null
                            : () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => LecturerUnitStudentsScreen(
                                    unitId: id,
                                    unitCode: code,
                                    unitName: name,
                                  ),
                                ),
                              ),
                      ),
                    );
                  }),
              ],
            ),
    ),
  );
}
