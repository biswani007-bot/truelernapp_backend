import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/onboarding_controller.dart';

/// Screen E / Step 3: Account Details (Figma Node 382:651 "Student Login (Account details)")
/// STEP 3 OF 4 in Parent(full app)_TreLern onboarding flow.
class OnboardingAccountScreen extends ConsumerStatefulWidget {
  const OnboardingAccountScreen({super.key});

  @override
  ConsumerState<OnboardingAccountScreen> createState() =>
      _OnboardingAccountScreenState();
}

class _OnboardingAccountScreenState
    extends ConsumerState<OnboardingAccountScreen> {
  final _fullNameController = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    final current = ref.read(onboardingControllerProvider);
    _fullNameController.text = current.parentFullName;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    super.dispose();
  }

  void _onContinue() {
    final name = _fullNameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Please enter your full name.');
      return;
    }

    if (name.length < 2) {
      setState(() => _error = 'Name must be at least 2 characters.');
      return;
    }

    ref
        .read(onboardingControllerProvider.notifier)
        .updateAccountDetails(fullName: name);

    context.push(AppRoutePaths.onboardingLocation);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background decorative gradient blob (Node 382:652)
          Positioned(
            top: -22.0,
            left: -22.0,
            width: 256.0,
            height: 256.0,
            child: IgnorePointer(
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0x334F46E5), Color(0x004F46E5)],
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420.0),
                  child: Container(
                    padding: const EdgeInsets.all(28.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24.0),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromRGBO(0, 0, 0, 0.06),
                          blurRadius: 24.0,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Back Navigation & Top Logo (Node 382:656)
                        Row(
                          children: [
                            InkWell(
                              onTap: () => context.pop(),
                              borderRadius: BorderRadius.circular(8.0),
                              child: Container(
                                padding: const EdgeInsets.all(6.0),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  size: 16.0,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                            const Spacer(),
                            Image.asset(
                              'assets/images/truelern_brand_logo.png',
                              height: 38.0,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  Text(
                                    'TrueLern',
                                    style: GoogleFonts.hankenGrotesk(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                    ),
                                  ),
                            ),
                            const Spacer(),
                            const SizedBox(width: 28.0),
                          ],
                        ),

                        const SizedBox(height: 28.0),

                        // Heading 1 (Node 382:661)
                        Text(
                          'Account details',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 24.0,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF191C1E),
                          ),
                        ),

                        const SizedBox(height: 8.0),

                        // Subtitle
                        Text(
                          'Please use your real name as it appears on official documents.',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 14.0,
                            height: 1.45,
                            color: const Color(0xFF64748B),
                          ),
                        ),

                        if (_error != null) ...[
                          const SizedBox(height: 14.0),
                          Container(
                            padding: const EdgeInsets.all(10.0),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Text(
                              _error!,
                              style: GoogleFonts.hankenGrotesk(
                                color: const Color(0xFFDC2626),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 24.0),

                        // Full Name Field (Node 382:668)
                        Text(
                          'Your Full Name *',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 14.0,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(height: 8.0),

                        TextFormField(
                          controller: _fullNameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            hintText: 'e.g. Jane Doe',
                            hintStyle: GoogleFonts.hankenGrotesk(
                              color: const Color(0xFF94A3B8),
                              fontSize: 14.0,
                            ),
                            prefixIcon: const Icon(
                              Icons.person_outline_rounded,
                              color: Color(0xFF64748B),
                              size: 20,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 14.0,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: const BorderSide(
                                color: Color(0xFFCBD5E1),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: const BorderSide(
                                color: Color(0xFFCBD5E1),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 1.8,
                              ),
                            ),
                          ),
                          onChanged: (_) {
                            if (_error != null) {
                              setState(() => _error = null);
                            }
                          },
                        ),

                        const SizedBox(height: 12.0),

                        // Security notice (Node 382:688)
                        Row(
                          children: [
                            const Icon(
                              Icons.lock_rounded,
                              size: 14.0,
                              color: Color(0xFF64748B),
                            ),
                            const SizedBox(width: 6.0),
                            Expanded(
                              child: Text(
                                'Your information is encrypted and securely stored.',
                                style: GoogleFonts.hankenGrotesk(
                                  fontSize: 12.0,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32.0),

                        // STEP 3 OF 4 indicator (Node 382:681)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10.0,
                            vertical: 4.0,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2F6),
                            borderRadius: BorderRadius.circular(6.0),
                          ),
                          child: Text(
                            'STEP 3 OF 4',
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 11.0,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16.0),

                        // Continue Button (Node 382:682)
                        SizedBox(
                          width: double.infinity,
                          height: 50.0,
                          child: ElevatedButton(
                            onPressed: _onContinue,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Continue',
                                  style: GoogleFonts.hankenGrotesk(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8.0),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 18.0,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
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
