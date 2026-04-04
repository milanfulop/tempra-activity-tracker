import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ApiService {
  static String get _baseUrl => dotenv.env['HOST_ADDRESS'] ?? '';

  static String? _getToken() {
    return Supabase.instance.client.auth.currentSession?.accessToken;
  }

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${_getToken()}',
  };

  // GET
  static Future<dynamic> get(String path) async {
    final response = await http.get(
      Uri.parse('$_baseUrl$path'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  // POST
  static Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('$_baseUrl$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  // PUT
  static Future<dynamic> put(String path, Map<String, dynamic> body) async {
    final response = await http.put(
      Uri.parse('$_baseUrl$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  // DELETE
  static Future<dynamic> delete(String path) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl$path'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  static dynamic _handleResponse(http.Response response) {
    final decoded = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }
    throw Exception(decoded['message'] ?? 'Request failed (${response.statusCode})');
  }
}