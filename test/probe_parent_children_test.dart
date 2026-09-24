import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

// ignore_for_file: avoid_print

void main() {
  test('Probe dashboard for Mia and Alex', () async {
    final dio = Dio(
      BaseOptions(
        baseUrl: 'https://truelern.visital.in/api',
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      ),
    );

    final loginRes = await dio.post('/auth/login', data: {
      'email': 'parent@truelern.com',
      'password': 'password123',
    });
    final body = loginRes.data;
    final payload = (body['data'] is Map<String, dynamic>)
        ? body['data'] as Map<String, dynamic>
        : body as Map<String, dynamic>;
    final token = (payload['accessToken'] ?? payload['token']).toString();
    dio.options.headers['Authorization'] = 'Bearer $token';

    for (final id in ['6a87e05e9b5f64a15873f66c', '6a87011efae35df7c876b0ab']) {
      try {
        final res = await dio.get('/parent/children/$id/dashboard');
        print('DASHBOARD FOR $id:');
        print(res.data);
      } catch (e) {
        if (e is DioException) {
          print('ERROR FOR $id: ${e.response?.data}');
        }
      }
    }
  });
}
