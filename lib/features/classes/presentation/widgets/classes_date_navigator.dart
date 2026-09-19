import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Horizontally sliding date/day selector matching Figma Node `76:1837` in `Parent(full app)_TreLern` (Frame 76:1820).
///
/// Exact Figma Specs:
/// - Date Strip Container: height 80px, overflow-auto horizontal scroll
/// - Card Dimensions: width 48px × height 64px, radius 8px
/// - Horizontal item spacing: 8px gap
/// - Active date card: #0037B1 background, white text (Day 11px Medium letter-spacing 0.5px, Date 16px SemiBold)
/// - Inactive date card: #FFFFFF background, border rgba(196,197,215,0.25), text #475569 and #0F172A
/// - Edge fade indicators with chevrons matching Figma nodes 76:1874 and 76:1877
class ClassesDateNavigator extends StatefulWidget {
  const ClassesDateNavigator({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.initialAnchorDate,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final DateTime? initialAnchorDate;

  @override
  State<ClassesDateNavigator> createState() => _ClassesDateNavigatorState();
}

class _ClassesDateNavigatorState extends State<ClassesDateNavigator> {
  late final ScrollController _scrollController;
  late List<DateTime> _dates;
  static const double _itemWidth = 48.0;
  static const double _itemSpacing = 8.0;
  static const double _itemPitch = _itemWidth + _itemSpacing; // 56.0

  static const int _pastDays = 30;
  static const int _futureDays = 90;

  DateTime _normalize(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  void initState() {
    super.initState();
    final anchor = _normalize(widget.initialAnchorDate ?? widget.selectedDate);
    _dates = List.generate(
      _pastDays + _futureDays + 1,
      (index) => anchor.subtract(Duration(days: _pastDays - index)),
    );

    // Initial scroll offset so that the anchor/selected date is visible with 1 previous day on the left
    final anchorIndex = _pastDays;
    final initialOffset = ((anchorIndex - 1) * _itemPitch).clamp(0.0, double.infinity);
    _scrollController = ScrollController(initialScrollOffset: initialOffset);
  }

  @override
  void didUpdateWidget(covariant ClassesDateNavigator oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldAnchor = _normalize(oldWidget.initialAnchorDate ?? oldWidget.selectedDate);
    final newAnchor = _normalize(widget.initialAnchorDate ?? widget.selectedDate);
    if (!_isSameDay(oldAnchor, newAnchor)) {
      setState(() {
        _dates = List.generate(
          _pastDays + _futureDays + 1,
          (index) => newAnchor.subtract(Duration(days: _pastDays - index)),
        );
      });
      _scrollToDate(widget.selectedDate);
    } else if (!_isSameDay(oldWidget.selectedDate, widget.selectedDate)) {
      _scrollToDate(widget.selectedDate);
    }
  }

  void _scrollToDate(DateTime target) {
    if (!_scrollController.hasClients) return;
    final index = _dates.indexWhere((d) => _isSameDay(d, target));
    if (index == -1) return;
    final targetOffset = ((index - 1) * _itemPitch).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollLeft() {
    if (!_scrollController.hasClients) return;
    final target = (_scrollController.offset - (_itemPitch * 3))
        .clamp(0.0, _scrollController.position.maxScrollExtent);
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _scrollRight() {
    if (!_scrollController.hasClients) return;
    final target = (_scrollController.offset + (_itemPitch * 3))
        .clamp(0.0, _scrollController.position.maxScrollExtent);
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onDateTap(DateTime day, int index) {
    widget.onDateSelected(day);

    // Keep tapped card comfortably within the viewport
    if (_scrollController.hasClients) {
      final itemOffset = index * _itemPitch;
      final currentOffset = _scrollController.offset;
      final viewportWidth = _scrollController.position.viewportDimension;
      if (itemOffset < currentOffset + 16.0) {
        _scrollController.animateTo(
          (itemOffset - 16.0).clamp(0.0, _scrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
        );
      } else if (itemOffset + _itemWidth > currentOffset + viewportWidth - 24.0) {
        _scrollController.animateTo(
          (itemOffset + _itemWidth - viewportWidth + 32.0)
              .clamp(0.0, _scrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80.0,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Horizontally sliding date cards list
          ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            itemCount: _dates.length,
            itemBuilder: (context, index) {
              final day = _dates[index];
              final isSelected = day.year == widget.selectedDate.year &&
                  day.month == widget.selectedDate.month &&
                  day.day == widget.selectedDate.day;
              final dayLabel = _dayLabels[day.weekday - 1];
              final dayNumber = day.day.toString();

              return Padding(
                padding: const EdgeInsets.only(right: _itemSpacing),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _onDateTap(day, index),
                    borderRadius: BorderRadius.circular(8.0),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: _itemWidth,
                      height: 64.0,
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF0037B1) : Colors.white,
                        borderRadius: BorderRadius.circular(8.0),
                        border: isSelected
                            ? null
                            : Border.all(
                                color: const Color(0xFFC4C5D7).withValues(alpha: 0.25),
                                width: 1.0,
                              ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0D000000),
                            blurRadius: 1.0,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Day name (11px Hanken Grotesk Medium, tracking 0.5px)
                          Text(
                            dayLabel,
                            style: GoogleFonts.hankenGrotesk(
                              color: isSelected
                                  ? Colors.white.withValues(alpha: 0.80)
                                  : const Color(0xFF475569),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                              height: 16.0 / 11.0,
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          // Day number (16px Hanken Grotesk SemiBold)
                          Text(
                            dayNumber,
                            style: GoogleFonts.hankenGrotesk(
                              color: isSelected ? Colors.white : const Color(0xFF0F172A),
                              fontSize: 17.0,
                              fontWeight: FontWeight.w600,
                              height: 24.0 / 16.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Left fade edge & scroll cue (Figma Node 76:1874)
          Positioned(
            left: 0,
            top: 8.0,
            bottom: 8.0,
            child: IgnorePointer(
              ignoring: false,
              child: GestureDetector(
                onTap: _scrollLeft,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 24.0,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        const Color(0xFFF3E8FF).withValues(alpha: 0.85),
                        const Color(0xFFF3E8FF).withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                  alignment: Alignment.centerLeft,
                  child: const Icon(
                    Icons.chevron_left_rounded,
                    size: 16.0,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
            ),
          ),

          // Right fade edge & scroll cue (Figma Node 76:1877)
          Positioned(
            right: 0,
            top: 8.0,
            bottom: 8.0,
            child: IgnorePointer(
              ignoring: false,
              child: GestureDetector(
                onTap: _scrollRight,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 24.0,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                      colors: [
                        const Color(0xFFE0F2FE).withValues(alpha: 0.85),
                        const Color(0xFFE0F2FE).withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                  alignment: Alignment.centerRight,
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    size: 16.0,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
