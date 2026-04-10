import 'package:flutter/material.dart';
import '../../../models/statistics_models.dart';

class DailySummaryPage extends StatelessWidget {
  final DailySummary summary;
  const DailySummaryPage({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 72, 24, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'DAILY SUMMARY',
              style: TextStyle(
                color: Colors.white.withOpacity(0.35),
                fontSize: 11,
                letterSpacing: 2,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 40),
            BigStat(
              value: '${summary.trackedPercent.toStringAsFixed(1)}%',
              label: 'of your day tracked',
              sublabel: '${summary.totalTrackedMinutes} minutes',
            ),
            const SizedBox(height: 32),
            BigStat(
              value: '${summary.productivePercent.toStringAsFixed(1)}%',
              label: 'productive time',
              sublabel: '${summary.totalProductiveMinutes} minutes',
              accentColor: const Color(0xFF68D391),
            ),
            const SizedBox(height: 40),
            LongestBlock(summary: summary),
          ],
        ),
      ),
    );
  }
}

class BigStat extends StatelessWidget {
  final String value;
  final String label;
  final String sublabel;
  final Color accentColor;

  const BigStat({
    super.key,
    required this.value,
    required this.label,
    required this.sublabel,
    this.accentColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w700,
                  color: accentColor,
                  letterSpacing: -1.5,
                  height: 1,
                ),
              ),
              TextSpan(
                text: '  $label',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w300,
                  color: Colors.white.withOpacity(0.4),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          sublabel,
          style: TextStyle(
            color: Colors.white.withOpacity(0.25),
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class LongestBlock extends StatelessWidget {
  final DailySummary summary;
  const LongestBlock({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LONGEST ACTIVITY',
            style: TextStyle(
              color: Colors.white.withOpacity(0.35),
              fontSize: 11,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${summary.longestDurationMinutes} min',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${summary.longestStartTime} → ${summary.longestEndTime}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}