import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../widgets/security_privacy_sub_app_bar.dart';
import '../../../../core/widgets/app_refresh_indicator.dart';

/// Screen 7 — Terms & Conditions.
///
/// Clean, highly readable legal terms screen matching TrueLern visual language:
/// - Gradient canvas background
/// - Top App Bar
/// - White rounded card container with subtle shadow
/// - Terms title, "Last updated", structured numbered sections, paragraphs, bullet lists
class ParentTermsConditionsScreen extends StatelessWidget {
  const ParentTermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('parent_terms_conditions_screen'),
      backgroundColor: const Color(0xFFFAF8FF),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF3E8FF), Color(0xFFE0F2FE), Color(0xFFFFFFFF)],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SecurityPrivacySubAppBar(title: 'Terms & Conditions'),
              Expanded(
                child: AppRefreshIndicator(
                  onRefresh: () async {
                    await Future.delayed(const Duration(milliseconds: 300));
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Please read our terms and conditions carefully.',
                              style: AppTypography.bodyMedium.copyWith(
                                color: const Color(0xFF64748B),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 18),

                            // Terms Document Card
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x08000000),
                                    blurRadius: 12,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'TrueLern Terms & Conditions',
                                    style: GoogleFonts.hankenGrotesk(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today_outlined,
                                        size: 14,
                                        color: Color(0xFF94A3B8),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Last updated: 01 September 2026',
                                        style: GoogleFonts.hankenGrotesk(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w500,
                                          color: const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  const Divider(
                                    color: Color(0xFFF1F5F9),
                                    height: 1,
                                  ),
                                  const SizedBox(height: 20),

                                  _buildSectionTitle('1. Acceptance of Terms'),
                                  _buildParagraph(
                                    'By accessing or using the TrueLern mobile application, parent portal, or associated educational services, you agree to be bound by these Terms and Conditions. If you do not agree, please do not use the application.',
                                  ),

                                  _buildSectionTitle('2. Use of Services'),
                                  _buildParagraph(
                                    'You agree to use our services exclusively for lawful educational purposes and in accordance with institutional codes of conduct.',
                                  ),

                                  _buildSectionTitle(
                                    '3. Account Responsibility',
                                  ),
                                  _buildParagraph(
                                    'As an authenticated parent or guardian:',
                                  ),
                                  _buildBulletPoint(
                                    'You are responsible for maintaining the confidentiality of your login credentials.',
                                  ),
                                  _buildBulletPoint(
                                    'You are responsible for all activities and submissions conducted under your parent account and linked student profiles.',
                                  ),
                                  _buildBulletPoint(
                                    'You agree to notify school authorities immediately of any suspected unauthorized access.',
                                  ),

                                  _buildSectionTitle(
                                    '4. Live Classes & Classroom Decorum',
                                  ),
                                  _buildParagraph(
                                    'Live video classrooms are strictly for registered students and educational supervision. Recording, rebroadcasting, screen-capturing, or unauthorized distribution of classroom sessions is strictly prohibited.',
                                  ),

                                  _buildSectionTitle(
                                    '5. Intellectual Property',
                                  ),
                                  _buildParagraph(
                                    'All curriculum materials, video lectures, assignments, and software features are protected under copyright and intellectual property laws of TrueLern and its academic partners. Content may not be copied or repurposed.',
                                  ),

                                  _buildSectionTitle(
                                    '6. Invoices & Fee Schedules',
                                  ),
                                  _buildParagraph(
                                    'Academic tuition fees, invoice billing dates, and receipt histories are managed through our secure billing subsystem. Parents agree to settle invoices within scheduled cycles as specified in enrollment agreements.',
                                  ),

                                  _buildSectionTitle(
                                    '7. Modifications & Inquiries',
                                  ),
                                  _buildParagraph(
                                    'TrueLern reserves the right to update these terms to reflect curriculum enhancements or regulatory requirements. For inquiries, contact legal@truelern.com.',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),
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
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.hankenGrotesk(
          fontSize: 15.5,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF0F172A),
        ),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: GoogleFonts.hankenGrotesk(
          fontSize: 13.5,
          height: 1.5,
          color: const Color(0xFF475569),
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(color: AppColors.primary, fontSize: 16),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 13,
                height: 1.45,
                color: const Color(0xFF475569),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
