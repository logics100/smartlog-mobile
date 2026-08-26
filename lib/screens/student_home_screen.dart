import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'student_logbooks_screen.dart';

class StudentHomeScreen extends StatelessWidget {
  final Map<String, dynamic> user;

  const StudentHomeScreen({
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
        title: const Text('SmartLog'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: () => logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
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

              Text(
                'DWU ID: ${user['dwu_id']}',
              ),

              const SizedBox(height: 4),

              Text(
                'Role: ${user['role']}',
              ),

              const SizedBox(height: 30),

              const Text(
                'Student Dashboard',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.menu_book,
                  ),
                  title: const Text(
                    'My Logbooks',
                  ),
                  subtitle: const Text(
                    'View your assigned clinical logbooks',
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 18,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const StudentLogbooksScreen(),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 8),

              const Card(
                child: ListTile(
                  leading: Icon(
                    Icons.access_time,
                  ),
                  title: Text(
                    'Attendance',
                  ),
                  subtitle: Text(
                    'Record clinical placement attendance',
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 18,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              const Card(
                child: ListTile(
                  leading: Icon(
                    Icons.sync,
                  ),
                  title: Text(
                    'Sync',
                  ),
                  subtitle: Text(
                    'Offline records will sync when connected',
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}