import '../entities/security_activity_entity.dart';

abstract class SecurityActivityRepository {
  /// Fetches recent security and authentication activity logs.
  Future<List<SecurityActivityEntity>> getActivityLogs();
}
