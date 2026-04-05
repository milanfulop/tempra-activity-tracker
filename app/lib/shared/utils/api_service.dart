import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class ApiService {
  static http.Client _client = http.Client();
  static void setClient(http.Client client) => _client = client;

  static String? _testBaseUrl;
  static void setBaseUrl(String url) => _testBaseUrl = url;
  static String get _baseUrl => _testBaseUrl ?? dotenv.env['HOST_ADDRESS'] ?? '';

  static String? _testToken;
  static void setToken(String? token) => _testToken = token;

  static String? _getToken() {
    if (_testToken != null) return _testToken;
    return Supabase.instance.client.auth.currentSession?.accessToken;
  }

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer eyJhbGciOiJFUzI1NiIsImtpZCI6ImNlZGFjNzExLWJkM2YtNDU2My1iOGE4LTJlODRhZDcwMjZiOCIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJodHRwczovL21yeGZrZXNiZ3VqcGl6Z3l5dWhjLnN1cGFiYXNlLmNvL2F1dGgvdjEiLCJzdWIiOiIwMWZiZGExNy1mODgxLTQzYmUtYmZlZS1jMjJmYzFmZmM3NjUiLCJhdWQiOiJhdXRoZW50aWNhdGVkIiwiZXhwIjoxNzc1NDIwMzA5LCJpYXQiOjE3NzU0MTY3MDksImVtYWlsIjoiZnVsb3BtaWxhbjE3MEBnbWFpbC5jb20iLCJwaG9uZSI6IiIsImFwcF9tZXRhZGF0YSI6eyJwcm92aWRlciI6ImVtYWlsIiwicHJvdmlkZXJzIjpbImVtYWlsIiwiZ29vZ2xlIl19LCJ1c2VyX21ldGFkYXRhIjp7ImF2YXRhcl91cmwiOiJodHRwczovL2xoMy5nb29nbGV1c2VyY29udGVudC5jb20vYS9BQ2c4b2NKOG5TTnBoZ1ZxRHdHQ3JVUlE3RlRfeTVJUFZvTXA3WlFhWjF5alBTc3JtOXVwOWkxVT1zOTYtYyIsImVtYWlsIjoiZnVsb3BtaWxhbjE3MEBnbWFpbC5jb20iLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwiZnVsbF9uYW1lIjoiRsO8bMO2cCBNaWzDoW4iLCJpc3MiOiJodHRwczovL2FjY291bnRzLmdvb2dsZS5jb20iLCJuYW1lIjoiRsO8bMO2cCBNaWzDoW4iLCJwaG9uZV92ZXJpZmllZCI6ZmFsc2UsInBpY3R1cmUiOiJodHRwczovL2xoMy5nb29nbGV1c2VyY29udGVudC5jb20vYS9BQ2c4b2NKOG5TTnBoZ1ZxRHdHQ3JVUlE3RlRfeTVJUFZvTXA3WlFhWjF5alBTc3JtOXVwOWkxVT1zOTYtYyIsInByb3ZpZGVyX2lkIjoiMTEzMzM0ODAwOTMxMjMwNDc5NTIzIiwic3ViIjoiMTEzMzM0ODAwOTMxMjMwNDc5NTIzIn0sInJvbGUiOiJhdXRoZW50aWNhdGVkIiwiYWFsIjoiYWFsMSIsImFtciI6W3sibWV0aG9kIjoicGFzc3dvcmQiLCJ0aW1lc3RhbXAiOjE3NzU0MTY3MDl9XSwic2Vzc2lvbl9pZCI6IjkzZGJiY2Q0LTRiMmMtNGQ2Ny05YTk4LWM1YjZiYTdlZTI3NyIsImlzX2Fub255bW91cyI6ZmFsc2V9.uFPlbqPCETFShbiIYMPGDLijOqSVfng2InCCUxl0z6AiriJoJ3f7pZ-QAeU4-8m4vu4tizHo9LSX9OX7FpTYDw',
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

  static Future<dynamic> delete(String path) async {
    final response = await _client.delete(
      Uri.parse('$_baseUrl$path'),
      headers: _headers,
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