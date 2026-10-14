import 'package:flutter/foundation.dart';

import '../../domain/entities/security_activity_entity.dart';

@immutable
sealed class SecurityActivityState {
  const SecurityActivityState();
}

class SecurityActivityInitial extends SecurityActivityState {
  const SecurityActivityInitial();
}

class SecurityActivityLoading extends SecurityActivityState {
  const SecurityActivityLoading();
}

class SecurityActivityLoaded extends SecurityActivityState {
  const SecurityActivityLoaded({
    required this.activities,
    this.selectedFilter = 'All',
  });

  final List<SecurityActivityEntity> activities;
  final String selectedFilter;

  List<SecurityActivityEntity> get filteredActivities {
    switch (selectedFilter.toLowerCase()) {
      case 'logins':
        return activities
            .where((a) =>
                a.action.toUpperCase().contains('LOGIN') ||
                a.action.toUpperCase().contains('AUTH'))
            .toList();
      case 'devices':
        return activities
            .where((a) =>
                a.action.toUpperCase().contains('DEVICE') ||
                a.action.toUpperCase().contains('SESSION') ||
                a.action.toUpperCase().contains('REVOKE'))
            .toList();
      case 'security':
        return activities
            .where((a) =>
                a.action.toUpperCase().contains('PASSWORD') ||
                a.action.toUpperCase().contains('TOKEN') ||
                a.action.toUpperCase().contains('KEY') ||
                a.action.toUpperCase().contains('SECURITY'))
            .toList();
      case 'all':
      default:
        return activities;
    }
  }

  SecurityActivityLoaded copyWith({
    List<SecurityActivityEntity>? activities,
    String? selectedFilter,
  }) {
    return SecurityActivityLoaded(
      activities: activities ?? this.activities,
      selectedFilter: selectedFilter ?? this.selectedFilter,
    );
  }
}

class SecurityActivityError extends SecurityActivityState {
  const SecurityActivityError({required this.message});

  final String message;
}
