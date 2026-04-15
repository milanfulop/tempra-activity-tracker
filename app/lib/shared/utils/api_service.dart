import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/env.dart';

class ApiService {
  static http.Client _client = http.Client();
  static void setClient(http.Client client) => _client = client;

  static String? _testBaseUrl;
  static void setBaseUrl(String url) => _testBaseUrl = url;
  static String get _baseUrl => _testBaseUrl ?? Env.hostAddress;

  static String? _testToken;
  static void setToken(String? token) => _testToken = token;

  static String? _getToken() {
    if (_testToken != null) return _testToken;
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    print("TOKEN: $token"); // add this
    return Supabase.instance.client.auth.currentSession?.accessToken;
  }

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${_getToken()}',
      };

  static Future<dynamic> get(String path) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl$path'),
      headers: _headers,
    );
    print("call");
    print(response.body);
    return _handleResponse(response);
  }

  static Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  static Future<dynamic> put(String path, Map<String, dynamic> body) async {
    final response = await _client.put(
      Uri.parse('$_baseUrl$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  static Future<dynamic> delete(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final response = await _client.delete(
      Uri.parse('$_baseUrl$path'),
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  static dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }
    String message;
    try {
      final body = jsonDecode(response.body);
      message = body['message'] ?? body['error'] ?? response.reasonPhrase ?? 'Unknown error';
    } catch (_) {
      message = response.reasonPhrase ?? 'Unknown error';
    }
    throw Exception('${response.statusCode}: $message');
  }
}