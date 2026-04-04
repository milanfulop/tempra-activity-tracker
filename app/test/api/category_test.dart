import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;
import 'package:tempra/shared/utils/api_service.dart';
import 'package:tempra/features/category_editor/utils/category_editor_utils.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  late MockHttpClient mockClient;

  setUpAll(() {
    registerFallbackValue(Uri.parse('http://localhost'));
  });

  setUp(() {
    ApiService.setBaseUrl('http://localhost:3000');
    ApiService.setToken('test-token');
    mockClient = MockHttpClient();
    ApiService.setClient(mockClient);
  });

  tearDown(() {
    reset(mockClient);
    ApiService.setToken(null);
  });

  // ── helpers ──────────────────────────────────────────────────────────────

  void mockPost(int statusCode, {String body = '{}'}) {
    when(() => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        )).thenAnswer((_) async => http.Response(body, statusCode));
  }

  void mockPut(int statusCode, {String body = '{}'}) {
    when(() => mockClient.put(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        )).thenAnswer((_) async => http.Response(body, statusCode));
  }

  void mockDelete(int statusCode, {String body = '{}'}) {
    when(() => mockClient.delete(
          any(),
          headers: any(named: 'headers'),
        )).thenAnswer((_) async => http.Response(body, statusCode));
  }

  /// Captures the actual request body sent to the mock client
  Future<Map<String, dynamic>> capturePostBody() async {
    final captured = verify(() => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: captureAny(named: 'body'),
        )).captured;
    return jsonDecode(captured.first as String) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> capturePutBody() async {
    final captured = verify(() => mockClient.put(
          any(),
          headers: any(named: 'headers'),
          body: captureAny(named: 'body'),
        )).captured;
    return jsonDecode(captured.first as String) as Map<String, dynamic>;
  }

  // ── createCategory ───────────────────────────────────────────────────────

  group('createCategory', () {
    test('completes successfully on 201', () async {
      mockPost(201);

      expect(
        () => createCategory(
          id: '1',
          name: 'Work',
          color: const Color(0xFFFF5733),
          isProductive: true,
        ),
        returnsNormally,
      );
    });

    test('completes successfully on 200', () async {
      mockPost(200);

      expect(
        () => createCategory(
          id: '1',
          name: 'Work',
          color: const Color(0xFFFF5733),
          isProductive: true,
        ),
        returnsNormally,
      );
    });

    test('sends correct body fields', () async {
      mockPost(201);

      await createCategory(
        id: '1',
        name: 'Work',
        color: const Color(0xFFFF5733),
        isProductive: true,
      );

      final body = await capturePostBody();
      expect(body['name'], 'Work');
      expect(body['color'], '#ff5733');
      expect(body['is_productive'], true);
    });

    test('sends correct color hex for productive=false', () async {
      mockPost(201);

      await createCategory(
        id: '1',
        name: 'Sleep',
        color: const Color(0xFF3399FF),
        isProductive: false,
      );

      final body = await capturePostBody();
      expect(body['color'], '#3399ff');
      expect(body['is_productive'], false);
    });

    test('sends correct hex for black color', () async {
      mockPost(201);

      await createCategory(
        id: '1',
        name: 'Other',
        color: const Color(0xFF000000),
        isProductive: false,
      );

      final body = await capturePostBody();
      expect(body['color'], '#000000');
    });

    test('sends correct hex for white color', () async {
      mockPost(201);

      await createCategory(
        id: '1',
        name: 'Other',
        color: const Color(0xFFFFFFFF),
        isProductive: false,
      );

      final body = await capturePostBody();
      expect(body['color'], '#ffffff');
    });

    test('hex is always lowercase', () async {
      mockPost(201);

      await createCategory(
        id: '1',
        name: 'Work',
        color: const Color(0xFFAABBCC),
        isProductive: true,
      );

      final body = await capturePostBody();
      expect(body['color'], '#aabbcc');
    });

    test('calls POST /category endpoint', () async {
      mockPost(201);

      await createCategory(
        id: '1',
        name: 'Work',
        color: const Color(0xFFFF5733),
        isProductive: true,
      );

      verify(() => mockClient.post(
            Uri.parse('http://localhost:3000/category'),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).called(1);
    });

    test('throws on 400 bad request', () async {
      mockPost(400, body: '{"message":"Invalid input"}');

      await expectLater(
        () => createCategory(
          id: '1',
          name: '',
          color: const Color(0xFFFF5733),
          isProductive: true,
        ),
        throwsException,
      );
    });

    test('throws on 401 unauthorized', () async {
      mockPost(401, body: '{"message":"Unauthorized"}');

      await expectLater(
        () => createCategory(
          id: '1',
          name: 'Work',
          color: const Color(0xFFFF5733),
          isProductive: true,
        ),
        throwsException,
      );
    });

    test('throws on 500 server error', () async {
      mockPost(500, body: '{"message":"Internal Server Error"}');

      await expectLater(
        () => createCategory(
          id: '1',
          name: 'Work',
          color: const Color(0xFFFF5733),
          isProductive: true,
        ),
        throwsException,
      );
    });
  });

  // ── deleteCategory ───────────────────────────────────────────────────────

  group('deleteCategory', () {
    test('completes successfully on 200', () async {
      mockDelete(200);

      await expectLater(
        () => deleteCategory('123'),
        returnsNormally,
      );
    });

    test('completes successfully on 204 no content', () async {
      mockDelete(204, body: '');

      await expectLater(
        () => deleteCategory('123'),
        returnsNormally,
      );
    });

    test('calls DELETE /category/:id with correct id', () async {
      mockDelete(200);

      await deleteCategory('abc-999');

      verify(() => mockClient.delete(
            Uri.parse('http://localhost:3000/category/abc-999'),
            headers: any(named: 'headers'),
          )).called(1);
    });

    test('throws on 404 not found', () async {
      mockDelete(404, body: '{"message":"Category not found"}');

      await expectLater(
        () => deleteCategory('nonexistent'),
        throwsException,
      );
    });

    test('throws on 401 unauthorized', () async {
      mockDelete(401, body: '{"message":"Unauthorized"}');

      await expectLater(
        () => deleteCategory('123'),
        throwsException,
      );
    });

    test('throws on 500 server error', () async {
      mockDelete(500, body: '{"message":"Internal Server Error"}');

      await expectLater(
        () => deleteCategory('123'),
        throwsException,
      );
    });
  });

  // ── editCategory ─────────────────────────────────────────────────────────

  group('editCategory', () {
    test('completes successfully on 200', () async {
      mockPut(200);

      await expectLater(
        () => editCategory(
          id: '1',
          name: 'Work',
          color: const Color(0xFFFF5733),
          isProductive: true,
        ),
        returnsNormally,
      );
    });

    test('sends correct body fields', () async {
      mockPut(200);

      await editCategory(
        id: '1',
        name: 'Updated Work',
        color: const Color(0xFF123456),
        isProductive: false,
      );

      final body = await capturePutBody();
      expect(body['name'], 'Updated Work');
      expect(body['color'], '#123456');
      expect(body['is_productive'], false);
    });

    test('calls PUT /category/:id with correct id', () async {
      mockPut(200);

      await editCategory(
        id: 'abc-42',
        name: 'Work',
        color: const Color(0xFFFF5733),
        isProductive: true,
      );

      verify(() => mockClient.put(
            Uri.parse('http://localhost:3000/category/abc-42'),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).called(1);
    });

    test('throws on 404 not found', () async {
      mockPut(404, body: '{"message":"Category not found"}');

      await expectLater(
        () => editCategory(
          id: 'nonexistent',
          name: 'Work',
          color: const Color(0xFFFF5733),
          isProductive: true,
        ),
        throwsException,
      );
    });

    test('throws on 401 unauthorized', () async {
      mockPut(401, body: '{"message":"Unauthorized"}');

      await expectLater(
        () => editCategory(
          id: '1',
          name: 'Work',
          color: const Color(0xFFFF5733),
          isProductive: true,
        ),
        throwsException,
      );
    });

    test('throws on 500 server error', () async {
      mockPut(500, body: '{"message":"Internal Server Error"}');

      await expectLater(
        () => editCategory(
          id: '1',
          name: 'Work',
          color: const Color(0xFFFF5733),
          isProductive: true,
        ),
        throwsException,
      );
    });
  });
}