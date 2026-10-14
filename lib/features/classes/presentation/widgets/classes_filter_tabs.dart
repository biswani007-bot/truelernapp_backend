import 'package:flutter/material.dart';

import '../../../../core/theme/app_typography.dart';

/// Horizontal filter tabs matching Figma Node `76:1880`.
///
/// Options:
/// - Upcoming (Active by default in Figma: #0037B1 blue, white text)
/// - Completed
/// - Missed
/// - Cancelled
///
/// Inactive styling:
/// - White background
/// - Border: rgba(196,197,215,0.3)
/// - Text: #0F172A, 12px Medium, tracking 0.5px
class ClassesFilterTabs extends StatelessWidget {
  const ClassesFilterTabs({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;

  static const filters = ['Upcoming', 'Completed', 'Missed', 'Cancelled'];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected =
              filter.toLowerCase() == selectedFilter.toLowerCase();

          return Material(
            color: Colors.transparent,
            child: InkWell(
              key: Key('classes_filter_${filter.toLowerCase()}'),
              onTap: () => onFilterChanged(filter),
              borderRadius: BorderRadius.circular(9999),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0037B1) : Colors.white,
                  borderRadius: BorderRadius.circular(9999),
                  border: isSelected
                      ? null
                      : Border.all(
                          color: const Color(0xFFC4C5D7).withValues(alpha: 0.5),
                          width: 1,
                        ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 1,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    filter,
                    style: AppTypography.labelMedium.copyWith(
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF0F172A),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
