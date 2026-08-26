import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class LecturerHomeScreen extends StatelessWidget {
  final Map<String, dynamic> user;

  const LecturerHomeScreen({
    super.key,
    required this.user,
  });

  Future<void> logout(BuildContext context) async {
    await ApiService.logout();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartLog Lecturer'),
        actions: [
          IconButton(
            onPressed: () => logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, ${user['name']}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text('DWU ID: ${user['dwu_id']}'),

            const SizedBox(height: 30),

            const Card(
              child: ListTile(
                leading: Icon(Icons.class_),
                title: Text('My Units'),
                subtitle: Text(
                  'View assigned clinical units',
                ),
              ),
            ),

            const Card(
              child: ListTile(
                leading: Icon(Icons.people),
                title: Text('Students'),
                subtitle: Text(
                  'View and enrol students',
                ),
              ),
            ),

            const Card(
              child: ListTile(
                leading: Icon(Icons.analytics),
                title: Text('Progress'),
                subtitle: Text(
                  'Monitor student logbook progress',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}