import 'package:flutter/material.dart';
import '../models/routine.dart';

class TaskTile extends StatelessWidget {
  final RoutineTask task;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool Function(TaskItem item)? isCompleted;
  final ValueChanged<TaskItem>? onToggleCompleted;

  const TaskTile({
    super.key,
    required this.task,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.isCompleted,
    this.onToggleCompleted,
  });

  bool get _supportsCompletion =>
      onToggleCompleted != null && isCompleted != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = task.items.length;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            dense: true,
            leading: const Icon(Icons.event_repeat),
            title: Text(task.scheduleSummary ?? 'No repeats'),
            subtitle: Text(
              '$count ${count == 1 ? 'item' : 'items'}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onEdit != null) ...[
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Edit',
                    onPressed: onEdit,
                  ),
                  const SizedBox(width: 8),
                ],
                if (onDelete != null) ...[
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Delete',
                    onPressed: onDelete,
                  ),
                ],
              ],
            ),
            onTap: onTap,
          ),
          for (final item in task.items) _buildItem(context, item),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext context, TaskItem item) {
    final theme = Theme.of(context);
    if (_supportsCompletion) {
      final completed = isCompleted!(item);
      return CheckboxListTile(
        dense: true,
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.only(left: 8, right: 16),
        value: completed,
        title: Text(
          item.name,
          style: completed
              ? TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  decoration: TextDecoration.lineThrough,
                )
              : null,
        ),
        subtitle: _buildItemSubtitle(context, item),
        onChanged: (_) => onToggleCompleted!(item),
      );
    }
    return ListTile(
      dense: true,
      leading: Icon(
        Icons.check_circle_outline,
        size: 20,
        color: theme.colorScheme.outline,
      ),
      title: Text(item.name),
      subtitle: _buildItemSubtitle(context, item),
    );
  }

  Widget? _buildItemSubtitle(BuildContext context, TaskItem item) {
    final theme = Theme.of(context);
    final parts = <String>[
      if (item.description != null && item.description!.isNotEmpty)
        item.description!,
      if (item.durationLabel != null) item.durationLabel!,
    ];
    if (parts.isEmpty) return null;
    return Text(
      parts.join(' · '),
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
