import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'lecturer_units_screen.dart';
import 'lecturer_verifications_screen.dart';
import 'login_screen.dart';

class LecturerHomeScreen extends StatelessWidget {
  final Map<String, dynamic> user;

  const LecturerHomeScreen({
    super.key,
    required this.user,
  });

  Future<void> logout(BuildContext context) async {
    try {
      await ApiService.logout();
    } catch (_) {
      // Continue to login screen even if logout request fails.
    }

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lecturerName =
        user['name']?.toString() ?? 'Lecturer';

    final dwuId =
        user['dwu_id']?.toString() ?? '-';

    final role =
        user['role']?.toString() ?? 'LECTURER';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SmartLog Lecturer',
        ),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(
              Icons.logout,
            ),
            onPressed: () {
              logout(context);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, $lecturerName',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'DWU ID: $dwuId',
              ),

              const SizedBox(height: 4),

              Text(
                'Role: $role',
              ),

              const SizedBox(height: 30),

              const Text(
                'Lecturer Dashboard',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              // ============================================================
              // MY UNITS
              // ============================================================
              Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.class_,
                  ),
                  title: const Text(
                    'My Units',
                  ),
                  subtitle: const Text(
                    'View assigned clinical units',
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
                            const LecturerUnitsScreen(),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // ============================================================
              // PENDING VERIFICATIONS
              // ============================================================
              Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.fact_check,
                  ),
                  title: const Text(
                    'Pending Verifications',
                  ),
                  subtitle: const Text(
                    'Review supervisor verification evidence',
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
                            const LecturerVerificationsScreen(),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'SmartLog Lecturer Portal',
                style: TextStyle(
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}