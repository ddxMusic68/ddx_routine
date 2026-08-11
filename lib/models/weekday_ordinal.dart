enum WeekdayOrdinal {
  first,
  second,
  last;

  String get label => switch (this) {
        WeekdayOrdinal.first => '1st',
        WeekdayOrdinal.second => '2nd',
        WeekdayOrdinal.last => 'Last',
      };
}
