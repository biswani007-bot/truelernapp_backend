import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/repositories/assessments_repository_impl.dart';
import '../../domain/entities/assessment_attempt_details_entity.dart';
import '../../domain/entities/assessment_question_entity.dart';
import '../../domain/entities/assessment_submission_result_entity.dart';

/// Native TrueLern Assessment Test-Taking Screen.
///
/// Features:
/// - Real-time countdown timer synchronized with backend attempt start time
/// - Dynamic question rendering matching backend verified question types
/// - Answer selection state preservation across question navigation
/// - Live interactive question map with jump-to-question capability
/// - Confirmation guards before final submission and back exit
/// - Authoritative submission handling with live score & evaluation feedback
class AssessmentRunnerScreen extends ConsumerStatefulWidget {
  const AssessmentRunnerScreen({
    super.key,
    this.attemptDetails,
    this.assessmentId,
    this.assessmentTitle,
    this.studentId,
    this.studentName,
    this.redirectUrl,
  });

  final AssessmentAttemptDetailsEntity? attemptDetails;
  final String? assessmentId;
  final String? assessmentTitle;
  final String? studentId;
  final String? studentName;
  final String? redirectUrl;

  @override
  ConsumerState<AssessmentRunnerScreen> createState() =>
      _AssessmentRunnerScreenState();
}

class _AssessmentRunnerScreenState
    extends ConsumerState<AssessmentRunnerScreen> {
  AssessmentAttemptDetailsEntity? _attemptDetails;
  bool _isLoading = false;
  String? _errorMessage;

  int _currentIndex = 0;
  final Map<String, dynamic> _answers = {};
  Timer? _countdownTimer;
  int _remainingSeconds = 0;
  bool _isSubmitting = false;
  AssessmentSubmissionResultEntity? _submissionResult;

  @override
  void initState() {
    super.initState();
    if (widget.attemptDetails != null) {
      _initAttempt(widget.attemptDetails!);
    } else {
      _loadAttemptFromBackend();
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAttemptFromBackend() async {
    final sId = widget.studentId;
    final aId = widget.assessmentId;

    if (sId == null || aId == null || sId.isEmpty || aId.isEmpty) {
      setState(() {
        _errorMessage = 'Invalid assessment session parameters.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(assessmentsRepositoryProvider);
      final details = await repo.prepareAssessmentAttempt(
        studentId: sId,
        assessmentId: aId,
        studentName: widget.studentName,
      );
      if (mounted) {
        _initAttempt(details);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceFirst(
            RegExp(r'^Exception:\s*'),
            '',
          );
        });
      }
    }
  }

  void _initAttempt(AssessmentAttemptDetailsEntity details) {
    _attemptDetails = details;
    _answers.clear();
    _answers.addAll(details.initialAnswers);

    // Calculate remaining duration
    final durationMins = details.durationMinutes ?? 30;
    final totalDurationSeconds = durationMins * 60;
    final elapsedSeconds = DateTime.now()
        .difference(details.startedAt)
        .inSeconds;
    _remainingSeconds = max(0, totalDurationSeconds - max(0, elapsedSeconds));

    _isLoading = false;
    _startTimer();
    setState(() {});
  }

  void _startTimer() {
    _countdownTimer?.cancel();
    if (_remainingSeconds <= 0) return;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() {
          _remainingSeconds = 0;
        });
        _handleTimeExpired();
      } else {
        setState(() {
          _remainingSeconds--;
        });
      }
    });
  }

  void _handleTimeExpired() {
    if (_isSubmitting || _submissionResult != null) return;
    _showTimeExpiredDialog();
  }

  void _showTimeExpiredDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.timer_off_rounded, color: Color(0xFFDC2626)),
            const SizedBox(width: 8),
            Text(
              'Time Expired',
              style: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Text(
          'Your assessment duration has elapsed. Your answers will now be submitted automatically.',
          style: GoogleFonts.hankenGrotesk(fontSize: 14),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              _submitAnswers(autoSubmitted: true);
            },
            child: const Text('Submit Exam'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitAnswers({bool autoSubmitted = false}) async {
    final details = _attemptDetails;
    if (details == null || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final repo = ref.read(assessmentsRepositoryProvider);
      final result = await repo.submitAssessmentAnswers(
        assessmentId: details.assessmentId,
        attemptId: details.attemptId,
        answers: _answers,
        autoSubmitted: autoSubmitted,
      );

      _countdownTimer?.cancel();

      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _submissionResult = result;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFDC2626),
            content: Text(
              'Submission failed: ${e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '')}',
            ),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _submitAnswers(autoSubmitted: autoSubmitted),
            ),
          ),
        );
      }
    }
  }

  void _showSubmitConfirmationDialog() {
    final details = _attemptDetails;
    if (details == null) return;

    final totalCount = details.questions.length;
    final answeredCount = _getAnsweredCount();
    final unansweredCount = totalCount - answeredCount;

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Submit Assessment?',
          style: GoogleFonts.hankenGrotesk(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to finish and submit your exam?',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Answered',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '$answeredCount of $totalCount',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF059669),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (unansweredCount > 0)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Unanswered',
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '$unansweredCount questions',
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFD97706),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            if (unansweredCount > 0) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: Color(0xFFD97706),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Unanswered questions will receive 0 marks.',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 12,
                        color: const Color(0xFFB45309),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Review',
              style: GoogleFonts.hankenGrotesk(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            key: const Key('btn_confirm_submit'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              _submitAnswers(autoSubmitted: false);
            },
            child: const Text('Yes, Submit'),
          ),
        ],
      ),
    );
  }

  Future<bool> _handleWillPop() async {
    if (_submissionResult != null) return true;

    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Leave Exam Attempt?',
          style: GoogleFonts.hankenGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Your answers are saved on this device, but the exam countdown timer will continue running. Are you sure you want to return to the assessments dashboard?',
          style: GoogleFonts.hankenGrotesk(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Stay in Exam',
              style: GoogleFonts.hankenGrotesk(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Exit Exam'),
          ),
        ],
      ),
    );

    return shouldExit ?? false;
  }

  int _getAnsweredCount() {
    final details = _attemptDetails;
    if (details == null) return 0;
    int count = 0;
    for (final q in details.questions) {
      final ans = _answers[q.effectiveQuestionId];
      if (ans != null) {
        if (ans is String && ans.trim().isNotEmpty) count++;
        if (ans is List && ans.isNotEmpty) count++;
      }
    }
    return count;
  }

  bool _isQuestionAnswered(AssessmentQuestionEntity q) {
    final ans = _answers[q.effectiveQuestionId];
    if (ans == null) return false;
    if (ans is String) return ans.trim().isNotEmpty;
    if (ans is List) return ans.isNotEmpty;
    return false;
  }

  String _formatTimer(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    final minsStr = minutes.toString().padLeft(2, '0');
    final secsStr = seconds.toString().padLeft(2, '0');
    return '$minsStr:$secsStr';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final canExit = await _handleWillPop();
        if (canExit && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(child: _buildBody()),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingView();
    }

    if (_errorMessage != null) {
      return _buildErrorView();
    }

    if (_submissionResult != null) {
      return _buildResultView();
    }

    final details = _attemptDetails;
    if (details == null || details.questions.isEmpty) {
      return _buildEmptyQuestionsView();
    }

    final questions = details.questions;
    final currentQ = questions[_currentIndex];

    return Column(
      children: [
        // Top App Bar with Title, Timer & Submit button
        _buildTopBar(details),

        // Scrollable Question Content
        Expanded(
          child: SingleChildScrollView(
            key: const Key('assessment_test_scroll_view'),
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 580),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Question Card
                    _buildQuestionCard(currentQ, questions.length),
                    const SizedBox(height: 16),

                    // Navigation Buttons
                    _buildQuestionNavigationRow(questions.length),
                    const SizedBox(height: 20),

                    // Interactive Question Map
                    _buildQuestionMap(questions),
                    const SizedBox(height: 20),

                    // Final Submit Exam Button
                    _buildSubmitExamButton(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar(AssessmentAttemptDetailsEntity details) {
    final isLowTime = _remainingSeconds < 300; // Under 5 mins

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: Row(
        children: [
          // Exit button
          Material(
            color: Colors.transparent,
            child: InkWell(
              key: const Key('btn_back_assessment_runner'),
              borderRadius: BorderRadius.circular(999),
              onTap: () async {
                final canExit = await _handleWillPop();
                if (canExit && mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  size: 20,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Title & Candidate
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  details.assessmentTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Candidate: ${details.studentName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Countdown Timer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isLowTime
                  ? const Color(0xFFFEF2F2)
                  : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isLowTime
                    ? const Color(0xFFFCA5A5)
                    : const Color(0xFFBFDBFE),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 15,
                  color: isLowTime
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF1E40AF),
                ),
                const SizedBox(width: 5),
                Text(
                  _formatTimer(_remainingSeconds),
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isLowTime
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF1E40AF),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Quick Submit in Header
          ElevatedButton(
            key: const Key('btn_header_submit'),
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: const Size(0, 36),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: _isSubmitting ? null : _showSubmitConfirmationDialog,
            child: _isSubmitting
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.send_rounded, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Submit',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(AssessmentQuestionEntity q, int totalQuestions) {
    final typeLabel = (q.type ?? 'Question').toUpperCase();
    final marks = q.marks ?? 5;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pills: Question Index, Type & Marks
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'QUESTION ${_currentIndex + 1} OF $totalQuestions',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF4F46E5),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  typeLabel,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  'Marks: $marks',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Question Prompt
          Text(
            q.questionText,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 24),

          // Answer Options
          _buildAnswerOptions(q),
        ],
      ),
    );
  }

  Widget _buildAnswerOptions(AssessmentQuestionEntity q) {
    final lowerType = (q.type ?? '').toLowerCase();
    final isTrueFalse =
        lowerType.contains('true-false') ||
        lowerType.contains('true_false') ||
        lowerType.contains('boolean');
    final isSubjective =
        lowerType.contains('subjective') ||
        lowerType.contains('short') ||
        lowerType.contains('written');

    if (isSubjective) {
      return _buildSubjectiveAnswerField(q);
    }

    final options = q.options.isNotEmpty
        ? q.options
        : (isTrueFalse ? const ['True', 'False'] : const <String>[]);

    if (options.isEmpty) {
      return Text(
        'No choices provided for this question.',
        style: GoogleFonts.hankenGrotesk(
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
      );
    }

    final currentAnswer = _answers[q.effectiveQuestionId]?.toString();

    return Column(
      children: options.map((option) {
        final isSelected =
            currentAnswer != null &&
            currentAnswer.toLowerCase().trim() == option.toLowerCase().trim();

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                setState(() {
                  _answers[q.effectiveQuestionId] = option;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFEFF6FF)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF2563EB)
                        : const Color(0xFFE2E8F0),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? const Color(0xFF2563EB)
                            : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF2563EB)
                              : const Color(0xFF94A3B8),
                          width: 1.5,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              size: 14,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        option,
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 15,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: isSelected
                              ? const Color(0xFF1E3A8A)
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSubjectiveAnswerField(AssessmentQuestionEntity q) {
    final currentText = _answers[q.effectiveQuestionId]?.toString() ?? '';

    return TextFormField(
      initialValue: currentText,
      maxLines: 5,
      decoration: InputDecoration(
        hintText: 'Type your answer here...',
        hintStyle: GoogleFonts.hankenGrotesk(
          color: const Color(0xFF94A3B8),
          fontSize: 14,
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
        ),
      ),
      onChanged: (val) {
        _answers[q.effectiveQuestionId] = val.trim();
      },
    );
  }

  Widget _buildQuestionNavigationRow(int totalQuestions) {
    final hasPrev = _currentIndex > 0;
    final hasNext = _currentIndex < totalQuestions - 1;

    return Row(
      children: [
        // Previous Question
        Expanded(
          child: OutlinedButton.icon(
            key: const Key('btn_prev_question'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: hasPrev
                ? () {
                    setState(() {
                      _currentIndex--;
                    });
                  }
                : null,
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: Text(
              'Previous',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Next Question
        Expanded(
          child: ElevatedButton.icon(
            key: const Key('btn_next_question'),
            style: ElevatedButton.styleFrom(
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              if (hasNext) {
                setState(() {
                  _currentIndex++;
                });
              } else {
                _showSubmitConfirmationDialog();
              }
            },
            icon: Icon(
              hasNext
                  ? Icons.arrow_forward_rounded
                  : Icons.check_circle_outline_rounded,
              size: 18,
            ),
            label: Text(
              hasNext ? 'Next' : 'Review & Submit',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionMap(List<AssessmentQuestionEntity> questions) {
    final answeredCount = _getAnsweredCount();
    final totalCount = questions.length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'QUESTION MAP',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Text(
                '$answeredCount / $totalCount Answered',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF059669),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: totalCount > 0 ? answeredCount / totalCount : 0.0,
              backgroundColor: const Color(0xFFF1F5F9),
              color: const Color(0xFF059669),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 16),

          // Badges Grid
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(totalCount, (index) {
              final q = questions[index];
              final isCurrent = index == _currentIndex;
              final isAnswered = _isQuestionAnswered(q);

              Color bg = Colors.white;
              Color border = const Color(0xFFCBD5E1);
              Color textColor = AppColors.textPrimary;

              if (isCurrent) {
                bg = const Color(0xFF4F46E5);
                border = const Color(0xFF4F46E5);
                textColor = Colors.white;
              } else if (isAnswered) {
                bg = const Color(0xFFECFDF5);
                border = const Color(0xFF10B981);
                textColor = const Color(0xFF065F46);
              }

              return InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: border, width: isCurrent ? 2 : 1),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 14),

          // Legend
          Row(
            children: [
              _buildLegendDot(const Color(0xFF4F46E5), 'Current'),
              const SizedBox(width: 14),
              _buildLegendDot(const Color(0xFF10B981), 'Answered'),
              const SizedBox(width: 14),
              _buildLegendDot(const Color(0xFFCBD5E1), 'Unanswered'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.hankenGrotesk(
            fontSize: 11,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitExamButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        key: const Key('btn_submit_exam'),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: const Color(0xFF059669),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: _isSubmitting ? null : _showSubmitConfirmationDialog,
        icon: _isSubmitting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.check_circle_outline_rounded, size: 20),
        label: Text(
          _isSubmitting ? 'Submitting Answers...' : 'Submit Exam',
          style: GoogleFonts.hankenGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildResultView() {
    final res = _submissionResult!;
    final isPassed = res.isPassedSuccessfully;
    final isPending = res.isPendingEvaluation;
    final title = _attemptDetails?.assessmentTitle ?? 'Assessment';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A0F172A),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Medal / Icon
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isPending
                        ? const Color(0xFFFEF3C7)
                        : (isPassed
                              ? const Color(0xFFD1FAE5)
                              : const Color(0xFFFEE2E2)),
                  ),
                  child: Icon(
                    isPending
                        ? Icons.hourglass_top_rounded
                        : (isPassed
                              ? Icons.emoji_events_rounded
                              : Icons.replay_rounded),
                    size: 38,
                    color: isPending
                        ? const Color(0xFFD97706)
                        : (isPassed
                              ? const Color(0xFF059669)
                              : const Color(0xFFDC2626)),
                  ),
                ),
                const SizedBox(height: 18),

                Text(
                  isPending
                      ? 'Exam Submitted Successfully!'
                      : (isPassed ? 'Assessment Completed!' : 'Needs Retake'),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),

                // Metrics Box
                if (!isPending)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildResultMetric(
                          'Score',
                          '${res.finalScore}/${res.maximumMarks ?? _attemptDetails?.maximumMarks ?? 10}',
                          const Color(0xFF059669),
                        ),
                        if (res.percentage != null)
                          _buildResultMetric(
                            'Grade %',
                            '${res.percentage!.toInt()}%',
                            const Color(0xFF4F46E5),
                          ),
                        if (res.grade != null && res.grade!.isNotEmpty)
                          _buildResultMetric(
                            'Grade',
                            res.grade!,
                            const Color(0xFFD97706),
                          ),
                      ],
                    ),
                  )
                else
                  Text(
                    'Your answers have been securely recorded and are pending review by your course instructor.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 13,
                      color: const Color(0xFF64748B),
                      height: 1.4,
                    ),
                  ),

                const SizedBox(height: 28),

                // Return to Assessments Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    key: const Key('btn_done_return_assessments'),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: const Color(0xFF0037B1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      'Done & Return to Assessments',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.hankenGrotesk(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.hankenGrotesk(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 20),
            Text(
              'Preparing Assessment Attempt...',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Connecting to secure testing environment',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFDC2626),
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to Launch Assessment',
              textAlign: TextAlign.center,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'An unexpected error occurred.',
              textAlign: TextAlign.center,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onPressed: _loadAttemptFromBackend,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyQuestionsView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.quiz_outlined, size: 48, color: Color(0xFF94A3B8)),
            const SizedBox(height: 16),
            Text(
              'No Questions Available',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This assessment does not currently contain active questions.',
              textAlign: TextAlign.center,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Return to Assessments'),
            ),
          ],
        ),
      ),
    );
  }
}
