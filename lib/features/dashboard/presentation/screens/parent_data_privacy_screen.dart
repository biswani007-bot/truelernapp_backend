import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../widgets/security_privacy_sub_app_bar.dart';

/// Screen 5 — Data & Privacy.
///
/// Sections:
/// 1. Download Your Data card (with "Request Data Download" action)
/// 2. Delete Account card (destructive styling & strict confirmation dialog)
/// 3. "What data is included?" informational breakdown
class ParentDataPrivacyScreen extends StatelessWidget {
  const ParentDataPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('parent_data_privacy_screen'),
      backgroundColor: const Color(0xFFFAF8FF),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF3E8FF),
              Color(0xFFE0F2FE),
              Color(0xFFFFFFFF),
            ],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SecurityPrivacySubAppBar(title: 'Data & Privacy'),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 540),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'You can download your data or delete your account at any time.',
                            style: AppTypography.bodyMedium.copyWith(
                              color: const Color(0xFF64748B),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Section 1: Download Your Data Card
                          _buildDownloadCard(context),
                          const SizedBox(height: 20),

                          // Section 2: Delete Account Card (Destructive)
                          _buildDeleteAccountCard(context),
                          const SizedBox(height: 24),

                          // Section 3: What data is included?
                          _buildWhatDataIncludedCard(),
                          const SizedBox(height: 32),
                        ],
                      ),
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

  Widget _buildDownloadCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.cloud_download_outlined,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Download Your Data',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Get a copy of your personal data, learning history, and account information in JSON/CSV archive.',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 13,
              height: 1.45,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: () => _handleDataDownloadRequest(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: Text(
                'Request Data Download',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteAccountCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFEE2E2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.delete_outline_rounded,
              color: Color(0xFFDC2626),
              size: 24,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Delete Account',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF991B1B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Permanently delete your account and all associated data. This action cannot be undone.',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 13,
              height: 1.45,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: () => _handleDeleteAccountConfirmation(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFEE2E2),
                foregroundColor: const Color(0xFFDC2626),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: Color(0xFFFCA5A5), width: 0.8),
                ),
              ),
              child: Text(
                'Delete My Account',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFDC2626),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhatDataIncludedCard() {
    final items = [
      'Profile information & credentials',
      'Child/Student links and verified ward accounts',
      'Class attendance, schedule, and participation progress',
      'Assignments, submissions, and teacher feedback',
      'Communication logs and notification preferences',
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 20,
                color: Color(0xFF1D4ED8),
              ),
              const SizedBox(width: 8),
              Text(
                'What data is included?',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(color: Color(0xFF3B82F6), fontSize: 16)),
                  Expanded(
                    child: Text(
                      item,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 13,
                        color: const Color(0xFF475569),
                        height: 1.4,
                      ),
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

  void _handleDataDownloadRequest(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Request Account Data',
          style: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Self-service automated exports are currently being finalized. In accordance with data privacy regulations, our data protection officer can deliver your data archive within 48 hours.\n\nPlease contact support@truelern.com with subject "Data Export Request".',
          style: GoogleFonts.hankenGrotesk(fontSize: 13.5, height: 1.45, color: const Color(0xFF334155)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Understood'),
          ),
        ],
      ),
    );
  }

  void _handleDeleteAccountConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete TrueLern Account?',
          style: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.w700, color: const Color(0xFFDC2626)),
        ),
        content: Text(
          'This action is irreversible. Because your account is linked to active enrolled students, deletion requires verified authorization from your school administrator to ensure academic records are preserved.\n\nPlease reach out to your institution\'s coordinator or submit a closure request to administration.',
          style: GoogleFonts.hankenGrotesk(fontSize: 13.5, height: 1.45, color: const Color(0xFF334155)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account closure request logged. Support will contact you.'),
                  backgroundColor: Color(0xFF334155),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: const Text('Contact Support'),
          ),
        ],
      ),
    );
  }
}
