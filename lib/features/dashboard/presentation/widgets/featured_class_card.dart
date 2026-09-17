import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../classes/domain/entities/class_entity.dart';

/// Featured Primary Card matching Figma Node `76:3513` (Section - Primary Featured Card).
class FeaturedClassCard extends StatelessWidget {
  const FeaturedClassCard({
    super.key,
    required this.upcomingClass,
    required this.onViewClass,
  });

  final ClassEntity? upcomingClass;
  final VoidCallback onViewClass;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            "TODAY'S CLASS",
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              fontSize: 13,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 20, 20, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: const Border(
              left: BorderSide(
                color: Color(0xFF22D3EE), // Figma #22d3ee
                width: 4,
              ),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000), // rgba(0, 0, 0, 0.04)
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0x1A22D3EE), // rgba(34, 211, 238, 0.1)
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.mic_rounded,
                      color: Color(0xFF22D3EE),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0x1A22D3EE), // rgba(34, 211, 238, 0.1)
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Text(
                            upcomingClass != null
                                ? (upcomingClass!.subject ?? 'Live Class')
                                : 'Schedule',
                            style: AppTypography.labelSmall.copyWith(
                              color: const Color(0xFF22D3EE),
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          upcomingClass?.title ?? 'No live class today',
                          style: AppTypography.titleMedium.copyWith(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1B23),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          upcomingClass != null
                              ? (upcomingClass!.teacherName != null && upcomingClass!.teacherName!.isNotEmpty
                                  ? 'Instructor: ${upcomingClass!.teacherName} • ${_formatTimeShort(upcomingClass!)}'
                                  : _formatTimeShort(upcomingClass!))
                              : 'Check upcoming classes in schedule',
                          style: AppTypography.bodySmall.copyWith(
                            color: const Color(0xFF434655),
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 36,
                child: ElevatedButton(
                  key: const Key('featured_class_action_button'),
                  onPressed: onViewClass,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E4ED8), // Figma #1e4ed8
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  ),
                  child: Text(
                    upcomingClass != null ? 'Join Class' : 'View Classes',
                    style: AppTypography.buttonText.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatTimeShort(ClassEntity session) {
    if (session.scheduledStartTime == null) return 'Scheduled';
    final dt = session.scheduledStartTime!;
    final hour = dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = hour >= 12 ? 'PM' : 'AM';
    final formattedHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$formattedHour:$minute $ampm';
  }
}
