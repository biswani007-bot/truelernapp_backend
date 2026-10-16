import '../../domain/entities/counseling_request_entity.dart';
import '../../domain/entities/counselor_entity.dart';

/// Sealed state hierarchy for the Counselor feature.
sealed class CounselorState {
  const CounselorState();
}

/// Initial state before data request.
final class CounselorInitial extends CounselorState {
  const CounselorInitial();
}

/// Loading state showing TrueLern skeleton placeholders.
final class CounselorLoading extends CounselorState {
  const CounselorLoading();
}

/// Successfully loaded state containing counselors and any user sessions.
final class CounselorLoaded extends CounselorState {
  const CounselorLoaded({
    required this.counselors,
    required this.myRequests,
    required this.activeChildId,
  });

  final List<CounselorEntity> counselors;
  final List<CounselingRequestEntity> myRequests;
  final String? activeChildId;

  bool get hasCounselor => counselors.isNotEmpty;
  CounselorEntity? get primaryCounselor =>
      counselors.isNotEmpty ? counselors.first : null;
}

/// Error state when network/server request fails.
final class CounselorError extends CounselorState {
  const CounselorError(this.message, {this.activeChildId});

  final String message;
  final String? activeChildId;
}
