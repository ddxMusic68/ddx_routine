import 'package:ddx_routine/models/routine.dart';
import 'package:ddx_routine/models/schedule.dart';
import 'package:ddx_routine/models/weekday.dart';
import 'package:flutter_test/flutter_test.dart';

DateTime d(int year, int month, int day) => DateTime(year, month, day);

void main() {
  group('Schedule.occursOn', () {
    test('daily interval 1 occurs every day', () {
      final schedule = Schedule(frequency: ScheduleFrequency.daily);
      expect(schedule.occursOn(d(2026, 8, 3)), isTrue);
      expect(schedule.occursOn(d(2026, 8, 4)), isTrue);
      expect(schedule.occursOn(d(2026, 12, 31)), isTrue);
    });

    test('every N days runs from the anchor', () {
      final schedule = Schedule(
        frequency: ScheduleFrequency.daily,
        interval: 3,
        anchor: d(2026, 8, 3),
      );
      expect(schedule.occursOn(d(2026, 8, 3)), isTrue);
      expect(schedule.occursOn(d(2026, 8, 4)), isFalse);
      expect(schedule.occursOn(d(2026, 8, 5)), isFalse);
      expect(schedule.occursOn(d(2026, 8, 6)), isTrue);
      expect(schedule.occursOn(d(2026, 8, 9)), isTrue);
    });

    test('every N days does not occur before the anchor', () {
      final schedule = Schedule(
        frequency: ScheduleFrequency.daily,
        interval: 2,
        anchor: d(2026, 8, 3),
      );
      expect(schedule.occursOn(d(2026, 8, 2)), isFalse);
    });

    test('weekly interval 1 runs on listed days every week', () {
      final schedule = Schedule(
        frequency: ScheduleFrequency.weekly,
        days: {Weekday.monday, Weekday.friday},
      );
      expect(schedule.occursOn(d(2026, 8, 3)), isTrue); // Monday
      expect(schedule.occursOn(d(2026, 8, 7)), isTrue); // Friday
      expect(schedule.occursOn(d(2026, 8, 10)), isTrue); // next Monday
      expect(schedule.occursOn(d(2026, 8, 4)), isFalse); // Tuesday
      expect(schedule.occursOn(d(2026, 8, 8)), isFalse); // Saturday
    });

    test('bi-weekly alternates weeks from the anchor', () {
      final schedule = Schedule(
        frequency: ScheduleFrequency.weekly,
        interval: 2,
        anchor: d(2026, 8, 3), // Monday
        days: {Weekday.monday, Weekday.wednesday},
      );
      expect(schedule.occursOn(d(2026, 8, 3)), isTrue); // anchor week Mon
      expect(schedule.occursOn(d(2026, 8, 5)), isTrue); // anchor week Wed
      expect(schedule.occursOn(d(2026, 8, 10)), isFalse); // off week
      expect(schedule.occursOn(d(2026, 8, 12)), isFalse);
      expect(schedule.occursOn(d(2026, 8, 17)), isTrue); // on week again
      expect(schedule.occursOn(d(2026, 8, 19)), isTrue);
    });

    test('bi-weekly counts the week containing a midweek anchor', () {
      final schedule = Schedule(
        frequency: ScheduleFrequency.weekly,
        interval: 2,
        anchor: d(2026, 8, 5), // Wednesday
        days: {Weekday.monday},
      );
      expect(schedule.occursOn(d(2026, 8, 3)), isTrue); // Mon of anchor week
      expect(schedule.occursOn(d(2026, 8, 10)), isFalse);
      expect(schedule.occursOn(d(2026, 8, 17)), isTrue);
    });

    test('recurring weekly does not occur before the anchor', () {
      final schedule = Schedule(
        frequency: ScheduleFrequency.weekly,
        interval: 2,
        anchor: d(2026, 8, 3),
        days: {Weekday.monday},
      );
      expect(schedule.occursOn(d(2026, 7, 27)), isFalse);
    });

    test('monthly interval 1 runs on the same day each month', () {
      final schedule = Schedule(
        frequency: ScheduleFrequency.monthly,
        dayOfMonth: 15,
      );
      expect(schedule.occursOn(d(2026, 8, 15)), isTrue);
      expect(schedule.occursOn(d(2026, 9, 15)), isTrue);
      expect(schedule.occursOn(d(2026, 9, 14)), isFalse);
    });

    test('quarterly runs every 3 months from the anchor', () {
      final schedule = Schedule(
        frequency: ScheduleFrequency.monthly,
        interval: 3,
        anchor: d(2026, 8, 15),
        dayOfMonth: 15,
      );
      expect(schedule.occursOn(d(2026, 8, 15)), isTrue);
      expect(schedule.occursOn(d(2026, 9, 15)), isFalse);
      expect(schedule.occursOn(d(2026, 10, 15)), isFalse);
      expect(schedule.occursOn(d(2026, 11, 15)), isTrue);
      expect(schedule.occursOn(d(2026, 12, 15)), isFalse);
    });

    test('monthly clamps day 31 to the last day of shorter months', () {
      final schedule = Schedule(
        frequency: ScheduleFrequency.monthly,
        dayOfMonth: 31,
      );
      expect(schedule.occursOn(d(2026, 5, 31)), isTrue);
      expect(schedule.occursOn(d(2026, 4, 30)), isTrue); // April
      expect(schedule.occursOn(d(2026, 4, 29)), isFalse);
    });

    test('yearly runs on the same month and day each year', () {
      final schedule = Schedule(
        frequency: ScheduleFrequency.yearly,
        month: 2,
        dayOfMonth: 14,
      );
      expect(schedule.occursOn(d(2026, 2, 14)), isTrue);
      expect(schedule.occursOn(d(2027, 2, 14)), isTrue);
      expect(schedule.occursOn(d(2026, 2, 15)), isFalse);
      expect(schedule.occursOn(d(2026, 3, 14)), isFalse);
    });

    test('yearly interval 2 skips every other year', () {
      final schedule = Schedule(
        frequency: ScheduleFrequency.yearly,
        interval: 2,
        anchor: d(2026, 2, 14),
        month: 2,
        dayOfMonth: 14,
      );
      expect(schedule.occursOn(d(2026, 2, 14)), isTrue);
      expect(schedule.occursOn(d(2027, 2, 14)), isFalse);
      expect(schedule.occursOn(d(2028, 2, 14)), isTrue);
    });

    test('yearly Feb 29 clamps to Feb 28 on non-leap years', () {
      final schedule = Schedule(
        frequency: ScheduleFrequency.yearly,
        month: 2,
        dayOfMonth: 29,
      );
      expect(schedule.occursOn(d(2028, 2, 29)), isTrue); // leap
      expect(schedule.occursOn(d(2026, 2, 28)), isTrue); // clamped
    });
  });

  group('Schedule.summary', () {
    test('formats each frequency', () {
      expect(
        Schedule(frequency: ScheduleFrequency.daily).summary,
        'Every day',
      );
      expect(
        Schedule(frequency: ScheduleFrequency.daily, interval: 2).summary,
        'Every 2 days',
      );
      expect(
        Schedule(
          frequency: ScheduleFrequency.weekly,
          days: {Weekday.monday, Weekday.wednesday},
        ).summary,
        'Mon · Wed',
      );
      expect(
        Schedule(
          frequency: ScheduleFrequency.weekly,
          interval: 2,
          days: {Weekday.monday},
        ).summary,
        'Every 2 weeks: Mon',
      );
      expect(
        Schedule(frequency: ScheduleFrequency.monthly, dayOfMonth: 15).summary,
        'Monthly on the 15th',
      );
      expect(
        Schedule(
          frequency: ScheduleFrequency.monthly,
          interval: 3,
          dayOfMonth: 1,
        ).summary,
        'Every 3 months on the 1st',
      );
      expect(
        Schedule(
          frequency: ScheduleFrequency.yearly,
          month: 2,
          dayOfMonth: 14,
        ).summary,
        'Every year on Feb 14th',
      );
    });
  });

  group('Schedule JSON', () {
    test('round-trips a recurring weekly schedule', () {
      final schedule = Schedule(
        frequency: ScheduleFrequency.weekly,
        interval: 2,
        anchor: d(2026, 8, 3),
        days: {Weekday.monday, Weekday.friday},
      );
      final decoded =
          Schedule.fromJson(schedule.toJson());
      expect(decoded.frequency, ScheduleFrequency.weekly);
      expect(decoded.interval, 2);
      expect(decoded.anchor, d(2026, 8, 3));
      expect(decoded.days, {Weekday.monday, Weekday.friday});
    });

    test('round-trips a yearly schedule', () {
      final schedule = Schedule(
        frequency: ScheduleFrequency.yearly,
        month: 2,
        dayOfMonth: 14,
      );
      final decoded = Schedule.fromJson(schedule.toJson());
      expect(decoded.frequency, ScheduleFrequency.yearly);
      expect(decoded.month, 2);
      expect(decoded.dayOfMonth, 14);
    });
  });

  group('v1 migration', () {
    test('legacy days-only task migrates to weekly interval 1', () {
      final task = RoutineTask.fromJson({
        'id': 't1',
        'title': 'Legacy',
        'days': ['monday', 'friday'],
      });
      expect(task.schedule.frequency, ScheduleFrequency.weekly);
      expect(task.schedule.interval, 1);
      expect(task.schedule.days, {Weekday.monday, Weekday.friday});
      expect(task.schedule.occursOn(d(2026, 8, 3)), isTrue);
      expect(task.schedule.occursOn(d(2026, 8, 7)), isTrue);
    });
  });

  group('Schedule.validate', () {
    test('rejects a weekly schedule with no days', () {
      expect(
        () => Schedule(frequency: ScheduleFrequency.weekly).validate(),
        throwsArgumentError,
      );
    });

    test('rejects a monthly schedule without a valid day', () {
      expect(
        () => Schedule(frequency: ScheduleFrequency.monthly).validate(),
        throwsArgumentError,
      );
    });

    test('accepts a valid yearly schedule', () {
      expect(
        () => Schedule(
          frequency: ScheduleFrequency.yearly,
          month: 2,
          dayOfMonth: 14,
        ).validate(),
        returnsNormally,
      );
    });
  });
}
