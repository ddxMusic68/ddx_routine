import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/routine.dart';
import '../models/schedule.dart';
import '../models/weekday.dart';
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
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _durationNoteController;

  late ScheduleFrequency _frequency;
  late Set<Weekday> _selectedDays;
  late int _interval;
  late int _month;
  late int _minDuration;
  late int _maxDuration;
  int? _dayOfMonth;
  String? _scheduleError;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    final schedule = task?.schedule;
    _titleController = TextEditingController(text: task?.title ?? '');
    _descriptionController = TextEditingController(
      text: task?.description ?? '',
    );
    _durationNoteController = TextEditingController(
      text: task?.durationNote ?? '',
    );
    _frequency = schedule?.frequency ?? ScheduleFrequency.weekly;
    _selectedDays = schedule?.days.toSet() ?? <Weekday>{};
    _interval = schedule?.interval ?? 1;
    _month = schedule?.month ?? DateTime.now().month;
    _dayOfMonth = schedule?.dayOfMonth;
    _minDuration = task?.minDurationMinutes ?? 0;
    _maxDuration = task?.maxDurationMinutes ?? 0;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _durationNoteController.dispose();
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
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
              textInputAction: TextInputAction.next,
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Enter a title'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            Text('Duration', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _DurationField(
              title: 'Min',
              value: _minDuration,
              min: 0,
              max: _maxDuration,
              onChanged: (value) => setState(() => _minDuration = value),
            ),
            const SizedBox(height: 4),
            _DurationField(
              title: 'Max',
              value: _maxDuration,
              min: _minDuration,
              max: 1440,
              onChanged: (value) => setState(() => _maxDuration = value),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _durationNoteController,
              decoration: const InputDecoration(
                labelText: 'Duration note (optional)',
              ),
            ),
            const SizedBox(height: 24),
            Text('Repeats', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            RadioGroup<ScheduleFrequency>(
              groupValue: _frequency,
              onChanged: _setFrequency,
              child: Column(
                children: [
                  RadioListTile<ScheduleFrequency>(
                    value: ScheduleFrequency.daily,
                    title: const Text('Daily'),
                    secondary: const Icon(Icons.event_repeat),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                  RadioListTile<ScheduleFrequency>(
                    value: ScheduleFrequency.weekly,
                    title: const Text('Weekly'),
                    secondary: const Icon(Icons.date_range),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                  RadioListTile<ScheduleFrequency>(
                    value: ScheduleFrequency.monthly,
                    title: const Text('Monthly'),
                    secondary: const Icon(Icons.calendar_month),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                  RadioListTile<ScheduleFrequency>(
                    value: ScheduleFrequency.yearly,
                    title: const Text('Yearly'),
                    secondary: const Icon(Icons.event),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _buildScheduleFields(),
            if (_scheduleError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _scheduleError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
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

  void _setFrequency(ScheduleFrequency? value) {
    if (value == null) return;
    setState(() {
      _frequency = value;
      _scheduleError = null;
    });
  }

  Widget _buildScheduleFields() {
    switch (_frequency) {
      case ScheduleFrequency.daily:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _IntervalField(
              label: 'day(s)',
              value: _interval,
              min: 1,
              max: 12,
              onChanged: (value) => setState(() => _interval = value),
            ),
          ],
        );
      case ScheduleFrequency.weekly:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WeekdaySelector(
              selectedDays: _selectedDays,
              onChanged: (days) {
                setState(() {
                  _selectedDays = days;
                  _scheduleError = null;
                });
              },
            ),
            const SizedBox(height: 16),
            _IntervalField(
              label: 'every week(s)',
              value: _interval,
              min: 1,
              max: 12,
              onChanged: (value) => setState(() => _interval = value),
            ),
          ],
        );
      case ScheduleFrequency.monthly:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DayOfMonthPicker(
              selectedDay: _dayOfMonth,
              onChanged: (day) {
                setState(() {
                  _dayOfMonth = day;
                  _scheduleError = null;
                });
              },
            ),
            const SizedBox(height: 16),
            _IntervalField(
              label: 'month(s)',
              value: _interval,
              min: 1,
              max: 12,
              onChanged: (value) => setState(() => _interval = value),
            ),
          ],
        );
      case ScheduleFrequency.yearly:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<int>(
              initialValue: _month,
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
                    _month = value;
                    _scheduleError = null;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            DayOfMonthPicker(
              selectedDay: _dayOfMonth,
              onChanged: (day) {
                setState(() {
                  _dayOfMonth = day;
                  _scheduleError = null;
                });
              },
            ),
            const SizedBox(height: 16),
            _IntervalField(
              label: 'year(s)',
              value: _interval,
              min: 1,
              max: 12,
              onChanged: (value) => setState(() => _interval = value),
            ),
          ],
        );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final schedule = Schedule(
      frequency: _frequency,
      interval: _interval,
      anchor: _interval > 1 ? DateTime.now() : null,
      days: _frequency == ScheduleFrequency.weekly ? _selectedDays : {},
      dayOfMonth:
          _frequency == ScheduleFrequency.monthly ||
              _frequency == ScheduleFrequency.yearly
          ? _dayOfMonth
          : null,
      month: _frequency == ScheduleFrequency.yearly ? _month : null,
    );
    try {
      schedule.validate();
    } on ArgumentError catch (e) {
      setState(() => _scheduleError = e.message);
      return;
    }

    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final durationNote = _durationNoteController.text.trim();
    final provider = context.read<RoutineProvider>();
    if (_isEditing) {
      await provider.updateTask(
        widget.routineId,
        widget.task!,
        title: title,
        description: description.isEmpty ? null : description,
        minDurationMinutes: _minDuration,
        maxDurationMinutes: _maxDuration,
        durationNote: durationNote.isEmpty ? null : durationNote,
        schedule: schedule,
      );
    } else {
      await provider.addTask(
        widget.routineId,
        title,
        description: description.isEmpty ? null : description,
        minDurationMinutes: _minDuration,
        maxDurationMinutes: _maxDuration,
        durationNote: durationNote.isEmpty ? null : durationNote,
        schedule: schedule,
      );
    }
    if (!mounted) return;
    Navigator.pop(context);
  }

  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
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
