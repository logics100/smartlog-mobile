import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/local_database_service.dart';
import 'supervisor_verification_screen.dart';

class ClinicalEntriesScreen extends StatefulWidget {
  final int logbookId;

  const ClinicalEntriesScreen({
    super.key,
    required this.logbookId,
  });

  @override
  State<ClinicalEntriesScreen> createState() =>
      _ClinicalEntriesScreenState();
}

class _ClinicalEntriesScreenState
    extends State<ClinicalEntriesScreen> {
  late Future<List<dynamic>> entriesFuture;

  bool usingOfflineData = false;

  @override
  void initState() {
    super.initState();

    entriesFuture = loadEntries();
  }

  // ===========================================================================
  // LOAD CLINICAL ENTRIES
  // ===========================================================================

  Future<List<dynamic>> loadEntries() async {
    try {
      // -----------------------------------------------------------------------
      // TRY LARAVEL FIRST
      // -----------------------------------------------------------------------

      final serverEntries =
          await ApiService.getClinicalEntries(
        widget.logbookId,
      );

      // Save the latest complete Laravel records into the dedicated
      // SQLite server cache. These cached records are for offline viewing
      // only and are never added to the PENDING_SYNC queue.
      await LocalDatabaseService.cacheClinicalEntries(
        logbookId: widget.logbookId,
        entries: serverEntries,
      );

      // Also include any local entries that are still waiting to sync.
      final localEntries =
          await buildLocalEntries(
        pendingOnly: true,
      );

      if (mounted) {
        setState(() {
          usingOfflineData = false;
        });
      }

      return [
        ...localEntries,
        ...serverEntries,
      ];
    } catch (_) {
      // -----------------------------------------------------------------------
      // SERVER FAILED - LOAD SQLITE
      // -----------------------------------------------------------------------

      // Previously downloaded Laravel records.
      final cachedServerEntries =
          await LocalDatabaseService
              .getCachedClinicalEntries(
        widget.logbookId,
      );

      // Local records include entries created offline. Some may already be
      // SYNCED, so we merge by server ID to avoid displaying duplicates.
      final localEntries =
          await buildLocalEntries(
        pendingOnly: false,
      );

      final mergedEntries =
          mergeCachedAndLocalEntries(
        cachedServerEntries:
            cachedServerEntries,
        localEntries: localEntries,
      );

      if (mounted) {
        setState(() {
          usingOfflineData = true;
        });
      }

      return mergedEntries;
    }
  }

  // ===========================================================================
  // MERGE CACHED SERVER + LOCAL SQLITE ENTRIES
  // ===========================================================================

  List<dynamic> mergeCachedAndLocalEntries({
    required List<dynamic> cachedServerEntries,
    required List<dynamic> localEntries,
  }) {
    final cachedServerIds = <int>{};

    for (final rawEntry in cachedServerEntries) {
      if (rawEntry is! Map) {
        continue;
      }

      final entry =
          Map<String, dynamic>.from(
        rawEntry,
      );

      final serverId = int.tryParse(
        entry['id']?.toString() ?? '',
      );

      if (serverId != null) {
        cachedServerIds.add(serverId);
      }
    }

    final uniqueLocalEntries = <dynamic>[];

    for (final rawEntry in localEntries) {
      if (rawEntry is! Map) {
        continue;
      }

      final entry =
          Map<String, dynamic>.from(
        rawEntry,
      );

      final serverId = int.tryParse(
        entry['id']?.toString() ?? '',
      );

      // If this local record has already synchronized and the same server
      // record exists in the full cache, prefer the cached Laravel copy.
      // The cached copy contains the richer server fields such as lecturer
      // review information and verification history.
      if (serverId != null &&
          cachedServerIds.contains(serverId)) {
        continue;
      }

      uniqueLocalEntries.add(entry);
    }

    return [
      ...uniqueLocalEntries,
      ...cachedServerEntries,
    ];
  }

  Future<void> refreshEntries() async {
    setState(() {
      entriesFuture = loadEntries();
    });

    await entriesFuture;
  }

  // ===========================================================================
  // BUILD LOCAL SQLITE ENTRIES
  // ===========================================================================

  Future<List<dynamic>> buildLocalEntries({
    required bool pendingOnly,
  }) async {
    final allLocalEntries =
        await LocalDatabaseService
            .getAllOfflineClinicalEntries();

    final logbookEntries =
    allLocalEntries.where(
  (record) {
    final localLogbookId =
        int.tryParse(
      record['logbook_id']
              ?.toString() ??
          '',
    );

    if (localLogbookId !=
        widget.logbookId) {
      return false;
    }

    if (pendingOnly) {
      return record['sync_status']
              ?.toString() ==
          'PENDING_SYNC';
    }

    return true;
  },
).map(
  (record) =>
      Map<String, dynamic>.from(
    record,
  ),
).toList();

    final cachedDetails =
        await LocalDatabaseService
            .getCachedLogbookDetails(
      widget.logbookId,
    );

    for (final record in logbookEntries) {
      final itemId = int.tryParse(
        record['logbook_item_id']
                ?.toString() ??
            '',
      );

      final requirementId =
          record['requirement_id'] == null
              ? null
              : int.tryParse(
                  record['requirement_id']
                      .toString(),
                );

      final itemInformation =
          findCachedItemInformation(
        cachedDetails,
        itemId,
        requirementId,
      );

      record['item_name'] =
          itemInformation['item_name'] ??
              'Clinical Entry';

      record['requirement_code'] =
          itemInformation[
              'requirement_code'];

      record['requirement_label'] =
          itemInformation[
              'requirement_label'];
    }

    return logbookEntries.map(
      (record) {
        final syncStatus =
            record['sync_status']
                    ?.toString() ??
                'PENDING_SYNC';

        final serverId =
            int.tryParse(
          record['server_id']
                  ?.toString() ??
              '',
        );

        return {
          'id': serverId,
          'local_id': record['id'],
          'logbook_item_id':
              record['logbook_item_id'],
          'requirement_id':
              record['requirement_id'],
          'item_name':
              record['item_name'],
          'activity_date':
              record['activity_date'],
          'activity_time':
              record['activity_time'],
          'facility_name':
              record['facility_name'],
          'clinical_area':
              record['clinical_area'],
          'activity_details':
              record['activity_details'],
          'requirement_code':
              record['requirement_code'],
          'requirement_label':
              record['requirement_label'],
          'status': syncStatus,
          'sync_status': syncStatus,
          'verification_status': null,
          'is_local': true,
        };
      },
    ).toList();
  }

  // ===========================================================================
  // FIND ITEM / REQUIREMENT FROM CACHED LOGBOOK
  // ===========================================================================

  Map<String, dynamic>
      findCachedItemInformation(
    Map<String, dynamic>? details,
    int? itemId,
    int? requirementId,
  ) {
    if (details == null ||
        itemId == null) {
      return {};
    }

    final sections =
        details['sections'];

    if (sections is! List) {
      return {};
    }

    for (final rawSection in sections) {
      if (rawSection is! Map) {
        continue;
      }

      final section =
          Map<String, dynamic>.from(
        rawSection,
      );

      final items =
          section['items'];

      if (items is! List) {
        continue;
      }

      for (final rawItem in items) {
        if (rawItem is! Map) {
          continue;
        }

        final item =
            Map<String, dynamic>.from(
          rawItem,
        );

        final currentItemId =
            int.tryParse(
          item['id']?.toString() ??
              '',
        );

        if (currentItemId != itemId) {
          continue;
        }

        final result =
            <String, dynamic>{
          'item_name':
              item['item_name']
                  ?.toString(),
        };

        if (requirementId == null) {
          return result;
        }

        final requirements =
            item['requirements'];

        if (requirements is! List) {
          return result;
        }

        for (final rawRequirement
            in requirements) {
          if (rawRequirement is! Map) {
            continue;
          }

          final requirement =
              Map<String, dynamic>.from(
            rawRequirement,
          );

          final currentRequirementId =
              int.tryParse(
            requirement['id']
                    ?.toString() ??
                '',
          );

          if (currentRequirementId ==
              requirementId) {
            result['requirement_code'] =
                requirement[
                        'requirement_code']
                    ?.toString();

            result['requirement_label'] =
                requirement[
                        'requirement_label']
                    ?.toString();

            return result;
          }
        }

        return result;
      }
    }

    return {};
  }

  // ===========================================================================
  // STATUS HELPERS
  // ===========================================================================

  IconData statusIcon(
    String status,
  ) {
    switch (status) {
      case 'VERIFIED':
        return Icons.verified;

      case 'REJECTED':
        return Icons.cancel;

      case 'PENDING_VERIFICATION':
        return Icons.pending_actions;

      case 'PENDING_SYNC':
        return Icons.cloud_upload;

      case 'SYNCED':
        return Icons.cloud_done;

      default:
        return Icons.description;
    }
  }

  Color statusColor(
    String status,
  ) {
    switch (status) {
      case 'VERIFIED':
        return Colors.green;

      case 'REJECTED':
        return Colors.red;

      case 'PENDING_VERIFICATION':
        return Colors.orange;

      case 'PENDING_SYNC':
        return Colors.blueGrey;

      case 'SYNCED':
        return Colors.blue;

      default:
        return Colors.grey;
    }
  }

  String readableStatus(
    String status,
  ) {
    switch (status) {
      case 'VERIFIED':
        return 'Verified';

      case 'REJECTED':
        return 'Rejected';

      case 'PENDING_VERIFICATION':
        return 'Pending Verification';

      case 'PENDING_SYNC':
        return 'Pending Sync';

      case 'SYNCED':
        return 'Synced';

      case 'DRAFT':
        return 'Draft';

      default:
        return status.replaceAll(
          '_',
          ' ',
        );
    }
  }

  String readableVerificationStatus(
    String? status,
  ) {
    switch (status) {
      case 'MANUAL_REVIEW':
        return 'Waiting for Lecturer Review';

      case 'APPROVED':
        return 'Approved';

      case 'REJECTED':
        return 'Rejected';

      case null:
        return 'Not Submitted';

      default:
        return status.replaceAll(
          '_',
          ' ',
        );
    }
  }

  Color verificationColor(
    String? status,
  ) {
    switch (status) {
      case 'APPROVED':
        return Colors.green;

      case 'REJECTED':
        return Colors.red;

      case 'MANUAL_REVIEW':
        return Colors.orange;

      default:
        return Colors.grey;
    }
  }

  IconData verificationIcon(
    String? status,
  ) {
    switch (status) {
      case 'APPROVED':
        return Icons.check_circle;

      case 'REJECTED':
        return Icons.cancel;

      case 'MANUAL_REVIEW':
        return Icons.hourglass_top;

      default:
        return Icons.info_outline;
    }
  }

  String readableFaceDecision(
    String? decision,
  ) {
    switch (decision) {
      case 'LIKELY_MATCH':
        return 'Likely Match';

      case 'LIKELY_DIFFERENT':
        return 'Likely Different';

      case 'INCONCLUSIVE':
        return 'Inconclusive';

      case null:
        return 'Not Available';

      default:
        return decision.replaceAll(
          '_',
          ' ',
        );
    }
  }

  Color faceDecisionColor(
    String? decision,
  ) {
    switch (decision) {
      case 'LIKELY_MATCH':
        return Colors.blue;

      case 'LIKELY_DIFFERENT':
        return Colors.red;

      case 'INCONCLUSIVE':
        return Colors.orange;

      default:
        return Colors.grey;
    }
  }

  // ===========================================================================
  // DATE / TIME
  // ===========================================================================

  String formatDateTime(
    dynamic value,
  ) {
    if (value == null) {
      return '';
    }

    final text =
        value.toString();

    if (text.isEmpty) {
      return '';
    }

    final parsed =
        DateTime.tryParse(
      text,
    );

    if (parsed == null) {
      return text;
    }

    final year =
        parsed.year.toString();

    final month =
        parsed.month
            .toString()
            .padLeft(
              2,
              '0',
            );

    final day =
        parsed.day
            .toString()
            .padLeft(
              2,
              '0',
            );

    final hour =
        parsed.hour
            .toString()
            .padLeft(
              2,
              '0',
            );

    final minute =
        parsed.minute
            .toString()
            .padLeft(
              2,
              '0',
            );

    return '$year-$month-$day '
        '$hour:$minute';
  }

  // ===========================================================================
  // STATUS BADGE
  // ===========================================================================

  Widget buildStatusBadge({
    required String text,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration:
          BoxDecoration(
        color: color.withValues(
          alpha: 0.10,
        ),
        borderRadius:
            BorderRadius.circular(
          20,
        ),
        border:
            Border.all(
          color: color.withValues(
            alpha: 0.35,
          ),
        ),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),

          const SizedBox(
            width: 6,
          ),

          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontWeight:
                    FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // INFORMATION ROW
  // ===========================================================================

  Widget buildInformationRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 8,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 17,
            color:
                Colors.grey.shade600,
          ),

          const SizedBox(
            width: 8,
          ),

          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color:
                      Colors.grey.shade800,
                  fontWeight:
                      FontWeight.normal,
                ),
                children: [
                  TextSpan(
                    text:
                        '$label: ',
                    style: TextStyle(
                      fontSize: 13,
                      color:
                          Colors.grey.shade700,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),

                  TextSpan(
                    text: value,
                    style: TextStyle(
                      fontSize: 13,
                      color:
                          Colors.grey.shade900,
                      fontWeight:
                          FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // LECTURER REVIEW
  // ===========================================================================

  Widget buildLecturerReview(
    Map<String, dynamic> entry,
  ) {
    final verificationStatus =
        entry['verification_status']
            ?.toString();

    final reviewerName =
        entry['reviewer_name']
            ?.toString();

    final reviewerDwuId =
        entry['reviewer_dwu_id']
            ?.toString();

    final reviewComment =
        entry['review_comment']
            ?.toString();

    final reviewedAt =
        entry['reviewed_at'];

    if (verificationStatus == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin:
          const EdgeInsets.only(
        top: 14,
      ),
      padding:
          const EdgeInsets.all(
        14,
      ),
      decoration:
          BoxDecoration(
        color: Colors.grey
            .withValues(
          alpha: 0.06,
        ),
        borderRadius:
            BorderRadius.circular(
          12,
        ),
        border:
            Border.all(
          color: Colors.grey
              .withValues(
            alpha: 0.20,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.rate_review,
                size: 20,
              ),

              SizedBox(
                width: 8,
              ),

              Text(
                'Lecturer Review',
                style: TextStyle(
                  fontWeight:
                      FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 12,
          ),

          buildStatusBadge(
            text:
                readableVerificationStatus(
              verificationStatus,
            ),
            color:
                verificationColor(
              verificationStatus,
            ),
            icon:
                verificationIcon(
              verificationStatus,
            ),
          ),

          if (verificationStatus ==
              'MANUAL_REVIEW') ...[
            const SizedBox(
              height: 10,
            ),

            const Text(
              'This supervisor verification '
              'has been submitted and is '
              'waiting for a lecturer to '
              'review it.',
              style: TextStyle(
                fontSize: 13,
                color:
                    Colors.black87,
              ),
            ),
          ],

          if (reviewerName != null &&
              reviewerName.isNotEmpty) ...[
            const SizedBox(
              height: 12,
            ),

            buildInformationRow(
              icon: Icons.person,
              label:
                  'Reviewed By',
              value:
                  reviewerDwuId != null &&
                          reviewerDwuId
                              .isNotEmpty
                      ? '$reviewerName '
                          '($reviewerDwuId)'
                      : reviewerName,
            ),
          ],

          if (reviewedAt != null)
            buildInformationRow(
              icon:
                  Icons.schedule,
              label:
                  'Reviewed At',
              value:
                  formatDateTime(
                reviewedAt,
              ),
            ),

          if (reviewComment != null &&
              reviewComment
                  .trim()
                  .isNotEmpty) ...[
            const SizedBox(
              height: 4,
            ),

            const Text(
              'Lecturer Comment',
              style: TextStyle(
                fontWeight:
                    FontWeight.w600,
                fontSize: 13,
                color:
                    Colors.black87,
              ),
            ),

            const SizedBox(
              height: 6,
            ),

            Container(
              width:
                  double.infinity,
              padding:
                  const EdgeInsets.all(
                12,
              ),
              decoration:
                  BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(
                  8,
                ),
                border:
                    Border.all(
                  color: Colors.grey
                      .withValues(
                    alpha: 0.25,
                  ),
                ),
              ),
              child: Text(
                reviewComment,
                style:
                    const TextStyle(
                  fontSize: 13,
                  color:
                      Colors.black87,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // FACE EVIDENCE
  // ===========================================================================

  Widget buildFaceEvidence(
    Map<String, dynamic> verification,
  ) {
    final decision =
        verification[
                'face_comparison_decision']
            ?.toString();

    final distance =
        verification[
            'face_lbph_distance'];

    if (decision == null &&
        distance == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin:
          const EdgeInsets.only(
        top: 10,
      ),
      padding:
          const EdgeInsets.all(
        12,
      ),
      decoration:
          BoxDecoration(
        color: Colors.blueGrey
            .withValues(
          alpha: 0.06,
        ),
        borderRadius:
            BorderRadius.circular(
          10,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Face Comparison Evidence',
            style: TextStyle(
              fontWeight:
                  FontWeight.bold,
              fontSize: 13,
              color:
                  Colors.black87,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          buildStatusBadge(
            text:
                readableFaceDecision(
              decision,
            ),
            color:
                faceDecisionColor(
              decision,
            ),
            icon: Icons.face,
          ),

          if (distance != null) ...[
            const SizedBox(
              height: 8,
            ),

            Text(
              'LBPH Distance: '
              '$distance',
              style:
                  const TextStyle(
                fontSize: 13,
                color:
                    Colors.black87,
              ),
            ),
          ],

          const SizedBox(
            height: 8,
          ),

          const Text(
            'Supporting evidence only. '
            'Final verification is decided '
            'by the lecturer.',
            style: TextStyle(
              fontSize: 12,
              color:
                  Colors.black54,
              fontStyle:
                  FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // VERIFICATION ATTEMPT
  // ===========================================================================

  Widget buildVerificationAttempt(
    Map<String, dynamic> verification,
    int index,
  ) {
    final status =
        verification[
                'verification_status']
            ?.toString();

    final supervisorName =
        verification[
                'supervisor_name']
            ?.toString();

    final facilityName =
        verification[
                'facility_name']
            ?.toString();

    final timestamp =
        verification[
            'verification_timestamp'];

    final reviewerName =
        verification[
                'reviewer_name']
            ?.toString();

    final reviewComment =
        verification[
                'review_comment']
            ?.toString();

    final reviewedAt =
        verification[
            'reviewed_at'];

    return Container(
      width: double.infinity,
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      padding:
          const EdgeInsets.all(
        14,
      ),
      decoration:
          BoxDecoration(
        borderRadius:
            BorderRadius.circular(
          12,
        ),
        border:
            Border.all(
          color: Colors.grey
              .withValues(
            alpha: 0.25,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            'Verification Attempt '
            '${index + 1}',
            style:
                const TextStyle(
              fontWeight:
                  FontWeight.bold,
              fontSize: 14,
              color:
                  Colors.black87,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          Align(
            alignment:
                Alignment.centerLeft,
            child:
                buildStatusBadge(
              text:
                  readableVerificationStatus(
                status,
              ),
              color:
                  verificationColor(
                status,
              ),
              icon:
                  verificationIcon(
                status,
              ),
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          if (supervisorName !=
                  null &&
              supervisorName
                  .isNotEmpty)
            buildInformationRow(
              icon:
                  Icons.verified_user,
              label: 'Supervisor',
              value:
                  supervisorName,
            ),

          if (facilityName != null &&
              facilityName.isNotEmpty)
            buildInformationRow(
              icon:
                  Icons.local_hospital,
              label: 'Facility',
              value:
                  facilityName,
            ),

          if (timestamp != null)
            buildInformationRow(
              icon:
                  Icons.schedule,
              label:
                  'Verification Time',
              value:
                  formatDateTime(
                timestamp,
              ),
            ),

          buildFaceEvidence(
            verification,
          ),

          if (reviewerName != null &&
              reviewerName
                  .isNotEmpty) ...[
            const SizedBox(
              height: 10,
            ),

            buildInformationRow(
              icon:
                  Icons.school,
              label:
                  'Reviewed By',
              value:
                  reviewerName,
            ),
          ],

          if (reviewedAt != null)
            buildInformationRow(
              icon:
                  Icons.event_available,
              label:
                  'Reviewed At',
              value:
                  formatDateTime(
                reviewedAt,
              ),
            ),

          if (reviewComment != null &&
              reviewComment
                  .trim()
                  .isNotEmpty) ...[
            const SizedBox(
              height: 4,
            ),

            const Text(
              'Lecturer Comment',
              style: TextStyle(
                fontWeight:
                    FontWeight.w600,
                fontSize: 13,
                color:
                    Colors.black87,
              ),
            ),

            const SizedBox(
              height: 6,
            ),

            Text(
              reviewComment,
              style:
                  const TextStyle(
                fontSize: 13,
                color:
                    Colors.black87,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // VERIFICATION HISTORY
  // ===========================================================================

  Widget buildVerificationHistory(
    Map<String, dynamic> entry,
  ) {
    final rawHistory =
        entry[
            'verification_history'];

    if (rawHistory is! List ||
        rawHistory.isEmpty) {
      return const SizedBox.shrink();
    }

    final history =
        rawHistory
            .map(
              (item) =>
                  Map<String, dynamic>.from(
                item as Map,
              ),
            )
            .toList();

    return Container(
      margin:
          const EdgeInsets.only(
        top: 12,
      ),
      decoration:
          BoxDecoration(
        borderRadius:
            BorderRadius.circular(
          12,
        ),
        border:
            Border.all(
          color: Colors.grey
              .withValues(
            alpha: 0.20,
          ),
        ),
      ),
      child: ExpansionTile(
        leading:
            const Icon(
          Icons.history,
        ),
        title: Text(
          'Verification History '
          '(${history.length})',
          style:
              const TextStyle(
            fontWeight:
                FontWeight.w600,
            fontSize: 14,
            color:
                Colors.black87,
          ),
        ),
        subtitle:
            const Text(
          'Tap to view all attempts',
          style: TextStyle(
            fontSize: 12,
            color:
                Colors.black54,
          ),
        ),
        childrenPadding:
            const EdgeInsets.fromLTRB(
          12,
          0,
          12,
          12,
        ),
        children: [
          for (
            int i = 0;
            i < history.length;
            i++
          )
            buildVerificationAttempt(
              history[i],
              i,
            ),
        ],
      ),
    );
  }

  // ===========================================================================
  // BUILD ENTRY CARD
  // ===========================================================================

  Widget buildEntryCard(
    Map<String, dynamic> entry,
  ) {
    final status =
        entry['status']
                ?.toString() ??
            '';

    final isLocal =
        entry['is_local'] == true;

    final isPendingSync =
        status == 'PENDING_SYNC';

    final verificationStatus =
        entry['verification_status']
            ?.toString();

    final supervisorName =
        entry['supervisor_name']
            ?.toString();

    final itemName =
        entry['item_name']
                ?.toString() ??
            'Clinical Activity';

    final activityDate =
        entry['activity_date']
                ?.toString() ??
            '';

    final facilityName =
        entry['facility_name']
                ?.toString() ??
            '';

    final clinicalArea =
        entry['clinical_area']
            ?.toString();

    final competencyLevel =
        entry['competency_level']
            ?.toString();

    final activityDetails =
        entry['activity_details']
            ?.toString();

    final requirementCode =
        entry['requirement_code']
            ?.toString();

    final requirementLabel =
        entry['requirement_label']
            ?.toString();

    final hasSubmittedVerification =
        verificationStatus != null;

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 16,
      ),
      clipBehavior:
          Clip.antiAlias,
      child: Padding(
        padding:
            const EdgeInsets.all(
          16,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Icon(
                  statusIcon(
                    status,
                  ),
                  color:
                      statusColor(
                    status,
                  ),
                  size: 25,
                ),

                const SizedBox(
                  width: 10,
                ),

                Expanded(
                  child: Text(
                    itemName,
                    style:
                        const TextStyle(
                      fontSize: 17,
                      fontWeight:
                          FontWeight.bold,
                      color:
                          Colors.black87,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 12,
            ),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                buildStatusBadge(
                  text:
                      readableStatus(
                    status,
                  ),
                  color:
                      statusColor(
                    status,
                  ),
                  icon:
                      statusIcon(
                    status,
                  ),
                ),

                if (verificationStatus !=
                    null)
                  buildStatusBadge(
                    text:
                        readableVerificationStatus(
                      verificationStatus,
                    ),
                    color:
                        verificationColor(
                      verificationStatus,
                    ),
                    icon:
                        verificationIcon(
                      verificationStatus,
                    ),
                  ),
              ],
            ),

            const SizedBox(
              height: 16,
            ),

            buildInformationRow(
              icon:
                  Icons.calendar_today,
              label: 'Date',
              value:
                  activityDate,
            ),

            buildInformationRow(
              icon:
                  Icons.local_hospital,
              label: 'Facility',
              value:
                  facilityName,
            ),

            if (clinicalArea != null &&
                clinicalArea.isNotEmpty)
              buildInformationRow(
                icon:
                    Icons.location_on,
                label:
                    'Clinical Area',
                value:
                    clinicalArea,
              ),

            if (competencyLevel !=
                    null &&
                competencyLevel
                    .isNotEmpty)
              buildInformationRow(
                icon:
                    Icons.stars,
                label:
                    'Competency Level',
                value:
                    competencyLevel,
              ),

            if (requirementCode != null &&
                requirementCode
                    .isNotEmpty)
              buildInformationRow(
                icon:
                    Icons.checklist,
                label:
                    'Requirement',
                value:
                    requirementLabel !=
                                null &&
                            requirementLabel
                                .isNotEmpty
                        ? '$requirementCode - '
                            '$requirementLabel'
                        : requirementCode,
              ),

            if (supervisorName != null &&
                supervisorName
                    .isNotEmpty)
              buildInformationRow(
                icon:
                    Icons.verified_user,
                label:
                    'Supervisor',
                value:
                    supervisorName,
              ),

            if (activityDetails != null &&
                activityDetails
                    .trim()
                    .isNotEmpty) ...[
              const SizedBox(
                height: 6,
              ),

              const Text(
                'Activity Details',
                style: TextStyle(
                  fontWeight:
                      FontWeight.w600,
                  fontSize: 13,
                  color:
                      Colors.black87,
                ),
              ),

              const SizedBox(
                height: 6,
              ),

              Container(
                width:
                    double.infinity,
                padding:
                    const EdgeInsets.all(
                  12,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      Colors.grey
                          .withValues(
                    alpha: 0.06,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                ),
                child: Text(
                  activityDetails,
                  style:
                      const TextStyle(
                    fontSize: 13,
                    color:
                        Colors.black87,
                  ),
                ),
              ),
            ],

            // ===============================================================
            // LOCAL OFFLINE RECORD MESSAGE
            // ===============================================================

            if (isPendingSync) ...[
              const SizedBox(
                height: 14,
              ),

              Container(
                width:
                    double.infinity,
                padding:
                    const EdgeInsets.all(
                  12,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      Colors.blueGrey
                          .withValues(
                    alpha: 0.08,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                  border:
                      Border.all(
                    color:
                        Colors.blueGrey
                            .withValues(
                      alpha: 0.30,
                    ),
                  ),
                ),
                child:
                    const Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.cloud_upload,
                      color:
                          Colors.blueGrey,
                    ),

                    SizedBox(
                      width: 10,
                    ),

                    Expanded(
                      child: Text(
                        'This clinical entry is stored locally '
                        'and is waiting to sync with the '
                        'SmartLog server.',
                        style: TextStyle(
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ===============================================================
            // LECTURER REVIEW
            // ===============================================================

            buildLecturerReview(
              entry,
            ),

            // ===============================================================
            // VERIFICATION HISTORY
            // ===============================================================

            buildVerificationHistory(
              entry,
            ),

            // ===============================================================
            // SUPERVISOR VERIFICATION BUTTON
            // ONLY FOR REAL SERVER RECORDS
            // ===============================================================

            if (!isLocal &&
                status ==
                    'PENDING_VERIFICATION' &&
                !hasSubmittedVerification) ...[
              const SizedBox(
                height: 16,
              ),

              SizedBox(
                width:
                    double.infinity,
                child:
                    ElevatedButton.icon(
                  onPressed: () async {
                    final entryId =
                        int.tryParse(
                      entry['id']
                              ?.toString() ??
                          '',
                    );

                    if (entryId == null) {
                      ScaffoldMessenger
                              .of(context)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Clinical entry ID is missing.',
                          ),
                        ),
                      );

                      return;
                    }

                    final result =
                        await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            SupervisorVerificationScreen(
                          entryId:
                              entryId,
                          procedureName:
                              itemName,
                          facilityName:
                              facilityName,
                        ),
                      ),
                    );

                    if (result == true) {
                      await refreshEntries();
                    }
                  },
                  icon:
                      const Icon(
                    Icons.verified_user,
                  ),
                  label:
                      const Text(
                    'Supervisor Verification',
                  ),
                ),
              ),
            ],

            // ===============================================================
            // WAITING FOR LECTURER REVIEW
            // ===============================================================

            if (status ==
                    'PENDING_VERIFICATION' &&
                verificationStatus ==
                    'MANUAL_REVIEW') ...[
              const SizedBox(
                height: 16,
              ),

              Container(
                width:
                    double.infinity,
                padding:
                    const EdgeInsets.all(
                  12,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      Colors.orange
                          .withValues(
                    alpha: 0.08,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                  border:
                      Border.all(
                    color:
                        Colors.orange
                            .withValues(
                      alpha: 0.30,
                    ),
                  ),
                ),
                child:
                    const Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.hourglass_top,
                      color:
                          Colors.orange,
                    ),

                    SizedBox(
                      width: 10,
                    ),

                    Expanded(
                      child: Text(
                        'Supervisor verification submitted. '
                        'Waiting for lecturer review.',
                        style: TextStyle(
                          fontSize: 13,
                          color:
                              Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // SCREEN BUILD
  // ===========================================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Clinical Entries',
        ),
      ),

      body:
          FutureBuilder<List<dynamic>>(
        future:
            entriesFuture,
        builder:
            (context, snapshot) {
          if (snapshot
                  .connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return RefreshIndicator(
              onRefresh:
                  refreshEntries,
              child: ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.all(
                  24,
                ),
                children: [
                  const SizedBox(
                    height: 140,
                  ),

                  const Icon(
                    Icons.error_outline,
                    size: 50,
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  const Text(
                    'Unable to load clinical entries.',
                    textAlign:
                        TextAlign.center,
                    style: TextStyle(
                      fontWeight:
                          FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  Text(
                    snapshot.error
                        .toString(),
                    textAlign:
                        TextAlign.center,
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  Center(
                    child:
                        ElevatedButton.icon(
                      onPressed:
                          refreshEntries,
                      icon:
                          const Icon(
                        Icons.refresh,
                      ),
                      label:
                          const Text(
                        'Try Again',
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final entries =
              snapshot.data ?? [];

          return RefreshIndicator(
            onRefresh:
                refreshEntries,
            child: ListView(
              physics:
                  const AlwaysScrollableScrollPhysics(),
              padding:
                  const EdgeInsets.all(
                16,
              ),
              children: [
                // ===========================================================
                // OFFLINE NOTICE
                // ===========================================================

                if (usingOfflineData)
                  Container(
                    margin:
                        const EdgeInsets.only(
                      bottom: 14,
                    ),
                    padding:
                        const EdgeInsets.all(
                      12,
                    ),
                    decoration:
                        BoxDecoration(
                      color:
                          Colors.orange
                              .withValues(
                        alpha: 0.10,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        10,
                      ),
                      border:
                          Border.all(
                        color:
                            Colors.orange
                                .withValues(
                          alpha: 0.35,
                        ),
                      ),
                    ),
                    child:
                        const Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.offline_bolt,
                          color:
                              Colors.orange,
                        ),

                        SizedBox(
                          width: 10,
                        ),

                        Expanded(
                          child: Text(
                            'Offline mode: showing clinical '
                            'entries stored on this device.',
                          ),
                        ),
                      ],
                    ),
                  ),

                // ===========================================================
                // EMPTY STATE
                // ===========================================================

                if (entries.isEmpty)
                  const Padding(
                    padding:
                        EdgeInsets.only(
                      top: 150,
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 50,
                        ),

                        SizedBox(
                          height: 12,
                        ),

                        Text(
                          'No clinical entries recorded yet.',
                          textAlign:
                              TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                // ===========================================================
                // ENTRY LIST
                // ===========================================================

                ...entries.map(
                  (rawEntry) {
                    final entry =
                        Map<String, dynamic>.from(
                      rawEntry as Map,
                    );

                    return buildEntryCard(
                      entry,
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}