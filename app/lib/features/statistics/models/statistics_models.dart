import 'package:flutter/material.dart';

// --- StatPeriod ---

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

// --- StatInsight ---

class StatInsight {
  final String prefix;
  final String highlight;
  final String suffix;

  const StatInsight({
    required this.prefix,
    required this.highlight,
    required this.suffix,
  });

  /// Builds an insight from a StatsResponse. Returns null if no summary data.
  static StatInsight? fromResponse(StatsResponse response) {
    final summary = response.dailySummary;
    if (summary == null) return null;

    return StatInsight(
      prefix: 'tracked',
      highlight: '${summary.trackedPercent.toStringAsFixed(0)}%',
      suffix: '${summary.productivePercent.toStringAsFixed(0)}%',
    );
  }
}

// --- DailySummary ---

class DailySummary {
  final double trackedPercent;
  final int totalTrackedMinutes;
  final double productivePercent;
  final int totalProductiveMinutes;
  final String longestCategoryId;
  final String longestStartTime;
  final String longestEndTime;
  final int longestDurationMinutes;
  final bool longestIsProductive;

  const DailySummary({
    required this.trackedPercent,
    required this.totalTrackedMinutes,
    required this.productivePercent,
    required this.totalProductiveMinutes,
    required this.longestCategoryId,
    required this.longestStartTime,
    required this.longestEndTime,
    required this.longestDurationMinutes,
    required this.longestIsProductive,
  });

  factory DailySummary.fromJson(Map<String, dynamic> json) {
    return DailySummary(
      trackedPercent: (json['tracked_percent'] as num).toDouble(),
      totalTrackedMinutes: json['total_tracked_minutes'] as int,
      productivePercent: (json['productive_percent'] as num).toDouble(),
      totalProductiveMinutes: json['total_productive_minutes'] as int,
      longestCategoryId: json['longest_category_id'] as String,
      longestStartTime: json['longest_start_time']['value'] as String,
      longestEndTime: json['longest_end_time']['value'] as String,
      longestDurationMinutes: json['longest_duration_minutes'] as int,
      longestIsProductive: json['longest_is_productive'] as bool,
    );
  }
}

// --- TimeDistribution ---

class TimeDistribution {
  final String categoryId;
  final String categoryName;
  final String categoryColor;
  final bool isProductive;
  final bool isSleep;
  final int? minutes;
  final double? percentOfDay;

  const TimeDistribution({
    required this.categoryId,
    required this.categoryName,
    required this.categoryColor,
    required this.isProductive,
    required this.isSleep,
    this.minutes,
    this.percentOfDay,
  });

  factory TimeDistribution.fromJson(Map<String, dynamic> json) {
    return TimeDistribution(
      categoryId: json['category_id'] as String,
      categoryName: json['category_name'] as String,
      categoryColor: json['category_color'] as String,
      isProductive: json['is_productive'] as bool,
      isSleep: json['is_sleep'] as bool,
      minutes: json['minutes'] as int?,
      percentOfDay: json['percent_of_day'] == null
          ? null
          : (json['percent_of_day'] as num).toDouble(),
    );
  }

  Color get color {
    final hex = categoryColor.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  bool get hasData => minutes != null && percentOfDay != null;
}

// --- StatsResponse ---

class StatsResponse {
  final DailySummary? dailySummary;
  final List<TimeDistribution>? timeDistribution;

  const StatsResponse({this.dailySummary, this.timeDistribution});

  factory StatsResponse.fromJson(Map<String, dynamic> json) {
    return StatsResponse(
      dailySummary: json['daily_summary'] != null
          ? DailySummary.fromJson(json['daily_summary'] as Map<String, dynamic>)
          : null,
      timeDistribution: json['time_distribution'] != null
          ? (json['time_distribution'] as List)
              .map((e) => TimeDistribution.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  List<TimeDistribution> get validDistribution =>
      timeDistribution?.where((e) => e.hasData).toList() ?? [];

  bool get isEmpty => dailySummary == null && validDistribution.isEmpty;

  List<StatPage> get pages {
    final result = <StatPage>[];
    if (dailySummary != null) {
      result.add(StatPage.dailySummary(dailySummary!));
    }
    if (validDistribution.isNotEmpty) {
      result.add(StatPage.timeDistribution(validDistribution));
    }
    return result;
  }
}

// --- StatPage ---

enum StatPageType { dailySummary, timeDistribution }

class StatPage {
  final StatPageType type;
  final DailySummary? summary;
  final List<TimeDistribution>? distribution;

  const StatPage._({required this.type, this.summary, this.distribution});

  factory StatPage.dailySummary(DailySummary s) =>
      StatPage._(type: StatPageType.dailySummary, summary: s);

  factory StatPage.timeDistribution(List<TimeDistribution> d) =>
      StatPage._(type: StatPageType.timeDistribution, distribution: d);
}