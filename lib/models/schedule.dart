import 'weekday.dart';

enum ScheduleFrequency { daily, weekly, monthly, yearly }

class Schedule {
  final ScheduleFrequency frequency;
  final int interval;
  final DateTime? anchor;
  final Set<Weekday> days;
  final int? dayOfMonth;
  final int? month;

  const Schedule({
    required this.frequency,
    this.interval = 1,
    this.anchor,
    this.days = const {},
    this.dayOfMonth,
    this.month,
  });

  bool get isRecurring => interval > 1;

  void validate() {
    if (interval < 1) {
      throw ArgumentError('Interval must be at least 1');
    }
    switch (frequency) {
      case ScheduleFrequency.daily:
        break;
      case ScheduleFrequency.weekly:
        if (days.isEmpty) {
          throw ArgumentError('Weekly schedule requires at least one day');
        }
        break;
      case ScheduleFrequency.monthly:
        if (dayOfMonth == null || dayOfMonth! < 1 || dayOfMonth! > 31) {
          throw ArgumentError(
            'Monthly schedule requires a day of the month (1-31)',
          );
        }
        break;
      case ScheduleFrequency.yearly:
        if (month == null || month! < 1 || month! > 12) {
          throw ArgumentError('Yearly schedule requires a month (1-12)');
        }
        if (dayOfMonth == null || dayOfMonth! < 1 || dayOfMonth! > 31) {
          throw ArgumentError(
            'Yearly schedule requires a day of the month (1-31)',
          );
        }
        break;
    }
  }

  bool occursOn(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    switch (frequency) {
      case ScheduleFrequency.daily:
        if (interval <= 1) return true;
        final a = _anchor();
        if (d.isBefore(a)) return false;
        return _daysBetween(a, d) % interval == 0;
      case ScheduleFrequency.weekly:
        if (!days.contains(_weekdayOf(d))) return false;
        if (interval <= 1) return true;
        final a = _anchor();
        if (_mondayOf(d).isBefore(_mondayOf(a))) return false;
        return _weeksSince(a, d) % interval == 0;
      case ScheduleFrequency.monthly:
        final target = _clampDay(d.year, d.month, dayOfMonth ?? 1);
        if (d.day != target) return false;
        if (interval <= 1) return true;
        final a = _anchor();
        if (d.isBefore(a)) return false;
        final monthDiff = (d.year - a.year) * 12 + (d.month - a.month);
        return monthDiff % interval == 0;
      case ScheduleFrequency.yearly:
        if (d.month != month) return false;
        final target = _clampDay(d.year, d.month, dayOfMonth ?? 1);
        if (d.day != target) return false;
        if (interval <= 1) return true;
        final a = _anchor();
        if (d.isBefore(a)) return false;
        return (d.year - a.year) % interval == 0;
    }
  }

  String get summary {
    switch (frequency) {
      case ScheduleFrequency.daily:
        return interval > 1 ? 'Every $interval days' : 'Every day';
      case ScheduleFrequency.weekly:
        final dayList = days.map((d) => d.label).join(' · ');
        return interval > 1 ? 'Every $interval weeks: $dayList' : dayList;
      case ScheduleFrequency.monthly:
        final day = _ordinal(dayOfMonth ?? 1);
        return interval > 1
            ? 'Every $interval months on the $day'
            : 'Monthly on the $day';
      case ScheduleFrequency.yearly:
        final day = _ordinal(dayOfMonth ?? 1);
        final name = _monthNames[month == null ? 0 : month! - 1];
        return interval > 1
            ? 'Every $interval years on $name $day'
            : 'Every year on $name $day';
    }
  }

  DateTime _anchor() {
    final a = anchor;
    if (a != null) return DateTime(a.year, a.month, a.day);
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  factory Schedule.fromJson(Map<String, dynamic> json) {
    final frequency = ScheduleFrequency.values.firstWhere(
      (f) => f.name == json['frequency'],
      orElse: () => ScheduleFrequency.weekly,
    );
    final anchorRaw = json['anchor'] as String?;
    return Schedule(
      frequency: frequency,
      interval: json['interval'] as int? ?? 1,
      anchor: anchorRaw == null ? null : DateTime.parse(anchorRaw),
      days: (json['days'] as List<dynamic>? ?? const [])
          .map((e) => Weekday.values.firstWhere(
                (w) => w.name == e,
                orElse: () => Weekday.monday,
              ))
          .toSet(),
      dayOfMonth: json['dayOfMonth'] as int?,
      month: json['month'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'frequency': frequency.name,
      'interval': interval,
      'anchor': anchor == null
          ? null
          : _dateString(anchor!),
      if (frequency == ScheduleFrequency.weekly)
        'days': days.map((w) => w.name).toList(),
      if (frequency == ScheduleFrequency.monthly ||
          frequency == ScheduleFrequency.yearly)
        'dayOfMonth': dayOfMonth,
      if (frequency == ScheduleFrequency.yearly) 'month': month,
    };
  }

  static Weekday _weekdayOf(DateTime d) => Weekday.values[d.weekday - 1];

  static DateTime _mondayOf(DateTime d) {
    final offset = d.weekday - DateTime.monday;
    return DateTime(d.year, d.month, d.day - offset);
  }

  static int _daysBetween(DateTime a, DateTime b) {
    final au = DateTime.utc(a.year, a.month, a.day);
    final bu = DateTime.utc(b.year, b.month, b.day);
    return bu.difference(au).inDays;
  }

  static int _weeksSince(DateTime a, DateTime b) {
    final aMonday = _mondayOf(a);
    final bMonday = _mondayOf(b);
    return _daysBetween(aMonday, bMonday) ~/ 7;
  }

  static int _clampDay(int year, int month, int day) {
    final lastDay = DateTime(year, month + 1, 0).day;
    return day > lastDay ? lastDay : day;
  }

  static String _dateString(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  static String _ordinal(int n) {
    if (n % 100 >= 11 && n % 100 <= 13) return '${n}th';
    return switch (n % 10) {
      1 => '${n}st',
      2 => '${n}nd',
      3 => '${n}rd',
      _ => '${n}th',
    };
  }

  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
}
