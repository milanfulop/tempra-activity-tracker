import 'package:flutter/material.dart';
import '../models/category.dart';
import '../../shared/utils/api_service.dart';

Future<List<Category>> fetchCategories() async {
  try {
    final decoded = await ApiService.get('/category');

    if (decoded is! List) {
      debugPrint('fetchCategories(): unexpected JSON shape (${decoded.runtimeType})');
      return const [];
    }

    Color parseColor(dynamic raw) {
      if (raw is int) return Color(raw);
      if (raw is! String) return const Color(0x00000000);
      var hex = raw.trim();
      if (hex.startsWith('#')) hex = hex.substring(1);
      if (hex.startsWith('0x') || hex.startsWith('0X')) hex = hex.substring(2);
      if (hex.length == 6) hex = 'FF$hex';
      if (hex.length != 8) return const Color(0x00000000);
      final value = int.tryParse(hex, radix: 16) ?? 0;
      return Color(value);
    }

    return decoded
        .map((e) {
          if (e is! Map) return null;
          return Category(
            id: e['id']?.toString() ?? '',
            name: e['name']?.toString() ?? '',
            color: parseColor(e['color']),
          );
        })
        .whereType<Category>()
        .toList();
  } catch (e) {
    debugPrint('fetchCategories(): $e');
    return const [];
  }
}