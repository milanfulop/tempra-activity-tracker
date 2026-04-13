import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../shared/utils/api_service.dart';
import '../../models/statistics_models.dart';
import '../widgets/period_bar.dart';
import '../widgets/date_bar.dart';
import '../widgets/insight_text.dart';
import '../widgets/insight_skeleton.dart';
import '../../utils/statistics_cache_service.dart';
import '../../../../shared/utils/user_profile_fetch.dart';

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
  final Map<String, StatsResponse> _memoryCache = {};

  // earliest date the user can navigate back to.
  DateTime? _createdAt;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _loadCreatedAt();
  }

  Future<void> _loadCreatedAt() async {
    try {
      final date = await UserProfileService.getCreatedAt();
      if (mounted) {
        setState(() {
          _createdAt = DateTime(date.year, date.month, date.day);
        });
      }
    } catch (_) {
    }
  }

  // ── navigation guards ────────────────────────────────────────────────────

  bool get _canGoBack {
    if (_createdAt == null) return true; // not yet loaded, allow
    final selectedDateOnly = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    return selectedDateOnly.isAfter(_createdAt!);
  }

  bool get _canGoForward {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return _selectedDate.isBefore(yesterday) &&
        !_isSameDay(_selectedDate, yesterday);
  }

  // ── data fetching ────────────────────────────────────────────────────────

  Future<void> _fetchData() async {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final cacheKey = '${dateStr}_${_selectedPeriod.queryValue}';

    // 1. memory cache
    if (_memoryCache.containsKey(cacheKey)) {
      setState(() {
        _stats = _memoryCache[cacheKey];
        _insight = StatInsight.fromResponse(_memoryCache[cacheKey]!);
        _isLoading = false;
        _error = null;
      });
      return;
    }

    // 2. disk cache — show while fetching fresh
    final cached = await StatsCacheService.load(cacheKey);
    if (cached != null && mounted) {
      final response = StatsResponse.fromJson(cached);
      _memoryCache[cacheKey] = response;
      setState(() {
        _stats = response;
        _insight = StatInsight.fromResponse(response);
      });
      _preloadAdjacent();
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    // 3. network — always fetch fresh
    try {
      final data = await ApiService.get(
        '/stats?date=$dateStr&stats=${_selectedPeriod.queryValue},time_distribution',
      );

      await StatsCacheService.save(cacheKey, data as Map<String, dynamic>);

      final response = StatsResponse.fromJson(data);
      _memoryCache[cacheKey] = response;

      if (mounted) {
        setState(() {
          _isLoading = false;
          _stats = response;
          _insight = StatInsight.fromResponse(response);
        });
        _preloadAdjacent();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (_stats == null) _error = e.toString();
        });
      }
    }
  }

  Future<void> _preloadAdjacent() async {
    final date = _selectedDate.subtract(const Duration(days: 1));
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final cacheKey = '${dateStr}_${_selectedPeriod.queryValue}';

    if (_memoryCache.containsKey(cacheKey)) return;

    final cached = await StatsCacheService.load(cacheKey);
    if (cached != null) {
      _memoryCache[cacheKey] = StatsResponse.fromJson(cached);
      return;
    }

    try {
      final data = await ApiService.get(
        '/stats?date=$dateStr&stats=${_selectedPeriod.queryValue},time_distribution',
      );
      await StatsCacheService.save(cacheKey, data as Map<String, dynamic>);
      _memoryCache[cacheKey] = StatsResponse.fromJson(data);
    } catch (_) {}
  }

  // ── navigation actions ───────────────────────────────────────────────────

  void _goToPreviousDay() {
    if (!_canGoBack) return;
    setState(() => _selectedDate = _selectedDate.subtract(const Duration(days: 1)));
    _fetchData();
  }

  void _goToNextDay() {
    if (!_canGoForward) return;
    setState(() => _selectedDate = _selectedDate.add(const Duration(days: 1)));
    _fetchData();
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
      if (_canGoBack) _goToPreviousDay();
    }
  }

  void _onTap() {
    if (_stats != null && !_stats!.isEmpty) {
      context.push('/statistics-details', extra: _stats);
    }
  }

  // ── helpers ──────────────────────────────────────────────────────────────

  String get _formattedDate {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    if (_isSameDay(_createdAt ?? yesterday, now)) return "Check back tomorrow";
    if (_isSameDay(_selectedDate, yesterday)) return 'Yesterday';
    return DateFormat('d MMM yyyy').format(_selectedDate);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool get _hasData => _stats != null && !_stats!.isEmpty;

  // ── build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12121A),
      body: GestureDetector(
        onHorizontalDragEnd: _onSwipe,
        onTap: _onTap,
        child: Stack(
          children: [
            // background gradient
            Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.3),
                  radius: 1.2,
                  colors: [Color(0xFF1C1C26), Color(0xFF12121A)],
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
                  const Spacer(),

                  // insight block — bottom area above date bar
                  Align(
                    alignment: Alignment.centerLeft,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 0),
                      child: _isLoading
                          ? const InsightSkeleton()
                          : _error != null
                              ? const InsightError()
                              : _insight != null
                                  ? InsightText(insight: _insight!)
                                  : const SizedBox.shrink(),
                    ),
                  ),

                  const SizedBox(height: 64),

                  // tap indicator
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: _isLoading ? 0 : 1,
                    child: Text(
                      _hasData
                          ? 'Tap for details'
                          : _isSameDay(_createdAt ?? _selectedDate, DateTime.now())
                              ? "It's your first day here!"
                              : 'No data recorded for this day',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.2),
                        fontSize: 12,
                        letterSpacing: 0.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),

            // date bar
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: DateBar(
                label: _formattedDate,
                onPrevious: _canGoBack ? _goToPreviousDay : null,
                onNext: _canGoForward ? _goToNextDay : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}