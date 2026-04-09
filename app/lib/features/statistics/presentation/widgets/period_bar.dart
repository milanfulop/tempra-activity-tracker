import 'package:flutter/material.dart';
import '../../models/statistics_models.dart';

class PeriodBar extends StatelessWidget {
  final StatPeriod selected;
  final ValueChanged<StatPeriod> onChanged;

  const PeriodBar({super.key, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: Colors.white.withOpacity(0.08),
            width: 1.2,
          ),
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          children: StatPeriod.values.map((period) {
            final isSelected = period == selected;
            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged(period),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(36),
                    border: isSelected
                        ? Border.all(
                            color: Colors.white.withOpacity(0.15),
                            width: 1,
                          )
                        : null,
                  ),
                  child: Text(
                    period.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withOpacity(0.35),
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}