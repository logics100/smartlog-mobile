import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SupervisorVerificationScreen extends StatefulWidget {
  final int entryId;
  final String procedureName;
  final String? facilityName;

  const SupervisorVerificationScreen({
    super.key,
    required this.entryId,
    required this.procedureName,
    this.facilityName,
  });

  @override
  State<SupervisorVerificationScreen> createState() =>
      _SupervisorVerificationScreenState();
}

class _SupervisorVerificationScreenState
    extends State<SupervisorVerificationScreen> {
  final supervisorController = TextEditingController();
  final facilityController = TextEditingController();

  bool submitting = false;

  @override
  void initState() {
    super.initState();

    if (widget.facilityName != null) {
      facilityController.text = widget.facilityName!;
    }
  }

  Future<void> submitVerification() async {
    final supervisorName =
        supervisorController.text.trim();

    if (supervisorName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter the supervisor name.',
          ),
        ),
      );

      return;
    }

    setState(() {
      submitting = true;
    });

    try {
      final result =
          await ApiService.verifyClinicalEntry(
        entryId: widget.entryId,
        supervisorName: supervisorName,
        facilityName:
            facilityController.text.trim().isEmpty
                ? null
                : facilityController.text.trim(),

        // Temporary until actual signature capture
        // is implemented.
        signaturePath:
            'mobile/signatures/pending_signature.png',
      );

      if (!mounted) return;

      final status =
          result['verification_status']?.toString() ??
              'MANUAL_REVIEW';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Verification submitted: $status',
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Verification failed: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          submitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    supervisorController.dispose();
    facilityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Supervisor Verification',
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Clinical Activity',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              widget.procedureName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 24),

            TextField(
              controller: supervisorController,
              decoration: const InputDecoration(
                labelText: 'Supervisor Name',
                prefixIcon: Icon(
                  Icons.person_outline,
                ),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: facilityController,
              decoration: const InputDecoration(
                labelText: 'Facility',
                prefixIcon: Icon(
                  Icons.local_hospital_outlined,
                ),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Supervisor Signature',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Container(
              width: double.infinity,
              height: 160,
              decoration: BoxDecoration(
                border: Border.all(),
                borderRadius:
                    BorderRadius.circular(8),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.draw,
                      size: 40,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Stylus signature capture\nwill be connected next.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Identity Verification',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(),
                borderRadius:
                    BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.face_outlined,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Face verification is not active yet. '
                      'This submission will require manual review.',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed:
                    submitting
                        ? null
                        : submitVerification,
                icon: const Icon(
                  Icons.verified_user_outlined,
                ),
                label: submitting
                    ? const CircularProgressIndicator()
                    : const Text(
                        'Submit Verification',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}