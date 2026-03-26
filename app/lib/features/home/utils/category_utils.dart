import 'package:flutter/material.dart';
import '../../../shared/models/category.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';


/// Fetches categories from the server.
/// Replace the body with a real API call when ready.
Future<List<Category>> fetchCategories() async {
  final host = dotenv.env['HOST_ADDRESS'];
  if (host == null || host.trim().isEmpty) {
    // Avoid crashing when env isn't loaded (or HOST_ADDRESS is unset).
    debugPrint('fetchCategories(): HOST_ADDRESS is missing');
    return const [];
  }

  try {
    final uri = Uri.parse('$host/category');

    final authToken = dotenv.env['AUTH_TOKEN'];
    final response = await http
        .get(
          uri,
          headers: {'Authorization': 'Bearer $authToken'},
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      debugPrint(
        'fetchCategories(): request failed '
        '(status=${response.statusCode}) body=${response.body}',
      );
      return const [];
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      debugPrint('fetchCategories(): unexpected JSON shape (${decoded.runtimeType})');
      return const [];
    }

    Color parseColor(dynamic raw) {
      // API might return colors as:
      // - integer (e.g. 4281555008)
      // - hex string like "#eb4034" or "#FFEB4034"
      // - hex string like "0xeb4034" / "0xFFEB4034"
      if (raw is int) return Color(raw);
      if (raw is! String) return const Color(0x00000000);

      var hex = raw.trim();
      if (hex.startsWith('#')) hex = hex.substring(1);
      if (hex.startsWith('0x') || hex.startsWith('0X')) {
        hex = hex.substring(2);
      }

      // If API gives RRGGBB, assume full opacity.
      if (hex.length == 6) hex = 'FF$hex';

      if (hex.length != 8) return const Color(0x00000000);
      final value = int.tryParse(hex, radix: 16) ?? 0;
      return Color(value);
    }

    return decoded
        .map((e) {
          if (e is! Map) return null;
          final id = e['id']?.toString() ?? '';
          final name = e['name']?.toString() ?? '';
          final colorValue = e['color']?.toString() ?? '';

          final color = parseColor(colorValue);
          return Category(id: id, name: name, color: color);
        })
        .whereType<Category>()
        .toList();
  } on TimeoutException catch (e) {
    debugPrint('fetchCategories(): timeout: $e');
    return const [];
  } on FormatException catch (e) {
    // jsonDecode can throw on invalid JSON.
    debugPrint('fetchCategories(): JSON parse error: $e');
    return const [];
  } catch (e) {
    debugPrint('fetchCategories(): unexpected error: $e');
    return const [];
  }
}