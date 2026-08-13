import 'package:ddx_routine/models/routine.dart';
import 'package:ddx_routine/models/schedule.dart';
import 'package:ddx_routine/models/weekday.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TaskGroup makeGroup(String id, Set<Weekday> days, {String taskName = 'X'}) {
    return TaskGroup(
      id: id,
      schedules: [
        Schedule(
          frequency: ScheduleFrequency.weekly,
          days: days,
        ),
      ],
      tasks: [Task(id: '${id}_i0', name: taskName)],
    );
  }

  group('Routine.groupsOn order', () {
    final routine = Routine(
      id: 'r1',
      name: 'Morning',
      groups: [
        makeGroup('a', {Weekday.monday}),
        makeGroup('b', {Weekday.monday}),
        makeGroup('c', {Weekday.tuesday}),
        makeGroup('d', {Weekday.monday}),
      ],
    );

    test('preserves saved group order for a given date', () {
      final monday = DateTime(2026, 8, 3);
      expect(
        routine.groupsOn(monday).map((g) => g.id).toList(),
        ['a', 'b', 'd'],
      );
    });

    test('reflects a reordered group list', () {
      final reordered =
          routine.copyWith(groups: routine.groups.reversed.toList());

      final monday = DateTime(2026, 8, 3);
      expect(
        reordered.groupsOn(monday).map((g) => g.id).toList(),
        ['d', 'b', 'a'],
      );
    });
  });

  group('Task.durationLabel', () {
    Task make({
      int min = 0,
      int max = 0,
      String? note,
    }) {
      return Task(
        id: 'i',
        name: 'T',
        minDurationMinutes: min,
        maxDurationMinutes: max,
        durationNote: note,
      );
    }

    test('is null when no duration and no note', () {
      expect(make().durationLabel, isNull);
      expect(make(min: 0, max: 0, note: '  ').durationLabel, isNull);
    });

    test('shows a single value when min equals max', () {
      expect(make(min: 30, max: 30).durationLabel, '~30 min');
    });

    test('shows a range when max exceeds min', () {
      expect(make(min: 15, max: 30).durationLabel, '15–30 min');
    });

    test('appends the note when present', () {
      expect(
        make(min: 10, max: 10, note: 'after lunch').durationLabel,
        '~10 min · after lunch',
      );
      expect(
        make(min: 15, max: 30, note: 'optional').durationLabel,
        '15–30 min · optional',
      );
    });

    test('shows only the note when duration is zero', () {
      expect(make(note: 'as needed').durationLabel, 'as needed');
    });
  });

  group('Task JSON', () {
    test('round-trips name, description, and durations', () {
      final task = Task(
        id: 'i1',
        name: 'Gym',
        description: 'light day',
        minDurationMinutes: 20,
        maxDurationMinutes: 45,
        durationNote: 'optional',
      );
      final restored = Task.fromJson(task.toJson());
      expect(restored.id, 'i1');
      expect(restored.name, 'Gym');
      expect(restored.description, 'light day');
      expect(restored.minDurationMinutes, 20);
      expect(restored.maxDurationMinutes, 45);
      expect(restored.durationNote, 'optional');
    });

    test('maps a legacy durationMinutes to min and max', () {
      final restored = Task.fromJson({
        'id': 'i1',
        'name': 'Gym',
        'durationMinutes': 30,
      });
      expect(restored.minDurationMinutes, 30);
      expect(restored.maxDurationMinutes, 30);
      expect(restored.durationNote, isNull);
    });
  });

  group('TaskGroup schedules', () {
    final taskGroup = TaskGroup(
      id: 't1',
      schedules: [
        Schedule(
          frequency: ScheduleFrequency.daily,
          interval: 2,
          anchor: DateTime(2026, 8, 10),
        ),
        Schedule(
          frequency: ScheduleFrequency.weekly,
          days: {Weekday.saturday},
        ),
      ],
      tasks: const [Task(id: 'i1', name: 'Stretch')],
    );

    test('occursOn is true when any schedule matches', () {
      expect(taskGroup.occursOn(DateTime(2026, 8, 8)), isTrue); // Saturday rule
      expect(taskGroup.occursOn(DateTime(2026, 8, 10)), isTrue); // every-other-day
      expect(taskGroup.occursOn(DateTime(2026, 8, 12)), isTrue); // every-other-day
      expect(taskGroup.occursOn(DateTime(2026, 8, 15)), isTrue); // Saturday rule
      expect(taskGroup.occursOn(DateTime(2026, 8, 9)), isFalse);
      expect(taskGroup.occursOn(DateTime(2026, 8, 11)), isFalse);
    });

    test('scheduleSummary joins all schedule summaries', () {
      expect(taskGroup.scheduleSummary, 'Every 2 days · Sat');
    });

    test('JSON round-trips schedules and tasks', () {
      final restored = TaskGroup.fromJson(taskGroup.toJson());
      expect(restored.schedules.length, 2);
      expect(restored.schedules[0].frequency, ScheduleFrequency.daily);
      expect(restored.schedules[1].frequency, ScheduleFrequency.weekly);
      expect(restored.tasks.single.id, 'i1');
      expect(restored.tasks.single.name, 'Stretch');
      expect(restored.occursOn(DateTime(2026, 8, 8)), isTrue);
      expect(restored.occursOn(DateTime(2026, 8, 12)), isTrue);
      expect((taskGroup.toJson()['schedules'] as List).length, 2);
    });

    test('legacy single-schedule JSON loads as one schedule', () {
      final restored = TaskGroup.fromJson({
        'id': 't1',
        'title': 'T',
        'schedule': {'frequency': 'daily'},
      });
      expect(restored.schedules.length, 1);
      expect(restored.schedules.single.frequency, ScheduleFrequency.daily);
      expect(restored.occursOn(DateTime(2026, 8, 10)), isTrue);
    });
  });

  group('v6 migration', () {
    test('legacy title task migrates to a single task', () {
      final restored = TaskGroup.fromJson({
        'id': 't1',
        'title': 'Brush teeth',
        'description': 'two minutes',
        'durationMinutes': 2,
        'durationNote': 'after breakfast',
        'schedule': {'frequency': 'daily'},
      });

      expect(restored.tasks.length, 1);
      final task = restored.tasks.single;
      expect(task.id, 't1_i0');
      expect(task.name, 'Brush teeth');
      expect(task.description, 'two minutes');
      expect(task.minDurationMinutes, 2);
      expect(task.maxDurationMinutes, 2);
      expect(task.durationNote, 'after breakfast');
      expect(restored.schedules.single.frequency, ScheduleFrequency.daily);
    });

    test('new-format task groups keep their tasks untouched', () {
      final taskGroup = TaskGroup(
        id: 't1',
        schedules: [
          Schedule(
            frequency: ScheduleFrequency.weekly,
            days: {Weekday.monday},
          ),
        ],
        tasks: const [
          Task(id: 'i1', name: 'A'),
          Task(id: 'i2', name: 'B', minDurationMinutes: 10),
        ],
      );
      final restored = TaskGroup.fromJson(taskGroup.toJson());
      expect(restored.tasks.length, 2);
      expect(restored.tasks[0].id, 'i1');
      expect(restored.tasks[1].name, 'B');
      expect(restored.tasks[1].minDurationMinutes, 10);
    });
  });

  group('Routine totals', () {
    test('totalDurationMinutes sums all task max durations', () {
      final routine = Routine(
        id: 'r1',
        name: 'M',
        groups: [
          TaskGroup(
            id: 'a',
            tasks: const [
              Task(id: 'a1', name: 'A', maxDurationMinutes: 10),
              Task(id: 'a2', name: 'B', maxDurationMinutes: 20),
            ],
          ),
          TaskGroup(
            id: 'b',
            tasks: const [
              Task(id: 'b1', name: 'C', maxDurationMinutes: 5),
            ],
          ),
        ],
      );
      expect(routine.allTasks().length, 3);
      expect(routine.totalDurationMinutes, 35);
    });
  });
}
