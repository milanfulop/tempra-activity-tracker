import 'package:flutter/material.dart';
import '../../../shared/models/category.dart';

/// Data model for a single category.


/// Fetches categories from the server.
/// Replace the body with a real API call when ready.
Future<List<Category>> fetchCategories() async {
  // TODO: replace with real API request, e.g.:
  // final response = await http.get(Uri.parse('https://yourapi.com/categories'));
  // final List data = jsonDecode(response.body);
  // return data.map((e) => Category(id: e['id'], name: e['name'], color: Color(int.parse(e['color'])))).toList();

  // Placeholder data:
  await Future.delayed(const Duration(milliseconds: 200)); // simulate network
  return const [
    Category(id: '1', name: 'Work',        color: Color(0xFF4A90D9)),
    Category(id: '2', name: 'Exercise',    color: Color(0xFF27AE60)),
    Category(id: '3', name: 'Study',       color: Color(0xFF8E44AD)),
    Category(id: '4', name: 'Meals',       color: Color(0xFFE67E22)),
    Category(id: '5', name: 'Sleep',       color: Color(0xFF2C3E50)),
    Category(id: '6', name: 'Social',      color: Color(0xFFE91E63)),
    Category(id: '7', name: 'Hobbies',     color: Color(0xFF00BCD4)),
    Category(id: '8', name: 'Errands',     color: Color(0xFFFF5722)),
    Category(id: '9', name: 'Family',      color: Color(0xFF795548)),
    Category(id: '10', name: 'Free time',  color: Color(0xFF607D8B)),
  ];
}