import 'package:flutter/material.dart';
import '../../../models/statistics_models.dart';
import '../widgets/daily_summary_page.dart';
import '../widgets/time_distribution_page.dart';
import '../widgets/page_dots.dart';
import '../widgets/back_button.dart';

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
      return _EmptyState();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D0A1A),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.3),
                radius: 1.2,
                colors: [Color(0xFF1E1040), Color(0xFF0D0A1A)],
              ),
            ),
          ),
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, index) {
              final page = _pages[index];
              return switch (page.type) {
                StatPageType.dailySummary =>
                  DailySummaryPage(summary: page.summary!),
                StatPageType.timeDistribution =>
                  TimeDistributionPage(distribution: page.distribution!),
              };
            },
          ),
          if (_pages.length > 1)
            Positioned(
              bottom: 48,
              left: 0,
              right: 0,
              child: PageDots(count: _pages.length, current: _currentPage),
            ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: StatsBackButton(onTap: () => Navigator.pop(context)),
          ),
        ],
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