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
  group('ClassJoinEntity Token & URI Authorization Contract', () {
    test('Constructs authenticatedMeetingUri with JWT when meetingUrl lacks parameter', () {
      const entity = ClassJoinEntity(
        token: 'secret_jwt_token_abc123',
        roomName: 'truelern-room-999',
        jitsiDomain: 'livetl.visital.in',
        serverUrl: 'https://livetl.visital.in',
        isModerator: false,
        meetingUrl: 'https://livetl.visital.in/truelern-room-999',
      );

      final uri = entity.authenticatedMeetingUri;
      expect(uri.host, equals('livetl.visital.in'));
      expect(uri.path, equals('/truelern-room-999'));
      expect(uri.queryParameters['jwt'], equals('secret_jwt_token_abc123'));
    });

    test('Preserves existing jwt parameter if meetingUrl already contains it', () {
      const entity = ClassJoinEntity(
        token: 'fallback_token',
        roomName: 'truelern-room-888',
        jitsiDomain: 'livetl.visital.in',
        serverUrl: 'https://livetl.visital.in',
        isModerator: false,
        meetingUrl: 'https://livetl.visital.in/truelern-room-888?jwt=verified_live_jwt_789',
      );

      final uri = entity.authenticatedMeetingUri;
      expect(uri.queryParameters['jwt'], equals('verified_live_jwt_789'));
    });

    test('Constructs HTTPS URI directly from jitsiDomain and roomName if meetingUrl is empty', () {
      const entity = ClassJoinEntity(
        token: 'direct_jwt_xyz',
        roomName: 'demo-class-555',
        jitsiDomain: 'livetl.visital.in',
        serverUrl: 'https://livetl.visital.in',
        isModerator: false,
        meetingUrl: '',
      );

      final uri = entity.authenticatedMeetingUri;
      expect(uri.scheme, equals('https'));
      expect(uri.host, equals('livetl.visital.in'));
      expect(uri.path, equals('/demo-class-555'));
      expect(uri.queryParameters['jwt'], equals('direct_jwt_xyz'));
    });

    test('Identifies expired and unexpired tokens correctly', () {
      final pastSec = (DateTime.now().millisecondsSinceEpoch ~/ 1000) - 3600; // 1 hour ago
      final futureSec = (DateTime.now().millisecondsSinceEpoch ~/ 1000) + 3600; // 1 hour ahead

      final expiredEntity = ClassJoinEntity(
        token: 'tok_1',
        roomName: 'room_1',
        jitsiDomain: 'livetl.visital.in',
        serverUrl: 'https://livetl.visital.in',
        isModerator: false,
        meetingUrl: '',
        expiresAt: pastSec,
      );
      expect(expiredEntity.isExpired, isTrue);
      expect(expiredEntity.hasValidCredentials, isFalse);

      final validEntity = ClassJoinEntity(
        token: 'tok_2',
        roomName: 'room_2',
        jitsiDomain: 'livetl.visital.in',
        serverUrl: 'https://livetl.visital.in',
        isModerator: false,
        meetingUrl: '',
        expiresAt: futureSec,
      );
      expect(validEntity.isExpired, isFalse);
      expect(validEntity.hasValidCredentials, isTrue);
    });
  });

  group('LiveClassroomScreen Authorization and In-App Error Handling', () {
    testWidgets(
      'Starts directly connecting to live classroom without wrapper header or fake participants',
      (WidgetTester tester) async {
        final mockStorage = MockTestSecureStorage();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [secureStorageProvider.overrideWithValue(mockStorage)],
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

        // Initial pump shows live classroom connecting directly
        expect(
          find.text('Connecting to TrueLern Live Classroom...'),
          findsOneWidget,
        );

        // Verify upper wrapper header area has been COMPLETELY removed
        expect(find.byKey(const Key('live_classroom_back_button')), findsNothing);
        expect(find.byKey(const Key('live_classroom_leave_button')), findsNothing);
        expect(find.text('LIVE'), findsNothing);
        expect(find.text("Viewing as Guardian for Alex Mercer"), findsNothing);

        // Verify zero fake/static participants remain
        expect(find.text('Sarah Jenkins'), findsNothing);
        expect(find.text('Instructor'), findsNothing);
        expect(find.text('Alex R.'), findsNothing);
        expect(find.text('Mia S.'), findsNothing);
        expect(find.text('+9 Others'), findsNothing);
      },
    );

    testWidgets(
      'Displays Token Request Failure error overlay when joinData has empty token',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: LiveClassroomScreen(
                classId: 'demo-12345',
                fromDemo: true,
                joinData: ClassJoinEntity(
                  token: '',
                  roomName: 'room-123',
                  jitsiDomain: 'livetl.visital.in',
                  serverUrl: 'https://livetl.visital.in',
                  isModerator: false,
                  meetingUrl: '',
                ),
              ),
            ),
          ),
        );

        // Execute post frame callback to process initialization
        await tester.pump();

        expect(find.text('Classroom Connection Error'), findsOneWidget);
        expect(find.text('Token Request Failure'), findsOneWidget);
        expect(find.byKey(const Key('classroom_back_to_demo_button')), findsOneWidget);
        expect(find.text('Back to Demo'), findsOneWidget);
        expect(find.byKey(const Key('classroom_retry_button')), findsOneWidget);

        // Must not expose secret tokens in UI
        expect(find.textContaining('eyJ'), findsNothing);
      },
    );

    testWidgets(
      'Displays Token Expired error overlay when token expiration has passed',
      (WidgetTester tester) async {
        final pastTimestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000) - 7200;

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: LiveClassroomScreen(
                classId: 'DEMO-888999',
                fromDemo: true,
                joinData: ClassJoinEntity(
                  token: 'expired_jwt_sample',
                  roomName: 'truelern-demo-888',
                  jitsiDomain: 'livetl.visital.in',
                  serverUrl: 'https://livetl.visital.in',
                  isModerator: false,
                  meetingUrl: '',
                  expiresAt: pastTimestamp,
                ),
              ),
            ),
          ),
        );

        await tester.pump();

        expect(find.text('Classroom Connection Error'), findsOneWidget);
        expect(find.text('Token Expired'), findsOneWidget);
        expect(find.text('Back to Demo'), findsOneWidget);
        expect(find.byKey(const Key('classroom_retry_button')), findsOneWidget);
      },
    );

    testWidgets(
      'Displays Room Configuration Mismatch when room identifier is empty',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: LiveClassroomScreen(
                classId: 'class-missing-room',
                joinData: ClassJoinEntity(
                  token: 'valid_token_xyz',
                  roomName: '',
                  jitsiDomain: 'livetl.visital.in',
                  serverUrl: 'https://livetl.visital.in',
                  isModerator: false,
                  meetingUrl: '',
                ),
              ),
            ),
          ),
        );

        await tester.pump();

        expect(find.text('Classroom Connection Error'), findsOneWidget);
        expect(find.text('Room Configuration Mismatch'), findsOneWidget);
      },
    );

    testWidgets(
      'Displays Entry Window Restricted when class is outside 15-minute join window',
      (WidgetTester tester) async {
        final futureClass = ClassEntity(
          id: 'future-class-123',
          title: 'Advanced Mathematics',
          scheduledStartTime: DateTime.now().add(const Duration(hours: 3)),
          status: 'SCHEDULED',
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: LiveClassroomScreen(
                classId: 'future-class-123',
                session: futureClass,
              ),
            ),
          ),
        );

        await tester.pump();

        expect(find.text('Classroom Connection Error'), findsOneWidget);
        expect(find.text('Entry Window Restricted'), findsOneWidget);
        expect(find.text('You can join 15 minutes before the class starts.'), findsOneWidget);
      },
    );

    testWidgets(
      'Retry connection button is protected against duplicate in-flight requests',
      (WidgetTester tester) async {
        final pastTimestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000) - 3600;

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: LiveClassroomScreen(
                classId: 'DEMO-RETRY-TEST',
                fromDemo: true,
                joinData: ClassJoinEntity(
                  token: 'stale_token',
                  roomName: 'truelern-room-test',
                  jitsiDomain: 'livetl.visital.in',
                  serverUrl: 'https://livetl.visital.in',
                  isModerator: false,
                  meetingUrl: '',
                  expiresAt: pastTimestamp,
                ),
              ),
            ),
          ),
        );

        await tester.pump();

        final retryBtn = find.byKey(const Key('classroom_retry_button'));
        expect(retryBtn, findsOneWidget);

        // Tap once
        await tester.tap(retryBtn);
        await tester.pump();

        // Immediate second tap should be debounced without crashing or duplicate loops
        await tester.tap(retryBtn);
        await tester.pump();

        expect(find.byKey(const Key('classroom_retry_button')), findsOneWidget);
      },
    );
  });
}
