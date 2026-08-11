import 'package:ddx_routine/models/routine.dart';
import 'package:ddx_routine/models/schedule.dart';
import 'package:ddx_routine/models/weekday.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  RoutineTask task(String id, Set<Weekday> days, {String itemName = 'X'}) {
    return RoutineTask(
      id: id,
      schedules: [
        Schedule(
          frequency: ScheduleFrequency.weekly,
          days: days,
        ),
      ],
      items: [TaskItem(id: '${id}_i0', name: itemName)],
    );
  }

  group('Routine.tasksOn order', () {
    final routine = Routine(
      id: 'r1',
      name: 'Morning',
      tasks: [
        task('a', {Weekday.monday}),
        task('b', {Weekday.monday}),
        task('c', {Weekday.tuesday}),
        task('d', {Weekday.monday}),
      ],
    );

    test('preserves saved task order for a given date', () {
      final monday = DateTime(2026, 8, 3);
      expect(
        routine.tasksOn(monday).map((t) => t.id).toList(),
        ['a', 'b', 'd'],
      );
    });

    test('reflects a reordered task list', () {
      final reordered = routine.copyWith(tasks: routine.tasks.reversed.toList());

      final monday = DateTime(2026, 8, 3);
      expect(
        reordered.tasksOn(monday).map((t) => t.id).toList(),
        ['d', 'b', 'a'],
      );
    });
  });

  group('TaskItem.durationLabel', () {
    TaskItem make({
      int min = 0,
      int max = 0,
      String? note,
    }) {
      return TaskItem(
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

  group('TaskItem JSON', () {
    test('round-trips name, description, and durations', () {
      final item = TaskItem(
        id: 'i1',
        name: 'Gym',
        description: 'light day',
        minDurationMinutes: 20,
        maxDurationMinutes: 45,
        durationNote: 'optional',
      );
      final restored = TaskItem.fromJson(item.toJson());
      expect(restored.id, 'i1');
      expect(restored.name, 'Gym');
      expect(restored.description, 'light day');
      expect(restored.minDurationMinutes, 20);
      expect(restored.maxDurationMinutes, 45);
      expect(restored.durationNote, 'optional');
    });

    test('maps a legacy durationMinutes to min and max', () {
      final restored = TaskItem.fromJson({
        'id': 'i1',
        'name': 'Gym',
        'durationMinutes': 30,
      });
      expect(restored.minDurationMinutes, 30);
      expect(restored.maxDurationMinutes, 30);
      expect(restored.durationNote, isNull);
    });
  });

  group('RoutineTask schedules', () {
    final task = RoutineTask(
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
      items: const [TaskItem(id: 'i1', name: 'Stretch')],
    );

    test('occursOn is true when any schedule matches', () {
      expect(task.occursOn(DateTime(2026, 8, 8)), isTrue); // Saturday rule
      expect(task.occursOn(DateTime(2026, 8, 10)), isTrue); // every-other-day
      expect(task.occursOn(DateTime(2026, 8, 12)), isTrue); // every-other-day
      expect(task.occursOn(DateTime(2026, 8, 15)), isTrue); // Saturday rule
      expect(task.occursOn(DateTime(2026, 8, 9)), isFalse);
      expect(task.occursOn(DateTime(2026, 8, 11)), isFalse);
    });

    test('scheduleSummary joins all schedule summaries', () {
      expect(task.scheduleSummary, 'Every 2 days · Sat');
    });

    test('JSON round-trips schedules and items', () {
      final restored = RoutineTask.fromJson(task.toJson());
      expect(restored.schedules.length, 2);
      expect(restored.schedules[0].frequency, ScheduleFrequency.daily);
      expect(restored.schedules[1].frequency, ScheduleFrequency.weekly);
      expect(restored.items.single.id, 'i1');
      expect(restored.items.single.name, 'Stretch');
      expect(restored.occursOn(DateTime(2026, 8, 8)), isTrue);
      expect(restored.occursOn(DateTime(2026, 8, 12)), isTrue);
      expect((task.toJson()['schedules'] as List).length, 2);
    });

    test('legacy single-schedule JSON loads as one schedule', () {
      final restored = RoutineTask.fromJson({
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
    test('legacy title task migrates to a single item', () {
      final restored = RoutineTask.fromJson({
        'id': 't1',
        'title': 'Brush teeth',
        'description': 'two minutes',
        'durationMinutes': 2,
        'durationNote': 'after breakfast',
        'schedule': {'frequency': 'daily'},
      });

      expect(restored.items.length, 1);
      final item = restored.items.single;
      expect(item.id, 't1_i0');
      expect(item.name, 'Brush teeth');
      expect(item.description, 'two minutes');
      expect(item.minDurationMinutes, 2);
      expect(item.maxDurationMinutes, 2);
      expect(item.durationNote, 'after breakfast');
      expect(restored.schedules.single.frequency, ScheduleFrequency.daily);
    });

    test('new-format tasks keep their items untouched', () {
      final task = RoutineTask(
        id: 't1',
        schedules: [
          Schedule(
            frequency: ScheduleFrequency.weekly,
            days: {Weekday.monday},
          ),
        ],
        items: const [
          TaskItem(id: 'i1', name: 'A'),
          TaskItem(id: 'i2', name: 'B', minDurationMinutes: 10),
        ],
      );
      final restored = RoutineTask.fromJson(task.toJson());
      expect(restored.items.length, 2);
      expect(restored.items[0].id, 'i1');
      expect(restored.items[1].name, 'B');
      expect(restored.items[1].minDurationMinutes, 10);
    });
  });

  group('Routine totals', () {
    test('totalDurationMinutes sums all item max durations', () {
      final routine = Routine(
        id: 'r1',
        name: 'M',
        tasks: [
          RoutineTask(
            id: 'a',
            items: const [
              TaskItem(id: 'a1', name: 'A', maxDurationMinutes: 10),
              TaskItem(id: 'a2', name: 'B', maxDurationMinutes: 20),
            ],
          ),
          RoutineTask(
            id: 'b',
            items: const [
              TaskItem(id: 'b1', name: 'C', maxDurationMinutes: 5),
            ],
          ),
        ],
      );
      expect(routine.allItems().length, 3);
      expect(routine.totalDurationMinutes, 35);
    });
  });
}
