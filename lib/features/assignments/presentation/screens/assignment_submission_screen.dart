import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../../dashboard/presentation/controllers/children_controller.dart';
import '../../../dashboard/presentation/controllers/children_state.dart';
import '../../domain/entities/assignment_entity.dart';
import '../controllers/assignment_submission_controller.dart';
import '../../../../core/widgets/app_refresh_indicator.dart';
import 'attachment_viewer_screen.dart';

/// Assignment Detail & Submission Screen (SCR-18/Figma Frame 76:2474)
///
/// Fully dynamic:
/// 1. Back navigation arrow and "Assignment" title
/// 2. Header Section with topic icon (puzzle), topic pill, title, and due date from backend assignment
/// 3. Upload Submission dynamic states:
///    - State A: Not Started (dashed upload dropzone with native file picker)
///    - State B: File Selected / Draft (file pill with actual name, size, delete & replace actions)
///    - State C: Submitting (animated progress indicator & submit status)
///    - State D: Submitted (green celebration badge, success message, real submitted file info)
class AssignmentSubmissionScreen extends ConsumerStatefulWidget {
  final String? assignmentId;
  final AssignmentEntity? assignment;
  final bool showAllStatesOverview;

  const AssignmentSubmissionScreen({
    super.key,
    this.assignmentId,
    this.assignment,
    this.showAllStatesOverview = false,
  });

  @override
  ConsumerState<AssignmentSubmissionScreen> createState() =>
      _AssignmentSubmissionScreenState();
}

class _AssignmentSubmissionScreenState
    extends ConsumerState<AssignmentSubmissionScreen> {
  String get _effectiveAssignmentId =>
      widget.assignmentId ?? widget.assignment?.id ?? 'default_asg';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        _initController();
      }
    });
  }

  void _initController() {
    final childrenState = ref.read(childrenControllerProvider);
    String? activeChildId;
    if (childrenState is ChildrenLoaded) {
      activeChildId = childrenState.activeChildId;
    }
    activeChildId ??= widget.assignment?.childStudentId;

    ref
        .read(assignmentSubmissionControllerProvider.notifier)
        .init(
          assignmentId: _effectiveAssignmentId,
          childStudentId: activeChildId,
          initialAssignment: widget.assignment,
        );
  }

  /// Opens the real native device file picker (PDF, DOCX, JPG; max 10MB)
  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'jpg', 'jpeg'],
      );

      if (result.isEmpty) {
        // User cancelled picker
        return;
      }

      final file = result.first;
      final path = file.path;
      final name = file.name;
      int size = file.lengthSync() ?? 0;
      if (size <= 0) {
        size = (await file.length()) ?? 0;
      }
      if (size <= 0 && path != null && path.isNotEmpty) {
        try {
          final ioFile = File(path);
          if (ioFile.existsSync()) {
            size = ioFile.lengthSync();
          }
        } catch (_) {}
      }

      // Validate size <= 10MB
      const maxSizeBytes = 10 * 1024 * 1024;
      if (size > maxSizeBytes) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'File size exceeds the 10 MB limit. Please select a smaller file.',
              ),
              backgroundColor: Color(0xFFBA1A1A),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      // Determine mime/extension type
      final ext = file.extension?.toLowerCase() ?? 'pdf';
      final mimeType = switch (ext) {
        'docx' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'jpg' || 'jpeg' => 'image/jpeg',
        _ => 'application/pdf',
      };

      ref
          .read(assignmentSubmissionControllerProvider.notifier)
          .setLocalFile(
            assignmentId: _effectiveAssignmentId,
            path: path ?? '',
            name: name,
            size: size,
            type: mimeType,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Selected "$name"'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not select file: $e'),
            backgroundColor: const Color(0xFFBA1A1A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _onDeleteFile() {
    ref
        .read(assignmentSubmissionControllerProvider.notifier)
        .clearFile(_effectiveAssignmentId);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Selected file removed.'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _onSubmitNow() async {
    final success = await ref
        .read(assignmentSubmissionControllerProvider.notifier)
        .submitNow(assignmentId: _effectiveAssignmentId);

    if (!mounted) return;

    final state = ref.read(
      singleAssignmentSubmissionProvider(_effectiveAssignmentId),
    );
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Assignment submitted successfully!'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
      try {
        context.go(
          '/parent/assignments/$_effectiveAssignmentId/submitted',
          extra: state.assignment ?? widget.assignment,
        );
      } catch (_) {}
    } else if (state.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.errorMessage!),
          backgroundColor: const Color(0xFFBA1A1A),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ChildrenState>(childrenControllerProvider, (prev, next) {
      if (next is ChildrenLoaded) {
        final prevChildId = prev is ChildrenLoaded ? prev.activeChildId : null;
        if (prevChildId != next.activeChildId && next.activeChildId != null) {
          ref
              .read(assignmentSubmissionControllerProvider.notifier)
              .init(
                assignmentId: _effectiveAssignmentId,
                childStudentId: next.activeChildId,
                initialAssignment: null,
              );
        }
      }
    });

    final subState = ref.watch(
      singleAssignmentSubmissionProvider(_effectiveAssignmentId),
    );

    final currentAssignment = subState.assignment ?? widget.assignment;
    final title = currentAssignment?.title ?? 'Assignment Details';
    final topic = currentAssignment?.topic ?? 'Academics';
    final dueDate = currentAssignment?.dueDate ?? 'Due date pending';

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient matching TrueLern design system
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(-0.8, -1.0),
                end: Alignment(0.8, 1.0),
                stops: [0.0, 0.5, 1.0],
                colors: [
                  Color(0xFFF3E8FF), // Light purple
                  Color(0xFFE0F2FE), // Sky blue tint
                  Color(0xFFFFFFFF), // Pure white
                ],
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Top Header (Figma Node 76:2498)
                _buildTopHeader(context),

                // Main Scrollable Area
                Expanded(
                  child: AppRefreshIndicator(
                    onRefresh: () async {
                      _initController();
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 96),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 448),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header Section (Figma Node 76:2507)
                              _buildHeaderSection(
                                topic,
                                title,
                                dueDate,
                                currentAssignment,
                              ),
                              const SizedBox(height: 16),

                              // Assignment Details & Instructions
                              _buildDescriptionCard(currentAssignment),
                              const SizedBox(height: 16),

                              // Teacher-Provided Attachments & Resources
                              if (currentAssignment != null &&
                                  currentAssignment.attachments.isNotEmpty) ...[
                                _buildTeacherAttachmentsCard(
                                  currentAssignment.attachments,
                                  assignmentTitle: currentAssignment.title,
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Submission Guidelines & Requirements
                              _buildRequirementsCard(currentAssignment),
                              const SizedBox(height: 24),

                              // Dynamic Active Card (Upload Submission)
                              _buildDynamicCard(subState),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Top Header Bar (Figma Node 76:2498)
  Widget _buildTopHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back Button (Node 76:2500)
          InkWell(
            key: const Key('submission_back_button'),
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/parent/assignments');
              }
            },
            borderRadius: BorderRadius.circular(9999),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: SvgPicture.asset(
                'assets/icons/submission_arrow_back.svg',
                width: 16,
                height: 16,
                colorFilter: const ColorFilter.mode(
                  Color(0xFF191C1E),
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Title (Node 76:2504)
          Text(
            'Assignment',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 21.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF191C1E),
              letterSpacing: -0.2,
              height: 28 / 20,
            ),
          ),
        ],
      ),
    );
  }

  /// Header Section (Figma Node 76:2507)
  Widget _buildHeaderSection(
    String topic,
    String title,
    String dueDate, [
    AssignmentEntity? assignment,
  ]) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Topic Icon Box (Node 76:2509)
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFA855F7).withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: SvgPicture.asset(
                'assets/icons/submission_puzzle.svg',
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(
                  Color(0xFFA855F7),
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Titles & Topic Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Topic Pill (Node 76:2512)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFA855F7).withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Text(
                    topic,
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFA855F7),
                      height: 16 / 12,
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                // Assignment Title (Node 76:2516)
                Text(
                  title,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1B23),
                    height: 32 / 26,
                  ),
                ),
                const SizedBox(height: 4),

                // Due Date (Node 76:2518)
                Text(
                  dueDate,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF747686),
                    height: 20 / 14,
                  ),
                ),

                // Key Metrics Row (from real API response)
                if (assignment != null) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _buildMiniBadge(
                        icon: Icons.assignment_turned_in_outlined,
                        label: 'Max: ${assignment.totalMarks ?? 100} pts',
                        color: const Color(0xFF0037B1),
                        bgColor: const Color(0xFFEFF4FF),
                      ),
                      if (assignment.passingMarks != null)
                        _buildMiniBadge(
                          icon: Icons.flag_outlined,
                          label: 'Pass: ${assignment.passingMarks} pts',
                          color: const Color(0xFF0D9488),
                          bgColor: const Color(0xFFF0FDFA),
                        ),
                      if (assignment.difficultyLevel != null &&
                          assignment.difficultyLevel!.isNotEmpty)
                        _buildMiniBadge(
                          icon: Icons.speed_outlined,
                          label:
                              assignment.difficultyLevel![0].toUpperCase() +
                              assignment.difficultyLevel!.substring(1),
                          color: const Color(0xFFD97706),
                          bgColor: const Color(0xFFFFFBEB),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Description and Instructions Card
  Widget _buildDescriptionCard(AssignmentEntity? assignment) {
    final descriptionText = assignment?.cleanDescription;
    final hasContent =
        descriptionText != null && descriptionText.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.04),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0037B1).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  size: 20,
                  color: Color(0xFF0037B1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Description & Instructions',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1B23),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            hasContent
                ? descriptionText
                : 'No specific instructions provided for this assignment.',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: hasContent
                  ? const Color(0xFF333647)
                  : const Color(0xFF747686),
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  /// Teacher-Provided Attachments and Resources Card
  Widget _buildTeacherAttachmentsCard(
    List<AssignmentAttachmentEntity> attachments, {
    String assignmentTitle = 'Assignment',
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.04),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFA855F7).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.attach_file_rounded,
                  size: 20,
                  color: Color(0xFFA855F7),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Teacher Attachments',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1B23),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFA855F7).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  '${attachments.length}',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFA855F7),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...attachments.map((att) {
            IconData iconData = Icons.picture_as_pdf_rounded;
            Color iconColor = const Color(0xFFDC2626);
            Color iconBgColor = const Color(0xFFFFEEEE);

            final lowerName = att.fileName.toLowerCase();
            final lowerType = att.fileType.toLowerCase();

            if (lowerName.endsWith('.doc') ||
                lowerName.endsWith('.docx') ||
                lowerType.contains('word') ||
                lowerType.contains('officedocument')) {
              iconData = Icons.article_rounded;
              iconColor = const Color(0xFF2563EB);
              iconBgColor = const Color(0xFFEFF6FF);
            } else if (lowerName.endsWith('.jpg') ||
                lowerName.endsWith('.jpeg') ||
                lowerName.endsWith('.png') ||
                lowerName.endsWith('.webp') ||
                lowerType.contains('image')) {
              iconData = Icons.image_rounded;
              iconColor = const Color(0xFF10B981);
              iconBgColor = const Color(0xFFECFDF5);
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: InkWell(
                key: Key('view_attachment_${att.id}'),
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => AttachmentViewerScreen(
                        attachment: att,
                        assignmentTitle: assignmentTitle,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: iconBgColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(iconData, color: iconColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              att.fileName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1F2937),
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              att.displayFileSize.isNotEmpty
                                  ? att.displayFileSize
                                  : 'Document',
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0037B1)
                              .withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'View',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0037B1),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Submission Requirements and Guidelines Card
  Widget _buildRequirementsCard(AssignmentEntity? assignment) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.04),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.rule_folder_outlined,
                  size: 20,
                  color: Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Submission Guidelines',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1B23),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildRequirementRow(
            icon: Icons.file_present_outlined,
            label: 'Allowed Formats',
            value: 'PDF, DOCX, JPG',
          ),
          const SizedBox(height: 8),
          _buildRequirementRow(
            icon: Icons.data_usage_rounded,
            label: 'Max File Size',
            value: '10 MB',
          ),
          const SizedBox(height: 8),
          _buildRequirementRow(
            icon: Icons.history_rounded,
            label: 'Attempt Limit',
            value: '${assignment?.maxAttempts ?? 1} Max Attempt',
          ),
          const SizedBox(height: 8),
          _buildRequirementRow(
            icon: Icons.alarm_outlined,
            label: 'Late Submission',
            value: assignment?.isLateSubmissionAllowed == true
                ? 'Allowed'
                : 'Not Allowed',
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF747686)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF747686),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: GoogleFonts.hankenGrotesk(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A1B23),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniBadge({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

  /// Dynamic card switcher based on actual assignment submission status
  Widget _buildDynamicCard(AssignmentSubmissionState state) {
    if (state.isSubmitted) {
      return _buildSubmittedCard(state);
    }

    switch (state.status) {
      case SubmissionFlowStatus.submitting:
        return _buildSubmittingCard(state);

      case SubmissionFlowStatus.localFileSelected:
        return _buildFileSelectedCard(state);

      case SubmissionFlowStatus.notStarted:
      case SubmissionFlowStatus.initial:
      case SubmissionFlowStatus.loadingDetail:
      case SubmissionFlowStatus.error:
      case SubmissionFlowStatus.submitted:
        return _buildNotStartedCard();
    }
  }

  // ==========================================
  // STATE A: NOT STARTED CARD (Figma Node 76:2520)
  // ==========================================
  Widget _buildNotStartedCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.04),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row (Node 76:2522)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Upload Submission',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 21.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1B23),
                    height: 28 / 20,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Not Started Pill (Node 76:2525)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8E7F3),
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  'Not Started',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF747686),
                    height: 16 / 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Dashed Upload Dropzone (Node 76:2527)
          InkWell(
            key: const Key('tap_to_upload_box'),
            onTap: _pickFile,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: DashedBorder(
                  color: const Color(0xFFC4C5D7),
                  strokeWidth: 2,
                  dashPattern: const [6, 4],
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 36),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Cloud Upload Icon (Node 76:2529)
                  SvgPicture.asset(
                    'assets/icons/submission_cloud_upload.svg',
                    width: 33,
                    height: 24,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFF747686),
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tap to upload file (Node 76:2533)
                  Text(
                    'Tap to upload file',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1B23),
                      height: 24 / 16,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Supported formats description (Node 76:2534)
                  Text(
                    'Supported formats: PDF, DOCX, JPG\n(Max 10MB)',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF747686),
                      height: 20 / 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // STATE B: FILE SELECTED CARD (Figma Node 76:2536)
  // ==========================================
  Widget _buildFileSelectedCard(AssignmentSubmissionState state) {
    final fileName = state.displayFileName ?? 'selected_file.pdf';
    final fileSize = state.displayFileSize ?? '0 KB';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.04),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row (Node 76:2538)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Upload Submission',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 21.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1B23),
                    height: 28 / 20,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // File Selected Pill (Node 76:2541)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      'assets/icons/submission_check_purple.svg',
                      width: 12,
                      height: 12,
                      colorFilter: const ColorFilter.mode(
                        Color(0xFF4F46E5),
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'File Selected',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF4F46E5),
                        height: 16 / 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Real File Card Box (Node 76:2546)
          Container(
            height: 81,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F2FE),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFC4C5D7).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                // File Type Icon Box (Node 76:2548)
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8E7F3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/icons/submission_file_blue.svg',
                      width: 16,
                      height: 20,
                      colorFilter: const ColorFilter.mode(
                        Color(0xFF4F46E5),
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // File Name & Size (Node 76:2551)
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fileName,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1B23),
                          height: 24 / 16,
                        ),
                      ),
                      Text(
                        fileSize,
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF747686),
                          height: 20 / 14,
                        ),
                      ),
                    ],
                  ),
                ),

                // Trash Delete Icon (Node 76:2556)
                IconButton(
                  key: const Key('delete_draft_file_button'),
                  onPressed: _onDeleteFile,
                  icon: SvgPicture.asset(
                    'assets/icons/submission_trash.svg',
                    width: 16,
                    height: 18,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFF747686),
                      BlendMode.srcIn,
                    ),
                  ),
                  tooltip: 'Delete File',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Action Buttons Row: Replace & Submit Now (Node 76:2559)
          Row(
            children: [
              // Replace Button (Node 76:2560)
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: OutlinedButton(
                    key: const Key('replace_file_button'),
                    onPressed: _pickFile,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF0037B1)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Replace',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0037B1),
                        height: 24 / 16,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Submit Now Button (Node 76:2562)
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    key: const Key('submit_now_button'),
                    onPressed: _onSubmitNow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0037B1),
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shadowColor: Colors.black.withValues(alpha: 0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Submit Now',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 24 / 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // STATE C: SUBMITTING CARD (Figma Node 76:2565)
  // ==========================================
  Widget _buildSubmittingCard(AssignmentSubmissionState state) {
    final pct = (state.uploadProgress * 100).toInt();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.04),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(left: BorderSide(color: Color(0xFF22D3EE), width: 4)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 25, 25, 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row (Node 76:2567)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'Upload Submission',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 21.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1B23),
                      height: 28 / 20,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Submitting Pill (Node 76:2570)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22D3EE).withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        'assets/icons/submission_refresh_cyan.svg',
                        width: 10.6,
                        height: 10.6,
                        colorFilter: const ColorFilter.mode(
                          Color(0xFF22D3EE),
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Submitting...',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF22D3EE),
                          height: 16 / 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Uploading Progress Box (Node 76:2574)
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 200),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F2FE),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFC4C5D7).withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Cyan Circular Spinner Indicator (Node 76:2575)
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      value: state.uploadProgress > 0
                          ? state.uploadProgress.clamp(0.0, 1.0)
                          : null,
                      strokeWidth: 3.5,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF22D3EE),
                      ),
                      backgroundColor: const Color(0xFFE2E1ED),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Uploading file... title (Node 76:2578)
                  Text(
                    'Uploading file...',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1B23),
                      height: 24 / 16,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Cyan Progress Bar (Node 76:2579)
                  Container(
                    width: 200,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E1ED),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: state.uploadProgress.clamp(0.0, 1.0),
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: const Color(0xFF22D3EE),
                            borderRadius: BorderRadius.circular(9999),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Progress percent (Node 76:2582)
                  Text(
                    '$pct% complete',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF747686),
                      height: 20 / 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // STATE D: SUBMITTED SUCCESS CARD (Figma Node 76:2583)
  // ==========================================
  Widget _buildSubmittedCard(AssignmentSubmissionState state) {
    final submission = state.submission;
    final submittedFile = submission != null && submission.files.isNotEmpty
        ? submission.files.first.fileName
        : (state.displayFileName ?? 'submission_file.pdf');

    String formattedTime = 'Recently';
    if (submission?.submittedAt != null) {
      final dt = submission!.submittedAt!.toLocal();
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      final minute = dt.minute.toString().padLeft(2, '0');
      formattedTime = 'at $hour:$minute $ampm';
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.04),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: const Key('submitted_card_link'),
        onTap: () {
          try {
            context.go(
              '/parent/assignments/$_effectiveAssignmentId/submitted',
              extra: state.assignment ?? widget.assignment,
            );
          } catch (_) {}
        },
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              left: BorderSide(color: Color(0xFF10B981), width: 4),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(24, 25, 25, 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row (Node 76:2585)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'Submission Status',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 21.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1B23),
                        height: 28 / 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Submitted Badge (Node 76:2588)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(9999),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromRGBO(0, 0, 0, 0.05),
                          blurRadius: 1,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          'assets/icons/submission_check_white.svg',
                          width: 13.3,
                          height: 13.3,
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Submitted',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 16 / 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Big Green Checkmark Icon (Node 76:2594)
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.20),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/icons/submission_check_green_big.svg',
                      width: 30,
                      height: 30,
                      colorFilter: const ColorFilter.mode(
                        Color(0xFF10B981),
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Great job! Title (Node 76:2599)
              Center(
                child: Text(
                  'Great job!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1B23),
                    height: 24 / 16,
                  ),
                ),
              ),
              const SizedBox(height: 4),

              // Confirmation Text (Node 76:2602)
              Center(
                child: Text(
                  'Your assignment was submitted $formattedTime.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF747686),
                    height: 20 / 14,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Submitted File Pill with "View" CTA (Node 76:2603)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFC4C5D7).withValues(alpha: 0.2),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.05),
                      blurRadius: 1,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          SvgPicture.asset(
                            'assets/icons/submission_file_blue_small.svg',
                            width: 16,
                            height: 20,
                            colorFilter: const ColorFilter.mode(
                              Color(0xFF0037B1),
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              submittedFile,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF1A1B23),
                                height: 20 / 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      key: const Key('view_submitted_file_button'),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('File: "$submittedFile"'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'View',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0037B1),
                          height: 16 / 12,
                        ),
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
}

/// Custom Dashed Border Painter for the dropzone
class DashedBorder extends BoxBorder {
  final Color color;
  final double strokeWidth;
  final List<double> dashPattern;

  const DashedBorder({
    required this.color,
    this.strokeWidth = 2.0,
    this.dashPattern = const [6.0, 4.0],
  });

  @override
  BorderSide get top => BorderSide(color: color, width: strokeWidth);
  @override
  BorderSide get bottom => BorderSide(color: color, width: strokeWidth);

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(strokeWidth);

  @override
  bool get isUniform => true;

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    TextDirection? textDirection,
    BoxShape shape = BoxShape.rectangle,
    BorderRadius? borderRadius,
  }) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = borderRadius != null
        ? borderRadius.toRRect(rect.deflate(strokeWidth / 2))
        : RRect.fromRectAndRadius(rect.deflate(strokeWidth / 2), Radius.zero);

    final path = Path()..addRRect(rrect);
    final dashedPath = _createDashedPath(path, dashPattern);
    canvas.drawPath(dashedPath, paint);
  }

  Path _createDashedPath(Path source, List<double> pattern) {
    final dest = Path();
    for (final metric in source.computeMetrics()) {
      var distance = 0.0;
      var patternIndex = 0;
      while (distance < metric.length) {
        final len = pattern[patternIndex % pattern.length];
        final draw = patternIndex % 2 == 0;
        if (draw) {
          dest.addPath(
            metric.extractPath(distance, distance + len),
            Offset.zero,
          );
        }
        distance += len;
        patternIndex++;
      }
    }
    return dest;
  }

  @override
  ShapeBorder scale(double t) => DashedBorder(
    color: color,
    strokeWidth: strokeWidth * t,
    dashPattern: dashPattern.map((e) => e * t).toList(),
  );
}
