import 'package:flutter/material.dart';
import '../../../../shared/models/time_slot.dart';

class TimeSlotCell extends StatelessWidget {
  final TimeSlot slot;
  final bool isSelected;
  final Color? color;

  const TimeSlotCell({
    super.key,
    required this.slot,
    required this.isSelected,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final hasColor = color != null;

    final borderColor = isSelected
        ? Theme.of(context).colorScheme.primary
        : hasColor
            ? color!
            : Colors.white.withOpacity(0.15);

    final bgColor = isSelected
        ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
        : hasColor
            ? color!.withOpacity(0.35)
            : Colors.white.withOpacity(0.06);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(
          color: borderColor,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: isSelected
          ? Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}