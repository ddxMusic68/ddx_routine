import 'schedule.dart';
import 'weekday.dart';

class TaskItem {
  final String id;
  final String name;
  final String? description;
  final int minDurationMinutes;
  final int maxDurationMinutes;
  final String? durationNote;

  const TaskItem({
    required this.id,
    required this.name,
    this.description,
    this.minDurationMinutes = 0,
    this.maxDurationMinutes = 0,
    this.durationNote,
  });

  String? get durationLabel {
    final note = durationNote?.trim();
    final base = maxDurationMinutes <= 0
        ? null
        : maxDurationMinutes == minDurationMinutes
            ? '~$maxDurationMinutes min'
            : '$minDurationMinutes–$maxDurationMinutes min';
    if (base == null) {
      return note == null || note.isEmpty ? null : note;
    }
    if (note == null || note.isEmpty) return base;
    return '$base · $note';
  }

  TaskItem copyWith({
    String? name,
    String? description,
    int? minDurationMinutes,
    int? maxDurationMinutes,
    String? durationNote,
  }) {
    return TaskItem(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      minDurationMinutes:
          minDurationMinutes ?? this.minDurationMinutes,
      maxDurationMinutes:
          maxDurationMinutes ?? this.maxDurationMinutes,
      durationNote: durationNote ?? this.durationNote,
    );
  }

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    return TaskItem(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      minDurationMinutes: json['minDurationMinutes'] as int? ??
          json['durationMinutes'] as int? ??
          0,
      maxDurationMinutes: json['maxDurationMinutes'] as int? ??
          json['durationMinutes'] as int? ??
          0,
      durationNote: json['durationNote'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'minDurationMinutes': minDurationMinutes,
      'maxDurationMinutes': maxDurationMinutes,
      'durationNote': durationNote,
    };
  }
}

class RoutineTask {
  final String id;
  final List<Schedule> schedules;
  final List<TaskItem> items;

  const RoutineTask({
    required this.id,
    this.schedules = const [],
    this.items = const [],
  });

  bool occursOn(DateTime date) =>
      schedules.any((schedule) => schedule.occursOn(date));

  String? get scheduleSummary {
    final summaries = schedules.map((s) => s.summary).toList();
    if (summaries.isEmpty) return null;
    return summaries.join(' · ');
  }

  RoutineTask copyWith({
    List<Schedule>? schedules,
    List<TaskItem>? items,
  }) {
    return RoutineTask(
      id: id,
      schedules: schedules ?? this.schedules,
      items: items ?? this.items,
    );
  }

  factory RoutineTask.fromJson(Map<String, dynamic> json) {
    final schedulesRaw = json['schedules'];
    List<Schedule> schedules;
    if (schedulesRaw is List) {
      schedules = schedulesRaw
          .map((e) => Schedule.fromJson(e as Map<String, dynamic>))
          .toList();
    } else if (json['schedule'] != null) {
      schedules = [
        Schedule.fromJson(json['schedule'] as Map<String, dynamic>),
      ];
    } else {
      schedules = [
        Schedule(
          frequency: ScheduleFrequency.weekly,
          days: (json['days'] as List<dynamic>? ?? const [])
              .map((e) => Weekday.values.firstWhere(
                    (w) => w.name == e,
                    orElse: () => Weekday.monday,
                  ))
              .toSet(),
        ),
      ];
    }

    final itemsRaw = json['items'];
    List<TaskItem> items;
    if (itemsRaw is List) {
      items = itemsRaw
          .map((e) => TaskItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      items = [
        TaskItem(
          id: '${json['id']}_i0',
          name: json['title'] as String? ?? '',
          description: json['description'] as String?,
          minDurationMinutes: json['minDurationMinutes'] as int? ??
              json['durationMinutes'] as int? ??
              0,
          maxDurationMinutes: json['maxDurationMinutes'] as int? ??
              json['durationMinutes'] as int? ??
              0,
          durationNote: json['durationNote'] as String?,
        ),
      ];
    }

    return RoutineTask(
      id: json['id'] as String,
      schedules: schedules,
      items: items,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'schedules': schedules.map((s) => s.toJson()).toList(),
      'items': items.map((i) => i.toJson()).toList(),
    };
  }
}

class Routine {
  final String id;
  final String name;
  final List<RoutineTask> tasks;

  const Routine({
    required this.id,
    required this.name,
    this.tasks = const [],
  });

  int get totalDurationMinutes => allItems().fold(
      0, (sum, item) => sum + item.maxDurationMinutes);

  int get taskCount => tasks.length;

  List<TaskItem> allItems() =>
      [for (final task in tasks) ...task.items];

  int taskCountOn(DateTime date) => tasksOn(date).length;

  List<RoutineTask> tasksOn(DateTime date) =>
      tasks.where((task) => task.occursOn(date)).toList();

  Routine copyWith({String? name, List<RoutineTask>? tasks}) {
    return Routine(
      id: id,
      name: name ?? this.name,
      tasks: tasks ?? this.tasks,
    );
  }

  factory Routine.fromJson(Map<String, dynamic> json) {
    return Routine(
      id: json['id'] as String,
      name: json['name'] as String,
      tasks: (json['tasks'] as List<dynamic>? ?? const [])
          .map((e) => RoutineTask.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'tasks': tasks.map((t) => t.toJson()).toList(),
    };
  }
}
