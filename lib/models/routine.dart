import 'schedule.dart';
import 'weekday.dart';

class RoutineTask {
  final String id;
  final String title;
  final String? description;
  final int minDurationMinutes;
  final int maxDurationMinutes;
  final String? durationNote;
  final Schedule schedule;

  const RoutineTask({
    required this.id,
    required this.title,
    this.description,
    this.minDurationMinutes = 0,
    this.maxDurationMinutes = 0,
    this.durationNote,
    required this.schedule,
  });

  Duration get duration =>
      Duration(minutes: maxDurationMinutes > minDurationMinutes
          ? maxDurationMinutes
          : minDurationMinutes);

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

  RoutineTask copyWith({
    String? title,
    String? description,
    int? minDurationMinutes,
    int? maxDurationMinutes,
    String? durationNote,
    Schedule? schedule,
  }) {
    return RoutineTask(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      minDurationMinutes:
          minDurationMinutes ?? this.minDurationMinutes,
      maxDurationMinutes:
          maxDurationMinutes ?? this.maxDurationMinutes,
      durationNote: durationNote ?? this.durationNote,
      schedule: schedule ?? this.schedule,
    );
  }

  factory RoutineTask.fromJson(Map<String, dynamic> json) {
    final schedule = json['schedule'] != null
        ? Schedule.fromJson(json['schedule'] as Map<String, dynamic>)
        : Schedule(
            frequency: ScheduleFrequency.weekly,
            days: (json['days'] as List<dynamic>? ?? const [])
                .map((e) => Weekday.values.firstWhere(
                      (w) => w.name == e,
                      orElse: () => Weekday.monday,
                    ))
                .toSet(),
          );
    return RoutineTask(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      minDurationMinutes: json['minDurationMinutes'] as int? ??
          json['durationMinutes'] as int? ??
          0,
      maxDurationMinutes: json['maxDurationMinutes'] as int? ??
          json['durationMinutes'] as int? ??
          0,
      durationNote: json['durationNote'] as String?,
      schedule: schedule,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'minDurationMinutes': minDurationMinutes,
      'maxDurationMinutes': maxDurationMinutes,
      'durationNote': durationNote,
      'schedule': schedule.toJson(),
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

  int get totalDurationMinutes =>
      tasks.fold(0, (sum, task) => sum + task.maxDurationMinutes);

  int get taskCount => tasks.length;

  int taskCountOn(DateTime date) => tasksOn(date).length;

  List<RoutineTask> tasksOn(DateTime date) =>
      tasks.where((task) => task.schedule.occursOn(date)).toList();

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
