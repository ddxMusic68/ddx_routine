import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/routine.dart';
import '../models/schedule.dart';
import '../models/weekday.dart';
import '../models/weekday_ordinal.dart';
import '../providers/routine_provider.dart';
import '../widgets/day_of_month_picker.dart';
import '../widgets/weekday_selector.dart';

class TaskEditorScreen extends StatefulWidget {
  final String routineId;
  final RoutineTask? task;

  const TaskEditorScreen({
    super.key,
    required this.routineId,
    this.task,
  });

  @override
  State<TaskEditorScreen> createState() => _TaskEditorScreenState();
}

class _TaskEditorScreenState extends State<TaskEditorScreen> {
  final _formKey = GlobalKey<FormState>();

  late List<_ItemDraft> _itemDrafts;
  late List<_ScheduleDraft> _drafts;
  int? _expandedIndex;
  String? _itemsError;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _itemDrafts = task == null || task.items.isEmpty
        ? [_ItemDraft()]
        : [for (final item in task.items) _ItemDraft.fromItem(item)];
    final schedules = task?.schedules;
    _drafts = schedules == null || schedules.isEmpty
        ? [_ScheduleDraft()]
        : [for (final s in schedules) _ScheduleDraft.fromSchedule(s)];
  }

  @override
  void dispose() {
    for (final draft in _itemDrafts) {
      draft.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Task' : 'New Task'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Items', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (var i = 0; i < _itemDrafts.length; i++)
              _buildItemCard(i),
            OutlinedButton.icon(
              onPressed: _addItem,
              icon: const Icon(Icons.add),
              label: const Text('Add item'),
            ),
            if (_itemsError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _itemsError!,
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

  Widget _buildItemCard(int index) {
    final draft = _itemDrafts[index];
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: draft.name,
                    decoration: const InputDecoration(labelText: 'Name'),
                    textInputAction: TextInputAction.next,
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                            ? 'Enter a name'
                            : null,
                    onChanged: (_) {
                      if (_itemsError != null) {
                        setState(() => _itemsError = null);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Remove item',
                  onPressed: () => setState(() {
                    _itemDrafts.removeAt(index);
                    _itemsError = null;
                  }),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: draft.description,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            _DurationField(
              title: 'Min',
              value: draft.minDuration,
              min: 0,
              max: draft.maxDuration,
              onChanged: (value) => setState(() => draft.minDuration = value),
            ),
            const SizedBox(height: 4),
            _DurationField(
              title: 'Max',
              value: draft.maxDuration,
              min: draft.minDuration,
              max: 1440,
              onChanged: (value) => setState(() => draft.maxDuration = value),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: draft.durationNote,
              decoration: const InputDecoration(
                labelText: 'Duration note (optional)',
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addItem() {
    setState(() {
      _itemDrafts.add(_ItemDraft());
      _itemsError = null;
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
    if (!_formKey.currentState!.validate()) return;
    if (_itemDrafts.isEmpty) {
      setState(() => _itemsError = 'Add at least one item.');
      return;
    }
    setState(() => _itemsError = null);

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

    final items = [for (final draft in _itemDrafts) draft.toItem()];
    final provider = context.read<RoutineProvider>();
    if (_isEditing) {
      await provider.updateTask(
        widget.routineId,
        widget.task!,
        schedules: schedules,
        items: items,
      );
    } else {
      await provider.addTask(
        widget.routineId,
        schedules: schedules,
        items: items,
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

class _ItemDraft {
  final String? existingId;
  final TextEditingController name;
  final TextEditingController description;
  final TextEditingController durationNote;
  int minDuration;
  int maxDuration;

  _ItemDraft({
    this.existingId,
    String name = '',
    String description = '',
    this.minDuration = 0,
    this.maxDuration = 0,
    String durationNote = '',
  })  : name = TextEditingController(text: name),
        description = TextEditingController(text: description),
        durationNote = TextEditingController(text: durationNote);

  factory _ItemDraft.fromItem(TaskItem item) {
    return _ItemDraft(
      existingId: item.id,
      name: item.name,
      description: item.description ?? '',
      minDuration: item.minDurationMinutes,
      maxDuration: item.maxDurationMinutes,
      durationNote: item.durationNote ?? '',
    );
  }

  TaskItem toItem() {
    return TaskItem(
      id: existingId ?? 'i${DateTime.now().microsecondsSinceEpoch}',
      name: name.text.trim(),
      description: description.text.trim().isEmpty
          ? null
          : description.text.trim(),
      minDurationMinutes: minDuration,
      maxDurationMinutes: maxDuration,
      durationNote: durationNote.text.trim().isEmpty
          ? null
          : durationNote.text.trim(),
    );
  }

  void dispose() {
    name.dispose();
    description.dispose();
    durationNote.dispose();
  }
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
    );
  }

  Schedule toSchedule() {
    final usesDayOrWeekday = frequency == ScheduleFrequency.monthly ||
        frequency == ScheduleFrequency.yearly;
    return Schedule(
      frequency: frequency,
      interval: interval,
      anchor: interval > 1 ? DateTime.now() : null,
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

class _DurationField extends StatelessWidget {
  final String title;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _DurationField({
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 48,
          child: Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          onPressed: value > min ? () => onChanged(value - 1) : null,
          constraints: const BoxConstraints.tightFor(
            width: 28,
            height: 28,
          ),
          padding: EdgeInsets.zero,
          iconSize: 16,
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.remove),
          tooltip: 'Decrease',
        ),
        SizedBox(
          width: 40,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        IconButton.filledTonal(
          onPressed: value < max ? () => onChanged(value + 1) : null,
          constraints: const BoxConstraints.tightFor(
            width: 28,
            height: 28,
          ),
          padding: EdgeInsets.zero,
          iconSize: 16,
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.add),
          tooltip: 'Increase',
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'min',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
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
        IconButton.filledTonal(
          onPressed: value > min ? () => onChanged(value - 1) : null,
          constraints: const BoxConstraints.tightFor(
            width: 28,
            height: 28,
          ),
          padding: EdgeInsets.zero,
          iconSize: 16,
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.remove),
          tooltip: 'Decrease',
        ),
        Text(
          '$value',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        IconButton.filledTonal(
          onPressed: value < max ? () => onChanged(value + 1) : null,
          constraints: const BoxConstraints.tightFor(
            width: 28,
            height: 28,
          ),
          padding: EdgeInsets.zero,
          iconSize: 16,
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.add),
          tooltip: 'Increase',
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
