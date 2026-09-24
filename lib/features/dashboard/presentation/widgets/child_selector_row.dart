import 'package:flutter/material.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../dashboard/domain/entities/child_entity.dart';

/// Child Selector Row matching Figma Node 76:3579 (Section - Child Selector).
///
/// Features:
/// - Active Child button (76:3580): white container, 16px radius, subtle shadow,
///   avatar with blue border, bold name, and class/grade indicator.
/// - Inactive Child button (76:3589): translucent container, subtle border,
///   muted avatar, and subtle name.
/// - Tap to seamlessly switch the active child context.
class ChildSelectorRow extends StatelessWidget {
  const ChildSelectorRow({
    super.key,
    required this.children,
    required this.activeChildId,
    required this.onSelectChild,
  });

  final List<ChildEntity> children;
  final String? activeChildId;
  final ValueChanged<String> onSelectChild;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    final effectiveActiveId = activeChildId ?? children.first.studentId;

    return Container(
      height: 66,
      margin: const EdgeInsets.only(top: 4, bottom: 4),
      child: ListView.separated(
        key: const Key('child_selector_list_view'),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: children.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final child = children[index];
          final isActive = child.studentId == effectiveActiveId;

          return _ChildCardItem(
            key: Key('child_card_${child.studentId}'),
            child: child,
            isActive: isActive,
            onTap: () => onSelectChild(child.studentId),
          );
        },
      ),
    );
  }
}

class _ChildCardItem extends StatelessWidget {
  const _ChildCardItem({
    super.key,
    required this.child,
    required this.isActive,
    required this.onTap,
  });

  final ChildEntity child;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : const Color(0xFFF3F2FE).withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(9999), // pill
          border: Border.all(
            color: isActive ? const Color(0xFFDCE1FF) : Colors.transparent,
            width: 1.0,
          ),
          boxShadow: isActive
              ? const [
                  BoxShadow(
                    color: Color(0x0D000000), // rgba(0, 0, 0, 0.05)
                    blurRadius: 1,
                    offset: Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? const Color(0xFF0037B1).withValues(alpha: 0.1) : const Color(0xFFC4C5D7).withValues(alpha: 0.3),
                border: Border.all(
                  color: isActive ? const Color(0xFF0037B1) : const Color(0xFFC4C5D7),
                  width: isActive ? 2.0 : 1.0,
                ),
              ),
              child: Center(
                child: child.avatar != null && child.avatar!.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          child.avatar!,
                          width: 36,
                          height: 36,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => _buildInitial(child),
                        ),
                      )
                    : _buildInitial(child),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  child.firstName,
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isActive ? const Color(0xFF0037B1) : const Color(0xFF434655),
                    fontSize: 17,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  child.grade != null && child.grade!.isNotEmpty
                      ? child.grade!
                      : 'Age 9',
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
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildInitial(ChildEntity child) {
    return Text(
      child.firstName.isNotEmpty ? child.firstName[0].toUpperCase() : 'A',
      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: isActive ? const Color(0xFF0037B1) : const Color(0xFF434655),
      ),
    );
  }
}
