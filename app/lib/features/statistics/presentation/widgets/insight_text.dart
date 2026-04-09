import 'package:flutter/material.dart';
import '../../models/statistics_models.dart';

class InsightText extends StatelessWidget {
  final StatInsight insight;
  const InsightText({super.key, required this.insight});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: insight.highlight,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -1,
                    height: 1.1,
                  ),
                ),
                TextSpan(
                  text: '  ${insight.prefix}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w300,
                    color: Colors.white.withOpacity(0.4),
                    letterSpacing: 0.2,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: insight.suffix,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -1,
                    height: 1.1,
                  ),
                ),
                TextSpan(
                  text: '  of it was productive',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w300,
                    color: Colors.white.withOpacity(0.4),
                    letterSpacing: 0.2,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ],
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
        style: TextStyle(
          color: Colors.white.withOpacity(0.3),
          fontSize: 14,
        ),
      ),
    );
  }
}