import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/routine.dart';
import '../providers/routine_provider.dart';
import '../widgets/task_tile.dart';
import 'task_editor_screen.dart';

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
              final routines = provider.routinesWithTasksOnDate(_selectedDate);
              if (routines.isEmpty) {
                return _EmptyDayView(date: _selectedDate);
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: routines.length,
                itemBuilder: (context, index) {
                  final routine = routines[index];
                  final tasks = routine.tasksOn(_selectedDate);
                  final items = [for (final task in tasks) ...task.items];
                  final minMinutes = items.fold<int>(
                    0,
                    (sum, item) => sum + item.minDurationMinutes,
                  );
                  final maxMinutes = items.fold<int>(
                    0,
                    (sum, item) => sum + item.maxDurationMinutes,
                  );
                  final String? durationRange = maxMinutes <= 0
                      ? null
                      : minMinutes == maxMinutes
                          ? '~$maxMinutes min'
                          : '$minMinutes–$maxMinutes min';
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () => _toggleRoutine(routine.id),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
                          child: Row(
                            children: [
                              Icon(
                                _collapsedRoutineIds.contains(routine.id)
                                    ? Icons.expand_more
                                    : Icons.expand_less,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  routine.name,
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                              ),
                              if (durationRange != null)
                                Text(
                                  durationRange,
                                  style:
                                      Theme.of(context).textTheme.labelMedium,
                                ),
                            ],
                          ),
                        ),
                      ),
                      if (!_collapsedRoutineIds.contains(routine.id))
                        for (final task in tasks)
                          TaskTile(
                            task: task,
                            isCompleted: (item) => provider.isItemCompleted(
                              task.id,
                              item.id,
                              _selectedDate,
                            ),
                            onToggleCompleted: (item) =>
                                provider.toggleItemCompleted(
                              task.id,
                              item.id,
                              _selectedDate,
                            ),
                            onEdit: () => _openEditor(
                              context,
                              provider,
                              routine,
                              task,
                            ),
                            onDelete: () =>
                                provider.removeTask(routine.id, task.id),
                          ),
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
    RoutineTask task,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskEditorScreen(
          routineId: routine.id,
          task: task,
        ),
      ),
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
