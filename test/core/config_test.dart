import 'package:flutter_test/flutter_test.dart';
import 'package:truelearn/core/config/app_config.dart';

void main() {
  group('AppConfig Tests', () {
    test('production config exposes authoritative API base URL', () {
      expect(
        AppConfig.production.apiBaseUrl,
        'https://truelern.visital.in/api',
      );
    });

    test('production config defines safe timeouts', () {
      expect(AppConfig.production.connectTimeout, const Duration(seconds: 15));
      expect(AppConfig.production.receiveTimeout, const Duration(seconds: 15));
      expect(AppConfig.production.sendTimeout, const Duration(seconds: 15));
    });

    test('production config has production environment flag', () {
      expect(AppConfig.production.environment, AppEnvironment.production);
    });
  });
}
