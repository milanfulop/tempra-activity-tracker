import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class DateBar extends StatelessWidget {
  final String label;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const DateBar({
    super.key,
    required this.label,
    required this.onPrevious,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1.2,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _NavButton(
            icon: CupertinoIcons.chevron_left, 
            onTap: onPrevious,
            disabled: onPrevious == null,
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
          _NavButton(
            icon: CupertinoIcons.chevron_right,
            onTap: onNext,
            disabled: onNext == null,
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool disabled;

  const _NavButton({
    required this.icon,
    this.onTap,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: disabled
              ? Colors.white.withOpacity(0.03)
              : Colors.white.withOpacity(0.08),
          shape: BoxShape.circle,
          border: Border.all(
            color: disabled
                ? Colors.white.withOpacity(0.05)
                : Colors.white.withOpacity(0.12),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: disabled
              ? Colors.white.withOpacity(0.15)
              : Colors.white.withOpacity(0.7),
          size: 16,
        ),
      ),
    );
  }
}