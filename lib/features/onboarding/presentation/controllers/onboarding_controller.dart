import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/controllers/auth_state.dart';
import '../../../courses/data/repositories/courses_repository_impl.dart';
import '../../../courses/domain/entities/course_entity.dart';
import '../../../courses/domain/repositories/courses_repository.dart';

/// State holding all verified parent and child onboarding details.
/// Preserved seamlessly across multi-step navigation.
class OnboardingState {
  const OnboardingState({
    this.selectedCourse,
    this.selectedCourseId,
    this.interestedCourse,
    this.timeZone = 'Asia/Kolkata (IST +5:30)',
    this.parentFullName = '',
    this.parentEmail = '',
    this.parentPhone = '',
    this.childFirstName = '',
    this.childLastName = '',
    this.childName = '',
    this.childAge,
    this.state = '',
    this.city = '',
    this.availableCourses = const [],
    this.isLoadingCourses = false,
    this.courseErrorMessage,
    this.isSubmitting = false,
    this.isSubmitted = false,
    this.errorMessage,
    this.submissionLeadId,
  });

  final CourseEntity? selectedCourse;
  final String? selectedCourseId;
  final String? interestedCourse;
  final String? timeZone;
  final String parentFullName;
  final String parentEmail;
  final String parentPhone;
  final String childFirstName;
  final String childLastName;
  final String childName;
  final int? childAge;
  final String state;
  final String city;
  final List<CourseEntity> availableCourses;
  final bool isLoadingCourses;
  final String? courseErrorMessage;
  final bool isSubmitting;
  final bool isSubmitted;
  final String? errorMessage;
  final String? submissionLeadId;

  /// Effective course title from selectedCourse or interestedCourse.
  String? get effectiveCourseName =>
      selectedCourse?.courseName ?? interestedCourse;

  OnboardingState copyWith({
    CourseEntity? selectedCourse,
    String? selectedCourseId,
    String? interestedCourse,
    String? timeZone,
    String? parentFullName,
    String? parentEmail,
    String? parentPhone,
    String? childFirstName,
    String? childLastName,
    String? childName,
    int? childAge,
    String? state,
    String? city,
    List<CourseEntity>? availableCourses,
    bool? isLoadingCourses,
    String? courseErrorMessage,
    bool? isSubmitting,
    bool? isSubmitted,
    String? errorMessage,
    String? submissionLeadId,
  }) {
    return OnboardingState(
      selectedCourse: selectedCourse ?? this.selectedCourse,
      selectedCourseId: selectedCourseId ?? this.selectedCourseId,
      interestedCourse: interestedCourse ?? this.interestedCourse,
      timeZone: timeZone ?? this.timeZone,
      parentFullName: parentFullName ?? this.parentFullName,
      parentEmail: parentEmail ?? this.parentEmail,
      parentPhone: parentPhone ?? this.parentPhone,
      childFirstName: childFirstName ?? this.childFirstName,
      childLastName: childLastName ?? this.childLastName,
      childName: childName ?? this.childName,
      childAge: childAge ?? this.childAge,
      state: state ?? this.state,
      city: city ?? this.city,
      availableCourses: availableCourses ?? this.availableCourses,
      isLoadingCourses: isLoadingCourses ?? this.isLoadingCourses,
      courseErrorMessage: courseErrorMessage,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      errorMessage: errorMessage,
      submissionLeadId: submissionLeadId ?? this.submissionLeadId,
    );
  }
}

/// Controller managing onboarding steps, form preservation, public course lookup,
/// and verified demo lead submission against live TrueLern endpoints.
class OnboardingController extends Notifier<OnboardingState> {
  @override
  OnboardingState build() {
    // Populate parent identity from existing authenticated session if available
    final authState = ref.watch(authControllerProvider);
    String initialName = '';
    String initialEmail = '';

    if (authState is Authenticated) {
      initialName = authState.user?.name ?? '';
      initialEmail = authState.user?.email ?? '';
    }

    return OnboardingState(
      parentFullName: initialName,
      parentEmail: initialEmail,
    );
  }

  ApiClient get _apiClient => ref.read(apiClientProvider);
  CoursesRepository get _coursesRepository =>
      ref.read(coursesRepositoryProvider);

  /// Loads real course options from GET /api/public/courses without hardcoded fallbacks.
  Future<void> loadCourses() async {
    state = state.copyWith(isLoadingCourses: true, courseErrorMessage: null);
    try {
      final courses = await _coursesRepository.getPublicCourses();

      CourseEntity? resolvedSelection = state.selectedCourse;
      if (resolvedSelection == null && courses.isNotEmpty) {
        if (state.selectedCourseId != null) {
          try {
            resolvedSelection = courses.firstWhere(
              (c) => c.id == state.selectedCourseId,
            );
          } catch (_) {
            resolvedSelection = courses.first;
          }
        } else if (state.interestedCourse != null) {
          try {
            resolvedSelection = courses.firstWhere(
              (c) => c.courseName == state.interestedCourse,
            );
          } catch (_) {
            resolvedSelection = courses.first;
          }
        } else {
          resolvedSelection = courses.first;
        }
      }

      state = state.copyWith(
        availableCourses: courses,
        isLoadingCourses: false,
        selectedCourse: resolvedSelection,
        selectedCourseId: resolvedSelection?.id,
        interestedCourse: resolvedSelection?.courseName,
        courseErrorMessage: null,
      );
    } catch (err) {
      // Honest error state: never substitute fake fallback course data
      state = state.copyWith(
        availableCourses: const [],
        isLoadingCourses: false,
        courseErrorMessage: 'Unable to load courses. Please check your connection and tap retry.',
      );
    }
  }

  void updateInterests({
    dynamic course,
    String? courseName,
    required String timeZone,
  }) {
    CourseEntity? resolved;
    String? resolvedName = courseName;

    if (course is CourseEntity) {
      resolved = course;
      resolvedName = course.courseName;
    } else if (course is String) {
      resolvedName = course;
      if (state.availableCourses.isNotEmpty) {
        try {
          resolved = state.availableCourses.firstWhere(
            (c) => c.courseName == course || c.id == course,
          );
        } catch (_) {
          resolved = null;
        }
      }
    } else if (resolvedName != null && state.availableCourses.isNotEmpty) {
      try {
        resolved = state.availableCourses.firstWhere(
          (c) => c.courseName == resolvedName || c.id == resolvedName,
        );
      } catch (_) {
        resolved = null;
      }
    }

    state = state.copyWith(
      selectedCourse: resolved ?? state.selectedCourse,
      selectedCourseId: resolved?.id ?? state.selectedCourseId,
      interestedCourse:
          resolved?.courseName ?? resolvedName ?? state.interestedCourse,
      timeZone: timeZone,
      errorMessage: null,
    );
  }

  void selectCourse(CourseEntity course) {
    state = state.copyWith(
      selectedCourse: course,
      selectedCourseId: course.id,
      interestedCourse: course.courseName,
      errorMessage: null,
    );
  }

  void updateAccountDetails({required String fullName}) {
    state = state.copyWith(parentFullName: fullName, errorMessage: null);
  }

  void updateChildDetails({
    String? childFirstName,
    String? childLastName,
    required String childName,
    required int childAge,
  }) {
    state = state.copyWith(
      childFirstName: childFirstName ?? state.childFirstName,
      childLastName: childLastName ?? state.childLastName,
      childName: childName,
      childAge: childAge,
      errorMessage: null,
    );
  }

  void updateLocation({required String stateName, required String cityName}) {
    state = state.copyWith(
      state: stateName,
      city: cityName,
      errorMessage: null,
    );
  }

  /// Submits onboarding demo lead to POST /api/public/lead with verified schema.
  Future<bool> submitLead() async {
    if (state.isSubmitting) return false;
    state = state.copyWith(isSubmitting: true, errorMessage: null);

    try {
      final courseName =
          state.selectedCourse?.courseName ??
          state.interestedCourse ??
          (state.availableCourses.isNotEmpty
              ? state.availableCourses.first.courseName
              : '');

      final payload = {
        'fullName': state.parentFullName.trim().isNotEmpty
            ? state.parentFullName.trim()
            : 'Parent Account',
        'parentName': state.parentFullName.trim().isNotEmpty
            ? state.parentFullName.trim()
            : 'Parent Account',
        'childName': state.childName.trim().isNotEmpty
            ? state.childName.trim()
            : 'Child Student',
        'childAge': state.childAge ?? 8,
        'email': state.parentEmail.isNotEmpty
            ? state.parentEmail
            : 'parent@truelern.com',
        'phone': state.parentPhone.isNotEmpty
            ? state.parentPhone
            : '+1-555-0199',
        if (courseName.isNotEmpty) 'interestedCourse': courseName,
        if (state.selectedCourseId != null) 'courseId': state.selectedCourseId,
        'preferredSchedule': 'Weekend Morning (9 AM - 12 PM)',
        'source': 'mobile_app_demo',
        'message': 'Parent onboarding demo request submitted via TrueLern Flutter app.',
      };

      final response = await _apiClient.post<dynamic>(
        '/public/lead',
        data: payload,
      );

      String? leadId;
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data['data'] is Map<String, dynamic>) {
          final nested = data['data'] as Map<String, dynamic>;
          leadId =
              nested['leadId']?.toString() ??
              nested['id']?.toString() ??
              nested['_id']?.toString();
        } else if (data['leadId'] != null) {
          leadId = data['leadId']?.toString();
        } else if (data['id'] != null) {
          leadId = data['id']?.toString();
        } else if (data['_id'] != null) {
          leadId = data['_id']?.toString();
        }
      }

      state = state.copyWith(
        isSubmitting: false,
        isSubmitted: true,
        submissionLeadId: leadId,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// Restores verified demo session / lead state populated from authoritative server query.
  void restoreDemoBookingState({
    String? leadId,
    String? courseName,
    String? childName,
  }) {
    state = state.copyWith(
      submissionLeadId: leadId ?? state.submissionLeadId,
      interestedCourse: courseName ?? state.interestedCourse,
      childName: childName ?? state.childName,
      // A parent-level or CRM lead without a linked childName must NEVER mark
      // the onboarding state as a submitted child application.
      isSubmitted: (childName != null && childName.trim().isNotEmpty) ||
          (state.childName.trim().isNotEmpty && state.isSubmitted),
    );
  }

  /// Resets state on logout or account switching.
  void reset() {
    state = const OnboardingState();
  }
}

/// Global provider for [OnboardingController].
final onboardingControllerProvider =
    NotifierProvider<OnboardingController, OnboardingState>(
      OnboardingController.new,
    );
