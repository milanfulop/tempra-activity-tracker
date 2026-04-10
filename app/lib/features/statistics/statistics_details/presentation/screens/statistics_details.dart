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
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToNext() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToPrevious() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_pages.isEmpty) return const _EmptyState();

    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFF12121A),
      body: Stack(
        children: [
          // background
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.3),
                radius: 1.2,
                colors: [Color(0xFF1C1C26), Color(0xFF12121A)],
              ),
            ),
          ),

          // page content
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

          // tap zones — left/right navigation
          Positioned.fill(
            child: Row(
              children: [
                // left tap — go back
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: _goToPrevious,
                  ),
                ),
                // right tap — go forward
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: _goToNext,
                  ),
                ),
              ],
            ),
          ),

          // progress bar at top
          Positioned(
            top: topPadding + 12,
            left: 16,
            right: 16,
            child: PageDots(
              count: _pages.length,
              current: _currentPage,
            ),
          ),

          // back button below the bar
          Positioned(
            top: topPadding + 28,
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
      backgroundColor: const Color(0xFF12121A),
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