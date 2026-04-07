import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../shared/utils/api_service.dart';
import '../../models/statistics_models.dart';
import '../widgets/period_bar.dart';
import '../widgets/date_bar.dart';
import '../widgets/insight_text.dart';
import '../widgets/insight_skeleton.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  StatPeriod _selectedPeriod = StatPeriod.daily;
  DateTime _selectedDate = DateTime.now().subtract(const Duration(days: 1));
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

      setState(() {
        _isLoading = false;
        _stats = response;
        _insight = StatInsight.fromResponse(response);
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
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

  bool get _canGoForward {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      return _selectedDate.isBefore(yesterday) &&
      !_isSameDay(_selectedDate, yesterday);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0A1A),
      body: GestureDetector(
        onHorizontalDragEnd: _onSwipe,
        onTap: _onTap,
        child: Stack(
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
            SafeArea(
              child: Column(
                children: [
                  PeriodBar(
                    selected: _selectedPeriod,
                    onChanged: _onPeriodChanged,
                  ),
                  const SizedBox(height: 16),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: _isLoading
                        ? const InsightSkeleton()
                        : _error != null
                            ? const InsightError()
                            : _insight != null
                                ? InsightText(insight: _insight!)
                                : const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Productivity Overview',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.2),
                          fontSize: 14,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: DateBar(
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