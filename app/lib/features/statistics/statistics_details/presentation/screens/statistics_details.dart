import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../models/statistics_models.dart';

// --- Screen ---

class StatisticsDetailsScreen extends StatefulWidget {
  final StatsResponse? stats;

  const StatisticsDetailsScreen({super.key, this.stats});

  @override
  State<StatisticsDetailsScreen> createState() =>
      _StatisticsDetailsScreenState();
}

class _StatisticsDetailsScreenState extends State<StatisticsDetailsScreen> {
  late final PageController _pageController;
  late final List<StatPage> _pages;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pages = widget.stats?.pages ?? [];
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_pages.isEmpty) {
      return const _EmptyState();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D0A1A),
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.3),
                radius: 1.2,
                colors: [Color(0xFF1E1040), Color(0xFF0D0A1A)],
              ),
            ),
          ),

          // PageView
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, index) {
              final page = _pages[index];
              return switch (page.type) {
                StatPageType.dailySummary =>
                  _DailySummaryPage(summary: page.summary!),
                StatPageType.timeDistribution =>
                  _TimeDistributionPage(distribution: page.distribution!),
              };
            },
          ),

          // Page indicator dots
          if (_pages.length > 1)
            Positioned(
              bottom: 48,
              left: 0,
              right: 0,
              child: _PageDots(count: _pages.length, current: _currentPage),
            ),

          // Back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: _BackButton(onTap: () => Navigator.pop(context)),
          ),
        ],
      ),
    );
  }
}

// --- Page: Daily Summary ---

class _DailySummaryPage extends StatelessWidget {
  final DailySummary summary;

  const _DailySummaryPage({required this.summary});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 64, 24, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Daily Summary',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
                letterSpacing: 2,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 32),
            _BigStat(
              value: '${summary.trackedPercent.toStringAsFixed(1)}%',
              label: 'of your day tracked',
              sublabel: '${summary.totalTrackedMinutes} minutes',
            ),
            const SizedBox(height: 32),
            _BigStat(
              value: '${summary.productivePercent.toStringAsFixed(1)}%',
              label: 'productive time',
              sublabel: '${summary.totalProductiveMinutes} minutes',
              accentColor: const Color(0xFF68D391),
            ),
            const SizedBox(height: 40),
            _LongestBlock(summary: summary),
          ],
        ),
      ),
    );
  }
}

class _BigStat extends StatelessWidget {
  final String value;
  final String label;
  final String sublabel;
  final Color accentColor;

  const _BigStat({
    required this.value,
    required this.label,
    required this.sublabel,
    this.accentColor = const Color(0xFFB794F4),
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 56,
            fontWeight: FontWeight.w700,
            color: accentColor,
            letterSpacing: -2,
            height: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 16,
            fontWeight: FontWeight.w300,
          ),
        ),
        Text(
          sublabel,
          style: TextStyle(
            color: Colors.white.withOpacity(0.3),
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _LongestBlock extends StatelessWidget {
  final DailySummary summary;

  const _LongestBlock({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Longest Activity',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
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
                  color: Colors.white.withOpacity(0.5),
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

// --- Page: Time Distribution ---

class _TimeDistributionPage extends StatelessWidget {
  final List<TimeDistribution> distribution;

  const _TimeDistributionPage({required this.distribution});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 64, 24, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Time Distribution',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
                letterSpacing: 2,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 32),
            _DistributionBar(distribution: distribution),
            const SizedBox(height: 32),
            Expanded(
              child: ListView.separated(
                itemCount: distribution.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) =>
                    _DistributionRow(item: distribution[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DistributionBar extends StatelessWidget {
  final List<TimeDistribution> distribution;

  const _DistributionBar({required this.distribution});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 12,
        child: Row(
          children: distribution.map((item) {
            return Flexible(
              // percentOfDay is guaranteed non-null here via validDistribution
              flex: (item.percentOfDay! * 100).round(),
              child: Container(color: item.color),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _DistributionRow extends StatelessWidget {
  final TimeDistribution item;

  const _DistributionRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: item.color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            item.categoryName,
            style: const TextStyle(
              color: Colors.white70,
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
        Text(
          '${item.minutes}m',
          style: TextStyle(
            color: Colors.white.withOpacity(0.35),
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

// --- Supporting widgets ---

class _PageDots extends StatelessWidget {
  final int count;
  final int current;

  const _PageDots({required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 20 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.white.withOpacity(0.25),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;

  const _BackButton({required this.onTap});

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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0A1A),
      body: Center(
        child: Text(
          'No data for this day',
          style: TextStyle(
            color: Colors.white.withOpacity(0.3),
            fontSize: 14,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}