import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'lecturer_verification_detail_screen.dart';

class LecturerVerificationsScreen extends StatefulWidget {
  const LecturerVerificationsScreen({
    super.key,
  });

  @override
  State<LecturerVerificationsScreen> createState() =>
      _LecturerVerificationsScreenState();
}

class _LecturerVerificationsScreenState
    extends State<LecturerVerificationsScreen> {
  bool isLoading = true;
  String? errorMessage;

  List<dynamic> verifications = [];

  @override
  void initState() {
    super.initState();
    loadVerifications();
  }

  Future<void> loadVerifications() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result =
          await ApiService.getLecturerPendingVerifications();

      if (!mounted) return;

      setState(() {
        verifications = result;
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

  Future<void> openVerification(
    Map<String, dynamic> verification,
  ) async {
    final rawId =
        verification['verification_id'] ??
        verification['id'];

    if (rawId == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Verification ID is missing.',
          ),
        ),
      );

      return;
    }

    final verificationId =
        int.tryParse(rawId.toString());

    if (verificationId == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Invalid verification ID: $rawId',
          ),
        ),
      );

      return;
    }

    final reviewed =
        await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            LecturerVerificationDetailScreen(
          verificationId: verificationId,
        ),
      ),
    );

    if (reviewed == true) {
      await loadVerifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pending Verifications',
        ),
      ),
      body: RefreshIndicator(
        onRefresh: loadVerifications,
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
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 80),

          const Icon(
            Icons.error_outline,
            size: 60,
          ),

          const SizedBox(height: 16),

          const Text(
            'Unable to load pending verifications.',
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

          ElevatedButton.icon(
            onPressed: loadVerifications,
            icon: const Icon(
              Icons.refresh,
            ),
            label: const Text(
              'Try Again',
            ),
          ),
        ],
      );
    }

    if (verifications.isEmpty) {
      return ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: const [
          SizedBox(height: 100),

          Icon(
            Icons.verified_outlined,
            size: 70,
          ),

          SizedBox(height: 16),

          Text(
            'No Pending Verifications',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(height: 8),

          Text(
            'There are currently no student clinical '
            'verifications waiting for lecturer review.',
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return ListView.builder(
      physics:
          const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      itemCount: verifications.length,
      itemBuilder: (
        context,
        index,
      ) {
        final verification =
            Map<String, dynamic>.from(
          verifications[index] as Map,
        );

        final studentName =
            verification['student_name']
                    ?.toString() ??
                'Unknown Student';

        final studentId =
            verification['student_dwu_id']
                    ?.toString() ??
                '-';

        final unitCode =
            verification['unit_code']
                    ?.toString() ??
                '-';

        final unitName =
            verification['unit_name']
                    ?.toString() ??
                '-';

        final activity =
            verification['procedure_name']
                    ?.toString() ??
                'No activity details';

        final facility =
            verification['facility_name']
                    ?.toString() ??
                '-';

        final faceDecision =
            verification[
                        'face_comparison_decision']
                    ?.toString() ??
                'NOT_AVAILABLE';

        final lbph =
            verification[
                    'face_lbph_distance']
                ?.toString();

        final verificationId =
            verification['verification_id'] ??
            verification['id'];

        return Card(
          margin: const EdgeInsets.only(
            bottom: 14,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      child: Icon(
                        Icons.person,
                      ),
                    ),

                    const SizedBox(
                      width: 12,
                    ),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Text(
                            studentName,
                            style:
                                const TextStyle(
                              fontSize: 17,
                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                          ),

                          const SizedBox(
                            height: 4,
                          ),

                          Text(
                            'DWU ID: $studentId',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      width: 8,
                    ),

                    buildPendingBadge(),
                  ],
                ),

                const Divider(
                  height: 28,
                ),

                Text(
                  '$unitCode - $unitName',
                  style: const TextStyle(
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                Text(
                  'Activity: $activity',
                ),

                const SizedBox(
                  height: 5,
                ),

                Text(
                  'Facility: $facility',
                ),

                const SizedBox(
                  height: 5,
                ),

                Text(
                  'Verification ID: '
                  '${verificationId ?? '-'}',
                ),

                const SizedBox(
                  height: 16,
                ),

                const Text(
                  'Face Comparison',
                  style: TextStyle(
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),

                const SizedBox(
                  height: 7,
                ),

                buildFaceComparisonBadge(
                  faceDecision,
                ),

                if (lbph != null) ...[
                  const SizedBox(
                    height: 8,
                  ),

                  Text(
                    'LBPH distance: $lbph',
                    style: TextStyle(
                      color:
                          Colors.grey.shade700,
                      fontSize: 13,
                    ),
                  ),
                ],

                const SizedBox(
                  height: 8,
                ),

                Text(
                  'Supporting evidence only',
                  style: TextStyle(
                    color:
                        Colors.grey.shade700,
                    fontSize: 12,
                    fontStyle:
                        FontStyle.italic,
                  ),
                ),

                const SizedBox(
                  height: 16,
                ),

                SizedBox(
                  width: double.infinity,
                  child:
                      ElevatedButton.icon(
                    onPressed: () {
                      openVerification(
                        verification,
                      );
                    },
                    icon: const Icon(
                      Icons.fact_check,
                    ),
                    label: const Text(
                      'Review Verification',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildPendingBadge() {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.rate_review_outlined,
            size: 15,
            color: Colors.orange.shade900,
          ),
          const SizedBox(
            width: 4,
          ),
          Text(
            'PENDING',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color:
                  Colors.orange.shade900,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildFaceComparisonBadge(
    String decision,
  ) {
    final normalized =
        decision.toUpperCase().trim();

    Color backgroundColor;
    Color foregroundColor;
    IconData icon;
    String label;

    switch (normalized) {
      case 'LIKELY_MATCH':
        backgroundColor =
            Colors.blue.shade100;
        foregroundColor =
            Colors.blue.shade900;
        icon = Icons.face_outlined;
        label = 'LIKELY MATCH';
        break;

      case 'LIKELY_DIFFERENT':
        backgroundColor =
            Colors.red.shade50;
        foregroundColor =
            Colors.red.shade800;
        icon =
            Icons.person_off_outlined;
        label = 'LIKELY DIFFERENT';
        break;

      case 'INCONCLUSIVE':
        backgroundColor =
            Colors.amber.shade100;
        foregroundColor =
            Colors.amber.shade900;
        icon = Icons.help_outline;
        label = 'INCONCLUSIVE';
        break;

      default:
        backgroundColor =
            Colors.grey.shade200;
        foregroundColor =
            Colors.grey.shade800;
        icon = Icons.info_outline;
        label = 'NOT AVAILABLE';
        break;
    }

    return Align(
      alignment:
          Alignment.centerLeft,
      child: Container(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius:
              BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: foregroundColor,
            ),
            const SizedBox(
              width: 5,
            ),
            Text(
              label,
              style: TextStyle(
                color: foregroundColor,
                fontSize: 12,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}