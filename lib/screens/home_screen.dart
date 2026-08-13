import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/routine.dart';
import '../providers/routine_provider.dart';
import '../utils/constants.dart';
import 'day_view.dart';
import 'routine_detail_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Today'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      drawer: const _AppDrawer(),
      body: Consumer<RoutineProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return const DayView();
        },
      ),
    );
  }
}

class _AppDrawer extends StatelessWidget {
  const _AppDrawer();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Consumer<RoutineProvider>(
        builder: (context, provider, child) {
          return SafeArea(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const _DrawerHeader(),
                ListTile(
                  leading: const Icon(Icons.today),
                  title: const Text('Today'),
                  onTap: () => Navigator.pop(context),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'ROUTINES',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                  ),
                ),
                if (provider.routines.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text('No routines yet.'),
                  ),
                for (final routine in provider.routines)
                  ListTile(
                    leading: const Icon(Icons.event_repeat),
                    title: Text(routine.name),
                    subtitle: Text(
                      '${routine.groupCount} '
                      '${routine.groupCount == 1 ? 'task group' : 'task groups'}',
                    ),
                    trailing: PopupMenuButton<String>(
                      tooltip: 'Routine options',
                      onSelected: (value) => _handleMenu(
                        context,
                        provider,
                        routine,
                        value,
                      ),
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'rename',
                          child: Text('Rename'),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              RoutineDetailScreen(routine: routine),
                        ),
                      );
                    },
                  ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.add),
                  title: const Text('New Routine'),
                  onTap: () {
                    Navigator.pop(context);
                    _createRoutine(context, provider);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Settings'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SettingsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleMenu(
    BuildContext context,
    RoutineProvider provider,
    Routine routine,
    String value,
  ) async {
    switch (value) {
      case 'rename':
        final name = await _promptForName(context, initial: routine.name);
        if (name == null || name.trim().isEmpty) return;
        await provider.renameRoutine(routine.id, name.trim());
      case 'delete':
        final confirmed = await _confirmDelete(context, routine.name);
        if (confirmed == true) {
          await provider.deleteRoutine(routine.id);
        }
    }
  }

  Future<void> _createRoutine(
    BuildContext context,
    RoutineProvider provider,
  ) async {
    final name = await _promptForName(context);
    if (name == null || name.trim().isEmpty) return;
    await provider.addRoutine(name.trim());
  }

  Future<bool?> _confirmDelete(BuildContext context, String name) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete routine?'),
          content: Text('"$name" and all of its task groups will be removed.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<String?> _promptForName(BuildContext context, {String? initial}) {
    final controller = TextEditingController(text: initial ?? '');
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(initial == null ? 'New Routine' : 'Rename Routine'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(labelText: 'Name'),
            onSubmitted: (value) => Navigator.pop(context, value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: Text(initial == null ? 'Create' : 'Save'),
            ),
          ],
        );
      },
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader();

  @override
  Widget build(BuildContext context) {
    return DrawerHeader(
      decoration: const BoxDecoration(color: AppColors.mintDark),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.event_repeat, size: 40, color: Colors.white),
          const SizedBox(height: 8),
          Text(
            'ddx routine',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}
