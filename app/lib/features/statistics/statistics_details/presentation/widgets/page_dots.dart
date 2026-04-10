import 'package:flutter/material.dart';

class PageDots extends StatelessWidget {
  final int count;
  final int current;

  const PageDots({super.key, required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(count, (i) {
        final isActive = i == current;
        //final isPast = i < current;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < count - 1 ? 4 : 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: Container(
                height: 2.5,
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.white.withOpacity(0.9)
                      : Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}