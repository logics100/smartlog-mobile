import 'package:flutter/material.dart';

import '../services/api_service.dart';

class LecturerClinicalEntryDetailScreen extends StatefulWidget {
  final int unitId;
  final int studentId;
  final int entryId;

  const LecturerClinicalEntryDetailScreen({
    super.key,
    required this.unitId,
    required this.studentId,
    required this.entryId,
  });

  @override
  State<LecturerClinicalEntryDetailScreen> createState() =>
      _LecturerClinicalEntryDetailScreenState();
}

class _LecturerClinicalEntryDetailScreenState
    extends State<LecturerClinicalEntryDetailScreen> {
  bool isLoading = true;
  String? errorMessage;

  Map<String, dynamic>? data;

  @override
  void initState() {
    super.initState();
    loadEntry();
  }

  Future<void> loadEntry() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await ApiService.getLecturerClinicalEntryDetails(
        unitId: widget.unitId,
        studentId: widget.studentId,
        entryId: widget.entryId,
      );

      if (!mounted) return;

      setState(() {
        data = result;
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

  void openFullScreenImage({required String imageUrl, required String title}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(title: Text(title)),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 5.0,
              panEnabled: true,
              scaleEnabled: true,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) {
                    return child;
                  }

                  return const SizedBox(
                    height: 250,
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image_outlined,
                            color: Colors.white,
                            size: 50,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Unable to load image.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clinical Entry Details')),
      body: RefreshIndicator(onRefresh: loadEntry, child: buildBody()),
    );
  }

  Widget buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 80),
          const Icon(Icons.error_outline, size: 60),
          const SizedBox(height: 16),
          const Text(
            'Unable to load clinical entry.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(errorMessage!, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: loadEntry, child: const Text('Try Again')),
        ],
      );
    }

    final responseData = data ?? {};

    final entry = responseData['entry'] as Map<String, dynamic>? ?? {};

    final verifications = responseData['verifications'] as List<dynamic>? ?? [];

    final notice = responseData['notice']?.toString();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Clinical Activity',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 8),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildDetailRow('Student', entry['student_name']),
                buildDetailRow('DWU ID', entry['student_dwu_id']),
                buildDetailRow(
                  'Unit',
                  '${entry['unit_code'] ?? '-'} - '
                      '${entry['unit_name'] ?? '-'}',
                ),
                buildDetailRow('Activity Date', entry['activity_date']),
                buildDetailRow('Facility', entry['facility_name']),
                buildDetailRow('Activity Details', entry['activity_details']),
                buildDetailRow('Status', entry['status']),
              ],
            ),
          ),
        ),

        const SizedBox(height: 18),

        Text(
          'Supervisor Verifications (${verifications.length})',
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 8),

        if (verifications.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No supervisor verification has been submitted for this entry.',
              ),
            ),
          ),

        ...verifications.map((verificationData) {
          final verification = Map<String, dynamic>.from(
            verificationData as Map,
          );

          final signatureUrl = verification['signature_url']?.toString();

          final faceCaptureUrl = verification['face_capture_url']?.toString();

          final verificationStatus =
              verification['verification_status']?.toString() ?? 'UNKNOWN';

          final faceComparisonDecision =
              verification['face_comparison_decision']?.toString() ??
              'NOT_AVAILABLE';

          final reviewerName = verification['reviewer_name']?.toString();

          final reviewerDwuId = verification['reviewer_dwu_id']?.toString();

          final reviewedAt = verification['reviewed_at']?.toString();

          final reviewComment = verification['review_comment']?.toString();

          final hasReviewInformation =
              (reviewerName != null && reviewerName.trim().isNotEmpty) ||
              (reviewerDwuId != null && reviewerDwuId.trim().isNotEmpty) ||
              (reviewedAt != null && reviewedAt.trim().isNotEmpty) ||
              (reviewComment != null && reviewComment.trim().isNotEmpty);

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          verification['supervisor_name']?.toString() ??
                              'Supervisor',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      buildVerificationStatusBadge(verificationStatus),
                    ],
                  ),

                  const SizedBox(height: 14),

                  buildDetailRow('Profession', verification['profession']),

                  buildDetailRow(
                    'Registration Number',
                    verification['registration_number'],
                  ),

                  buildDetailRow(
                    'Supervisor Facility',
                    verification['supervisor_facility'],
                  ),

                  buildDetailRow(
                    'Verification Method',
                    verification['verification_method'],
                  ),

                  buildDetailRow(
                    'Verification Time',
                    verification['verification_timestamp'],
                  ),

                  const Divider(height: 28),

                  const Text(
                    'Face Comparison',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'Comparison Result',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),

                  const SizedBox(height: 7),

                  buildFaceComparisonBadge(faceComparisonDecision),

                  const SizedBox(height: 12),

                  buildDetailRow(
                    'LBPH Distance',
                    verification['face_lbph_distance'],
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Face comparison is supporting evidence only.',
                    style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
                  ),

                  if (signatureUrl != null && signatureUrl.isNotEmpty) ...[
                    const Divider(height: 30),

                    const Row(
                      children: [
                        Icon(Icons.draw_outlined),
                        SizedBox(width: 8),
                        Text(
                          'Supervisor Signature',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    buildEvidenceImage(
                      imageUrl: signatureUrl,
                      evidenceName: 'Supervisor Signature',
                      height: 180,
                    ),
                  ],

                  if (faceCaptureUrl != null && faceCaptureUrl.isNotEmpty) ...[
                    const Divider(height: 30),

                    const Row(
                      children: [
                        Icon(Icons.face_outlined),
                        SizedBox(width: 8),
                        Text(
                          'Supervisor Face Capture',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    buildEvidenceImage(
                      imageUrl: faceCaptureUrl,
                      evidenceName: 'Supervisor Face Capture',
                      height: 300,
                    ),
                  ],

                  if ((signatureUrl == null || signatureUrl.isEmpty) &&
                      (faceCaptureUrl == null || faceCaptureUrl.isEmpty)) ...[
                    const Divider(height: 30),

                    const Row(
                      children: [
                        Icon(Icons.image_not_supported_outlined),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'No signature or face image is available for this verification.',
                          ),
                        ),
                      ],
                    ),
                  ],

                  if (hasReviewInformation) ...[
                    const Divider(height: 30),

                    const Row(
                      children: [
                        Icon(Icons.rate_review_outlined),
                        SizedBox(width: 8),
                        Text(
                          'Lecturer Review',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    buildDetailRow('Review Status', verificationStatus),

                    buildDetailRow('Reviewed By', reviewerName),

                    buildDetailRow('Reviewer DWU ID', reviewerDwuId),

                    buildDetailRow('Reviewed At', reviewedAt),

                    const SizedBox(height: 4),

                    const Text(
                      'Lecturer Comment',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        reviewComment == null || reviewComment.trim().isEmpty
                            ? 'No lecturer comment was provided.'
                            : reviewComment,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),

        if (notice != null && notice.isNotEmpty) ...[
          const SizedBox(height: 8),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline),
                  const SizedBox(width: 10),
                  Expanded(child: Text(notice)),
                ],
              ),
            ),
          ),
        ],

        const SizedBox(height: 20),
      ],
    );
  }

  Widget buildFaceComparisonBadge(String decision) {
    final normalizedDecision = decision.toUpperCase().trim();

    Color backgroundColor;
    Color foregroundColor;
    IconData icon;
    String label;

    switch (normalizedDecision) {
      case 'LIKELY_MATCH':
        backgroundColor = Colors.blue.shade100;
        foregroundColor = Colors.blue.shade900;
        icon = Icons.face_outlined;
        label = 'LIKELY MATCH';
        break;

      case 'LIKELY_DIFFERENT':
        backgroundColor = Colors.red.shade50;
        foregroundColor = Colors.red.shade800;
        icon = Icons.person_off_outlined;
        label = 'LIKELY DIFFERENT';
        break;

      case 'INCONCLUSIVE':
        backgroundColor = Colors.amber.shade100;
        foregroundColor = Colors.amber.shade900;
        icon = Icons.help_outline;
        label = 'INCONCLUSIVE';
        break;

      case 'NOT_AVAILABLE':
        backgroundColor = Colors.grey.shade200;
        foregroundColor = Colors.grey.shade800;
        icon = Icons.info_outline;
        label = 'NOT AVAILABLE';
        break;

      default:
        backgroundColor = Colors.grey.shade200;
        foregroundColor = Colors.grey.shade800;
        icon = Icons.info_outline;
        label = normalizedDecision.replaceAll('_', ' ');
        break;
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: foregroundColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: foregroundColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildVerificationStatusBadge(String status) {
    final normalizedStatus = status.toUpperCase().trim();

    Color backgroundColor;
    Color foregroundColor;
    IconData icon;
    String label;

    switch (normalizedStatus) {
      case 'APPROVED':
        backgroundColor = Colors.green.shade100;
        foregroundColor = Colors.green.shade800;
        icon = Icons.check_circle;
        label = 'APPROVED';
        break;

      case 'REJECTED':
        backgroundColor = Colors.red.shade100;
        foregroundColor = Colors.red.shade800;
        icon = Icons.cancel;
        label = 'REJECTED';
        break;

      case 'MANUAL_REVIEW':
        backgroundColor = Colors.orange.shade100;
        foregroundColor = Colors.orange.shade900;
        icon = Icons.rate_review_outlined;
        label = 'MANUAL REVIEW';
        break;

      default:
        backgroundColor = Colors.grey.shade200;
        foregroundColor = Colors.grey.shade800;
        icon = Icons.info_outline;
        label = normalizedStatus.replaceAll('_', ' ');
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: foregroundColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: foregroundColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildEvidenceImage({
    required String imageUrl,
    required String evidenceName,
    required double height,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              openFullScreenImage(imageUrl: imageUrl, title: evidenceName);
            },
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(minHeight: height),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.network(
                imageUrl,
                height: height,
                width: double.infinity,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) {
                    return child;
                  }

                  return SizedBox(
                    height: height,
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return SizedBox(
                    height: height,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.broken_image_outlined, size: 42),
                            const SizedBox(height: 8),
                            Text(
                              '$evidenceName could not be loaded.',
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.zoom_in, size: 18),
            SizedBox(width: 5),
            Text(
              'Tap image to enlarge',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildDetailRow(String label, dynamic value) {
    final text = value == null || value.toString().trim().isEmpty
        ? '-'
        : value.toString();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 145,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
