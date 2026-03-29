import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

String get _base => dotenv.env['HOST_ADDRESS'] ?? 'http://localhost:5000';

// ── helpers ────────────────────────────────────────────────────────────────

/// Converts a Flutter Color to a hex string the API expects, e.g. "#ff5733"
String _colorToHex(Color color) =>
    '#${color.red.toRadixString(16).padLeft(2, '0')}'
    '${color.green.toRadixString(16).padLeft(2, '0')}'
    '${color.blue.toRadixString(16).padLeft(2, '0')}';

/// Throws a descriptive exception for any non-2xx response.
void _assertOk(http.Response response, String operation) {
  if (response.statusCode < 200 || response.statusCode >= 300) {
    String message;
    try {
      final body = jsonDecode(response.body);
      message = body['error'] ?? response.reasonPhrase ?? 'Unknown error';
    } catch (_) {
      message = response.reasonPhrase ?? 'Unknown error';
    }
    throw Exception('$operation failed (${response.statusCode}): $message');
  }
}

// ── auth token ─────────────────────────────────────────────────────────────
// Replace with however you store your JWT (shared_preferences, secure_storage, etc.)
String _getToken() => dotenv.env['AUTH_TOKEN'] ?? '';

Map<String, String> get _headers => {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${_getToken()}',
    };

// ── API calls ──────────────────────────────────────────────────────────────

Future<void> createCategory({
  required String id,
  required String name,
  required Color color,
  required bool isProductive,
}) async {
  final response = await http.post(
    Uri.parse('$_base/category'),
    headers: _headers,
    body: jsonEncode({
      'name': name,
      'color': _colorToHex(color),
      'is_productive': isProductive,
    }),
  );
  _assertOk(response, 'Create category');
}

Future<void> deleteCategory(String categoryId) async {
  final response = await http.delete(
    Uri.parse('$_base/category/$categoryId'),
    headers: _headers,
  );
  _assertOk(response, 'Delete category');
}

Future<void> editCategory({
  required String id,
  required String name,
  required Color color,
  required bool isProductive,
}) async {
  final response = await http.put(
    Uri.parse('$_base/category/$id'),
    headers: _headers,
    body: jsonEncode({
      'name': name,
      'color': _colorToHex(color),
      'is_productive': isProductive,
    }),
  );
  _assertOk(response, 'Edit category');
}