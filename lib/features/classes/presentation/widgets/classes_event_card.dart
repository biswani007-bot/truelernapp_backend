import 'package:flutter/material.dart';

import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/class_entity.dart';

/// Event card matching Figma Node `76:1897` and `76:1907`.
///
/// Features:
/// - 12px rounded corner container
/// - White surface, border rgba(196,197,215,0.3), soft shadow
/// - 64×64px #F2F4F7 container with 3D calendar or subject illustration
/// - Title in 14px Hanken Grotesk Regular #0F172A
/// - Subtitle (Date / Timing) in 14px Hanken Grotesk Regular #475569
/// - Right chevron icon (#94A3B8)
class ClassesEventCard extends StatelessWidget {
  const ClassesEventCard({
    super.key,
    required this.session,
    this.onTap,
    this.useThinkingIcon = false,
  });

  final ClassEntity session;
  final VoidCallback? onTap;
  final bool useThinkingIcon;

  @override
  Widget build(BuildContext context) {
    final title = session.title.isNotEmpty ? session.title : 'Live Session';
    final timing = _formatDateTime(
      session.scheduledStartTime,
      session.scheduledEndTime,
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFC4C5D7).withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: Key('classes_event_card_${session.id}'),
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 64×64px Thumbnail container (Node 76:1898 / 76:1908)
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F4F7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Center(
                    child: SizedBox(
                      width: 50,
                      height: 50,
                      child: Image.asset(
                        useThinkingIcon
                            ? 'assets/images/figma_bulb_single.png'
                            : 'assets/images/figma_mic_single.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          useThinkingIcon
                              ? Icons.lightbulb_rounded
                              : Icons.mic_rounded,
                          color: const Color(0xFF0037B1),
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Title + Timing
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: AppTypography.bodyMedium.copyWith(
                          color: const Color(0xFF0F172A),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        timing,
                        style: AppTypography.bodySmall.copyWith(
                          color: const Color(0xFF475569),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Right Chevron Arrow (Node 76:1905 / 76:1915)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF94A3B8),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime? start, DateTime? end) {
    if (start == null) return 'Schedule TBA';

    final localStart = start.toLocal();

    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
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

    final dayName = weekdays[localStart.weekday - 1];
    final dayNum = localStart.day;
    final monthName = months[localStart.month - 1];

    final hour = localStart.hour;
    final minute = localStart.minute.toString().padLeft(2, '0');
    final ampm = hour >= 12 ? 'PM' : 'AM';
    final formattedHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

    return '$dayName, $dayNum $monthName at $formattedHour:$minute $ampm';
  }
}
