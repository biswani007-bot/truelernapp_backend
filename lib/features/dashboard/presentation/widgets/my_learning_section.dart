import 'package:flutter/material.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/dashboard_entity.dart';

/// My Learning Section matching Figma Node 58:1377 (Student Dashboard).
class MyLearningSection extends StatelessWidget {
  const MyLearningSection({
    super.key,
    this.enrolledBatches = const [],
  });

  final List<EnrolledBatchEntity> enrolledBatches;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'My Learning',
            style: AppTypography.titleMedium.copyWith(
              fontSize: 21.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1B23),
            ),
          ),
        ),
        if (enrolledBatches.isNotEmpty) ...[
          for (int i = 0; i < enrolledBatches.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _CourseCard(
              icon: i % 2 == 0
                  ? Icons.menu_book_rounded
                  : Icons.lightbulb_outline_rounded,
              iconColor: i % 2 == 0
                  ? const Color(0xFF14B8A6)
                  : const Color(0xFFFB7185),
              iconBg: i % 2 == 0
                  ? const Color(0x1A14B8A6)
                  : const Color(0x1AFB7185),
              statusPill: enrolledBatches[i].courseName ?? 'Junior Foundation',
              title: enrolledBatches[i].batchName,
              progressPercent: 0.65,
              completedText: 'Progress',
              percentageText: '65%',
              scheduleText: enrolledBatches[i].instructor != null
                  ? 'Instructor: ${enrolledBatches[i].instructor}'
                  : 'Scheduled Class',
            ),
          ],
        ] else ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(21),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x80E2E1ED), width: 1),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0x1A14B8A6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.menu_book_rounded, color: Color(0xFF14B8A6), size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No enrolled courses',
                        style: AppTypography.titleMedium.copyWith(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1B23),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Explore available courses to enroll',
                        style: AppTypography.bodySmall.copyWith(
                          color: const Color(0xFF434655),
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.statusPill,
    required this.title,
    required this.progressPercent,
    required this.completedText,
    required this.percentageText,
    required this.scheduleText,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String statusPill;
  final String title;
  final double progressPercent;
  final String completedText;
  final String percentageText;
  final String scheduleText;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x80E2E1ED), width: 1), // rgba(226, 225, 237, 0.5)
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  statusPill,
                  style: AppTypography.labelSmall.copyWith(
                    color: iconColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: AppTypography.titleMedium.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1B23),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                completedText,
                style: AppTypography.labelSmall.copyWith(
                  color: const Color(0xFF434655),
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
              Text(
                percentageText,
                style: AppTypography.labelSmall.copyWith(
                  color: iconColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(9999),
            child: LinearProgressIndicator(
              value: progressPercent,
              backgroundColor: const Color(0xFFF1F5F9), // #f1f5f9
              valueColor: AlwaysStoppedAnimation<Color>(iconColor),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 13,
                color: Color(0xFF434655),
              ),
              const SizedBox(width: 6),
              Text(
                scheduleText,
                style: AppTypography.bodySmall.copyWith(
                  color: const Color(0xFF434655),
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
