import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/admin_ui.dart';

class AdminEnrollmentsScreen extends StatefulWidget {
  const AdminEnrollmentsScreen({super.key});
  @override
  State<AdminEnrollmentsScreen> createState() => _AdminEnrollmentsScreenState();
}

class _AdminEnrollmentsScreenState extends State<AdminEnrollmentsScreen> {
  final searchController = TextEditingController();
  bool loading = true;
  String? error;
  int? unitId;
  int page = 1;
  int lastPage = 1;
  int total = 0;
  List<Map<String, dynamic>> units = [];
  List<Map<String, dynamic>> records = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> load({bool loadUnits = true}) async {
    setState(() { loading = true; error = null; });
    try {
      if (loadUnits) {
        final unitsResponse = await ApiService.getAdminUnits();
        units = (unitsResponse['units'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      final result = await ApiService.getAdminEnrollments(
        search: searchController.text, unitId: unitId, page: page,
      );
      final pagination = Map<String, dynamic>.from(result['enrollments'] as Map);
      if (!mounted) return;
      setState(() {
        records = (pagination['data'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map)).toList();
        total = (pagination['total'] as num?)?.toInt() ?? records.length;
        lastPage = (pagination['last_page'] as num?)?.toInt() ?? 1;
      });
    } catch (e) {
      if (mounted) setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AdminUi.theme(context),
      child: Scaffold(
        appBar: AppBar(title: const Text('Enrollment Monitoring'), actions: [
          IconButton(tooltip: 'Refresh', icon: const Icon(Icons.refresh),
            onPressed: loading ? null : () => load()),
        ]),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          const Text('Read-only. Lecturers manage student enrollments.'),
          const SizedBox(height: 12),
          TextField(controller: searchController,
            decoration: const InputDecoration(labelText: 'Student, DWU ID or unit code',
              border: OutlineInputBorder()),
            onSubmitted: (_) { page = 1; load(loadUnits: false); }),
          const SizedBox(height: 12),
          DropdownButtonFormField<int?>(
            initialValue: unitId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Unit', border: OutlineInputBorder()),
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('All units')),
              ...units.map((u) => DropdownMenuItem<int?>(
                value: (u['id'] as num).toInt(),
                child: Text('${u['unit_code']} - ${u['unit_name']}',
                  overflow: TextOverflow.ellipsis))),
            ],
            onChanged: loading ? null : (v) {
              setState(() { unitId = v; page = 1; });
              load(loadUnits: false);
            },
          ),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: loading ? null : () {
            page = 1; load(loadUnits: false);
          }, child: const Text('Search')),
          const SizedBox(height: 12),
          if (loading) const Center(child: CircularProgressIndicator())
          else if (error != null) ...[
            Text(error!, textAlign: TextAlign.center),
            TextButton(onPressed: () => load(), child: const Text('Retry')),
          ] else ...[
            Text('Enrollment records: $total'),
            const SizedBox(height: 8),
            if (records.isEmpty) const Text('No enrollment records found.'),
            ...records.map((r) {
              final mismatch = r['student_department_id'] != r['unit_department_id'];
              return Card(child: Padding(padding: const EdgeInsets.all(12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(r['student_name']?.toString() ?? 'Student',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('DWU ID: ${r['dwu_id'] ?? '-'}'),
                  Text('Unit: ${r['unit_code'] ?? '-'} - ${r['unit_name'] ?? '-'}'),
                  Text('Status: ${r['status'] ?? '-'}'),
                  Text('Date: ${r['enrollment_date'] ?? '-'}'),
                  Text('Enrolled by: ${r['enrolled_by_name'] ?? 'Not recorded'}'),
                  if (mismatch) const Text('Check: department mismatch',
                    style: TextStyle(color: Colors.red)),
                ])));
            }),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              TextButton(onPressed: page <= 1 ? null : () {
                page--; load(loadUnits: false);
              }, child: const Text('Previous')),
              Text('Page $page of $lastPage'),
              TextButton(onPressed: page >= lastPage ? null : () {
                page++; load(loadUnits: false);
              }, child: const Text('Next')),
            ]),
          ],
        ]),
      ),
    );
  }
}
