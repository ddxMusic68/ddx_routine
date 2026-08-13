import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/routine.dart';
import '../models/schedule.dart';
import '../models/weekday.dart';
import '../models/weekday_ordinal.dart';
import '../providers/routine_provider.dart';
import '../widgets/day_of_month_picker.dart';
import '../widgets/stepper_input.dart';
import '../widgets/weekday_selector.dart';
import 'task_draft.dart';
import 'task_editor_screen.dart';

class TaskGroupEditorScreen extends StatefulWidget {
  final String routineId;
  final TaskGroup? group;

  const TaskGroupEditorScreen({
    super.key,
    required this.routineId,
    this.group,
  });

  @override
  State<TaskGroupEditorScreen> createState() => _TaskGroupEditorScreenState();
}

class _TaskGroupEditorScreenState extends State<TaskGroupEditorScreen> {
  final _formKey = GlobalKey<FormState>();

  late List<TaskDraft> _taskDrafts;
  late List<_ScheduleDraft> _drafts;
  int? _expandedIndex;
  String? _tasksError;

  bool get _isEditing => widget.group != null;

  @override
  void initState() {
    super.initState();
    final group = widget.group;
    _taskDrafts = group == null || group.tasks.isEmpty
        ? [TaskDraft()]
        : [for (final task in group.tasks) TaskDraft.fromTask(task)];
    final schedules = group?.schedules;
    _drafts = schedules == null || schedules.isEmpty
        ? [_ScheduleDraft()]
        : [for (final s in schedules) _ScheduleDraft.fromSchedule(s)];
  }

  @override
  void dispose() {
    for (final draft in _taskDrafts) {
      draft.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Task Group' : 'New Task Group'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Tasks', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (var i = 0; i < _taskDrafts.length; i++)
              _buildTaskTile(i),
            OutlinedButton.icon(
              onPressed: _addTask,
              icon: const Icon(Icons.add),
              label: const Text('Add task'),
            ),
            if (_tasksError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _tasksError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 24),
            Text('Repeats', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _buildScheduleCards(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _save,
        icon: const Icon(Icons.check),
        label: Text(_isEditing ? 'Save' : 'Add'),
      ),
    );
  }

  Widget _buildTaskTile(int index) {
    final draft = _taskDrafts[index];
    final name = draft.name.text.trim();
    final description = draft.description.text.trim();
    final durationLabel = _draftDurationLabel(draft);
    final subtitleParts = <String>[
      if (description.isNotEmpty) description,
      ?durationLabel,
    ];
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.check_circle_outline),
        title: Text(name.isEmpty ? 'Unnamed task' : name),
        subtitle: subtitleParts.isEmpty
            ? null
            : Text(
                subtitleParts.join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit task',
              onPressed: () => _editTask(index),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Remove task',
              onPressed: () => setState(() {
                _taskDrafts.removeAt(index);
                _tasksError = null;
              }),
            ),
          ],
        ),
        onTap: () => _editTask(index),
      ),
    );
  }

  String? _draftDurationLabel(TaskDraft draft) {
    final base = draft.maxDuration <= 0
        ? null
        : draft.maxDuration == draft.minDuration
            ? '~${draft.maxDuration} min'
            : '${draft.minDuration}–${draft.maxDuration} min';
    if (base == null) return null;
    final note = draft.durationNote.text.trim();
    return note.isEmpty ? base : '$base · $note';
  }

  Future<void> _editTask(int index) async {
    final result = await Navigator.push<TaskDraft>(
      context,
      MaterialPageRoute(
        builder: (_) => TaskEditorScreen(initial: _taskDrafts[index]),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      final draft = _taskDrafts[index];
      draft.name.text = result.name.text;
      draft.description.text = result.description.text;
      draft.durationNote.text = result.durationNote.text;
      draft.minDuration = result.minDuration;
      draft.maxDuration = result.maxDuration;
      _tasksError = null;
    });
    result.dispose();
  }

  Future<void> _addTask() async {
    final draft = TaskDraft();
    final result = await Navigator.push<TaskDraft>(
      context,
      MaterialPageRoute(builder: (_) => TaskEditorScreen(initial: draft)),
    );
    draft.dispose();
    if (result == null || !mounted) return;
    setState(() {
      _taskDrafts.add(result);
      _tasksError = null;
    });
  }

  Widget _buildScheduleCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < _drafts.length; i++) _buildScheduleCard(i),
        const SizedBox(height: 4),
        OutlinedButton.icon(
          onPressed: _addSchedule,
          icon: const Icon(Icons.add),
          label: const Text('Add schedule'),
        ),
      ],
    );
  }

  Widget _buildScheduleCard(int index) {
    final expanded = _expandedIndex == index;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: expanded
          ? _buildExpandedScheduleCard(index)
          : _buildCollapsedScheduleChip(index),
    );
  }

  Widget _buildCollapsedScheduleChip(int index) {
    final draft = _drafts[index];
    return ListTile(
      leading: const Icon(Icons.schedule),
      title: Text(draft.summaryLabel),
      trailing: const Icon(Icons.expand_more),
      onTap: () {
        setState(() {
          _expandedIndex = index;
          draft.error = null;
        });
      },
    );
  }

  Widget _buildExpandedScheduleCard(int index) {
    final draft = _drafts[index];
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<ScheduleFrequency>(
            initialValue: draft.frequency,
            decoration: const InputDecoration(labelText: 'Repeats'),
            items: [
              for (final frequency in ScheduleFrequency.values)
                DropdownMenuItem(
                  value: frequency,
                  child: Text(_frequencyLabel(frequency)),
                ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  draft.frequency = value;
                  draft.error = null;
                });
              }
            },
          ),
          const SizedBox(height: 16),
          _buildScheduleFields(draft),
          if (draft.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                draft.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _drafts.length > 1
                    ? () => _deleteSchedule(index)
                    : null,
                child: const Text('Delete'),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                onPressed: () => _collapseSchedule(index),
                child: const Text('Done'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _collapseSchedule(int index) {
    final draft = _drafts[index];
    final schedule = draft.toSchedule();
    try {
      schedule.validate();
    } on ArgumentError catch (e) {
      setState(() {
        draft.error = e.message;
        _expandedIndex = index;
      });
      return;
    }
    setState(() {
      draft.error = null;
      _expandedIndex = null;
    });
  }

  void _deleteSchedule(int index) {
    if (_drafts.length <= 1) return;
    setState(() {
      _drafts.removeAt(index);
      final expanded = _expandedIndex;
      if (expanded == null) return;
      if (expanded == index) {
        _expandedIndex = null;
      } else if (expanded > index) {
        _expandedIndex = expanded - 1;
      }
    });
  }

  void _addSchedule() {
    setState(() {
      _drafts.add(_ScheduleDraft());
      _expandedIndex = _drafts.length - 1;
    });
  }

  Widget _buildScheduleFields(_ScheduleDraft draft) {
    switch (draft.frequency) {
      case ScheduleFrequency.daily:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _IntervalField(
              label: 'day(s)',
              value: draft.interval,
              min: 1,
              max: 12,
              onChanged: (value) => setState(() => draft.interval = value),
            ),
          ],
        );
      case ScheduleFrequency.weekly:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WeekdaySelector(
              selectedDays: draft.selectedDays,
              onChanged: (days) {
                setState(() {
                  draft.selectedDays = days;
                  draft.error = null;
                });
              },
            ),
            const SizedBox(height: 16),
            _IntervalField(
              label: 'every week(s)',
              value: draft.interval,
              min: 1,
              max: 12,
              onChanged: (value) => setState(() => draft.interval = value),
            ),
          ],
        );
      case ScheduleFrequency.monthly:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMonthModeToggle(draft),
            const SizedBox(height: 16),
            _buildMonthModePicker(draft),
            const SizedBox(height: 16),
            _IntervalField(
              label: 'month(s)',
              value: draft.interval,
              min: 1,
              max: 12,
              onChanged: (value) => setState(() => draft.interval = value),
            ),
          ],
        );
      case ScheduleFrequency.yearly:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<int>(
              initialValue: draft.month,
              decoration: const InputDecoration(labelText: 'Month'),
              items: [
                for (var m = 1; m <= 12; m++)
                  DropdownMenuItem(
                    value: m,
                    child: Text(_monthNames[m - 1]),
                  ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    draft.month = value;
                    draft.error = null;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            _buildMonthModeToggle(draft),
            const SizedBox(height: 16),
            _buildMonthModePicker(draft),
            const SizedBox(height: 16),
            _IntervalField(
              label: 'year(s)',
              value: draft.interval,
              min: 1,
              max: 12,
              onChanged: (value) => setState(() => draft.interval = value),
            ),
          ],
        );
    }
  }

  Widget _buildMonthModeToggle(_ScheduleDraft draft) {
    return SegmentedButton<bool>(
      segments: const [
        ButtonSegment(value: false, label: Text('Day of month')),
        ButtonSegment(value: true, label: Text('Nth weekday')),
      ],
      selected: {draft.useWeekdayOfMonth},
      showSelectedIcon: false,
      onSelectionChanged: (selection) {
        setState(() {
          draft.useWeekdayOfMonth = selection.first;
          if (draft.useWeekdayOfMonth) {
            draft.weekdayOfMonth ??= Weekday.sunday;
            draft.weekdayOrdinal ??= WeekdayOrdinal.first;
          } else {
            draft.dayOfMonth ??= DateTime.now().day;
          }
          draft.error = null;
        });
      },
    );
  }

  Widget _buildMonthModePicker(_ScheduleDraft draft) {
    if (!draft.useWeekdayOfMonth) {
      return DayOfMonthPicker(
        selectedDay: draft.dayOfMonth,
        onChanged: (day) {
          setState(() {
            draft.dayOfMonth = day;
            draft.error = null;
          });
        },
      );
    }
    return _WeekdayOfMonthFields(
      ordinal: draft.weekdayOrdinal,
      weekday: draft.weekdayOfMonth,
      onOrdinalChanged: (value) {
        setState(() {
          draft.weekdayOrdinal = value;
          draft.error = null;
        });
      },
      onWeekdayChanged: (value) {
        setState(() {
          draft.weekdayOfMonth = value;
          draft.error = null;
        });
      },
    );
  }

  Future<void> _save() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (_taskDrafts.isEmpty) {
      setState(() => _tasksError = 'Add at least one task.');
      return;
    }
    setState(() => _tasksError = null);

    final schedules = <Schedule>[];
    for (var i = 0; i < _drafts.length; i++) {
      final draft = _drafts[i];
      final schedule = draft.toSchedule();
      try {
        schedule.validate();
      } on ArgumentError catch (e) {
        setState(() {
          _expandedIndex = i;
          draft.error = e.message;
        });
        return;
      }
      schedules.add(schedule);
    }

    final tasks = [for (final draft in _taskDrafts) draft.toTask()];
    final provider = context.read<RoutineProvider>();
    if (_isEditing) {
      await provider.updateTaskGroup(
        widget.routineId,
        widget.group!,
        schedules: schedules,
        tasks: tasks,
      );
    } else {
      await provider.addTaskGroup(
        widget.routineId,
        schedules: schedules,
        tasks: tasks,
      );
    }
    if (!mounted) return;
    Navigator.pop(context);
  }

  static String _frequencyLabel(ScheduleFrequency frequency) =>
      switch (frequency) {
        ScheduleFrequency.daily => 'Daily',
        ScheduleFrequency.weekly => 'Weekly',
        ScheduleFrequency.monthly => 'Monthly',
        ScheduleFrequency.yearly => 'Yearly',
      };

  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
}

class _ScheduleDraft {
  ScheduleFrequency frequency;
  Set<Weekday> selectedDays;
  int interval;
  int month;
  int? dayOfMonth;
  Weekday? weekdayOfMonth;
  WeekdayOrdinal? weekdayOrdinal;
  bool useWeekdayOfMonth;
  DateTime? anchor;
  String? error;

  _ScheduleDraft({
    this.frequency = ScheduleFrequency.weekly,
    Set<Weekday>? selectedDays,
    this.interval = 1,
    int? month,
    this.dayOfMonth,
    this.weekdayOfMonth,
    this.weekdayOrdinal,
    this.useWeekdayOfMonth = false,
    this.anchor,
  })  : selectedDays = selectedDays ?? <Weekday>{},
        month = month ?? DateTime.now().month;

  factory _ScheduleDraft.fromSchedule(Schedule schedule) {
    return _ScheduleDraft(
      frequency: schedule.frequency,
      selectedDays: schedule.days.toSet(),
      interval: schedule.interval,
      month: schedule.month ?? DateTime.now().month,
      dayOfMonth: schedule.dayOfMonth,
      weekdayOfMonth: schedule.weekdayOfMonth,
      weekdayOrdinal: schedule.weekdayOrdinal,
      useWeekdayOfMonth: schedule.usesWeekdayOfMonth,
      anchor: schedule.anchor,
    );
  }

  Schedule toSchedule() {
    final usesDayOrWeekday = frequency == ScheduleFrequency.monthly ||
        frequency == ScheduleFrequency.yearly;
    return Schedule(
      frequency: frequency,
      interval: interval,
      anchor: interval > 1 ? (anchor ?? DateTime.now()) : null,
      days: frequency == ScheduleFrequency.weekly ? selectedDays : {},
      dayOfMonth: usesDayOrWeekday && !useWeekdayOfMonth ? dayOfMonth : null,
      month: frequency == ScheduleFrequency.yearly ? month : null,
      weekdayOfMonth:
          usesDayOrWeekday && useWeekdayOfMonth ? weekdayOfMonth : null,
      weekdayOrdinal:
          usesDayOrWeekday && useWeekdayOfMonth ? weekdayOrdinal : null,
    );
  }

  String get summaryLabel {
    final schedule = toSchedule();
    try {
      schedule.validate();
      return schedule.summary;
    } on ArgumentError {
      return 'Tap to configure';
    }
  }
}

class _WeekdayOfMonthFields extends StatelessWidget {
  final WeekdayOrdinal? ordinal;
  final Weekday? weekday;
  final ValueChanged<WeekdayOrdinal> onOrdinalChanged;
  final ValueChanged<Weekday> onWeekdayChanged;

  const _WeekdayOfMonthFields({
    required this.ordinal,
    required this.weekday,
    required this.onOrdinalChanged,
    required this.onWeekdayChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<WeekdayOrdinal>(
            initialValue: ordinal,
            decoration: const InputDecoration(labelText: 'Occurrence'),
            items: [
              for (final value in WeekdayOrdinal.values)
                DropdownMenuItem(value: value, child: Text(value.label)),
            ],
            onChanged: (value) {
              if (value != null) onOrdinalChanged(value);
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<Weekday>(
            initialValue: weekday,
            decoration: const InputDecoration(labelText: 'Weekday'),
            items: [
              for (final value in Weekday.values)
                DropdownMenuItem(value: value, child: Text(value.label)),
            ],
            onChanged: (value) {
              if (value != null) onWeekdayChanged(value);
            },
          ),
        ),
      ],
    );
  }
}

class _IntervalField extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _IntervalField({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Every',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(width: 8),
        StepperInput(
          value: value,
          min: min,
          max: max,
          onChanged: onChanged,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

