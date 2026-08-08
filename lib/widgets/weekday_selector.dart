import 'package:flutter/material.dart';
import '../models/weekday.dart';

class WeekdaySelector extends StatelessWidget {
  final Set<Weekday> selectedDays;
  final ValueChanged<Set<Weekday>> onChanged;

  const WeekdaySelector({
    super.key,
    required this.selectedDays,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final day in Weekday.values)
          FilterChip(
            label: Text(day.label),
            selected: selectedDays.contains(day),
            onSelected: (selected) {
              final updated = {...selectedDays};
              if (selected) {
                updated.add(day);
              } else {
                updated.remove(day);
              }
              onChanged(updated);
            },
          ),
      ],
    );
  }
}
