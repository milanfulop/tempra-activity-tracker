import 'package:flutter/material.dart';
import '../../../models/statistics_models.dart';

class TimeDistributionPage extends StatelessWidget {
  final List<TimeDistribution> distribution;
  const TimeDistributionPage({super.key, required this.distribution});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 72, 24, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TIME DISTRIBUTION',
              style: TextStyle(
                color: Colors.white.withOpacity(0.35),
                fontSize: 11,
                letterSpacing: 2,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 32),
            DistributionBar(distribution: distribution),
            const SizedBox(height: 32),
            Expanded(
              child: ListView.separated(
                itemCount: distribution.length,
                separatorBuilder: (_, __) => Divider(
                  color: Colors.white.withOpacity(0.06),
                  height: 24,
                ),
                itemBuilder: (context, index) =>
                    DistributionRow(item: distribution[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DistributionBar extends StatelessWidget {
  final List<TimeDistribution> distribution;
  const DistributionBar({super.key, required this.distribution});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        height: 10,
        child: Row(
          children: distribution.map((item) {
            return Flexible(
              flex: (item.percentOfDay! * 100).round(),
              child: Container(color: item.color),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class DistributionRow extends StatelessWidget {
  final TimeDistribution item;
  const DistributionRow({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: item.color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            item.categoryName,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        Text(
          '${item.percentOfDay!.toStringAsFixed(1)}%',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 40,
          child: Text(
            '${item.minutes}m',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}