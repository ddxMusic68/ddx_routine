import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/routine.dart';
import '../models/schedule.dart';
import '../utils/storage.dart';

class RoutineProvider extends ChangeNotifier {
  static const _schemaVersion = 6;

  List<Routine> _routines = [];
  final Set<String> _completedKeys = {};
  bool _isLoading = false;
  bool _hasError = false;
  int _idCounter = 0;

  List<Routine> get routines => List.unmodifiable(_routines);
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;

  Routine? routineById(String id) {
    for (final routine in _routines) {
      if (routine.id == id) return routine;
    }
    return null;
  }

  bool isTaskCompleted(String groupId, String taskId, DateTime date) =>
      _completedKeys.contains(_completionKey(groupId, taskId, date));

  Future<void> toggleTaskCompleted(
    String groupId,
    String taskId,
    DateTime date,
  ) async {
    final key = _completionKey(groupId, taskId, date);
    if (_completedKeys.contains(key)) {
      _completedKeys.remove(key);
    } else {
      _completedKeys.add(key);
    }
    await _save();
    notifyListeners();
  }

  Future<void> load() async {
    _isLoading = true;
    _hasError = false;
    notifyListeners();
    try {
      final file = await _file;
      if (!await file.exists()) {
        _routines = [];
        return;
      }
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      final version = json['version'] as int? ?? 1;
      _routines = (json['routines'] as List<dynamic>? ?? const [])
          .map((e) => Routine.fromJson(e as Map<String, dynamic>))
          .toList();
      _completedKeys
        ..clear()
        ..addAll((json['completions'] as List<dynamic>? ?? const [])
            .cast<String>());
      if (version < 6) {
        _migrateCompletionKeysToTasks();
      }
      if (version < _schemaVersion) {
        await _save();
      }
    } catch (e) {
      _hasError = true;
      _routines = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Routine> addRoutine(String name) async {
    final routine = Routine(id: _newId(), name: name);
    _routines = [..._routines, routine];
    await _save();
    notifyListeners();
    return routine;
  }

  Future<void> renameRoutine(String id, String name) async {
    final index = _indexOfRoutine(id);
    if (index < 0) throw ArgumentError('Routine not found: $id');
    _routines[index] = _routines[index].copyWith(name: name);
    await _save();
    notifyListeners();
  }

  Future<void> deleteRoutine(String id) async {
    final removed = _routines.where((r) => r.id == id).toList();
    _routines = _routines.where((r) => r.id != id).toList();
    for (final routine in removed) {
      for (final group in routine.groups) {
        _completedKeys.removeWhere((k) => k.startsWith('${group.id}|'));
      }
    }
    await _save();
    notifyListeners();
  }

  Future<void> clearAll() async {
    _routines = [];
    _completedKeys.clear();
    await _save();
    notifyListeners();
  }

  Future<TaskGroup> addTaskGroup(
    String routineId, {
    List<Schedule> schedules = const [],
    List<Task> tasks = const [],
  }) async {
    for (final schedule in schedules) {
      schedule.validate();
    }
    final routineIndex = _indexOfRoutine(routineId);
    if (routineIndex < 0) {
      throw ArgumentError('Routine not found: $routineId');
    }
    final group = TaskGroup(
      id: _newId(),
      schedules: schedules,
      tasks: tasks,
    );
    final routine = _routines[routineIndex];
    _routines[routineIndex] =
        routine.copyWith(groups: [...routine.groups, group]);
    await _save();
    notifyListeners();
    return group;
  }

  Future<void> updateTaskGroup(
    String routineId,
    TaskGroup group, {
    List<Schedule>? schedules,
    List<Task>? tasks,
  }) async {
    final schedulesToValidate = schedules ?? group.schedules;
    for (final schedule in schedulesToValidate) {
      schedule.validate();
    }
    final routineIndex = _indexOfRoutine(routineId);
    if (routineIndex < 0) {
      throw ArgumentError('Routine not found: $routineId');
    }
    final routine = _routines[routineIndex];
    final groupIndex = routine.groups.indexWhere((g) => g.id == group.id);
    if (groupIndex < 0) {
      throw ArgumentError('Task group not found: ${group.id}');
    }
    final groups = [...routine.groups];
    groups[groupIndex] = group.copyWith(
      schedules: schedules,
      tasks: tasks,
    );
    _routines[routineIndex] = routine.copyWith(groups: groups);
    await _save();
    notifyListeners();
  }

  Future<void> removeTaskGroup(String routineId, String groupId) async {
    final routineIndex = _indexOfRoutine(routineId);
    if (routineIndex < 0) {
      throw ArgumentError('Routine not found: $routineId');
    }
    final routine = _routines[routineIndex];
    _routines[routineIndex] = routine.copyWith(
      groups: routine.groups.where((g) => g.id != groupId).toList(),
    );
    _completedKeys.removeWhere((k) => k.startsWith('$groupId|'));
    await _save();
    notifyListeners();
  }

  Future<void> moveTaskGroup(
    String routineId,
    int oldIndex,
    int newIndex,
  ) async {
    final routineIndex = _indexOfRoutine(routineId);
    if (routineIndex < 0) {
      throw ArgumentError('Routine not found: $routineId');
    }
    final groups = [..._routines[routineIndex].groups];
    if (oldIndex < 0 ||
        oldIndex >= groups.length ||
        newIndex < 0 ||
        newIndex >= groups.length) {
      throw RangeError('Invalid task group index');
    }
    final group = groups.removeAt(oldIndex);
    groups.insert(newIndex, group);
    _routines[routineIndex] = _routines[routineIndex].copyWith(groups: groups);
    await _save();
    notifyListeners();
  }

  Future<void> importJson(String content) async {
    final decoded = jsonDecode(content);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Imported file is not a JSON object');
    }
    final routinesRaw = decoded['routines'];
    if (routinesRaw is! List) {
      throw const FormatException('Imported file has no "routines" list');
    }
    final imported = <Routine>[];
    for (final entry in routinesRaw) {
      if (entry is! Map<String, dynamic>) {
        throw const FormatException('Invalid routine entry in imported file');
      }
      final routine = Routine.fromJson(entry);
      for (final group in routine.groups) {
        for (final schedule in group.schedules) {
          schedule.validate();
        }
      }
      imported.add(routine);
    }
    final completions = decoded['completions'] is List
        ? (decoded['completions'] as List).whereType<String>().toSet()
        : <String>{};
    _routines = imported;
    _completedKeys
      ..clear()
      ..addAll(completions);
    await _save();
    notifyListeners();
  }

  Future<File> get _file async {
    final directory = await appDataDirectory();
    return File('${directory.path}/routines.json');
  }

  String exportJson() => jsonEncode(_payload);

  Map<String, dynamic> get _payload => {
        'version': _schemaVersion,
        'routines': _routines.map((r) => r.toJson()).toList(),
        'completions': _completedKeys.toList(),
      };

  Future<void> _save() async {
    final file = await _file;
    await file.writeAsString(jsonEncode(_payload));
  }

  int _indexOfRoutine(String id) => _routines.indexWhere((r) => r.id == id);

  void _migrateCompletionKeysToTasks() {
    final taskIdByGroup = <String, String>{};
    for (final routine in _routines) {
      for (final group in routine.groups) {
        if (group.tasks.isNotEmpty) {
          taskIdByGroup[group.id] = group.tasks.first.id;
        }
      }
    }
    final migrated = <String>{};
    for (final key in _completedKeys) {
      final parts = key.split('|');
      if (parts.length != 2) continue;
      final groupId = parts[0];
      final taskId = taskIdByGroup[groupId];
      if (taskId == null) continue;
      migrated.add('$groupId|$taskId|${parts[1]}');
    }
    _completedKeys
      ..clear()
      ..addAll(migrated);
  }

  static String _completionKey(String groupId, String taskId, DateTime date) =>
      '$groupId|$taskId|${_dateString(date)}';

  static String _dateString(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  String _newId() {
    _idCounter++;
    return '${DateTime.now().microsecondsSinceEpoch}_$_idCounter';
  }
}
