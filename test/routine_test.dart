import 'package:ddx_routine/models/routine.dart';
import 'package:ddx_routine/models/schedule.dart';
import 'package:ddx_routine/models/weekday.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Routine.tasksOn order', () {
    RoutineTask task(String id, String title, Set<Weekday> days) {
      return RoutineTask(
        id: id,
        title: title,
        schedule: Schedule(
          frequency: ScheduleFrequency.weekly,
          days: days,
        ),
      );
    }

    test('preserves saved task order for a given date', () {
      final routine = Routine(
        id: 'r1',
        name: 'Morning',
        tasks: [
          task('a', 'A', {Weekday.monday}),
          task('b', 'B', {Weekday.monday}),
          task('c', 'C', {Weekday.tuesday}),
          task('d', 'D', {Weekday.monday}),
        ],
      );

      final monday = DateTime(2026, 8, 3);
      expect(
        routine.tasksOn(monday).map((t) => t.id).toList(),
        ['a', 'b', 'd'],
      );
    });

    test('reflects a reordered task list', () {
      final original = Routine(
        id: 'r1',
        name: 'Morning',
        tasks: [
          task('a', 'A', {Weekday.monday}),
          task('b', 'B', {Weekday.monday}),
        ],
      );
      final reordered = original.copyWith(tasks: original.tasks.reversed.toList());

      final monday = DateTime(2026, 8, 3);
      expect(
        reordered.tasksOn(monday).map((t) => t.id).toList(),
        ['b', 'a'],
      );
    });
  });

  group('RoutineTask.durationLabel', () {
    RoutineTask make({
      int min = 0,
      int max = 0,
      String? note,
    }) {
      return RoutineTask(
        id: 't',
        title: 'T',
        minDurationMinutes: min,
        maxDurationMinutes: max,
        durationNote: note,
        schedule: Schedule(
          frequency: ScheduleFrequency.daily,
        ),
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

  group('RoutineTask JSON', () {
    test('round-trips min/max duration and note', () {
      final task = RoutineTask(
        id: 't1',
        title: 'Gym',
        minDurationMinutes: 20,
        maxDurationMinutes: 45,
        durationNote: 'light day',
        schedule: Schedule(
          frequency: ScheduleFrequency.daily,
        ),
      );
      final restored = RoutineTask.fromJson(task.toJson());
      expect(restored.minDurationMinutes, 20);
      expect(restored.maxDurationMinutes, 45);
      expect(restored.durationNote, 'light day');
    });

    test('maps a legacy durationMinutes to min and max', () {
      final restored = RoutineTask.fromJson({
        'id': 't1',
        'title': 'Gym',
        'durationMinutes': 30,
        'schedule': {
          'frequency': 'daily',
        },
      });
      expect(restored.minDurationMinutes, 30);
      expect(restored.maxDurationMinutes, 30);
      expect(restored.durationNote, isNull);
    });
  });
}
