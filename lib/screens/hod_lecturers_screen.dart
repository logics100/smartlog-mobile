import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'hod_lecturer_progress_screen.dart';

class HodLecturersScreen extends StatefulWidget {
  const HodLecturersScreen({super.key});

  @override
  State<HodLecturersScreen> createState() =>
      _HodLecturersScreenState();
}

class _HodLecturersScreenState
    extends State<HodLecturersScreen> {
  bool loading = true;
  String? errorMessage;

  List<dynamic> lecturers = [];

  final TextEditingController searchController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    loadLecturers();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadLecturers() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final result =
          await ApiService.getHodLecturers(
        search: searchController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        lecturers = result;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage =
            'Unable to load department lecturers.';
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> clearSearch() async {
    searchController.clear();
    await loadLecturers();
  }

  Future<void> openLecturerProgress(
    int lecturerId,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            HodLecturerProgressScreen(
          lecturerId: lecturerId,
        ),
      ),
    );

    if (mounted) {
      await loadLecturers();
    }
  }

  double toDouble(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value.toString(),
        ) ??
        0;
  }

  Map<String, dynamic> mapOf(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return {};
  }

  List<dynamic> listOf(dynamic value) {
    if (value is List) {
      return value;
    }

    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teaching Staff'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: loading
                ? null
                : loadLecturers,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          buildSearchCard(),
          Expanded(
            child: loading
                ? const Center(
                    child:
                        CircularProgressIndicator(),
                  )
                : errorMessage != null
                    ? buildErrorState()
                    : buildLecturerList(),
          ),
        ],
      ),
    );
  }

  Widget buildSearchCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              textInputAction:
                  TextInputAction.search,
              decoration: const InputDecoration(
                labelText: 'Search Lecturer',
                hintText:
                    'Name, DWU ID, or email',
                prefixIcon:
                    Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) {
                loadLecturers();
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: loading
                        ? null
                        : loadLecturers,
                    icon:
                        const Icon(Icons.search),
                    label:
                        const Text('Search'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: loading
                        ? null
                        : clearSearch,
                    icon: const Icon(
                      Icons.clear,
                    ),
                    label: const Text(
                      'Clear',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 52,
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: loadLecturers,
              icon:
                  const Icon(Icons.refresh),
              label:
                  const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildLecturerList() {
    return RefreshIndicator(
      onRefresh: loadLecturers,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          16,
          0,
          16,
          24,
        ),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${lecturers.length} Lecturer'
                  '${lecturers.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
              const Chip(
                avatar: Icon(
                  Icons.visibility_outlined,
                  size: 17,
                ),
                label:
                    Text('Read Only'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (lecturers.isEmpty)
            const Card(
              child: Padding(
                padding:
                    EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 48,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'No lecturers found.',
                      textAlign:
                          TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ...lecturers.map((item) {
              final lecturer =
                  mapOf(item);

              return buildLecturerCard(
                lecturer,
              );
            }),
        ],
      ),
    );
  }

  Widget buildLecturerCard(
    Map<String, dynamic> lecturer,
  ) {
    final statistics =
        mapOf(lecturer['statistics']);

    final units =
        listOf(lecturer['units']);

    final assignedUnits =
        statistics[
                'assigned_unit_count'] ??
            0;

    final enrolledStudents =
        statistics[
                'enrolled_student_count'] ??
            0;

    final logbookCount =
        statistics['logbook_count'] ?? 0;

    final averageCompletion =
        toDouble(
      statistics[
          'average_completion_percentage'],
    );

    final progress =
        (averageCompletion / 100)
            .clamp(0.0, 1.0);

    final lecturerId =
        int.tryParse(
      lecturer['id']?.toString() ?? '',
    );

    return Card(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(12),
        onTap: lecturerId == null
            ? null
            : () {
                openLecturerProgress(
                  lecturerId,
                );
              },
        child: Padding(
          padding:
              const EdgeInsets.all(16),
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
                      Icons.person_outline,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          lecturer['name']
                                  ?.toString() ??
                              'Lecturer',
                          style:
                              const TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        const SizedBox(
                          height: 4,
                        ),
                        Text(
                          lecturer['dwu_id']
                                  ?.toString() ??
                              'No DWU ID',
                        ),
                        const SizedBox(
                          height: 3,
                        ),
                        Text(
                          lecturer['email']
                                  ?.toString() ??
                              '',
                          style: TextStyle(
                            color: Colors
                                .grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Column(
                    children: [
                      Chip(
                        label:
                            Text('LECTURER'),
                      ),
                      Icon(
                        Icons.chevron_right,
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Average Unit Progress',
                      style: TextStyle(
                        color: Colors
                            .grey.shade700,
                      ),
                    ),
                  ),
                  Text(
                    '${averageCompletion.toStringAsFixed(2)}%',
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
                value: progress,
                minHeight: 8,
              ),

              const SizedBox(height: 16),

              Wrap(
                spacing: 24,
                runSpacing: 12,
                children: [
                  buildSmallStat(
                    'Assigned Units',
                    assignedUnits,
                  ),
                  buildSmallStat(
                    'Students',
                    enrolledStudents,
                  ),
                  buildSmallStat(
                    'Logbooks',
                    logbookCount,
                  ),
                ],
              ),

              if (units.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'Assigned Units',
                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...units.map((item) {
                  final unit =
                      mapOf(item);

                  final year =
                      mapOf(
                    unit['year_level'],
                  );

                  return Padding(
                    padding:
                        const EdgeInsets.only(
                      bottom: 8,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons
                              .menu_book_outlined,
                          size: 18,
                        ),
                        const SizedBox(
                          width: 8,
                        ),
                        Expanded(
                          child: Text(
                            '${unit['unit_code'] ?? ''} - '
                            '${unit['unit_name'] ?? ''}',
                          ),
                        ),
                        Text(
                          year['year_name']
                                  ?.toString() ??
                              '',
                          style: TextStyle(
                            color: Colors
                                .grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],

              const SizedBox(height: 12),

              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(
                  12,
                ),
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(
                    8,
                  ),
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest,
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons
                          .visibility_outlined,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tap to view lecturer progress. HOD access remains read-only.',
                      ),
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

  Widget buildSmallStat(
    String label,
    dynamic value,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color:
                Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}