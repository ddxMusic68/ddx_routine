import 'package:flutter/material.dart';

class DayOfMonthPicker extends StatelessWidget {
  final int? selectedDay;
  final ValueChanged<int> onChanged;

  const DayOfMonthPicker({
    super.key,
    this.selectedDay,
    required this.onChanged,
  });

  static const _maxDays = 31;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Day of month',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final label in _weekdayLabels)
              Expanded(
                child: Center(
                  child: Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        for (var rowStart = 0; rowStart < _maxDays; rowStart += 7)
          _buildRow(context, rowStart),
      ],
    );
  }

  Widget _buildRow(BuildContext context, int rowStart) {
    final count = rowStart + 7 <= _maxDays ? 7 : _maxDays - rowStart;
    return Row(
      children: [
        for (var i = 0; i < count; i++)
          Expanded(child: _buildCell(context, rowStart + 1 + i)),
        for (var i = count; i < 7; i++)
          const Expanded(child: SizedBox(height: 40)),
      ],
    );
  }

  Widget _buildCell(BuildContext context, int day) {
    final isSelected = day == selectedDay;
    final theme = Theme.of(context);
    return SizedBox(
      height: 40,
      child: Center(
        child: Material(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => onChanged(day),
            child: SizedBox(
              width: 36,
              height: 36,
              child: Center(
                child: Text(
                  '$day',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static const _weekdayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
}
