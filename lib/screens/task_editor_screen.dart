import 'package:flutter/material.dart';
import '../widgets/stepper_input.dart';
import 'task_draft.dart';

class TaskEditorScreen extends StatefulWidget {
  final TaskDraft initial;

  const TaskEditorScreen({super.key, required this.initial});

  @override
  State<TaskEditorScreen> createState() => _TaskEditorScreenState();
}

class _TaskEditorScreenState extends State<TaskEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late TaskDraft _draft;

  @override
  void initState() {
    super.initState();
    _draft = TaskDraft.fromDraft(widget.initial);
  }

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  void _save() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, TaskDraft.fromDraft(_draft));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Task')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _draft.name,
              decoration: const InputDecoration(labelText: 'Name'),
              textInputAction: TextInputAction.next,
              autofocus: true,
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Enter a name'
                  : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _draft.description,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            _DurationField(
              title: 'Min',
              value: _draft.minDuration,
              min: 0,
              max: _draft.maxDuration,
              onChanged: (value) => setState(() => _draft.minDuration = value),
            ),
            const SizedBox(height: 4),
            _DurationField(
              title: 'Max',
              value: _draft.maxDuration,
              min: _draft.minDuration,
              max: 1440,
              onChanged: (value) => setState(() => _draft.maxDuration = value),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _draft.durationNote,
              decoration: const InputDecoration(
                labelText: 'Duration note (optional)',
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _save,
        icon: const Icon(Icons.check),
        label: const Text('Save'),
      ),
    );
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
        StepperInput(
          value: value,
          min: min,
          max: max,
          onChanged: onChanged,
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
