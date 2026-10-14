import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/security_activity_repository_impl.dart';
import '../../domain/repositories/security_activity_repository.dart';
import 'security_activity_state.dart';

class SecurityActivityController extends Notifier<SecurityActivityState> {
  @override
  SecurityActivityState build() => const SecurityActivityInitial();

  SecurityActivityRepository get _repository =>
      ref.read(securityActivityRepositoryProvider);

  Future<void> loadActivityLogs({bool forceRefresh = false}) async {
    final current = state;
    if (!forceRefresh && current is SecurityActivityLoaded) return;
    if (current is SecurityActivityLoading) return;

    state = const SecurityActivityLoading();
    try {
      final logs = await _repository.getActivityLogs();
      state = SecurityActivityLoaded(activities: logs);
    } catch (e) {
      state = SecurityActivityError(message: e.toString());
    }
  }

  void setFilter(String filter) {
    final current = state;
    if (current is SecurityActivityLoaded) {
      state = current.copyWith(selectedFilter: filter);
    }
  }
}

final securityActivityControllerProvider =
    NotifierProvider<SecurityActivityController, SecurityActivityState>(
  SecurityActivityController.new,
);
