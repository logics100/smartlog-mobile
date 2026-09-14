import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'admin_create_unit_screen.dart';
import 'admin_edit_unit_screen.dart';

class AdminUnitsScreen extends StatefulWidget {
  const AdminUnitsScreen({
    super.key,
  });

  @override
  State<AdminUnitsScreen> createState() =>
      _AdminUnitsScreenState();
}

class _AdminUnitsScreenState
    extends State<AdminUnitsScreen> {
  final searchController =
      TextEditingController();

  bool loading = true;
  String? errorMessage;

  List<dynamic> units = [];
  List<dynamic> departments = [];
  List<dynamic> yearLevels = [];
  List<dynamic> semesters = [];

  int totalUnits = 0;
  int activeUnits = 0;
  int inactiveUnits = 0;
  int logbookUnits = 0;

  int? selectedDepartmentId;
  int? selectedYearLevelId;
  int? selectedSemesterId;
  String? selectedStatus;
  String? selectedLogbook;

  @override
  void initState() {
    super.initState();
    loadUnits();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadUnits() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final result =
          await ApiService.getAdminUnits(
        search:
            searchController.text.trim(),
        departmentId:
            selectedDepartmentId,
        yearLevelId:
            selectedYearLevelId,
        semesterId:
            selectedSemesterId,
        status:
            selectedStatus,
        requiresLogbook:
            selectedLogbook,
      );

      if (!mounted) return;

      final summary =
          Map<String, dynamic>.from(
        result['summary'] ?? {},
      );

      final options =
          Map<String, dynamic>.from(
        result['options'] ?? {},
      );

      setState(() {
        units = List<dynamic>.from(
          result['units'] ?? [],
        );

        totalUnits =
            summary['total'] ?? 0;

        activeUnits =
            summary['active'] ?? 0;

        inactiveUnits =
            summary['inactive'] ?? 0;

        logbookUnits =
            summary['requiring_logbook'] ??
                0;

        departments =
            List<dynamic>.from(
          options['departments'] ?? [],
        );

        yearLevels =
            List<dynamic>.from(
          options['year_levels'] ?? [],
        );

        semesters =
            List<dynamic>.from(
          options['semesters'] ?? [],
        );
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e
            .toString()
            .replaceFirst(
              'Exception: ',
              '',
            );
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  void clearFilters() {
    searchController.clear();

    setState(() {
      selectedDepartmentId = null;
      selectedYearLevelId = null;
      selectedSemesterId = null;
      selectedStatus = null;
      selectedLogbook = null;
    });

    loadUnits();
  }
  Future<void> openCreateUnit() async {
  final created = await Navigator.push<bool>(
    context,
    MaterialPageRoute(
      builder: (_) => AdminCreateUnitScreen(
        departments: departments,
        yearLevels: yearLevels,
        semesters: semesters,
      ),
    ),
  );

  if (!mounted) return;

  if (created == true) {
    await loadUnits();
  }
}
Future<void> openEditUnit(
  Map<String, dynamic> unit,
) async {
  final updated = await Navigator.push<bool>(
    context,
    MaterialPageRoute(
      builder: (_) => AdminEditUnitScreen(
        unit: unit,
        departments: departments,
        yearLevels: yearLevels,
        semesters: semesters,
      ),
    ),
  );

  if (!mounted) return;

  if (updated == true) {
    await loadUnits();
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Unit Management',
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed:
                loading
                    ? null
                    : loadUnits,
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),

      floatingActionButton:
    FloatingActionButton.extended(
  onPressed:
      loading ? null : openCreateUnit,
  icon: const Icon(
    Icons.add,
  ),
  label: const Text(
    'Add Unit',
  ),
),

      body: RefreshIndicator(
        onRefresh: loadUnits,
        child: ListView(
          padding:
              const EdgeInsets.fromLTRB(
            16,
            16,
            16,
            90,
          ),
          children: [
            buildSummary(),

            const SizedBox(
              height: 20,
            ),

            const Text(
              'Search & Filter',
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            TextField(
              controller:
                  searchController,
              decoration:
                  const InputDecoration(
                labelText: 'Search unit',
                hintText:
                    'Unit code or name',
                border:
                    OutlineInputBorder(),
                prefixIcon:
                    Icon(Icons.search),
              ),
              textInputAction:
                  TextInputAction.search,
              onSubmitted: (_) {
                loadUnits();
              },
            ),

            const SizedBox(
              height: 12,
            ),

            DropdownButtonFormField<
                int>(
              initialValue:
                  selectedDepartmentId,
              isExpanded: true,
              decoration:
                  const InputDecoration(
                labelText: 'Department',
                border:
                    OutlineInputBorder(),
                prefixIcon:
                    Icon(Icons.business),
              ),
              items: departments.map(
                (item) {
                  final department =
                      Map<String,
                          dynamic>.from(
                    item,
                  );

                  return DropdownMenuItem<
                      int>(
                    value:
                        department['id']
                            as int,
                    child: Text(
                      '${department['department_code']} - '
                      '${department['department_name']}',
                      overflow:
                          TextOverflow
                              .ellipsis,
                    ),
                  );
                },
              ).toList(),
              onChanged: (value) {
                setState(() {
                  selectedDepartmentId =
                      value;
                });
              },
            ),

            const SizedBox(
              height: 12,
            ),

            DropdownButtonFormField<
                int>(
              initialValue:
                  selectedYearLevelId,
              decoration:
                  const InputDecoration(
                labelText:
                    'Year Level',
                border:
                    OutlineInputBorder(),
                prefixIcon:
                    Icon(Icons.school),
              ),
              items: yearLevels.map(
                (item) {
                  return DropdownMenuItem<
                      int>(
                    value:
                        item['id'] as int,
                    child: Text(
                      item['year_name']
                          .toString(),
                    ),
                  );
                },
              ).toList(),
              onChanged: (value) {
                setState(() {
                  selectedYearLevelId =
                      value;
                });
              },
            ),

            const SizedBox(
              height: 12,
            ),

            DropdownButtonFormField<
                int>(
              initialValue:
                  selectedSemesterId,
              decoration:
                  const InputDecoration(
                labelText: 'Semester',
                border:
                    OutlineInputBorder(),
                prefixIcon:
                    Icon(
                  Icons.calendar_month,
                ),
              ),
              items: semesters.map(
                (item) {
                  return DropdownMenuItem<
                      int>(
                    value:
                        item['id'] as int,
                    child: Text(
                      item[
                              'semester_name']
                          .toString(),
                    ),
                  );
                },
              ).toList(),
              onChanged: (value) {
                setState(() {
                  selectedSemesterId =
                      value;
                });
              },
            ),

            const SizedBox(
              height: 12,
            ),

            DropdownButtonFormField<
                String>(
              initialValue:
                  selectedStatus,
              decoration:
                  const InputDecoration(
                labelText: 'Status',
                border:
                    OutlineInputBorder(),
                prefixIcon: Icon(
                  Icons
                      .toggle_on_outlined,
                ),
              ),
              items: const [
                DropdownMenuItem<String>(
                  value: 'active',
                  child: Text('Active'),
                ),
                DropdownMenuItem<String>(
                  value: 'inactive',
                  child: Text(
                    'Inactive',
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  selectedStatus = value;
                });
              },
            ),

            const SizedBox(
              height: 12,
            ),

            DropdownButtonFormField<
                String>(
              initialValue:
                  selectedLogbook,
              decoration:
                  const InputDecoration(
                labelText:
                    'Requires Logbook',
                border:
                    OutlineInputBorder(),
                prefixIcon:
                    Icon(Icons.menu_book),
              ),
              items: const [
                DropdownMenuItem<String>(
                  value: 'yes',
                  child: Text('Yes'),
                ),
                DropdownMenuItem<String>(
                  value: 'no',
                  child: Text('No'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  selectedLogbook = value;
                });
              },
            ),

            const SizedBox(
              height: 12,
            ),

            Row(
              children: [
                Expanded(
                  child:
                      OutlinedButton.icon(
                    onPressed:
                        clearFilters,
                    icon: const Icon(
                      Icons
                          .filter_alt_off,
                    ),
                    label: const Text(
                      'Clear Filters',
                    ),
                  ),
                ),

                const SizedBox(
                  width: 12,
                ),

                Expanded(
                  child:
                      ElevatedButton.icon(
                    onPressed:
                        loading
                            ? null
                            : loadUnits,
                    icon: const Icon(
                      Icons.search,
                    ),
                    label: const Text(
                      'Search',
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 24,
            ),

            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Units',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),

                Text(
                  '${units.length} shown',
                ),
              ],
            ),

            const SizedBox(
              height: 12,
            ),

            if (loading)
              const Padding(
                padding:
                    EdgeInsets.symmetric(
                  vertical: 50,
                ),
                child: Center(
                  child:
                      CircularProgressIndicator(),
                ),
              )
            else if (errorMessage != null)
              buildError()
            else if (units.isEmpty)
              buildEmpty()
            else
              ...units.map(
                (item) {
                  final unit =
                      Map<String,
                          dynamic>.from(
                    item,
                  );

                  return buildUnitCard(
                    unit,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget buildSummary() {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(
                  Icons.menu_book,
                  size: 28,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'SmartLog Units',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 18,
            ),

            Wrap(
              spacing: 20,
              runSpacing: 16,
              alignment:
                  WrapAlignment.center,
              children: [
                buildSummaryItem(
                  'Total',
                  totalUnits,
                ),
                buildSummaryItem(
                  'Active',
                  activeUnits,
                ),
                buildSummaryItem(
                  'Inactive',
                  inactiveUnits,
                ),
                buildSummaryItem(
                  'Logbook',
                  logbookUnits,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSummaryItem(
    String label,
    int value,
  ) {
    return SizedBox(
      width: 70,
      child: Column(
        children: [
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 22,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          Text(
            label,
            textAlign:
                TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget buildUnitCard(
    Map<String, dynamic> unit,
  ) {
    final department =
        Map<String, dynamic>.from(
      unit['department'] ?? {},
    );

    final yearLevel =
        Map<String, dynamic>.from(
      unit['year_level'] ?? {},
    );

    final semester =
        Map<String, dynamic>.from(
      unit['semester'] ?? {},
    );

    final statistics =
        Map<String, dynamic>.from(
      unit['statistics'] ?? {},
    );

    final isActive =
        unit['is_active'] == true;

    final requiresLogbook =
        unit['requires_logbook'] ==
            true;

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      child: InkWell(
        onTap: () {
  openEditUnit(
    unit,
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
                      Icons.menu_book,
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
                          unit['unit_name'] ??
                              'Unit',
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
                          'Code: '
                          '${unit['unit_code'] ?? '-'}',
                        ),
                      ],
                    ),
                  ),

                  Chip(
                    label: Text(
                      isActive
                          ? 'Active'
                          : 'Inactive',
                    ),
                  ),
                ],
              ),

              const Divider(
                height: 24,
              ),

              Text(
                'Department: '
                '${department['code'] ?? '-'} - '
                '${department['name'] ?? '-'}',
              ),

              Text(
                'Year Level: '
                '${yearLevel['name'] ?? '-'}',
              ),

              Text(
                'Semester: '
                '${semester['name'] ?? '-'}',
              ),

              Text(
                'Requires Logbook: '
                '${requiresLogbook ? 'Yes' : 'No'}',
              ),

              const SizedBox(
                height: 10,
              ),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(
                    label: Text(
                      '${statistics['enrollments'] ?? 0} Enrollments',
                    ),
                  ),
                  Chip(
                    label: Text(
                      '${statistics['logbooks'] ?? 0} Logbooks',
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 10,
              ),

              const Row(
                mainAxisAlignment:
                    MainAxisAlignment.end,
                children: [
                  Icon(
                    Icons.edit_outlined,
                    size: 17,
                  ),
                  SizedBox(width: 5),
                  Text(
                    'Tap to edit',
                    style: TextStyle(
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildError() {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
            ),
            const SizedBox(
              height: 12,
            ),
            Text(
              errorMessage!,
              textAlign:
                  TextAlign.center,
            ),
            const SizedBox(
              height: 16,
            ),
            ElevatedButton.icon(
              onPressed: loadUnits,
              icon: const Icon(
                Icons.refresh,
              ),
              label: const Text(
                'Try Again',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildEmpty() {
    return const Card(
      child: Padding(
        padding:
            EdgeInsets.all(30),
        child: Column(
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 50,
            ),
            SizedBox(
              height: 12,
            ),
            Text(
              'No units found.',
              style: TextStyle(
                fontSize: 17,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            SizedBox(
              height: 6,
            ),
            Text(
              'Try changing the search or filters.',
              textAlign:
                  TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}