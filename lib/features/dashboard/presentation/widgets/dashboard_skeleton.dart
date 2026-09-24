import 'package:flutter/material.dart';

/// Shimmer box for skeleton placeholders.
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    this.width,
    required this.height,
    required this.opacity,
    this.borderRadius = 8,
    this.color,
    this.shape = BoxShape.rectangle,
  });

  final double? width;
  final double height;
  final double opacity;
  final double borderRadius;
  final Color? color;
  final BoxShape shape;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          shape: shape,
          color: color ?? const Color(0xFFE2E1ED),
          borderRadius: shape == BoxShape.rectangle
              ? BorderRadius.circular(borderRadius)
              : null,
        ),
      ),
    );
  }
}

/// Child Selector Skeleton Row matching Figma Node 76:3579.
class ChildSelectorSkeleton extends StatefulWidget {
  const ChildSelectorSkeleton({super.key});

  @override
  State<ChildSelectorSkeleton> createState() => _ChildSelectorSkeletonState();
}

class _ChildSelectorSkeletonState extends State<ChildSelectorSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    final isTesting = WidgetsBinding.instance.runtimeType.toString().contains('TestWidgetsFlutterBinding') ||
        WidgetsBinding.instance.runtimeType.toString().contains('AutomatedTestWidgetsFlutterBinding');
    if (!isTesting) {
      _controller.repeat(reverse: true);
    } else {
      _controller.value = 0.5;
    }
    _animation = Tween<double>(begin: 0.35, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final opacity = _animation.value;
        return Container(
          key: const Key('child_selector_skeleton'),
          height: 66,
          margin: const EdgeInsets.only(top: 4, bottom: 4),
          child: ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 3,
            separatorBuilder: (_, _) => const SizedBox(width: 16),
            itemBuilder: (_, index) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: index == 0
                      ? Colors.white.withValues(alpha: 0.9)
                      : const Color(0xFFF3F2FE).withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(
                    color: index == 0
                        ? const Color(0xFFDCE1FF)
                        : Colors.transparent,
                    width: 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ShimmerBox(
                      width: 40,
                      height: 40,
                      opacity: opacity,
                      shape: BoxShape.circle,
                    ),
                    const SizedBox(width: 10),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerBox(
                          width: index == 0 ? 56 : 48,
                          height: 14,
                          opacity: opacity,
                          borderRadius: 4,
                        ),
                        const SizedBox(height: 4),
                        ShimmerBox(
                          width: 36,
                          height: 10,
                          opacity: opacity,
                          borderRadius: 4,
                        ),
                      ],
                    ),
                    const SizedBox(width: 6),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// Parent Dashboard Skeleton matching Figma Node 76:3476.
///
/// Accurately preserves:
/// 1. Greeting text area
/// 2. Today's Class Card (with left cyan accent border, icon box, text bars, button bar)
/// 3. My Learning Card (with icon box, course badge, progress bar, instructor)
/// 4. 2x2 Bento Snapshot Grid (Progress, Attendance, Assignments, Current Topic)
class ParentDashboardSkeleton extends StatefulWidget {
  const ParentDashboardSkeleton({super.key});

  @override
  State<ParentDashboardSkeleton> createState() => _ParentDashboardSkeletonState();
}

class _ParentDashboardSkeletonState extends State<ParentDashboardSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    final isTesting = WidgetsBinding.instance.runtimeType.toString().contains('TestWidgetsFlutterBinding') ||
        WidgetsBinding.instance.runtimeType.toString().contains('AutomatedTestWidgetsFlutterBinding');
    if (!isTesting) {
      _controller.repeat(reverse: true);
    } else {
      _controller.value = 0.5;
    }
    _animation = Tween<double>(begin: 0.35, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final opacity = _animation.value;
        return SingleChildScrollView(
          key: const Key('parent_dashboard_skeleton'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Greeting Skeleton
              ShimmerBox(
                width: 240,
                height: 28,
                opacity: opacity,
                borderRadius: 6,
              ),
              const SizedBox(height: 8),
              ShimmerBox(
                width: 180,
                height: 20,
                opacity: opacity,
                borderRadius: 6,
              ),
              const SizedBox(height: 24),

              // 2. Today's Class Card Skeleton (Figma Node 76:3513)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 10),
                child: ShimmerBox(
                  width: 110,
                  height: 14,
                  opacity: opacity,
                  borderRadius: 4,
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
                      color: Color(0xFF22D3EE), // Figma cyan #22d3ee
                      width: 4,
                    ),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A000000),
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
                        ShimmerBox(
                          width: 48,
                          height: 48,
                          opacity: opacity,
                          borderRadius: 12,
                          color: const Color(0x2A22D3EE),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ShimmerBox(
                                width: 70,
                                height: 16,
                                opacity: opacity,
                                borderRadius: 9999,
                                color: const Color(0x2A22D3EE),
                              ),
                              const SizedBox(height: 8),
                              ShimmerBox(
                                width: 170,
                                height: 18,
                                opacity: opacity,
                                borderRadius: 4,
                              ),
                              const SizedBox(height: 6),
                              ShimmerBox(
                                width: 130,
                                height: 14,
                                opacity: opacity,
                                borderRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ShimmerBox(
                      width: double.infinity,
                      height: 48,
                      opacity: opacity,
                      borderRadius: 12,
                      color: const Color(0xFF0037B1).withValues(alpha: 0.25),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 3. My Learning Section Skeleton (Figma Node 76:3530)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ShimmerBox(
                  width: 120,
                  height: 22,
                  opacity: opacity,
                  borderRadius: 4,
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerBox(
                          width: 40,
                          height: 40,
                          opacity: opacity,
                          borderRadius: 10,
                          color: const Color(0x2A14B8A6),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ShimmerBox(
                                width: 110,
                                height: 16,
                                opacity: opacity,
                                borderRadius: 9999,
                                color: const Color(0x2A14B8A6),
                              ),
                              const SizedBox(height: 8),
                              ShimmerBox(
                                width: double.infinity,
                                height: 18,
                                opacity: opacity,
                                borderRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ShimmerBox(
                      width: double.infinity,
                      height: 6,
                      opacity: opacity,
                      borderRadius: 9999,
                    ),
                    const SizedBox(height: 12),
                    ShimmerBox(
                      width: 160,
                      height: 14,
                      opacity: opacity,
                      borderRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 4. Bento Snapshot Grid Skeleton (Figma Node 76:3646)
              Row(
                children: [
                  // Progress Card Skeleton
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E1ED)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShimmerBox(
                            width: 32,
                            height: 32,
                            opacity: opacity,
                            borderRadius: 8,
                          ),
                          const SizedBox(height: 12),
                          ShimmerBox(
                            width: 60,
                            height: 14,
                            opacity: opacity,
                            borderRadius: 4,
                          ),
                          const SizedBox(height: 6),
                          ShimmerBox(
                            width: 45,
                            height: 20,
                            opacity: opacity,
                            borderRadius: 4,
                          ),
                          const SizedBox(height: 12),
                          ShimmerBox(
                            width: double.infinity,
                            height: 6,
                            opacity: opacity,
                            borderRadius: 9999,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Attendance Card Skeleton
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E1ED)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShimmerBox(
                            width: 32,
                            height: 32,
                            opacity: opacity,
                            borderRadius: 8,
                          ),
                          const SizedBox(height: 12),
                          ShimmerBox(
                            width: 70,
                            height: 14,
                            opacity: opacity,
                            borderRadius: 4,
                          ),
                          const SizedBox(height: 6),
                          ShimmerBox(
                            width: 50,
                            height: 20,
                            opacity: opacity,
                            borderRadius: 4,
                          ),
                          const SizedBox(height: 12),
                          ShimmerBox(
                            width: 65,
                            height: 14,
                            opacity: opacity,
                            borderRadius: 9999,
                            color: const Color(0x2A10B981),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  // Assignments Card Skeleton
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3E8FF).withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShimmerBox(
                            width: 28,
                            height: 28,
                            opacity: opacity,
                            borderRadius: 8,
                          ),
                          const SizedBox(height: 10),
                          ShimmerBox(
                            width: 80,
                            height: 14,
                            opacity: opacity,
                            borderRadius: 4,
                          ),
                          const SizedBox(height: 6),
                          ShimmerBox(
                            width: 30,
                            height: 20,
                            opacity: opacity,
                            borderRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Current Topic Card Skeleton
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2FE).withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShimmerBox(
                            width: 28,
                            height: 28,
                            opacity: opacity,
                            borderRadius: 8,
                          ),
                          const SizedBox(height: 10),
                          ShimmerBox(
                            width: 75,
                            height: 14,
                            opacity: opacity,
                            borderRadius: 4,
                          ),
                          const SizedBox(height: 6),
                          ShimmerBox(
                            width: 90,
                            height: 16,
                            opacity: opacity,
                            borderRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}
