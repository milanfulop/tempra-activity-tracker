import 'package:flutter/material.dart';

class StatsBackButton extends StatelessWidget {
  final VoidCallback onTap;
  const StatsBackButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withOpacity(0.12),
            width: 1.2,
          ),
        ),
        child: Center(
          child: Text(
            '×',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 22,
              fontWeight: FontWeight.w300,
              height: 0,
            ),
          ),
        ),
      ),
    );
  }
}