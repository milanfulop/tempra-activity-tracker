import 'package:flutter/material.dart';

class TimeSlot {
  final int index;
  final DateTime time;
  final String? activity;
  final String? category;
  final Color? color;

  const TimeSlot({
    required this.index,
    required this.time,
    this.activity,
    this.category,
    this.color,
  });

  TimeSlot copyWith({
    String? activity,
    String? category,
    Color? color,
  }) {
    return TimeSlot(
      index: index,
      time: time,
      activity: activity ?? this.activity,
      category: category ?? this.category,
      color: color ?? this.color,
    );
  }
}