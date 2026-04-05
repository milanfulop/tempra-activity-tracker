import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../shared/utils/api_service.dart';
import '../../models/statistics_models.dart';

// --- Models ---

enum StatPeriod { daily, weekly, monthly }

extension StatPeriodLabel on StatPeriod {
  String get label {
    switch (this) {
      case StatPeriod.daily:
        return 'Daily';
      case StatPeriod.weekly:
        return 'Weekly';
      case StatPeriod.monthly:
        return 'Monthly';
    }
  }

  String get queryValue {
    switch (this) {
      case StatPeriod.daily:
        return 'daily_summary';
      case StatPeriod.weekly:
        return 'weekly_summary';
      case StatPeriod.monthly:
        return 'monthly_summary';
    }
  }
}

class StatInsight {
  final String prefix;
  final String highlight;
  final String suffix;

  const StatInsight({
    required this.prefix,
    required this.highlight,
    required this.suffix,
  });
}

// --- Main Screen ---

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  StatPeriod _selectedPeriod = StatPeriod.daily;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  String? _error;
  StatInsight? _insight;
  StatsResponse? _stats;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _insight = null;
      _stats = null;
    });

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final data = await ApiService.get(
        '/stats?date=$dateStr&stats=${_selectedPeriod.queryValue},time_distribution',
      );

      final response = StatsResponse.fromJson(data as Map<String, dynamic>);
      final insight = _buildInsight(response);

      setState(() {
        _isLoading = false;
        _stats = response;
        _insight = insight;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  StatInsight? _buildInsight(StatsResponse response) {
    final summary = response.dailySummary;
    if (summary == null) return null;

    if (summary.productivePercent > 0) {
      return StatInsight(
        prefix: 'You spent',
        highlight: '${summary.productivePercent.toStringAsFixed(0)}%',
        suffix: 'of your day productively',
      );
    }

    return StatInsight(
      prefix: 'You tracked',
      highlight: '${summary.trackedPercent.toStringAsFixed(0)}%',
      suffix: 'of your day',
    );
  }

  void _goToPreviousDay() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    });
    _fetchData();
  }

  void _goToNextDay() {
    if (_canGoForward) {
      setState(() {
        _selectedDate = _selectedDate.add(const Duration(days: 1));
      });
      _fetchData();
    }
  }

  void _onPeriodChanged(StatPeriod period) {
    setState(() => _selectedPeriod = period);
    _fetchData();
  }

  void _onSwipe(DragEndDetails details) {
    const double velocityThreshold = 200;
    final velocity = details.primaryVelocity ?? 0;

    if (velocity < -velocityThreshold) {
      if (_canGoForward) _goToNextDay();
    } else if (velocity > velocityThreshold) {
      _goToPreviousDay();
    }
  }

  void _onTap() {
    if (_stats != null) {
      context.push('/statistics-details', extra: _stats);
    }
  }

  String get _formattedDate {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    if (_isSameDay(_selectedDate, now)) return 'Today';
    if (_isSameDay(_selectedDate, yesterday)) return 'Yesterday';

    return DateFormat('d MMM yyyy').format(_selectedDate);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool get _canGoForward =>
      _selectedDate.isBefore(DateTime.now()) &&
      !_isSameDay(_selectedDate, DateTime.now());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0A1A),
      body: GestureDetector(
        onHorizontalDragEnd: _onSwipe,
        onTap: _onTap,
        child: Stack(
          children: [
            // Background gradient
            Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.3),
                  radius: 1.2,
                  colors: [
                    Color(0xFF1E1040),
                    Color(0xFF0D0A1A),
                  ],
                ),
              ),
            ),

            // Main content
            SafeArea(
              child: Column(
                children: [
                  _PeriodBar(
                    selected: _selectedPeriod,
                    onChanged: _onPeriodChanged,
                  ),

                  const SizedBox(height: 16),

                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: _isLoading
                        ? const _InsightSkeleton()
                        : _error != null
                            ? _ErrorText(error: _error!)
                            : _insight != null
                                ? _InsightText(insight: _insight!)
                                : const SizedBox.shrink(),
                  ),

                  const SizedBox(height: 24),

                  const Expanded(
                    child: _PlaceholderStatPage(label: 'Productivity Overview'),
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),

            // Bottom date bar
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: _DateBar(
                label: _formattedDate,
                onPrevious: _goToPreviousDay,
                onNext: _canGoForward ? _goToNextDay : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Period Bar ---

class _PeriodBar extends StatelessWidget {
  final StatPeriod selected;
  final ValueChanged<StatPeriod> onChanged;

  const _PeriodBar({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: StatPeriod.values.map((period) {
              final isSelected = period == selected;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(period),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withOpacity(0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(36),
                    ),
                    child: Text(
                      period.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withOpacity(0.4),
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// --- Date Bar ---

class _DateBar extends StatelessWidget {
  final String label;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;

  const _DateBar({
    required this.label,
    required this.onPrevious,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(40),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _NavButton(
              icon: CupertinoIcons.chevron_left,
              onTap: onPrevious,
            ),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
            _NavButton(
              icon: CupertinoIcons.chevron_right,
              onTap: onNext,
              disabled: onNext == null,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool disabled;

  const _NavButton({
    required this.icon,
    this.onTap,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: disabled
              ? Colors.white.withOpacity(0.03)
              : Colors.white.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: disabled
              ? Colors.white.withOpacity(0.2)
              : Colors.white.withOpacity(0.8),
          size: 16,
        ),
      ),
    );
  }
}

// --- Insight Text ---

class _InsightText extends StatelessWidget {
  final StatInsight insight;

  const _InsightText({required this.insight});

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

// --- Error Text ---

class _ErrorText extends StatelessWidget {
  final String error;

  const _ErrorText({required this.error});

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

// --- Insight Skeleton ---

class _InsightSkeleton extends StatefulWidget {
  const _InsightSkeleton();

  @override
  State<_InsightSkeleton> createState() => _InsightSkeletonState();
}

class _InsightSkeletonState extends State<_InsightSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          children: [
            Container(
              height: 14,
              width: 180,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(_animation.value * 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 32,
              width: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(_animation.value * 0.4),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 14,
              width: 220,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(_animation.value * 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Placeholder ---

class _PlaceholderStatPage extends StatelessWidget {
  final String label;

  const _PlaceholderStatPage({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withOpacity(0.2),
          fontSize: 14,
          letterSpacing: 1,
        ),
      ),
    );
  }
}