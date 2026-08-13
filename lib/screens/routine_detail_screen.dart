import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/routine.dart';
import '../providers/routine_provider.dart';
import 'task_group_editor_screen.dart';

class RoutineDetailScreen extends StatelessWidget {
  final Routine routine;

  const RoutineDetailScreen({super.key, required this.routine});

  @override
  Widget build(BuildContext context) {
    final routineId = routine.id;
    return Consumer<RoutineProvider>(
      builder: (context, provider, child) {
        final current = provider.routineById(routineId);
        if (current == null) {
          return const Scaffold(body: SizedBox.shrink());
        }
        return Scaffold(
          appBar: AppBar(title: Text(current.name)),
          body: current.groups.isEmpty
              ? _EmptyTasksView(
                  onCreate: () => _openEditor(context, provider, current),
                )
              : ReorderableListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: current.groups.length,
                  onReorder: (oldIndex, newIndex) {
                    if (newIndex > oldIndex) newIndex--;
                    provider.moveTaskGroup(routineId, oldIndex, newIndex);
                  },
                  itemBuilder: (context, index) {
                    final group = current.groups[index];
                    return _TaskGroupTile(
                      key: ValueKey(group.id),
                      group: group,
                      onTap: () =>
                          _openEditor(context, provider, current, group),
                      onEdit: () =>
                          _openEditor(context, provider, current, group),
                      onDelete: () =>
                          provider.removeTaskGroup(routineId, group.id),
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openEditor(context, provider, current),
            icon: const Icon(Icons.add),
            label: const Text('Add Task Group'),
          ),
        );
      },
    );
  }

  void _openEditor(
    BuildContext context,
    RoutineProvider provider,
    Routine routine, [
    TaskGroup? group,
  ]) {
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
}

class _TaskGroupTile extends StatelessWidget {
  final TaskGroup group;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TaskGroupTile({
    super.key,
    required this.group,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final taskNames = [
      for (final task in group.tasks)
        if (task.name.isNotEmpty) task.name,
    ];
    final subtitle = taskNames.isEmpty
        ? 'No tasks'
        : taskNames.join(' · ');

    return ListTile(
      leading: const Icon(Icons.event_repeat),
      title: Text(group.scheduleSummary ?? 'No repeats'),
      subtitle: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: onEdit,
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete',
            onPressed: onDelete,
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}

class _EmptyTasksView extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyTasksView({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.playlist_add, size: 64),
          const SizedBox(height: 16),
          Text(
            'No task groups yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first task group to get started.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add),
            label: const Text('Add Task Group'),
          ),
        ],
      ),
    );
  }
}
