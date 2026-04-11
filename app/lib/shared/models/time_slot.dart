import 'package:flutter/material.dart';

class TimeSlot {
  final int index;
  final DateTime time;
  final String? activity;
  final String? category;
  final Color? color;

  TimeSlot({
    required this.index,
    required this.time,
    this.activity,
    this.category,
    this.color,
  });

  TimeSlot copyWith({
    Object? activity = _sentinel,
    Object? category = _sentinel,
    Object? color = _sentinel,
  }) {
    return TimeSlot(
      index: index,
      time: time,
      activity: activity == _sentinel ? this.activity : activity as String?,
      category: category == _sentinel ? this.category : category as String?,
      color: color == _sentinel ? this.color : color as Color?,
    );
  }
}

const _sentinel = Object();