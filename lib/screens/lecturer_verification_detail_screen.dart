import 'package:flutter/material.dart';

import '../services/api_service.dart';

class LecturerVerificationDetailScreen extends StatefulWidget {
  final int verificationId;

  const LecturerVerificationDetailScreen({
    super.key,
    required this.verificationId,
  });

  @override
  State<LecturerVerificationDetailScreen> createState() =>
      _LecturerVerificationDetailScreenState();
}

class _LecturerVerificationDetailScreenState
    extends State<LecturerVerificationDetailScreen> {
  bool isLoading = true;
  bool isSubmitting = false;

  String? errorMessage;

  Map<String, dynamic>? verification;
  Map<String, dynamic>? evidence;
  Map<String, dynamic>? faceComparison;

  final TextEditingController commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadVerification();
  }

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  Future<void> loadVerification() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final data = await ApiService.getLecturerVerificationDetails(
        widget.verificationId,
      );

      if (!mounted) return;

      setState(() {
        verification = data['verification'] as Map<String, dynamic>?;

        evidence = data['evidence'] as Map<String, dynamic>?;

        faceComparison = data['face_comparison'] as Map<String, dynamic>?;

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

  Future<void> reviewVerification(String decision) async {
    final action = decision == 'APPROVED' ? 'Approve' : 'Reject';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('$action Verification'),
          content: Text(
            'Are you sure you want to '
            '${action.toLowerCase()} this verification?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: Text(action),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      final result = await ApiService.reviewLecturerVerification(
        verificationId: widget.verificationId,
        decision: decision,
        comment: commentController.text.trim().isEmpty
            ? null
            : commentController.text.trim(),
      );

      if (!mounted) return;

      final message =
          result['message']?.toString() ??
          'Verification reviewed successfully.';

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isSubmitting = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Unable to submit review: $e')));
    }
  }

  Widget infoRow(String label, dynamic value) {
    final text = value?.toString().trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(text == null || text.isEmpty ? '-' : text)),
        ],
      ),
    );
  }

  Widget section({required String title, required Widget child}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            child,
          ],
        ),
      ),
    );
  }

  Widget evidenceImage(String title, dynamic url) {
    final imageUrl = url?.toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),

        if (imageUrl == null || imageUrl.isEmpty)
          const Text('No evidence available.')
        else
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 150, maxHeight: 300),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        'Unable to load image evidence.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verification Review')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 60),
              const SizedBox(height: 16),
              const Text(
                'Unable to load verification.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: loadVerification,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (verification == null) {
      return const Center(
        child: Text('Verification information is unavailable.'),
      );
    }

    final v = verification!;
    final e = evidence ?? {};
    final f = faceComparison ?? {};

    final verificationType =
        v['verification_type']?.toString() ?? 'CLINICAL_ENTRY';

    final isAttendance = verificationType == 'ATTENDANCE';

    final faceDecision = f['decision']?.toString() ?? 'NOT_AVAILABLE';

    final lbphDistance = f['lbph_distance']?.toString() ?? '-';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          section(
            title: 'Student',
            child: Column(
              children: [
                infoRow('Name', v['student_name']),
                infoRow('DWU ID', v['student_dwu_id']),
                infoRow('Email', v['student_email']),
              ],
            ),
          ),

          section(
            title: isAttendance ? 'Attendance Record' : 'Clinical Activity',
            child: Column(
              children: [
                infoRow(
                  'Unit',
                  '${v['unit_code'] ?? '-'} - '
                      '${v['unit_name'] ?? '-'}',
                ),

                if (isAttendance) ...[
                  infoRow('Activity', 'ATTENDANCE'),
                  infoRow('Date', v['attendance_date']),
                  infoRow('Clinical Unit', v['clinical_unit']),
                  infoRow('Start Time', v['start_time']),
                  infoRow('Finish Time', v['finish_time']),
                  infoRow(
                    'Total Hours',
                    v['total_hours'] == null
                        ? '-'
                        : '${v['total_hours']} hours',
                  ),
                  infoRow('Facility', v['facility_name']),
                ] else ...[
                  infoRow('Activity', v['procedure_name']),
                  infoRow('Date', v['activity_date']),
                  infoRow('Facility', v['facility_name']),
                ],
              ],
            ),
          ),
          section(
            title: 'Clinical Supervisor',
            child: Column(
              children: [
                infoRow('Name', v['supervisor_name']),
                infoRow('Registered', v['registered_supervisor_name']),
                infoRow('Profession', v['supervisor_profession']),
                infoRow('Registration', v['supervisor_registration_number']),
                infoRow('Facility', v['supervisor_facility']),
              ],
            ),
          ),

          section(
            title: 'Verification Information',
            child: Column(
              children: [
                infoRow('Status', v['verification_status']),
                infoRow('Method', v['verification_method']),
                infoRow('Verified At', v['verification_timestamp']),
              ],
            ),
          ),

          section(
            title: 'Face Comparison Evidence',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                infoRow('Result', faceDecision),
                infoRow('LBPH Distance', lbphDistance),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Face comparison is supporting '
                    'evidence only. It does not approve '
                    'or reject this clinical activity. '
                    'The lecturer must make the final '
                    'review decision.',
                  ),
                ),
              ],
            ),
          ),

          section(
            title: 'Evidence',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                evidenceImage('Supervisor Signature', e['signature_url']),
                const SizedBox(height: 24),
                evidenceImage('Supervisor Face Capture', e['face_capture_url']),
              ],
            ),
          ),

          section(
            title: 'Lecturer Comment',
            child: TextField(
              controller: commentController,
              maxLines: 4,
              enabled: !isSubmitting,
              decoration: const InputDecoration(
                hintText: 'Enter an optional review comment...',
                border: OutlineInputBorder(),
              ),
            ),
          ),

          const SizedBox(height: 4),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isSubmitting
                      ? null
                      : () {
                          reviewVerification('REJECTED');
                        },
                  icon: const Icon(Icons.close),
                  label: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isSubmitting
                      ? null
                      : () {
                          reviewVerification('APPROVED');
                        },
                  icon: const Icon(Icons.check),
                  label: const Text('Approve'),
                ),
              ),
            ],
          ),

          if (isSubmitting) ...[
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
          ],

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
