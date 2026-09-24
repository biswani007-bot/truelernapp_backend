import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../widgets/security_privacy_sub_app_bar.dart';

/// Screen 6 — Privacy Policy.
///
/// Clean, highly readable policy document screen matching TrueLern visual language:
/// - Gradient canvas background
/// - Top App Bar
/// - White rounded card container with subtle shadow
/// - Policy title, "Last updated", structured numbered sections, paragraphs, bullet lists
class ParentPrivacyPolicyScreen extends StatelessWidget {
  const ParentPrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('parent_privacy_policy_screen'),
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
              const SecurityPrivacySubAppBar(title: 'Privacy Policy'),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Learn how we collect, use, and protect your data.',
                            style: AppTypography.bodyMedium.copyWith(
                              color: const Color(0xFF64748B),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Policy Document Card
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
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
                                  'TrueLern Privacy Policy',
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
                                const Divider(color: Color(0xFFF1F5F9), height: 1),
                                const SizedBox(height: 20),

                                _buildSectionTitle('1. Introduction'),
                                _buildParagraph(
                                  'This Privacy Policy explains how TrueLern collects, uses, and protects your personal and educational information when you and your children access our mobile applications, web portals, and learning management services.',
                                ),

                                _buildSectionTitle('2. Information We Collect'),
                                _buildParagraph(
                                  'We collect information necessary to deliver educational courses, monitor academic progress, and manage parental oversight:',
                                ),
                                _buildBulletPoint('Personal Information: Parent name, email address, phone number, and physical billing address.'),
                                _buildBulletPoint('Child / Student Information: Student name, grade, enrolled cohorts, and student identification code.'),
                                _buildBulletPoint('Learning Activity & Progress: Live class attendance, homework submissions, teacher evaluations, and assessment scores.'),
                                _buildBulletPoint('Technical Information: Device model, operating system, and IP address for secure session verification.'),

                                _buildSectionTitle('3. How We Use Your Information'),
                                _buildParagraph('We use the gathered information strictly for educational services:'),
                                _buildBulletPoint('Delivering interactive live classroom sessions and recorded tutorials.'),
                                _buildBulletPoint('Facilitating communication between teachers, students, and parents.'),
                                _buildBulletPoint('Sending schedule alerts, assignment reminders, and academic report cards.'),
                                _buildBulletPoint('Preventing unauthorized access and ensuring platform security.'),

                                _buildSectionTitle('4. Data Sharing & Protection'),
                                _buildParagraph(
                                  'TrueLern does NOT sell, rent, or monetize your personal or student data to advertisers or third parties. Information is only shared with authorized educational staff and essential platform sub-processors (such as secure video conferencing and push notifications).',
                                ),

                                _buildSectionTitle('5. Children\'s Privacy'),
                                _buildParagraph(
                                  'We strictly uphold student data privacy standards in accordance with applicable child privacy protections. Student accounts are established under verifiable parental consent, and only parents or school guardians may configure accounts.',
                                ),

                                _buildSectionTitle('6. Security & Encryption'),
                                _buildParagraph(
                                  'All sensitive traffic is encrypted using TLS 1.3 in transit and AES-256 at rest. Authentication credentials are protected with salted hashing and hardware-backed secure storage.',
                                ),

                                _buildSectionTitle('7. Contact Our Data Protection Officer'),
                                _buildParagraph(
                                  'If you have questions about your privacy rights or wish to inspect your recorded data, contact our security team at privacy@truelern.com.',
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
          const Text('• ', style: TextStyle(color: AppColors.primary, fontSize: 16)),
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
