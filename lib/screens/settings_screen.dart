import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import '../providers/routine_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/constants.dart';
import 'about_screen.dart';
import 'wip_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _jsonTypeGroup = XTypeGroup(
    label: 'JSON',
    extensions: ['json'],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return ListView(
            children: [
              const _SectionHeader(title: 'Appearance'),
              RadioGroup<AppThemeMode>(
                groupValue: settings.themeMode,
                onChanged: (mode) {
                  if (mode != null) settings.setThemeMode(mode);
                },
                child: Column(
                  children: [
                    _ThemeTile(
                      title: 'System',
                      value: AppThemeMode.system,
                    ),
                    _ThemeTile(
                      title: 'Light',
                      value: AppThemeMode.light,
                    ),
                    _ThemeTile(
                      title: 'Dark',
                      value: AppThemeMode.dark,
                    ),
                  ],
                ),
              ),
              const Divider(),
              const _SectionHeader(title: 'Sync'),
              _WipTile(
                icon: Icons.cloud,
                title: 'Connect to Dropbox',
                subtitle: 'Sync data across devices',
                feature: 'Dropbox sync',
              ),
              _WipTile(
                icon: Icons.sync,
                title: 'Sync Now',
                subtitle: 'Push pending changes',
                feature: 'Sync',
              ),
              const Divider(),
              const _SectionHeader(title: 'Data'),
              _DataTile(
                icon: Icons.upload_file,
                title: 'Export Data',
                subtitle: 'Save data to a JSON file',
                onTap: () => _exportData(context),
              ),
              _DataTile(
                icon: Icons.download,
                title: 'Import Data',
                subtitle: 'Load data from a JSON file',
                onTap: () => _importData(context),
              ),
              _DataTile(
                icon: Icons.delete_outline,
                title: 'Clear Local Data',
                subtitle: 'Delete all data on this device',
                iconColor: Theme.of(context).colorScheme.error,
                onTap: () => _clearLocalData(context),
              ),
              _WipTile(
                icon: Icons.cloud_off,
                title: 'Clear Cloud Data',
                subtitle: 'Delete all synced data',
                feature: 'Clear cloud data',
              ),
              const Divider(),
              const _SectionHeader(title: 'Info'),
              _DataTile(
                icon: Icons.info_outline,
                title: 'Learn more about this app',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AboutScreen()),
                  );
                },
              ),
              const Divider(),
              const _VersionTile(),
            ],
          );
        },
      ),
    );
  }

  Future<void> _exportData(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<RoutineProvider>();
    try {
      final location = await getSaveLocation(
        suggestedName: 'ddx_routine_backup.json',
        acceptedTypeGroups: const [_jsonTypeGroup],
      );
      if (location == null) return;
      await File(location.path).writeAsString(provider.exportJson());
      messenger.showSnackBar(
        SnackBar(content: Text('Exported to ${location.path}')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  Future<void> _importData(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<RoutineProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Import data?'),
          content: const Text(
            'This replaces all current routines and completions on this device.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Import'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;
    try {
      final file = await openFile(
        acceptedTypeGroups: const [_jsonTypeGroup],
      );
      if (file == null) return;
      final content = await file.readAsString();
      await provider.importJson(content);
      messenger.showSnackBar(
        const SnackBar(content: Text('Data imported')),
      );
    } on FormatException {
      messenger.showSnackBar(
        const SnackBar(content: Text('Import failed: invalid file')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Import failed: $e')),
      );
    }
  }

  Future<void> _clearLocalData(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<RoutineProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear local data?'),
          content: const Text(
            'All routines and completion history on this device will be deleted. '
            'This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;
    try {
      await provider.clearAll();
      messenger.showSnackBar(
        const SnackBar(content: Text('Local data cleared')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to clear local data: $e')),
      );
    }
  }
}

class _DataTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? iconColor;

  const _DataTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppColors.mintDark),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: onTap,
    );
  }
}

class _WipTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String feature;

  const _WipTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.feature,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.mintDark),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.mintLight,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'WIP',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, size: 18),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => WipScreen(feature: feature)),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  final String title;
  final AppThemeMode value;

  const _ThemeTile({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Radio<AppThemeMode>(
          value: value,
        ),
        Text(title),
      ],
    );
  }
}

class _VersionTile extends StatelessWidget {
  const _VersionTile();

  static final Future<PackageInfo> _packageInfo = PackageInfo.fromPlatform();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: _packageInfo,
      builder: (context, snapshot) {
        final String label;
        if (snapshot.connectionState != ConnectionState.done) {
          label = '...';
        } else if (snapshot.hasError) {
          label = 'Unknown';
        } else {
          final version = snapshot.data?.version ?? '';
          final buildNumber = snapshot.data?.buildNumber ?? '';
          label = version.isEmpty && buildNumber.isEmpty
              ? 'Unknown'
              : 'v$version+$buildNumber';
        }
        return ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('Version'),
          subtitle: Text(label),
        );
      },
    );
  }
}
