import 'package:flutter/material.dart';

class Category {
  final String id;
  final String name;
  final Color color;
  final bool isProductive;

  const Category({
    required this.id,
    required this.name,
    required this.color,
    this.isProductive = false,
  });

  Category copyWith({
    String? id,
    String? name,
    Color? color,
    bool? isProductive,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      isProductive: isProductive ?? this.isProductive,
    );
  }
}