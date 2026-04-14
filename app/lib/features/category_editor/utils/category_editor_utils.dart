import 'package:flutter/material.dart';
import '../../../shared/utils/api_service.dart';
import '../../../shared/models/category.dart';

String _colorToHex(Color color) =>
    '#${color.red.toRadixString(16).padLeft(2, '0')}'
    '${color.green.toRadixString(16).padLeft(2, '0')}'
    '${color.blue.toRadixString(16).padLeft(2, '0')}';

Future<Category> createCategory({
  required String name,
  required Color color,
  required bool isProductive,
}) async {
  final response = await ApiService.post('/category', {
    'name': name,
    'color': _colorToHex(color),
    'is_productive': isProductive,
  });
  return Category(
    id: response['id'] as String,
    name: name,
    color: color,
    isProductive: isProductive,
  );
}

Future<void> deleteCategory(String categoryId) async {
  await ApiService.delete('/category/$categoryId');
}

Future<void> editCategory({
  required String id,
  required String name,
  required Color color,
  required bool isProductive,
}) async {
  await ApiService.put('/category/$id', {
    'name': name,
    'color': _colorToHex(color),
    'is_productive': isProductive,
  });
}