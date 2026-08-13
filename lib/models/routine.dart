import 'schedule.dart';
import 'weekday.dart';

class Task {
  final String id;
  final String name;
  final String? description;
  final int minDurationMinutes;
  final int maxDurationMinutes;
  final String? durationNote;

  const Task({
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

  Task copyWith({
    String? name,
    String? description,
    int? minDurationMinutes,
    int? maxDurationMinutes,
    String? durationNote,
  }) {
    return Task(
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

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
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

class TaskGroup {
  final String id;
  final List<Schedule> schedules;
  final List<Task> tasks;

  const TaskGroup({
    required this.id,
    this.schedules = const [],
    this.tasks = const [],
  });

  bool occursOn(DateTime date) =>
      schedules.any((schedule) => schedule.occursOn(date));

  String? get scheduleSummary {
    final summaries = schedules.map((s) => s.summary).toList();
    if (summaries.isEmpty) return null;
    return summaries.join(' · ');
  }

  TaskGroup copyWith({
    List<Schedule>? schedules,
    List<Task>? tasks,
  }) {
    return TaskGroup(
      id: id,
      schedules: schedules ?? this.schedules,
      tasks: tasks ?? this.tasks,
    );
  }

  factory TaskGroup.fromJson(Map<String, dynamic> json) {
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
    List<Task> tasks;
    if (itemsRaw is List) {
      tasks = itemsRaw
          .map((e) => Task.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      tasks = [
        Task(
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

    return TaskGroup(
      id: json['id'] as String,
      schedules: schedules,
      tasks: tasks,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'schedules': schedules.map((s) => s.toJson()).toList(),
      'items': tasks.map((t) => t.toJson()).toList(),
    };
  }
}

class Routine {
  final String id;
  final String name;
  final List<TaskGroup> groups;

  const Routine({
    required this.id,
    required this.name,
    this.groups = const [],
  });

  int get totalDurationMinutes => allTasks().fold(
      0, (sum, task) => sum + task.maxDurationMinutes);

  int get groupCount => groups.length;

  List<Task> allTasks() =>
      [for (final group in groups) ...group.tasks];

  int groupCountOn(DateTime date) => groupsOn(date).length;

  List<TaskGroup> groupsOn(DateTime date) =>
      groups.where((group) => group.occursOn(date)).toList();

  Routine copyWith({String? name, List<TaskGroup>? groups}) {
    return Routine(
      id: id,
      name: name ?? this.name,
      groups: groups ?? this.groups,
    );
  }

  factory Routine.fromJson(Map<String, dynamic> json) {
    return Routine(
      id: json['id'] as String,
      name: json['name'] as String,
      groups: (json['tasks'] as List<dynamic>? ?? const [])
          .map((e) => TaskGroup.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'tasks': groups.map((t) => t.toJson()).toList(),
    };
  }
}
