import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/entities/assignment_entity.dart';

/// Assignment card component corresponding to Figma Node 76:1987.
///
/// Supports 3 distinct states:
/// 1. Pending: Purple left border (#A855F7), PENDING & topic badges, due date with calendar icon, CTA button.
/// 2. Completed: Green left border (#10B981), COMPLETED checkmark & topic badges, 3D quiz trophy, Grade banner (e.g. 95/100).
/// 3. Overdue: Red left border (#BA1A1A), OVERDUE warning triangle & topic badges, was due with clock icon, outline CTA button.
class AssignmentCard extends StatelessWidget {
  final AssignmentEntity assignment;
  final VoidCallback? onActionTap;

  const AssignmentCard({super.key, required this.assignment, this.onActionTap});

  @override
  Widget build(BuildContext context) {
    return switch (assignment.status) {
      AssignmentStatus.pending => _buildPendingCard(context),
      AssignmentStatus.completed => _buildCompletedCard(context),
      AssignmentStatus.overdue => _buildOverdueCard(context),
    };
  }

  /// Card 1: Pending (Figma Node 76:1988)
  Widget _buildPendingCard(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000), // rgba(0, 0, 0, 0.04)
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onActionTap,
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              left: BorderSide(
                color: Color(0xFFA855F7), // Purple accent
                width: 4,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status & Topic Badges
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // PENDING badge (Node 76:1992)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDEDF9),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Text(
                      'PENDING',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF434655),
                        letterSpacing: 0.3,
                        height: 16 / 12,
                      ),
                    ),
                  ),
                  // Topic badge (Node 76:1994)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA855F7).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Text(
                      assignment.topic,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFA855F7),
                        height: 16 / 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Title (Node 76:1998)
              Text(
                assignment.title,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 21.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1B23),
                  height: 28 / 20,
                ),
              ),
              const SizedBox(height: 8),

              // Due Date Row (Node 76:1999)
              if (assignment.dueDate != null)
                Row(
                  children: [
                    SvgPicture.asset(
                      'assets/icons/calendar_due.svg',
                      width: 14,
                      height: 15,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      assignment.dueDate!,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF434655),
                        height: 20 / 14,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 16),

              // CTA Button: Open Assignment (Node 76:2004)
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  key: const Key('open_assignment_button'),
                  onPressed: onActionTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E4ED8),
                    foregroundColor: Colors.white,
                    elevation: 1,
                    shadowColor: Colors.black.withValues(alpha: 0.05),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 10,
                    ),
                  ),
                  child: Text(
                    assignment.buttonText ?? 'Open Assignment',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.1,
                      height: 20 / 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Card 2: Completed (Figma Node 76:2006)
  Widget _buildCompletedCard(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000), // rgba(0, 0, 0, 0.04)
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onActionTap,
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              left: BorderSide(
                color: Color(0xFF10B981), // Emerald Green accent
                width: 4,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left: 3D Trophy Icon (Node 76:2024)
              Image.asset(
                'assets/images/trophy_3d_quiz_cropped.png',
                width: 46,
                height: 48,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.emoji_events_rounded,
                  size: 44,
                  color: Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 14),

              // Right: Content Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status & Topic Badges
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // COMPLETED badge (Node 76:2010)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SvgPicture.asset(
                                'assets/icons/check_circle_green.svg',
                                width: 12,
                                height: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'COMPLETED',
                                style: GoogleFonts.hankenGrotesk(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF10B981),
                                  letterSpacing: 0.3,
                                  height: 16 / 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Topic badge (Node 76:2014)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF22D3EE)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Text(
                            assignment.topic,
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF22D3EE),
                              height: 16 / 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Title (Node 76:2018)
                    Text(
                      assignment.title,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 21.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1B23),
                        height: 28 / 20,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Grade banner (Node 76:2019)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F2FE),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Grade:',
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF434655),
                              letterSpacing: 0.1,
                              height: 20 / 14,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            assignment.score != null
                                ? '${assignment.score}/${assignment.totalMarks ?? 100}'
                                : (assignment.grade != null &&
                                          assignment.grade!.isNotEmpty
                                      ? assignment.grade!
                                      : '--'),
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 21.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0037B1),
                              height: 28 / 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Card 3: Overdue (Figma Node 76:2025)
  Widget _buildOverdueCard(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000), // rgba(0, 0, 0, 0.04)
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onActionTap,
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              left: BorderSide(
                color: Color(0xFFBA1A1A), // Red accent
                width: 4,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status & Topic Badges
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // OVERDUE badge (Node 76:2029)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFDAD6),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          'assets/icons/alert_triangle_red.svg',
                          width: 13,
                          height: 11,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'OVERDUE',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF93000A),
                            letterSpacing: 0.3,
                            height: 16 / 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Topic badge (Node 76:2033)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Text(
                      assignment.topic,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF4F46E5),
                        height: 16 / 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Title (Node 76:2037)
              Text(
                assignment.title,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 21.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1B23),
                  height: 28 / 20,
                ),
              ),
              const SizedBox(height: 8),

              // Was Due Row (Node 76:2038)
              if (assignment.overdueDate != null)
                Row(
                  children: [
                    SvgPicture.asset(
                      'assets/icons/history_clock_red.svg',
                      width: 14,
                      height: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      assignment.overdueDate!,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFFBA1A1A),
                        height: 20 / 14,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 16),

              // CTA Button: Submit Late (Node 76:2043)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  key: const Key('submit_late_button'),
                  onPressed: onActionTap,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFBA1A1A),
                    side: const BorderSide(color: Color(0xFFBA1A1A), width: 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 10,
                    ),
                  ),
                  child: Text(
                    assignment.buttonText ?? 'Submit Late',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.1,
                      height: 20 / 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
