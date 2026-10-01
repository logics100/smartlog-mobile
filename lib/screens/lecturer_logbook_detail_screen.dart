import 'package:flutter/material.dart';

import '../services/lecturer_logbook_api.dart';

class LecturerLogbookDetailScreen extends StatefulWidget {
  final int templateId;

  const LecturerLogbookDetailScreen({super.key, required this.templateId});

  @override
  State<LecturerLogbookDetailScreen> createState() =>
      _LecturerLogbookDetailScreenState();
}

class _LecturerLogbookDetailScreenState
    extends State<LecturerLogbookDetailScreen> {
  bool loading = true;
  String? error;
  Map<String, dynamic>? data;

  static const sectionTypes = [
    'ATTENDANCE',
    'PROCEDURE',
    'CHECKLIST',
    'PATIENT_LOG',
    'CASELOAD',
    'SKILLS',
    'REFLECTION',
    'ASSESSMENT',
    'GENERAL',
  ];

  @override
  void initState() {
    super.initState();
    load();
  }

  Map<String, dynamic> mapOf(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return {};
  }

  List<dynamic> listOf(dynamic value) {
    if (value is List) return value;
    return [];
  }

  bool boolOf(dynamic value) {
    return value == true ||
        value == 1 ||
        value?.toString() == '1' ||
        value?.toString().toLowerCase() == 'true';
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final result = await LecturerLogbookApi.getLogbook(widget.templateId);

      if (!mounted) return;
      setState(() => data = result);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<bool?> formSheet({
    required String title,
    required Widget Function(BuildContext context, StateSetter setSheetState)
    builder,
  }) {
    return showModalBottomSheet<bool>(
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
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Close',
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
                        child: builder(sheetContext, setSheetState),
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
  }

  Future<void> assignStudents() async {
    try {
      final result = await LecturerLogbookApi.assign(widget.templateId);

      if (!mounted) return;

      message(
        (result['message'] ?? 'Students assigned successfully.').toString(),
      );

      await load();
    } catch (e) {
      if (mounted) {
        message(e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  Future<void> addSection() async {
    final title = TextEditingController();
    final instructions = TextEditingController();
    final order = TextEditingController(text: '1');

    String type = 'SKILLS';
    bool verify = true;

    final ok = await formSheet(
      title: 'Add Section',
      builder: (context, setSheetState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SECTION INFORMATION',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),

            TextField(
              controller: title,
              decoration: const InputDecoration(
                labelText: 'Section title *',
                hintText: 'e.g. Clinical Skills',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
            ),
            const SizedBox(height: 14),

            DropdownButtonFormField<String>(
              initialValue: type,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Section type *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: sectionTypes
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text(value.replaceAll('_', ' ')),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setSheetState(() {
                  type = value ?? 'SKILLS';
                });
              },
            ),
            const SizedBox(height: 14),

            TextField(
              controller: instructions,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Instructions',
                hintText: 'Instructions for students completing this section',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 14),

            TextField(
              controller: order,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Display order',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.format_list_numbered),
              ),
            ),
            const SizedBox(height: 10),

            Card(
              margin: EdgeInsets.zero,
              child: SwitchListTile(
                title: const Text(
                  'Supervisor verification',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Students will require supervisor verification for this section.',
                ),
                value: verify,
                onChanged: (value) {
                  setSheetState(() => verify = value);
                },
              ),
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.pop(context, true),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Section'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (ok != true || title.text.trim().isEmpty) return;

    try {
      await LecturerLogbookApi.addSection(
        templateId: widget.templateId,
        title: title.text.trim(),
        type: type,
        instructions: instructions.text.trim(),
        order: int.tryParse(order.text) ?? 1,
        verify: verify,
      );

      await load();

      if (mounted) message('Section added.');
    } catch (e) {
      if (mounted) {
        message(e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  Future<void> addItem(int sectionId) async {
    final name = TextEditingController();
    final description = TextEditingController();
    final level = TextEditingController(text: 'Perform');
    final count = TextEditingController(text: '1');
    final order = TextEditingController(text: '1');

    bool verify = true;
    bool active = true;

    final ok = await formSheet(
      title: 'Add Clinical Item',
      builder: (context, setSheetState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CLINICAL ITEM INFORMATION',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),

            TextField(
              controller: name,
              decoration: const InputDecoration(
                labelText: 'Item name *',
                hintText: 'e.g. Patient Assessment',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.medical_services_outlined),
              ),
            ),
            const SizedBox(height: 14),

            TextField(
              controller: description,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 14),

            TextField(
              controller: level,
              decoration: const InputDecoration(
                labelText: 'Required level',
                hintText: 'e.g. Perform',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.school_outlined),
              ),
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: count,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Required count',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: order,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Display order',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Card(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text(
                      'Supervisor verification',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'Require supervisor evidence for this item.',
                    ),
                    value: verify,
                    onChanged: (value) {
                      setSheetState(() => verify = value);
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text(
                      'Active',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'Make this item available to students.',
                    ),
                    value: active,
                    onChanged: (value) {
                      setSheetState(() => active = value);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.pop(context, true),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Item'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (ok != true || name.text.trim().isEmpty) return;

    try {
      await LecturerLogbookApi.addItem(
        templateId: widget.templateId,
        sectionId: sectionId,
        name: name.text.trim(),
        description: description.text.trim(),
        level: level.text.trim(),
        count: int.tryParse(count.text) ?? 1,
        verify: verify,
        order: int.tryParse(order.text) ?? 1,
        active: active,
      );

      await load();

      if (mounted) message('Clinical item added.');
    } catch (e) {
      if (mounted) {
        message(e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  Future<void> addRequirement(int itemId) async {
    final code = TextEditingController();
    final label = TextEditingController();
    bool simulation = false;

    final ok = await formSheet(
      title: 'Add Requirement',
      builder: (context, setSheetState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'REQUIREMENT INFORMATION',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),

            TextField(
              controller: code,
              decoration: const InputDecoration(
                labelText: 'Requirement code *',
                hintText: 'e.g. R2',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.tag),
              ),
            ),
            const SizedBox(height: 14),

            TextField(
              controller: label,
              decoration: const InputDecoration(
                labelText: 'Requirement label *',
                hintText: 'e.g. Attempt 2',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.checklist_outlined),
              ),
            ),
            const SizedBox(height: 12),

            Card(
              margin: EdgeInsets.zero,
              child: SwitchListTile(
                title: const Text(
                  'Simulation',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  simulation
                      ? 'This requirement is a simulation.'
                      : 'This requirement is a clinical activity.',
                ),
                value: simulation,
                onChanged: (value) {
                  setSheetState(() => simulation = value);
                },
              ),
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.pop(context, true),
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (ok != true || code.text.trim().isEmpty || label.text.trim().isEmpty) {
      return;
    }

    try {
      await LecturerLogbookApi.addRequirement(
        templateId: widget.templateId,
        itemId: itemId,
        code: code.text.trim(),
        label: label.text.trim(),
        simulation: simulation,
      );

      await load();

      if (mounted) message('Requirement added.');
    } catch (e) {
      if (mounted) {
        message(e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  Widget badge({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer
            .withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget buildTemplateHeader(
    Map<String, dynamic> template,
    List<dynamic> sections,
  ) {
    int itemCount = 0;
    int requirementCount = 0;

    for (final sectionRaw in sections) {
      final section = mapOf(sectionRaw);
      final items = listOf(section['items']);
      itemCount += items.length;

      for (final itemRaw in items) {
        requirementCount += listOf(mapOf(itemRaw)['requirements']).length;
      }
    }

    final active = boolOf(template['is_active']);
    final assigned = data?['assigned_count'] ?? 0;
    final eligible = data?['eligible_enrollments'] ?? 0;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.menu_book_outlined, color: Colors.white, size: 34),
          const SizedBox(height: 12),
          Text(
            (template['template_name'] ?? 'Clinical Logbook').toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${template['unit_code'] ?? ''} - '
            '${template['unit_name'] ?? ''}',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          if ((template['description'] ?? '').toString().trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              template['description'].toString(),
              style: const TextStyle(color: Colors.white70),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              badge(
                icon: Icons.folder_outlined,
                text: '${sections.length} Sections',
              ),
              badge(
                icon: Icons.medical_services_outlined,
                text: '$itemCount Items',
              ),
              badge(
                icon: Icons.checklist_outlined,
                text: '$requirementCount Requirements',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              badge(icon: Icons.people_outline, text: '$assigned Assigned'),
              badge(
                icon: Icons.person_add_alt_outlined,
                text: '$eligible Eligible',
              ),
              badge(
                icon: active
                    ? Icons.check_circle_outline
                    : Icons.pause_circle_outline,
                text: active ? 'ACTIVE' : 'INACTIVE',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildAssignmentCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.groups_outlined),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Student Assignment',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Assign this clinical logbook to eligible active students enrolled in this unit.',
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: assignStudents,
                icon: const Icon(Icons.group_add_outlined),
                label: const Text('Assign to Active Students'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildRequirement(Map<String, dynamic> requirement) {
    final simulation = boolOf(requirement['is_simulation']);

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            simulation
                ? Icons.science_outlined
                : Icons.medical_services_outlined,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${requirement['requirement_code'] ?? ''} — '
                  '${requirement['requirement_label'] ?? ''}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  simulation ? 'Simulation' : 'Clinical',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildItem(Map<String, dynamic> item) {
    final requirements = listOf(item['requirements']);
    final itemId = int.tryParse(item['id']?.toString() ?? '');

    final active = boolOf(item['is_active']);
    final verify = boolOf(item['requires_supervisor_verification']);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          child: Icon(
            active ? Icons.medical_services_outlined : Icons.pause_outlined,
          ),
        ),
        title: Text(
          (item['item_name'] ?? 'Clinical Item').toString(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            'Level: ${item['required_level'] ?? '-'}  •  '
            'Required: ${item['required_count'] ?? 0}  •  '
            '${requirements.length} requirement'
            '${requirements.length == 1 ? '' : 's'}',
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        children: [
          if ((item['item_description'] ?? '').toString().trim().isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(item['item_description'].toString()),
              ),
            ),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                avatar: Icon(
                  verify
                      ? Icons.verified_user_outlined
                      : Icons.remove_circle_outline,
                  size: 17,
                ),
                label: Text(
                  verify
                      ? 'Supervisor Verification'
                      : 'No Supervisor Verification',
                ),
              ),
              Chip(label: Text(active ? 'ACTIVE' : 'INACTIVE')),
              Chip(label: Text('Order ${item['display_order'] ?? '-'}')),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Requirements',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),

          if (requirements.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('No requirements added yet.'),
              ),
            )
          else
            ...requirements.map((raw) => buildRequirement(mapOf(raw))),

          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: itemId == null ? null : () => addRequirement(itemId),
              icon: const Icon(Icons.add),
              label: const Text('Add Requirement'),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSection(Map<String, dynamic> section) {
    final items = listOf(section['items']);
    final sectionId = int.tryParse(section['id']?.toString() ?? '');

    final verify = boolOf(section['requires_supervisor_verification']);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: const CircleAvatar(child: Icon(Icons.folder_copy_outlined)),
        title: Text(
          (section['section_title'] ?? 'Section').toString(),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            '${(section['section_type'] ?? 'GENERAL').toString().replaceAll('_', ' ')}'
            '  •  ${items.length} item${items.length == 1 ? '' : 's'}',
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if ((section['instructions'] ?? '')
                    .toString()
                    .trim()
                    .isNotEmpty) ...[
                  const Text(
                    'Instructions',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(section['instructions'].toString()),
                  const SizedBox(height: 10),
                ],

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(
                      label: Text('Order ${section['display_order'] ?? '-'}'),
                    ),
                    Chip(
                      avatar: Icon(
                        verify
                            ? Icons.verified_user_outlined
                            : Icons.remove_circle_outline,
                        size: 17,
                      ),
                      label: Text(
                        verify
                            ? 'Supervisor Verification'
                            : 'No Supervisor Verification',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: sectionId == null
                        ? null
                        : () => addItem(sectionId),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Clinical Item'),
                  ),
                ),
              ],
            ),
          ),

          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('No clinical items in this section yet.'),
              ),
            )
          else
            ...items.map((raw) => buildItem(mapOf(raw))),
        ],
      ),
    );
  }

  Widget buildContent() {
    final template = mapOf(data?['template']);
    final sections = listOf(data?['sections']);

    return RefreshIndicator(
      onRefresh: load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 36),
        children: [
          buildTemplateHeader(template, sections),

          const SizedBox(height: 16),

          buildAssignmentCard(),

          const SizedBox(height: 20),

          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Logbook Structure',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text('Sections → Clinical Items → Requirements'),
                  ],
                ),
              ),
              IconButton.filledTonal(
                tooltip: 'Add Section',
                onPressed: addSection,
                icon: const Icon(Icons.add),
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (sections.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(Icons.folder_open_outlined, size: 48),
                    const SizedBox(height: 12),
                    const Text(
                      'No sections yet',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Start building this clinical logbook by creating its first section.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: addSection,
                      icon: const Icon(Icons.add),
                      label: const Text('Add First Section'),
                    ),
                  ],
                ),
              ),
            )
          else
            ...sections.map((raw) => buildSection(mapOf(raw))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Clinical Logbook',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Template Builder', style: TextStyle(fontSize: 11)),
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
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 100),
                const Icon(Icons.error_outline, size: 52),
                const SizedBox(height: 16),
                Text(error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: load,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                ),
              ],
            )
          : buildContent(),
    );
  }
}
