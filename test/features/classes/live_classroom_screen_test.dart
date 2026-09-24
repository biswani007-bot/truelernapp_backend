import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truelearn/core/storage/secure_storage_service.dart';
import 'package:truelearn/features/classes/domain/entities/class_entity.dart';
import 'package:truelearn/features/classes/domain/entities/class_join_entity.dart';
import 'package:truelearn/features/classes/presentation/screens/live_classroom_screen.dart';

class MockTestSecureStorage implements SecureStorageService {
  @override
  Future<String?> getAccessToken() async => 'mock_access_token_12345';

  @override
  Future<void> saveAccessToken(String token) async {}

  @override
  Future<void> deleteAccessToken() async {}

  @override
  Future<String?> getRefreshToken() async => 'mock_refresh_token';

  @override
  Future<void> saveRefreshToken(String token) async {}

  @override
  Future<void> deleteRefreshToken() async {}

  @override
  Future<String?> getUserId() async => 'user_123';

  @override
  Future<void> saveUserId(String id) async {}

  @override
  Future<void> clearAuthSession() async {}

  @override
  Future<String?> getActiveChildId() async => 'child_123';

  @override
  Future<void> saveActiveChildId(String childId) async {}

  @override
  Future<void> deleteActiveChildId() async {}
}

void main() {
  testWidgets('LiveClassroomScreen removes upper header and starts directly from classroom', (WidgetTester tester) async {
    final mockStorage = MockTestSecureStorage();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          secureStorageProvider.overrideWithValue(mockStorage),
        ],
        child: const MaterialApp(
          home: LiveClassroomScreen(
            classId: '6ab24641aabd606a21c0dbdf',
            session: ClassEntity(
              id: '6ab24641aabd606a21c0dbdf',
              title: 'testing',
            ),
            joinData: ClassJoinEntity(
              token: 'test_token',
              roomName: 'truelern-6ab24641aabd606a21c0dbdf',
              jitsiDomain: 'livetl.visital.in',
              serverUrl: 'https://livetl.visital.in',
              isModerator: false,
              classTitle: 'testing',
              childName: 'Alex Mercer',
              meetingUrl: 'https://livetl.visital.in/truelern-6ab24641aabd606a21c0dbdf',
            ),
          ),
        ),
      ),
    );

    // Initial pump shows live classroom connecting directly without wrapper header
    expect(find.text('Connecting to TrueLern Live Classroom...'), findsOneWidget);

    // Verify upper classroom header area has been COMPLETELY removed (Requirement 1)
    expect(find.byKey(const Key('live_classroom_back_button')), findsNothing);
    expect(find.byKey(const Key('live_classroom_leave_button')), findsNothing);
    expect(find.text('LIVE'), findsNothing);
    expect(find.text("Viewing as Guardian for Alex Mercer"), findsNothing);

    // Verify absolutely ZERO fake/static participants remain
    expect(find.text('Sarah Jenkins'), findsNothing);
    expect(find.text('Instructor'), findsNothing);
    expect(find.text('Alex R.'), findsNothing);
    expect(find.text('Mia S.'), findsNothing);
    expect(find.text('+9 Others'), findsNothing);
  });
}
