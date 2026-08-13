import 'package:flutter/material.dart';
import '../models/routine.dart';

class TaskDraft {
  final String? existingId;
  final TextEditingController name;
  final TextEditingController description;
  final TextEditingController durationNote;
  int minDuration;
  int maxDuration;

  TaskDraft({
    this.existingId,
    String name = '',
    String description = '',
    this.minDuration = 0,
    this.maxDuration = 0,
    String durationNote = '',
  })  : name = TextEditingController(text: name),
        description = TextEditingController(text: description),
        durationNote = TextEditingController(text: durationNote);

  factory TaskDraft.fromTask(Task task) {
    return TaskDraft(
      existingId: task.id,
      name: task.name,
      description: task.description ?? '',
      minDuration: task.minDurationMinutes,
      maxDuration: task.maxDurationMinutes,
      durationNote: task.durationNote ?? '',
    );
  }

  factory TaskDraft.fromDraft(TaskDraft draft) {
    return TaskDraft(
      existingId: draft.existingId,
      name: draft.name.text,
      description: draft.description.text,
      minDuration: draft.minDuration,
      maxDuration: draft.maxDuration,
      durationNote: draft.durationNote.text,
    );
  }

  Task toTask() {
    return Task(
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
