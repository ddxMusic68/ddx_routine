import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/routine.dart';
import '../providers/routine_provider.dart';
import '../widgets/task_tile.dart';
import 'task_editor_screen.dart';

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
          body: current.tasks.isEmpty
              ? _EmptyTasksView(
                  onCreate: () => _openEditor(context, provider, current),
                )
              : ReorderableListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: current.tasks.length,
                  onReorder: (oldIndex, newIndex) {
                    if (newIndex > oldIndex) newIndex--;
                    provider.moveTask(routineId, oldIndex, newIndex);
                  },
                  itemBuilder: (context, index) {
                    final task = current.tasks[index];
                    return TaskTile(
                      key: ValueKey(task.id),
                      task: task,
                      onTap: () => _openEditor(context, provider, current, task),
                      onEdit: () => _openEditor(context, provider, current, task),
                      onDelete: () => provider.removeTask(routineId, task.id),
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openEditor(context, provider, current),
            icon: const Icon(Icons.add),
            label: const Text('Add Task'),
          ),
        );
      },
    );
  }

  void _openEditor(
    BuildContext context,
    RoutineProvider provider,
    Routine routine, [
    RoutineTask? task,
  ]) {
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
            'No tasks yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first task to get started.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add),
            label: const Text('Add Task'),
          ),
        ],
      ),
    );
  }
}
