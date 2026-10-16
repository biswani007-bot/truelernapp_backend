import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Supported application execution environments.
enum AppEnvironment { production }

/// Centralized configuration for TrueLern mobile application.
///
/// Production API base URL is strictly locked to `https://truelern.visital.in/api`.
/// Multi-environment configuration can be supported via `--dart-define=ENV=...`
/// without requiring external environment packages.
class AppConfig {
  const AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.connectTimeout,
    required this.receiveTimeout,
    required this.sendTimeout,
  });

  final AppEnvironment environment;
  final String apiBaseUrl;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final Duration sendTimeout;

  /// Authoritative production configuration baseline.
  static const AppConfig production = AppConfig(
    environment: AppEnvironment.production,
    apiBaseUrl: 'https://truelern.visital.in/api',
    connectTimeout: Duration(seconds: 15),
    receiveTimeout: Duration(seconds: 15),
    sendTimeout: Duration(seconds: 15),
  );
}

/// Global provider exposing the active [AppConfig].
final appConfigProvider = Provider<AppConfig>((ref) {
  return AppConfig.production;
});
