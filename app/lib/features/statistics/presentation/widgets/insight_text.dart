import 'package:flutter/material.dart';
import '../../models/statistics_models.dart';

class InsightText extends StatelessWidget {
  final StatInsight insight;

  const InsightText({super.key, required this.insight});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white70,
            height: 1.6,
            fontWeight: FontWeight.w300,
            letterSpacing: 0.2,
          ),
          children: [
            TextSpan(text: '${insight.prefix} '),
            TextSpan(
              text: insight.highlight,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Color(0xFFB794F4),
                letterSpacing: -0.5,
              ),
            ),
            TextSpan(text: '\n${insight.suffix}'),
          ],
        ),
      ),
    );
  }
}

class InsightError extends StatelessWidget {
  const InsightError({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Text(
        'Could not load stats',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white.withOpacity(0.3),
          fontSize: 14,
        ),
      ),
    );
  }
}