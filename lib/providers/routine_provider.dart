import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/routine.dart';
import '../models/schedule.dart';
import '../utils/storage.dart';

class RoutineProvider extends ChangeNotifier {
  static const _schemaVersion = 5;

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

  List<Routine> routinesWithTasksOnDate(DateTime date) => _routines
      .where((routine) => routine.taskCountOn(date) > 0)
      .toList();

  List<RoutineTask> tasksOnDate(DateTime date) {
    final tasks = <RoutineTask>[];
    for (final routine in _routines) {
      tasks.addAll(routine.tasksOn(date));
    }
    return tasks;
  }

  bool isTaskCompleted(String taskId, DateTime date) =>
      _completedKeys.contains(_completionKey(taskId, date));

  Future<void> toggleTaskCompleted(String taskId, DateTime date) async {
    final key = _completionKey(taskId, date);
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
      for (final task in routine.tasks) {
        _completedKeys.removeWhere((k) => k.startsWith('${task.id}|'));
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

  Future<RoutineTask> addTask(
    String routineId,
    String title, {
    String? description,
    int minDurationMinutes = 0,
    int maxDurationMinutes = 0,
    String? durationNote,
    required List<Schedule> schedules,
  }) async {
    for (final schedule in schedules) {
      schedule.validate();
    }
    final routineIndex = _indexOfRoutine(routineId);
    if (routineIndex < 0) {
      throw ArgumentError('Routine not found: $routineId');
    }
    final task = RoutineTask(
      id: _newId(),
      title: title,
      description: description,
      minDurationMinutes: minDurationMinutes,
      maxDurationMinutes: maxDurationMinutes,
      durationNote: durationNote,
      schedules: schedules,
    );
    final routine = _routines[routineIndex];
    _routines[routineIndex] = routine.copyWith(tasks: [...routine.tasks, task]);
    await _save();
    notifyListeners();
    return task;
  }

  Future<void> updateTask(
    String routineId,
    RoutineTask task, {
    String? title,
    String? description,
    int? minDurationMinutes,
    int? maxDurationMinutes,
    String? durationNote,
    List<Schedule>? schedules,
  }) async {
    final schedulesToValidate = schedules ?? task.schedules;
    for (final schedule in schedulesToValidate) {
      schedule.validate();
    }
    final routineIndex = _indexOfRoutine(routineId);
    if (routineIndex < 0) {
      throw ArgumentError('Routine not found: $routineId');
    }
    final routine = _routines[routineIndex];
    final taskIndex = routine.tasks.indexWhere((t) => t.id == task.id);
    if (taskIndex < 0) {
      throw ArgumentError('Task not found: ${task.id}');
    }
    final tasks = [...routine.tasks];
    tasks[taskIndex] = task.copyWith(
      title: title,
      description: description,
      minDurationMinutes: minDurationMinutes,
      maxDurationMinutes: maxDurationMinutes,
      durationNote: durationNote,
      schedules: schedules,
    );
    _routines[routineIndex] = routine.copyWith(tasks: tasks);
    await _save();
    notifyListeners();
  }

  Future<void> removeTask(String routineId, String taskId) async {
    final routineIndex = _indexOfRoutine(routineId);
    if (routineIndex < 0) {
      throw ArgumentError('Routine not found: $routineId');
    }
    final routine = _routines[routineIndex];
    _routines[routineIndex] = routine.copyWith(
      tasks: routine.tasks.where((t) => t.id != taskId).toList(),
    );
    _completedKeys.removeWhere((k) => k.startsWith('$taskId|'));
    await _save();
    notifyListeners();
  }

  Future<void> moveTask(
    String routineId,
    int oldIndex,
    int newIndex,
  ) async {
    final routineIndex = _indexOfRoutine(routineId);
    if (routineIndex < 0) {
      throw ArgumentError('Routine not found: $routineId');
    }
    final tasks = [..._routines[routineIndex].tasks];
    if (oldIndex < 0 ||
        oldIndex >= tasks.length ||
        newIndex < 0 ||
        newIndex >= tasks.length) {
      throw RangeError('Invalid task index');
    }
    final task = tasks.removeAt(oldIndex);
    tasks.insert(newIndex, task);
    _routines[routineIndex] = _routines[routineIndex].copyWith(tasks: tasks);
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
      for (final task in routine.tasks) {
        for (final schedule in task.schedules) {
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

  static String _completionKey(String taskId, DateTime date) =>
      '$taskId|${_dateString(date)}';

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
