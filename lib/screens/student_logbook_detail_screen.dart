import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/local_database_service.dart';
import 'clinical_entry_screen.dart';
import 'clinical_entries_screen.dart';
import 'student_logbook_progress_screen.dart';

class StudentLogbookDetailScreen
    extends StatefulWidget {
  final int logbookId;

  const StudentLogbookDetailScreen({
    super.key,
    required this.logbookId,
  });

  @override
  State<StudentLogbookDetailScreen> createState() =>
      _StudentLogbookDetailScreenState();
}

class _StudentLogbookDetailScreenState
    extends State<StudentLogbookDetailScreen> {
 late Future<Map<String, dynamic>> detailFuture;

@override
void initState() {
  super.initState();

  detailFuture =
      loadLogbookDetails();
}

Future<Map<String, dynamic>>
    loadLogbookDetails() async {
  try {
    final data =
        await ApiService
            .getStudentLogbookDetails(
      widget.logbookId,
    );

    await LocalDatabaseService
        .cacheLogbookDetails(
      logbookId: widget.logbookId,
      data: data,
    );

    return data;
  } catch (_) {
    final cached =
        await LocalDatabaseService
            .getCachedLogbookDetails(
      widget.logbookId,
    );

    if (cached != null) {
      return cached;
    }

    rethrow;
  }
}

Future<void> refreshDetails() async {
  setState(() {
    detailFuture =
        loadLogbookDetails();
  });

  await detailFuture;
}

  Color getRequirementColor(String status) {
    switch (status) {
      case 'COMPLETED':
        return Colors.green;

      case 'PENDING':
        return Colors.orange;

      case 'REJECTED':
        return Colors.red;

      case 'NOT_COMPLETED':
        return Colors.grey;

      default:
        return Colors.grey;
    }
  }

  IconData getRequirementIcon(String status) {
    switch (status) {
      case 'COMPLETED':
        return Icons.check_circle;

      case 'PENDING':
        return Icons.hourglass_top;

      case 'REJECTED':
        return Icons.cancel;

      case 'NOT_COMPLETED':
        return Icons.radio_button_unchecked;

      default:
        return Icons.radio_button_unchecked;
    }
  }

  String formatRequirementStatus(
    String status,
  ) {
    switch (status) {
      case 'COMPLETED':
        return 'COMPLETED';

      case 'PENDING':
        return 'PENDING';

      case 'REJECTED':
        return 'REJECTED';

      case 'NOT_COMPLETED':
        return 'NOT COMPLETED';

      default:
        return status
            .replaceAll('_', ' ')
            .toUpperCase();
    }
  }

  Color getItemStatusColor(String status) {
    switch (status) {
      case 'COMPLETED':
        return Colors.green;

      case 'IN_PROGRESS':
        return Colors.orange;

      case 'NOT_STARTED':
        return Colors.grey;

      default:
        return Colors.grey;
    }
  }

  String formatItemStatus(String status) {
    return status
        .replaceAll('_', ' ')
        .toUpperCase();
  }

  Widget buildStatusBadge({
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.12,
        ),
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(
            alpha: 0.4,
          ),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> openClinicalEntry({
    required Map<String, dynamic> item,
    int? requirementId,
  }) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClinicalEntryScreen(
          logbookId: widget.logbookId,
          item: item,
          preselectedRequirementId:
              requirementId,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    if (result == true) {
      await refreshDetails();
    }
  }

  Widget buildRequirementRow({
    required Map<String, dynamic>
        requirement,
    required Map<String, dynamic> item,
  }) {
    final requirementId =
        int.parse(
      requirement['id'].toString(),
    );

    final requirementCode =
        requirement['requirement_code']
                ?.toString() ??
            '';

    final requirementLabel =
        requirement['requirement_label']
                ?.toString() ??
            '';

    final requirementStatus =
        requirement['requirement_status']
                ?.toString() ??
            'NOT_COMPLETED';

    final color =
        getRequirementColor(
      requirementStatus,
    );

    final icon =
        getRequirementIcon(
      requirementStatus,
    );

    final statusText =
        formatRequirementStatus(
      requirementStatus,
    );

    final canAddEntry =
        requirementStatus ==
                'NOT_COMPLETED' ||
            requirementStatus ==
                'REJECTED';

    String helperText;

    if (requirementStatus ==
        'NOT_COMPLETED') {
      helperText =
          'Tap to add this requirement';
    } else if (requirementStatus ==
        'REJECTED') {
      helperText =
          'Tap to create a new attempt';
    } else if (requirementStatus ==
        'PENDING') {
      helperText =
          'Waiting for verification';
    } else {
      helperText =
          'Requirement completed';
    }

    return Container(
      margin: const EdgeInsets.only(
        top: 8,
      ),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey.shade300,
        ),
        borderRadius:
            BorderRadius.circular(10),
      ),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(10),
        onTap: canAddEntry
            ? () {
                openClinicalEntry(
                  item: item,
                  requirementId:
                      requirementId,
                );
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 24,
                color: color,
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        if (requirementCode
                            .isNotEmpty)
                          Container(
                            margin:
                                const EdgeInsets.only(
                              right: 8,
                            ),
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration:
                                BoxDecoration(
                              color: Colors
                                  .grey.shade200,
                              borderRadius:
                                  BorderRadius
                                      .circular(6),
                            ),
                            child: Text(
                              requirementCode,
                              style:
                                  const TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),

                        Expanded(
                          child: Text(
                            requirementLabel
                                    .isNotEmpty
                                ? requirementLabel
                                : 'Requirement',
                            softWrap: true,
                            overflow:
                                TextOverflow.visible,
                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    buildStatusBadge(
                      text: statusText,
                      color: color,
                    ),

                    const SizedBox(height: 6),

                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            helperText,
                            softWrap: true,
                            style: TextStyle(
                              fontSize: 12,
                              color: canAddEntry
                                  ? Colors.blue
                                  : Colors
                                      .grey.shade600,
                              fontWeight:
                                  canAddEntry
                                      ? FontWeight.w600
                                      : FontWeight
                                          .normal,
                            ),
                          ),
                        ),

                        if (canAddEntry) ...[
                          const SizedBox(
                            width: 8,
                          ),
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.blue,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Logbook',
        ),
      ),
      body:
          FutureBuilder<Map<String, dynamic>>(
        future: detailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return RefreshIndicator(
              onRefresh: refreshDetails,
              child: ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 140),

                  const Icon(
                    Icons.error_outline,
                    size: 50,
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'Unable to load logbook.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    snapshot.error.toString(),
                    textAlign:
                        TextAlign.center,
                  ),

                  const SizedBox(height: 16),

                  Center(
                    child: ElevatedButton(
                      onPressed:
                          refreshDetails,
                      child: const Text(
                        'Try Again',
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data!;

          final logbook =
              Map<String, dynamic>.from(
            data['logbook'],
          );

          final sections =
              (data['sections']
                      as List<dynamic>?) ??
                  [];

          final completion =
              double.tryParse(
                    logbook[
                                'completion_percentage']
                            ?.toString() ??
                        '0',
                  ) ??
                  0;

          final requiredCompletion =
              double.tryParse(
                    logbook[
                                'minimum_completion_percentage']
                            ?.toString() ??
                        '100',
                  ) ??
                  100;

          final completionStatus =
              logbook['completion_status']
                      ?.toString() ??
                  'NOT_STARTED';

          return RefreshIndicator(
            onRefresh: refreshDetails,
            child: ListView(
              physics:
                  const AlwaysScrollableScrollPhysics(),
              padding:
                  const EdgeInsets.all(16),
              children: [
                Text(
                  logbook['template_name']
                          ?.toString() ??
                      'Clinical Logbook',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  '${logbook['unit_code']} - ${logbook['unit_name']}',
                ),

                const SizedBox(height: 8),

                Text(
                  'Logbook Status: ${logbook['status']}',
                ),

                const SizedBox(height: 16),

                Card(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Overall Progress',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(
                          height: 12,
                        ),

                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .spaceBetween,
                          children: [
                            const Text(
                              'Completed',
                            ),
                            Text(
                              '${completion.toStringAsFixed(2)}%',
                              style:
                                  const TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        LinearProgressIndicator(
                          value:
                              (completion / 100)
                                  .clamp(
                                    0.0,
                                    1.0,
                                  )
                                  .toDouble(),
                          minHeight: 8,
                          borderRadius:
                              BorderRadius.circular(
                            8,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          'Required completion: ${requiredCompletion.toStringAsFixed(0)}%',
                        ),

                        const SizedBox(height: 4),

                        Text(
                          'Progress Status: ${formatItemStatus(completionStatus)}',
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child:
                      ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              StudentLogbookProgressScreen(
                            logbookId:
                                widget.logbookId,
                          ),
                        ),
                      );

                      if (!mounted) {
                        return;
                      }

                      await refreshDetails();
                    },
                    icon:
                        const Icon(
                      Icons.bar_chart,
                    ),
                    label:
                        const Text(
                      'My Logbook Progress',
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  child:
                      ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ClinicalEntriesScreen(
                            logbookId:
                                widget.logbookId,
                          ),
                        ),
                      );

                      if (!mounted) {
                        return;
                      }

                      await refreshDetails();
                    },
                    icon:
                        const Icon(
                      Icons.assignment,
                    ),
                    label:
                        const Text(
                      'My Clinical Entries',
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  'Logbook Requirements',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  'Tap a NOT COMPLETED or REJECTED requirement to create an entry for that exact requirement.',
                ),

                const SizedBox(height: 14),

                ...sections.map(
                  (section) {
                    final sectionMap =
                        Map<String, dynamic>.from(
                      section,
                    );

                    final items =
                        (sectionMap['items']
                                as List<dynamic>?) ??
                            [];

                    return Card(
                      margin:
                          const EdgeInsets.only(
                        bottom: 14,
                      ),
                      child: ExpansionTile(
                        title: Text(
                          sectionMap[
                                      'section_title']
                                  ?.toString() ??
                              'Section',
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        subtitle:
                            sectionMap[
                                        'instructions'] !=
                                    null
                                ? Text(
                                    sectionMap[
                                            'instructions']
                                        .toString(),
                                  )
                                : null,
                        children: [
                          if (items.isEmpty)
                            const Padding(
                              padding:
                                  EdgeInsets.all(
                                16,
                              ),
                              child: Text(
                                'No procedure items in this section.',
                              ),
                            ),

                          ...items.map(
                            (item) {
                              final itemMap =
                                  Map<String,
                                      dynamic>.from(
                                item,
                              );

                              final requirements =
                                  (itemMap[
                                              'requirements']
                                          as List<
                                              dynamic>?) ??
                                      [];

                              final itemStatus =
                                  itemMap[
                                          'item_progress_status']
                                      ?.toString() ??
                                      'NOT_STARTED';

                              final itemColor =
                                  getItemStatusColor(
                                itemStatus,
                              );

                              final completed =
                                  int.tryParse(
                                        itemMap[
                                                    'completed_requirements']
                                                ?.toString() ??
                                            '0',
                                      ) ??
                                      0;

                              final pending =
                                  int.tryParse(
                                        itemMap[
                                                    'pending_requirements']
                                                ?.toString() ??
                                            '0',
                                      ) ??
                                      0;

                              final rejected =
                                  int.tryParse(
                                        itemMap[
                                                    'rejected_requirements']
                                                ?.toString() ??
                                            '0',
                                      ) ??
                                      0;

                              final total =
                                  int.tryParse(
                                        itemMap[
                                                    'total_requirements']
                                                ?.toString() ??
                                            requirements
                                                .length
                                                .toString(),
                                      ) ??
                                      requirements
                                          .length;

                              return Container(
                                decoration:
                                    BoxDecoration(
                                  border: Border(
                                    top: BorderSide(
                                      color: Colors
                                          .grey
                                          .shade200,
                                    ),
                                  ),
                                ),
                                child: ExpansionTile(
                                  tilePadding:
                                      const EdgeInsets
                                          .symmetric(
                                    horizontal: 12,
                                  ),
                                  childrenPadding:
                                      const EdgeInsets
                                          .only(
                                    bottom: 8,
                                  ),
                                  leading:
                                      CircleAvatar(
                                    backgroundColor:
                                        itemColor
                                            .withValues(
                                      alpha: 0.12,
                                    ),
                                    child: Icon(
                                      itemStatus ==
                                              'COMPLETED'
                                          ? Icons.check
                                          : itemStatus ==
                                                  'IN_PROGRESS'
                                              ? Icons
                                                  .pending_outlined
                                              : Icons
                                                  .radio_button_unchecked,
                                      color:
                                          itemColor,
                                    ),
                                  ),
                                  title: Text(
                                    itemMap[
                                                'item_name']
                                            ?.toString() ??
                                        'Procedure',
                                    softWrap: true,
                                    style:
                                        const TextStyle(
                                      fontWeight:
                                          FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Padding(
                                    padding:
                                        const EdgeInsets
                                            .only(
                                      top: 6,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment
                                              .start,
                                      children: [
                                        Align(
                                          alignment:
                                              Alignment
                                                  .centerLeft,
                                          child:
                                              buildStatusBadge(
                                            text:
                                                formatItemStatus(
                                              itemStatus,
                                            ),
                                            color:
                                                itemColor,
                                          ),
                                        ),

                                        const SizedBox(
                                          height: 6,
                                        ),

                                        Text(
                                          '$completed of $total requirements completed',
                                          softWrap: true,
                                        ),

                                        if (pending > 0)
                                          Text(
                                            '$pending pending verification',
                                            softWrap: true,
                                          ),

                                        if (rejected > 0)
                                          Text(
                                            '$rejected rejected',
                                            softWrap: true,
                                          ),
                                      ],
                                    ),
                                  ),
                                  children: [
                                    Padding(
                                      padding:
                                          const EdgeInsets
                                              .fromLTRB(
                                        12,
                                        4,
                                        12,
                                        12,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment
                                                .start,
                                        children: [
                                          if (requirements
                                              .isEmpty)
                                            const Text(
                                              'No requirements available.',
                                            ),

                                          ...requirements.map(
                                            (requirement) {
                                              return buildRequirementRow(
                                                requirement:
                                                    Map<String,
                                                        dynamic>.from(
                                                  requirement,
                                                ),
                                                item:
                                                    itemMap,
                                              );
                                            },
                                          ),

                                          const SizedBox(
                                            height: 12,
                                          ),

                                          SizedBox(
                                            width:
                                                double.infinity,
                                            child:
                                                OutlinedButton.icon(
                                              onPressed:
                                                  () {
                                                openClinicalEntry(
                                                  item:
                                                      itemMap,
                                                );
                                              },
                                              icon:
                                                  const Icon(
                                                Icons.add,
                                              ),
                                              label:
                                                  const Text(
                                                'Add Clinical Entry Manually',
                                                textAlign:
                                                    TextAlign.center,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
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