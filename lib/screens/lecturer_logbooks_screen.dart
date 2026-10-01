import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/lecturer_logbook_api.dart';
import 'lecturer_logbook_detail_screen.dart';

class LecturerLogbooksScreen extends StatefulWidget {
  const LecturerLogbooksScreen({super.key});

  @override
  State<LecturerLogbooksScreen> createState() => _LecturerLogbooksScreenState();
}

class _LecturerLogbooksScreenState extends State<LecturerLogbooksScreen> {
  bool loading = true;
  String? error;
  List<dynamic> logbooks = [];
  List<dynamic> units = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  bool boolOf(dynamic value) {
    return value == true ||
        value == 1 ||
        value?.toString() == '1' ||
        value?.toString().toLowerCase() == 'true';
  }

  int intOf(dynamic value) {
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final result = await Future.wait([
        LecturerLogbookApi.getLogbooks(),
        ApiService.getLecturerUnits(),
      ]);

      if (!mounted) return;

      setState(() {
        logbooks = result[0];
        units = result[1];
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  void message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> create() async {
    if (units.isEmpty) {
      message('No assigned units available.');
      return;
    }

    final name = TextEditingController();
    final description = TextEditingController();
    final minimum = TextEditingController(text: '90');

    final firstUnit = Map<String, dynamic>.from(units.first as Map);

    int? unitId = int.tryParse(
      (firstUnit['unit_id'] ?? firstUnit['id']).toString(),
    );

    bool active = true;

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final keyboard = MediaQuery.of(context).viewInsets.bottom;

            return AnimatedPadding(
              duration: const Duration(milliseconds: 150),
              padding: EdgeInsets.only(bottom: keyboard),
              child: FractionallySizedBox(
                heightFactor: 0.88,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 12, 10),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'New Clinical Logbook',
                                  style: TextStyle(
                                    fontSize: 21,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Create a template for an assigned unit',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(sheetContext, false),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TEMPLATE INFORMATION',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 14),

                            DropdownButtonFormField<int>(
                              initialValue: unitId,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Unit *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.class_outlined),
                              ),
                              items: units.map((raw) {
                                final unit = Map<String, dynamic>.from(
                                  raw as Map,
                                );

                                final id = int.parse(
                                  (unit['unit_id'] ?? unit['id']).toString(),
                                );

                                return DropdownMenuItem<int>(
                                  value: id,
                                  child: Text(
                                    '${unit['unit_code'] ?? ''} - '
                                    '${unit['unit_name'] ?? ''}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setSheetState(() => unitId = value);
                              },
                            ),

                            const SizedBox(height: 14),

                            TextField(
                              controller: name,
                              decoration: const InputDecoration(
                                labelText: 'Template name *',
                                hintText: 'e.g. Year 3 Surgery Clinical Skills Logbook',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.menu_book_outlined),
                              ),
                            ),

                            const SizedBox(height: 14),

                            TextField(
                              controller: description,
                              minLines: 3,
                              maxLines: 5,
                              decoration: const InputDecoration(
                                labelText: 'Description',
                                hintText: 'Short description of this clinical logbook',
                                border: OutlineInputBorder(),
                                alignLabelWithHint: true,
                              ),
                            ),

                            const SizedBox(height: 14),

                            TextField(
                              controller: minimum,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Minimum completion %',
                                hintText: '90',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.percent),
                              ),
                            ),

                            const SizedBox(height: 12),

                            Card(
                              margin: EdgeInsets.zero,
                              child: SwitchListTile(
                                title: const Text(
                                  'Active',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: const Text(
                                  'Make this logbook template active and available for assignment.',
                                ),
                                value: active,
                                onChanged: (value) {
                                  setSheetState(() => active = value);
                                },
                              ),
                            ),

                            const SizedBox(height: 24),

                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    icon: const Icon(Icons.add),
                                    label: const Text('Create'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (ok != true || unitId == null || name.text.trim().isEmpty) {
      return;
    }

    final minimumValue = double.tryParse(minimum.text) ?? 90;

    if (minimumValue < 0 || minimumValue > 100) {
      message('Minimum completion must be between 0 and 100.');
      return;
    }

    try {
      final result = await LecturerLogbookApi.createLogbook(
        unitId: unitId!,
        name: name.text.trim(),
        description: description.text.trim(),
        minimum: minimumValue,
        active: active,
      );

      if (!mounted) return;

      message((result['message'] ?? 'Clinical logbook created.').toString());

      await load();
    } catch (e) {
      if (mounted) {
        message(e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  Widget statBox(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest
              .withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20),
            const SizedBox(height: 5),
            Text(
              value,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildLogbookCard(Map<String, dynamic> logbook) {
    final id = int.tryParse(logbook['id']?.toString() ?? '');

    final active = boolOf(logbook['is_active']);

    final sections = intOf(logbook['sections_count']);

    final items = intOf(logbook['items_count']);

    final requirements = intOf(logbook['requirements_count']);

    final students = intOf(logbook['student_logbooks_count']);

    final minimum = logbook['minimum_completion_percentage'];

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: id == null
            ? null
            : () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LecturerLogbookDetailScreen(templateId: id),
                  ),
                );

                if (mounted) {
                  await load();
                }
              },
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24,
                    child: const Icon(Icons.menu_book_outlined),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (logbook['template_name'] ?? 'Clinical Logbook')
                              .toString(),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${logbook['unit_code'] ?? ''} - '
                          '${logbook['unit_name'] ?? ''}',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: active
                          ? Colors.green.withValues(alpha: 0.12)
                          : Colors.grey.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      active ? 'ACTIVE' : 'INACTIVE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: active
                            ? Colors.green.shade700
                            : Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),

              if ((logbook['description'] ?? '')
                  .toString()
                  .trim()
                  .isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  logbook['description'].toString(),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 15),

              Row(
                children: [
                  statBox('Sections', '$sections', Icons.folder_outlined),
                  const SizedBox(width: 7),
                  statBox('Items', '$items', Icons.medical_services_outlined),
                  const SizedBox(width: 7),
                  statBox(
                    'Requirements',
                    '$requirements',
                    Icons.checklist_outlined,
                  ),
                  const SizedBox(width: 7),
                  statBox('Students', '$students', Icons.people_outline),
                ],
              ),

              if (minimum != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.flag_outlined, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'Minimum completion: $minimum%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),

              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Open template builder',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.menu_book_outlined, color: Colors.white, size: 34),
          SizedBox(height: 12),
          Text(
            'Clinical Logbook Builder',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Create, structure and assign digital clinical logbooks for your assigned units.',
            style: TextStyle(color: Colors.white, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget buildBody() {
    if (loading) {
      return ListView(
        children: const [
          SizedBox(height: 220),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (error != null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 90),
          const Icon(Icons.error_outline, size: 52),
          const SizedBox(height: 14),
          Text(error!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: load,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        buildHeader(),

        const SizedBox(height: 20),

        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Clinical Logbooks',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 3),
                  Text('Select a template to manage its structure.'),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${logbooks.length}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        if (logbooks.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(26),
              child: Column(
                children: [
                  const Icon(Icons.menu_book_outlined, size: 50),
                  const SizedBox(height: 12),
                  const Text(
                    'No clinical logbooks yet',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Create your first digital clinical logbook for one of your assigned units.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: create,
                    icon: const Icon(Icons.add),
                    label: const Text('Create Logbook'),
                  ),
                ],
              ),
            ),
          )
        else
          ...logbooks.map(
            (raw) => buildLogbookCard(Map<String, dynamic>.from(raw as Map)),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SMARTLOG', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Clinical Logbooks', style: TextStyle(fontSize: 11)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: loading ? null : load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: loading ? null : create,
        icon: const Icon(Icons.add),
        label: const Text('New Logbook'),
      ),

      body: RefreshIndicator(onRefresh: load, child: buildBody()),
    );
  }
}
