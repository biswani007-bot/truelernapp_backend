import 'package:flutter_test/flutter_test.dart';
import 'package:truelearn/features/dashboard/data/models/dashboard_dto.dart';

void main() {
  group('DashboardDto Date Filtering for "TODAY\'S CLASS"', () {
    final now = DateTime.now();

    test('ignores future class scheduled days ahead (e.g. Sept 30 when today is Sept 18)', () {
      final futureDate = now.add(const Duration(days: 12));
      final json = {
        'upcomingLiveClasses': [
          {
            'id': 'future-class-1',
            'classTitle': 'Junior Foundation first class',
            'startDate': futureDate.toUtc().toIso8601String(),
            'duration': 60,
            'instructor': {'name': 'Elizabeth Vance'},
            'effectiveStatus': 'SCHEDULED',
          }
        ]
      };

      final dto = DashboardDto.fromJson(json);
      expect(dto.featuredClass, isNull,
          reason: 'Future classes must not be featured under "TODAY\'S CLASS"');
    });

    test('selects class occurring on current local calendar day', () {
      // Class occurring 2 hours from now today
      final todayDate = DateTime(now.year, now.month, now.day, 16, 0);
      final json = {
        'upcomingLiveClasses': [
          {
            'id': 'today-class-1',
            'classTitle': 'Today Foundation Class',
            'startDate': todayDate.toUtc().toIso8601String(),
            'duration': 60,
            'instructor': {'name': 'Teacher John'},
            'effectiveStatus': 'SCHEDULED',
          }
        ]
      };

      final dto = DashboardDto.fromJson(json);
      expect(dto.featuredClass, isNotNull,
          reason: 'A class occurring today must be selected');
      expect(dto.featuredClass!.id, equals('today-class-1'));
      expect(dto.featuredClass!.title, equals('Today Foundation Class'));
      expect(dto.featuredClass!.teacherName, equals('Teacher John'));
    });

    test('when API returns both today class and future class, selects today class', () {
      final todayDate = DateTime(now.year, now.month, now.day, 14, 30);
      final futureDate = now.add(const Duration(days: 5));

      final json = {
        'upcomingLiveClasses': [
          {
            'id': 'future-class-1',
            'classTitle': 'Next Week Class',
            'startDate': futureDate.toUtc().toIso8601String(),
            'duration': 60,
            'instructor': {'name': 'Teacher Amy'},
          },
          {
            'id': 'today-class-1',
            'classTitle': 'Today Session',
            'startDate': todayDate.toUtc().toIso8601String(),
            'duration': 60,
            'instructor': {'name': 'Teacher Bob'},
          },
        ]
      };

      final dto = DashboardDto.fromJson(json);
      expect(dto.featuredClass, isNotNull);
      expect(dto.featuredClass!.id, equals('today-class-1'));
      expect(dto.featuredClass!.title, equals('Today Session'));
    });

    test('when child has no classes today, featuredClass is null', () {
      final json = {
        'upcomingLiveClasses': <dynamic>[],
      };

      final dto = DashboardDto.fromJson(json);
      expect(dto.featuredClass, isNull);
    });
  });
}
