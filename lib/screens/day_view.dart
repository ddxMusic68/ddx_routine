import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/routine.dart';
import '../providers/routine_provider.dart';
import 'task_group_editor_screen.dart';

class DayView extends StatefulWidget {
  const DayView({super.key});

  @override
  State<DayView> createState() => _DayViewState();
}

class _DayViewState extends State<DayView> {
  late DateTime _selectedDate;
  final Set<String> _collapsedRoutineIds = {};

  @override
  void initState() {
    super.initState();
    _selectedDate = _dateOnly(DateTime.now());
  }

  void _selectDate(DateTime date) {
    setState(() => _selectedDate = _dateOnly(date));
  }

  void _toggleRoutine(String routineId) {
    setState(() {
      if (!_collapsedRoutineIds.add(routineId)) {
        _collapsedRoutineIds.remove(routineId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = _dateOnly(DateTime.now());
    final isToday = _selectedDate == now;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Previous day',
                onPressed: () =>
                    _selectDate(DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day - 1)),
              ),
              Expanded(
                child: InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isToday
                              ? '${_weekdayNames[_selectedDate.weekday - 1]} (current day)'
                              : _weekdayNames[_selectedDate.weekday - 1],
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '${_monthNames[_selectedDate.month - 1]} ${_selectedDate.day}, ${_selectedDate.year}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Next day',
                onPressed: () =>
                    _selectDate(DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day + 1)),
              ),
            ],
          ),
        ),
        if (!isToday)
          TextButton.icon(
            onPressed: () => _selectDate(now),
            icon: const Icon(Icons.today, size: 18),
            label: const Text('Jump to Today'),
          ),
        const Divider(height: 1),
        Expanded(
          child: Consumer<RoutineProvider>(
            builder: (context, provider, child) {
              final routines = provider.routines
                  .where((routine) => routine.groupCountOn(_selectedDate) > 0)
                  .toList();
              if (routines.isEmpty) {
                return _EmptyDayView(date: _selectedDate);
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: routines.length,
                itemBuilder: (context, index) {
                  final routine = routines[index];
                  final groups = routine.groupsOn(_selectedDate);
                  final tasks = [for (final group in groups) ...group.tasks];
                  final minMinutes = tasks.fold<int>(
                    0,
                    (sum, task) => sum + task.minDurationMinutes,
                  );
                  final maxMinutes = tasks.fold<int>(
                    0,
                    (sum, task) => sum + task.maxDurationMinutes,
                  );
                  final String? durationRange = maxMinutes <= 0
                      ? null
                      : minMinutes == maxMinutes
                          ? '~$maxMinutes min'
                          : '$minMinutes–$maxMinutes min';
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _RoutineHeader(
                        routine: routine,
                        durationRange: durationRange,
                        collapsed: _collapsedRoutineIds.contains(routine.id),
                        onToggle: () => _toggleRoutine(routine.id),
                        onEdit: () =>
                            _renameRoutine(context, provider, routine),
                        onDelete: () =>
                            _deleteRoutine(context, provider, routine),
                      ),
                      if (!_collapsedRoutineIds.contains(routine.id))
                        for (final group in groups)
                          for (final task in group.tasks)
                            _TaskRow(
                              routineId: routine.id,
                              group: group,
                              task: task,
                              date: _selectedDate,
                              onOpenGroup: () => _openEditor(
                                context,
                                provider,
                                routine,
                                group,
                              ),
                              onDeleteGroup: () => provider.removeTaskGroup(
                                routine.id,
                                group.id,
                              ),
                            ),
                      const Divider(height: 1),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      helpText: 'Select a date',
    );
    if (picked != null && mounted) {
      _selectDate(picked);
    }
  }

  void _openEditor(
    BuildContext context,
    RoutineProvider provider,
    Routine routine,
    TaskGroup group,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskGroupEditorScreen(
          routineId: routine.id,
          group: group,
        ),
      ),
    );
  }

  Future<void> _renameRoutine(
    BuildContext context,
    RoutineProvider provider,
    Routine routine,
  ) async {
    final name = await _promptForName(context, initial: routine.name);
    if (name == null || name.trim().isEmpty) return;
    await provider.renameRoutine(routine.id, name.trim());
  }

  Future<void> _deleteRoutine(
    BuildContext context,
    RoutineProvider provider,
    Routine routine,
  ) async {
    final confirmed = await _confirmDelete(context, routine.name);
    if (confirmed == true) {
      await provider.deleteRoutine(routine.id);
    }
  }

  Future<bool?> _confirmDelete(BuildContext context, String name) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete routine?'),
          content: Text('"$name" and all of its task groups will be removed.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<String?> _promptForName(BuildContext context, {String? initial}) {
    final controller = TextEditingController(text: initial ?? '');
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rename Routine'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(labelText: 'Name'),
            onSubmitted: (value) => Navigator.pop(context, value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static const _weekdayNames = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday',
    'Friday', 'Saturday', 'Sunday',
  ];

  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
}

class _RoutineHeader extends StatelessWidget {
  final Routine routine;
  final String? durationRange;
  final bool collapsed;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RoutineHeader({
    required this.routine,
    required this.durationRange,
    required this.collapsed,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
        child: Row(
          children: [
            Icon(
              collapsed ? Icons.expand_more : Icons.expand_less,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                routine.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium,
              ),
            ),
            if (durationRange != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  durationRange!,
                  style: theme.textTheme.labelMedium,
                ),
              ),
            PopupMenuButton<String>(
              tooltip: 'Routine options',
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    onEdit();
                  case 'delete':
                    onDelete();
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  final String routineId;
  final TaskGroup group;
  final Task task;
  final DateTime date;
  final VoidCallback onOpenGroup;
  final VoidCallback onDeleteGroup;

  const _TaskRow({
    required this.routineId,
    required this.group,
    required this.task,
    required this.date,
    required this.onOpenGroup,
    required this.onDeleteGroup,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final description = (task.description ?? '').trim();
    final summary = group.scheduleSummary;
    return Consumer<RoutineProvider>(
      builder: (context, provider, child) {
        final completed = provider.isTaskCompleted(group.id, task.id, date);
        return ListTile(
          dense: true,
          leading: Checkbox(
            value: completed,
            onChanged: (_) => provider.toggleTaskCompleted(
              group.id,
              task.id,
              date,
            ),
          ),
          title: Text(
            task.name,
            style: completed
                ? TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    decoration: TextDecoration.lineThrough,
                  )
                : null,
          ),
          subtitle: summary == null
              ? null
              : Text(
                  summary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (task.durationLabel != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    task.durationLabel!,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              if (description.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.info_outline, size: 18),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Details',
                  onPressed: () => _showDescription(context),
                ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Edit',
                onPressed: onOpenGroup,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Delete',
                onPressed: onDeleteGroup,
              ),
            ],
          ),
          onTap: () => provider.toggleTaskCompleted(
            group.id,
            task.id,
            date,
          ),
        );
      },
    );
  }

  void _showDescription(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(task.name),
          content: SingleChildScrollView(
            child: SelectableText(
              (task.description ?? '').trim(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

class _EmptyDayView extends StatelessWidget {
  final DateTime date;

  const _EmptyDayView({required this.date});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.event_available, size: 64),
            const SizedBox(height: 16),
            Text(
              'Nothing scheduled',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'No tasks occur on this date.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
