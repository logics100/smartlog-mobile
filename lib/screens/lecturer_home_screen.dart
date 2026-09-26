import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'lecturer_units_screen.dart';
import 'lecturer_verifications_screen.dart';
import 'login_screen.dart';

class LecturerHomeScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const LecturerHomeScreen({super.key, required this.user});

  @override
  State<LecturerHomeScreen> createState() => _LecturerHomeScreenState();
}

class _LecturerHomeScreenState extends State<LecturerHomeScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  int _myUnits = 0;
  int _enrolledStudents = 0;
  int _pendingVerifications = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final data = await ApiService.getLecturerDashboard();
      final summary = Map<String, dynamic>.from(
        data['summary'] ?? <String, dynamic>{},
      );

      if (!mounted) return;

      setState(() {
        _myUnits = _toInt(summary['my_units']);
        _enrolledStudents = _toInt(summary['enrolled_students']);
        _pendingVerifications = _toInt(summary['pending_verifications']);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  Future<void> _logout() async {
    try {
      await ApiService.logout();
    } catch (_) {
      // Continue to login screen even if logout request fails.
    }

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _openUnits() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LecturerUnitsScreen()),
    );

    if (mounted) {
      await _loadDashboard();
    }
  }

  Future<void> _openVerifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LecturerVerificationsScreen()),
    );

    if (mounted) {
      await _loadDashboard();
    }
  }

  Widget _summaryCard({
    required IconData icon,
    required String title,
    required int value,
  }) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
          child: Column(
            children: [
              Icon(icon, size: 28),
              const SizedBox(height: 8),
              Text(
                value.toString(),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lecturerName = widget.user['name']?.toString() ?? 'Lecturer';

    final dwuId = widget.user['dwu_id']?.toString() ?? '-';

    final role = widget.user['role']?.toString() ?? 'LECTURER';

    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartLog Lecturer'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadDashboard,
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboard,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Welcome, $lecturerName',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text('DWU ID: $dwuId'),
              const SizedBox(height: 4),
              Text('Role: $role'),
              const SizedBox(height: 30),
              const Text(
                'Lecturer Dashboard',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_errorMessage != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(Icons.cloud_off, size: 32),
                        const SizedBox(height: 8),
                        const Text(
                          'Unable to load dashboard summary.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(_errorMessage!, textAlign: TextAlign.center),
                        const SizedBox(height: 10),
                        TextButton.icon(
                          onPressed: _loadDashboard,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _summaryCard(
                      icon: Icons.class_,
                      title: 'My Units',
                      value: _myUnits,
                    ),
                    _summaryCard(
                      icon: Icons.people,
                      title: 'Students',
                      value: _enrolledStudents,
                    ),
                    _summaryCard(
                      icon: Icons.fact_check,
                      title: 'Pending',
                      value: _pendingVerifications,
                    ),
                  ],
                ),

              const SizedBox(height: 20),

              // ============================================================
              // MY UNITS
              // ============================================================
              Card(
                child: ListTile(
                  leading: const Icon(Icons.class_),
                  title: const Text('My Units'),
                  subtitle: Text(
                    _isLoading
                        ? 'View assigned clinical units'
                        : '$_myUnits assigned clinical unit${_myUnits == 1 ? '' : 's'}',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                  onTap: _openUnits,
                ),
              ),

              const SizedBox(height: 12),

              // ============================================================
              // PENDING VERIFICATIONS
              // ============================================================
              Card(
                child: ListTile(
                  leading: const Icon(Icons.fact_check),
                  title: const Text('Pending Verifications'),
                  subtitle: Text(
                    _isLoading
                        ? 'Review supervisor verification evidence'
                        : '$_pendingVerifications waiting for lecturer review',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                  onTap: _openVerifications,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Student progress is available through My Units → Students.',
                style: TextStyle(fontSize: 13),
              ),

              const SizedBox(height: 8),

              const Text(
                'SmartLog Lecturer Portal',
                style: TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
