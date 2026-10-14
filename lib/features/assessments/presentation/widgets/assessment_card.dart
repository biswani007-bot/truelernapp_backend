import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/assessment_entity.dart';

/// Interactive card component displaying a single assessment with API-supported actions.
class AssessmentCard extends StatelessWidget {
  const AssessmentCard({
    super.key,
    required this.assessment,
    required this.isLaunching,
    required this.isStudent,
    required this.onLaunch,
    this.onViewQuestions,
    this.onStart,
  });

  final AssessmentEntity assessment;
  final bool isLaunching;
  final bool isStudent;
  final VoidCallback onLaunch;
  final VoidCallback? onViewQuestions;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEDEDF9), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Type Pill + Status Chip
            Row(
              children: [_buildTypeBadge(), const Spacer(), _buildStatusChip()],
            ),
            const SizedBox(height: 14),

            // Assessment Title
            Text(
              assessment.title,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                height: 1.25,
              ),
            ),

            // Description if available
            if (assessment.description != null &&
                assessment.description!.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                assessment.description!,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Metrics row: Duration & Marks
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (assessment.durationMinutes != null)
                  _buildMetricPill(
                    icon: Icons.timer_outlined,
                    label: '${assessment.durationMinutes} mins',
                    color: const Color(0xFF1E4ED8),
                    bgColor: const Color(0xFFEFF6FF),
                  ),
                if (!assessment.isEvaluated && assessment.maximumMarks != null)
                  _buildMetricPill(
                    icon: Icons.assignment_outlined,
                    label: 'Max: ${assessment.maximumMarks} pts',
                    color: const Color(0xFF7C3AED),
                    bgColor: const Color(0xFFF5F3FF),
                  ),
                if (!assessment.isEvaluated && assessment.passingMarks != null)
                  _buildMetricPill(
                    icon: Icons.flag_outlined,
                    label: 'Pass: ${assessment.passingMarks} pts',
                    color: const Color(0xFF059669),
                    bgColor: const Color(0xFFECFDF5),
                  ),
                if (assessment.score != null)
                  _buildMetricPill(
                    icon: Icons.stars_rounded,
                    label: assessment.maximumMarks != null
                        ? 'Score: ${assessment.score}/${assessment.maximumMarks}'
                        : 'Score: ${assessment.score}',
                    color: assessment.isPassedSuccessfully
                        ? const Color(0xFF059669)
                        : const Color(0xFFDC2626),
                    bgColor: assessment.isPassedSuccessfully
                        ? const Color(0xFFECFDF5)
                        : const Color(0xFFFEF2F2),
                  ),
                if (assessment.percentage != null)
                  _buildMetricPill(
                    icon: Icons.percent_rounded,
                    label: '${assessment.percentage!.toInt()}% Grade',
                    color: assessment.isPassedSuccessfully
                        ? const Color(0xFF059669)
                        : const Color(0xFFDC2626),
                    bgColor: assessment.isPassedSuccessfully
                        ? const Color(0xFFECFDF5)
                        : const Color(0xFFFEF2F2),
                  ),
              ],
            ),

            const SizedBox(height: 20),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 16),

            // Bottom Action Area
            _buildActionArea(context),
          ],
        ),
      ),
    );
  }

  Widget _buildActionArea(BuildContext context) {
    if (assessment.isEvaluated) {
      return Container(
        key: Key('evaluated_banner_${assessment.assessmentId}'),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: assessment.isPassedSuccessfully
              ? const Color(0xFFF0FDF4)
              : const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: assessment.isPassedSuccessfully
                ? const Color(0xFFBBF7D0)
                : const Color(0xFFFECACA),
          ),
        ),
        child: Row(
          children: [
            Icon(
              assessment.isPassedSuccessfully
                  ? Icons.check_circle_rounded
                  : Icons.replay_rounded,
              size: 20,
              color: assessment.isPassedSuccessfully
                  ? const Color(0xFF15803D)
                  : const Color(0xFFB91C1C),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    assessment.isPassedSuccessfully
                        ? 'Evaluated: Passed (${assessment.score ?? 0}/${assessment.maximumMarks ?? 0})'
                        : 'Evaluated: Needs Retake (${assessment.score ?? 0}/${assessment.maximumMarks ?? 0})',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: assessment.isPassedSuccessfully
                          ? const Color(0xFF15803D)
                          : const Color(0xFFB91C1C),
                    ),
                  ),
                  if (assessment.evaluatedAt != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Evaluated on ${_formatDate(assessment.evaluatedAt!)}',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: assessment.isPassedSuccessfully
                            ? const Color(0xFF166534)
                            : const Color(0xFF991B1B),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (assessment.isSubmittedPendingEvaluation) {
      return Container(
        key: Key('submitted_banner_${assessment.assessmentId}'),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.hourglass_top_rounded,
              size: 20,
              color: Color(0xFFD97706),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Submitted • Pending Evaluation',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF92400E),
                    ),
                  ),
                  if (assessment.submittedAt != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Submitted on ${_formatDate(assessment.submittedAt!)}',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFB45309),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Full-Width Action: Launch (Parent) or Start/Resume (Student)
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        key: Key('btn_launch_${assessment.assessmentId}'),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: const Color(0xFF0037B1),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: isLaunching
            ? null
            : (isStudent ? onStart ?? onLaunch : onLaunch),
        icon: isLaunching
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(
                assessment.isActive
                    ? Icons.play_arrow_rounded
                    : (isStudent
                          ? Icons.play_arrow_rounded
                          : Icons.rocket_launch_outlined),
                size: 18,
              ),
        label: Text(
          isLaunching
              ? 'Launching...'
              : (assessment.isActive
                    ? 'Resume'
                    : (isStudent ? 'Start' : 'Launch')),
          style: GoogleFonts.hankenGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildTypeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFE0E7FF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.school_outlined, size: 14, color: Color(0xFF0037B1)),
          const SizedBox(width: 5),
          Text(
            assessment.displayType.toUpperCase(),
            style: GoogleFonts.hankenGrotesk(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0037B1),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip() {
    Color bg;
    Color fg;
    IconData icon;
    String label;

    final lower = assessment.status.toLowerCase();
    if (assessment.isPassedSuccessfully) {
      bg = const Color(0xFFECFDF5);
      fg = const Color(0xFF059669);
      icon = Icons.check_circle_outline_rounded;
      label = 'Passed';
    } else if (assessment.needsRetake) {
      bg = const Color(0xFFFEF2F2);
      fg = const Color(0xFFDC2626);
      icon = Icons.cancel_outlined;
      label = 'Needs Retake';
    } else if (assessment.isSubmittedPendingEvaluation) {
      bg = const Color(0xFFFFFBEB);
      fg = const Color(0xFFD97706);
      icon = Icons.hourglass_top_rounded;
      label = 'Pending Evaluation';
    } else if (assessment.isActive) {
      bg = const Color(0xFFEFF6FF);
      fg = const Color(0xFF1E4ED8);
      icon = Icons.play_circle_outline_rounded;
      label = 'Active';
    } else if (lower == 'completed') {
      bg = const Color(0xFFECFDF5);
      fg = const Color(0xFF059669);
      icon = Icons.task_alt_rounded;
      label = 'Completed';
    } else {
      bg = const Color(0xFFFFFBEB);
      fg = const Color(0xFFD97706);
      icon = Icons.hourglass_empty_rounded;
      label = 'Pending';
    }

    return Container(
      key: Key('chip_status_${assessment.assessmentId}'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: fg.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricPill({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final local = date.toLocal();
    final month = months[local.month - 1];
    return '$month ${local.day}, ${local.year}';
  }
}
