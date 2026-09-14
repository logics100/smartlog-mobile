import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'lecturer_unit_students_screen.dart';

class LecturerUnitsScreen extends StatefulWidget {
  const LecturerUnitsScreen({super.key});

  @override
  State<LecturerUnitsScreen> createState() =>
      _LecturerUnitsScreenState();
}

class _LecturerUnitsScreenState
    extends State<LecturerUnitsScreen> {
  bool isLoading = true;
  String? errorMessage;
  List<dynamic> units = [];

  @override
  void initState() {
    super.initState();
    loadUnits();
  }

  Future<void> loadUnits() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result =
          await ApiService.getLecturerUnits();

      if (!mounted) return;

      setState(() {
        units = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Units'),
      ),
      body: RefreshIndicator(
        onRefresh: loadUnits,
        child: buildBody(),
      ),
    );
  }

  Widget buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (errorMessage != null) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 80),
          const Icon(
            Icons.error_outline,
            size: 60,
          ),
          const SizedBox(height: 16),
          const Text(
            'Unable to load your units.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            errorMessage!,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: loadUnits,
            child: const Text('Try Again'),
          ),
        ],
      );
    }

    if (units.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          SizedBox(height: 100),
          Icon(
            Icons.class_outlined,
            size: 70,
          ),
          SizedBox(height: 16),
          Text(
            'No Assigned Units',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'You are not currently assigned to any clinical units.',
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: units.length,
      itemBuilder: (context, index) {
        final unit = Map<String, dynamic>.from(
          units[index] as Map,
        );

        final unitCode =
            unit['unit_code']?.toString() ??
                unit['code']?.toString() ??
                '-';

        final unitName =
            unit['unit_name']?.toString() ??
                unit['name']?.toString() ??
                'Unnamed Unit';

        final yearLevel =
    unit['year_name']?.toString();

        final semester =
    unit['semester_name']?.toString();

        final department =
            unit['department_name']?.toString() ??
                unit['department']?.toString();

        return Card(
          margin: const EdgeInsets.only(
            bottom: 12,
          ),
          child: ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.class_),
            ),
            title: Text(
              '$unitCode - $unitName',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                if (department != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    'Department: $department',
                  ),
                ],
                if (yearLevel != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    'Year Level: $yearLevel',
                  ),
                  if (semester != null) ...[
  const SizedBox(height: 3),
  Text(
    'Semester: $semester',
  ),
],
                ],
              ],
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 18,
            ),

            // We will connect this to the
            // enrolled-students screen next.
            onTap: () {
  final rawUnitId =
      unit['unit_id'] ?? unit['id'];

  final unitId =
      int.tryParse(rawUnitId.toString());

  if (unitId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Unit ID is missing.',
        ),
      ),
    );
    return;
  }

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) =>
          LecturerUnitStudentsScreen(
        unitId: unitId,
        unitCode: unitCode,
        unitName: unitName,
      ),
    ),
  );
},
          ),
        );
      },
    );
  }
}
