import 'package:flutter/material.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../dashboard/domain/entities/child_entity.dart';

/// Centered Student Selector pill button matching Figma Node `76:1831`.
///
/// Features:
/// - Pill shape (#0037B1 background, 9999px border radius)
/// - 24px circular child avatar with image or initial
/// - Child first name in 14px Hanken Grotesk SemiBold white text
/// - Dropdown / modal affordance to switch between linked children
class ClassesStudentSelector extends StatelessWidget {
  const ClassesStudentSelector({
    super.key,
    required this.activeChild,
    required this.children,
    required this.onChildSelected,
  });

  final ChildEntity activeChild;
  final List<ChildEntity> children;
  final ValueChanged<String> onChildSelected;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const Key('classes_student_selector_button'),
          borderRadius: BorderRadius.circular(9999),
          onTap: children.length > 1
              ? () => _showChildSwitchMenu(context)
              : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0037B1),
              borderRadius: BorderRadius.circular(9999),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 1,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 24px Circular Avatar (Node 76:1833)
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: activeChild.avatar != null
                      ? Image.network(
                          activeChild.avatar!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildInitialAvatar(),
                        )
                      : (activeChild.firstName.toLowerCase() == 'alex'
                            ? Image.asset(
                                'assets/images/avatar_mia.png',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildInitialAvatar(),
                              )
                            : _buildInitialAvatar()),
                ),
                const SizedBox(width: 8),
                // Child name (Node 76:1836)
                Text(
                  activeChild.firstName.isNotEmpty
                      ? activeChild.firstName
                      : 'Student',
                  style: AppTypography.labelLarge.copyWith(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (children.length > 1) ...[
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_drop_down_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInitialAvatar() {
    return Center(
      child: Text(
        activeChild.firstName.isNotEmpty
            ? activeChild.firstName[0].toUpperCase()
            : 'S',
        style: const TextStyle(
          color: Color(0xFF0037B1),
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }

  void _showChildSwitchMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Text(
                    'Select Student',
                    style: AppTypography.titleMedium.copyWith(
                      color: const Color(0xFF0F172A),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Divider(),
                ...children.map((c) {
                  final isCurrent = c.studentId == activeChild.studentId;
                  return ListTile(
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: const Color(0xFF0037B1)
                          .withValues(alpha: 0.1),
                      child: Text(
                        c.firstName.isNotEmpty
                            ? c.firstName[0].toUpperCase()
                            : 'S',
                        style: const TextStyle(
                          color: Color(0xFF0037B1),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    title: Text(
                      c.displayName,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: isCurrent
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isCurrent
                            ? const Color(0xFF0037B1)
                            : const Color(0xFF0F172A),
                      ),
                    ),
                    subtitle: c.grade != null ? Text(c.grade!) : null,
                    trailing: isCurrent
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF0037B1),
                          )
                        : null,
                    onTap: () {
                      Navigator.of(ctx).pop();
                      onChildSelected(c.studentId);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}
