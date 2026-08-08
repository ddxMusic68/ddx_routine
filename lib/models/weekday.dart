enum Weekday {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday;

  String get label => switch (this) {
        Weekday.monday => 'Mon',
        Weekday.tuesday => 'Tue',
        Weekday.wednesday => 'Wed',
        Weekday.thursday => 'Thu',
        Weekday.friday => 'Fri',
        Weekday.saturday => 'Sat',
        Weekday.sunday => 'Sun',
      };
}
