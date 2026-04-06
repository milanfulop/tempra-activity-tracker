import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class StatsBackButton extends StatelessWidget {
  final VoidCallback onTap;

  const StatsBackButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: const Icon(
          CupertinoIcons.chevron_left,
          color: Colors.white,
          size: 16,
        ),
      ),
    );
  }
}