import 'package:flutter/material.dart';
import '../../../../shared/models/time_slot.dart';

class TimeSlotCell extends StatelessWidget {
  final TimeSlot slot;
  final bool isSelected;
  final Color? color; // ← add this

  const TimeSlotCell({
    super.key,
    required this.slot,
    required this.isSelected,
    this.color,
  });

  String _formatTime(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected
      ? Theme.of(context).colorScheme.primary
      : color ?? Colors.grey.shade300;
  final bgColor = isSelected
      ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
      : color?.withOpacity(0.35) ?? Colors.grey.shade100;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      decoration: BoxDecoration(
        color: bgColor,
      border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          // ── time + activity label ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatTime(slot.time),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (slot.activity != null) ...[
                  const SizedBox(height: 2),
                  Expanded(
                    child: Text(
                      slot.activity!,
                      style: const TextStyle(fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── selection indicator (top-right corner square) ─────────────
          if (isSelected)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}