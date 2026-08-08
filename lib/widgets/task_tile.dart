import 'package:flutter/material.dart';
import '../models/routine.dart';

class TaskTile extends StatelessWidget {
  final RoutineTask task;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool completed;
  final VoidCallback? onToggleCompleted;

  const TaskTile({
    super.key,
    required this.task,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.completed = false,
    this.onToggleCompleted,
  });

  bool get _supportsCompletion => onToggleCompleted != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: _supportsCompletion
          ? Icon(
              completed ? Icons.check_circle : Icons.check_circle_outline,
              color: completed
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline,
            )
          : null,
      title: Text(
        task.title,
        style: completed
            ? TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                decoration: TextDecoration.lineThrough,
              )
            : null,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (task.description != null && task.description!.isNotEmpty)
            Text(task.description!),
          const SizedBox(height: 4),
          Text(
            task.schedule.summary,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (task.durationLabel != null)
            Text(
              task.durationLabel!,
              style: theme.textTheme.labelMedium,
            ),
          if (onEdit != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit',
              onPressed: onEdit,
            ),
          ],
          if (onDelete != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
            ),
          ],
        ],
      ),
      onTap: _supportsCompletion ? onToggleCompleted : onTap,
    );
  }
}
