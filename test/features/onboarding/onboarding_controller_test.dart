import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truelearn/core/network/api_client.dart';
import 'package:truelearn/features/onboarding/presentation/controllers/onboarding_controller.dart';

class FakeApiClient extends ApiClient {
  FakeApiClient() : super(dio: Dio());

  dynamic getResponseData;
  dynamic postResponseData;
  Exception? postErrorToThrow;
  String? lastPostPath;
  dynamic lastPostData;
  int postCallCount = 0;

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: getResponseData as T,
    );
  }

  @override
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    postCallCount++;
    if (postErrorToThrow != null) {
      throw postErrorToThrow!;
    }
    lastPostPath = path;
    lastPostData = data;
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: 201,
      data: postResponseData as T,
    );
  }
}

void main() {
  late FakeApiClient fakeApiClient;
  late ProviderContainer container;

  setUp(() {
    fakeApiClient = FakeApiClient();
    container = ProviderContainer(
      overrides: [apiClientProvider.overrideWithValue(fakeApiClient)],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('OnboardingController Tests', () {
    test('initial state contains default values and empty course options', () {
      final state = container.read(onboardingControllerProvider);

      expect(state.parentFullName, isEmpty);
      expect(state.parentEmail, isEmpty);
      expect(state.availableCourses, isEmpty);
      expect(state.isSubmitted, isFalse);
    });

    test('updateInterests updates course and timeZone', () {
      final notifier = container.read(onboardingControllerProvider.notifier);
      notifier.updateInterests(
        course: 'Junior Public Speaking',
        timeZone: 'Asia/Kolkata (IST +5:30)',
      );

      final state = container.read(onboardingControllerProvider);
      expect(state.interestedCourse, 'Junior Public Speaking');
      expect(state.timeZone, 'Asia/Kolkata (IST +5:30)');
    });

    test('updateAccountDetails updates parent fullName', () {
      final notifier = container.read(onboardingControllerProvider.notifier);
      notifier.updateAccountDetails(fullName: 'John Doe');

      final state = container.read(onboardingControllerProvider);
      expect(state.parentFullName, 'John Doe');
    });

    test(
      'updateChildDetails updates childName, childAge, and first/last names',
      () {
        final notifier = container.read(onboardingControllerProvider.notifier);
        notifier.updateChildDetails(
          childFirstName: 'Sammy',
          childLastName: 'Doe',
          childName: 'Sammy Doe',
          childAge: 7,
        );

        final state = container.read(onboardingControllerProvider);
        expect(state.childFirstName, 'Sammy');
        expect(state.childLastName, 'Doe');
        expect(state.childName, 'Sammy Doe');
        expect(state.childAge, 7);
      },
    );

    test('updateLocation updates state and city', () {
      final notifier = container.read(onboardingControllerProvider.notifier);
      notifier.updateLocation(
        stateName: 'California',
        cityName: 'San Francisco',
      );

      final state = container.read(onboardingControllerProvider);
      expect(state.state, 'California');
      expect(state.city, 'San Francisco');
    });

    test(
      'loadCourses populates availableCourses from GET /public/courses',
      () async {
        fakeApiClient.getResponseData = {
          'status': 'success',
          'data': [
            {'title': 'ACE Public Speaking Program'},
            {'name': 'Young Leaders Debate'},
            {'courseName': 'Creative Writing Mastery'},
          ],
        };

        await container
            .read(onboardingControllerProvider.notifier)
            .loadCourses();

        final state = container.read(onboardingControllerProvider);
        expect(state.availableCourses.map((c) => c.courseName).toList(), [
          'ACE Public Speaking Program',
          'Young Leaders Debate',
          'Creative Writing Mastery',
        ]);
      },
    );

    test('submitLead dispatches lead payload to POST /public/lead and flags submission', () async {
      final notifier = container.read(onboardingControllerProvider.notifier);
      notifier.updateInterests(course: 'ACE Speaking', timeZone: 'EST');
      notifier.updateAccountDetails(fullName: 'Alice Smith');
      notifier.updateChildDetails(childName: 'Bob Smith', childAge: 6);
      notifier.updateLocation(stateName: 'New York', cityName: 'Albany');

      fakeApiClient.postResponseData = {
        'status': 'success',
        'leadId': 'lead_998877',
      };

      final success = await notifier.submitLead();

      expect(success, isTrue);
      expect(fakeApiClient.lastPostPath, '/public/lead');

      final payload = fakeApiClient.lastPostData as Map<String, dynamic>;
      expect(payload['fullName'], 'Alice Smith');
      expect(payload['childName'], 'Bob Smith');
      expect(payload['childAge'], 6);
      expect(payload['interestedCourse'], 'ACE Speaking');

      final state = container.read(onboardingControllerProvider);
      expect(state.isSubmitted, isTrue);
      expect(state.submissionLeadId, 'lead_998877');
    });

    test('Scenario D: submitLead preserves entered data on failure and sets errorMessage', () async {
      final notifier = container.read(onboardingControllerProvider.notifier);
      notifier.updateInterests(course: 'ACE Speaking', timeZone: 'EST');
      notifier.updateAccountDetails(fullName: 'Alice Smith');
      notifier.updateChildDetails(childName: 'Bob Smith', childAge: 6);
      notifier.updateLocation(stateName: 'New York', cityName: 'Albany');

      // Configure fake API client to throw network exception
      fakeApiClient.postErrorToThrow = DioException(
        requestOptions: RequestOptions(path: '/public/lead'),
        error: 'Network connection timeout',
        type: DioExceptionType.connectionTimeout,
      );

      final success = await notifier.submitLead();

      expect(success, isFalse);

      final state = container.read(onboardingControllerProvider);
      expect(state.isSubmitted, isFalse);
      expect(state.isSubmitting, isFalse);
      expect(state.errorMessage, isNotNull);
      // All user input is preserved for safe retry
      expect(state.parentFullName, 'Alice Smith');
      expect(state.childName, 'Bob Smith');
      expect(state.childAge, 6);
      expect(state.interestedCourse, 'ACE Speaking');
      expect(state.state, 'New York');
      expect(state.city, 'Albany');

      // Safe retry after network error recovers
      fakeApiClient.postErrorToThrow = null;
      fakeApiClient.postResponseData = {
        'status': 'success',
        'leadId': 'lead_retry_123',
      };

      final retrySuccess = await notifier.submitLead();
      expect(retrySuccess, isTrue);

      final retryState = container.read(onboardingControllerProvider);
      expect(retryState.isSubmitted, isTrue);
      expect(retryState.submissionLeadId, 'lead_retry_123');
    });

    test('Scenario D: submitLead prevents duplicate submission while request is in flight', () async {
      final notifier = container.read(onboardingControllerProvider.notifier);
      notifier.updateInterests(course: 'ACE Speaking', timeZone: 'EST');
      notifier.updateAccountDetails(fullName: 'Alice Smith');
      notifier.updateChildDetails(childName: 'Bob Smith', childAge: 6);
      notifier.updateLocation(stateName: 'New York', cityName: 'Albany');

      fakeApiClient.postResponseData = {
        'status': 'success',
        'leadId': 'lead_single_flight',
      };

      // Fire two submitLead calls simultaneously
      final future1 = notifier.submitLead();
      final future2 = notifier.submitLead();

      final results = await Future.wait([future1, future2]);

      // Exactly one submission succeeded, the other was guarded against duplicate re-entrancy
      expect(results.contains(true), isTrue);
      expect(fakeApiClient.postCallCount, 1);
    });
  });
}
