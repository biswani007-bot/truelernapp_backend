import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/onboarding_controller.dart';

/// Screen F / Step 4: Location Details (Figma Node 382:731 "Student Login (select state city)")
/// "Almost Ready" step finalizing onboarding lead submission.
class OnboardingLocationScreen extends ConsumerStatefulWidget {
  const OnboardingLocationScreen({super.key});

  @override
  ConsumerState<OnboardingLocationScreen> createState() =>
      _OnboardingLocationScreenState();
}

class _OnboardingLocationScreenState
    extends ConsumerState<OnboardingLocationScreen> {
  final _stateController = TextEditingController();
  final _cityController = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    final current = ref.read(onboardingControllerProvider);
    _stateController.text = current.state;
    _cityController.text = current.city;
  }

  @override
  void dispose() {
    _stateController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (ref.read(onboardingControllerProvider).isSubmitting) return;

    final stateVal = _stateController.text.trim();
    final cityVal = _cityController.text.trim();

    if (stateVal.isEmpty) {
      setState(() => _error = 'Please enter your state or province.');
      return;
    }

    if (cityVal.isEmpty) {
      setState(() => _error = 'Please enter your city.');
      return;
    }

    ref
        .read(onboardingControllerProvider.notifier)
        .updateLocation(stateName: stateVal, cityName: cityVal);

    final success = await ref
        .read(onboardingControllerProvider.notifier)
        .submitLead();

    if (!mounted) return;

    if (success) {
      context.go(AppRoutePaths.demoBookingDashboard);
    } else {
      final errorMessage =
          ref.read(onboardingControllerProvider).errorMessage ??
          'Submission failed. Please try again.';
      setState(() => _error = errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final onboardingState = ref.watch(onboardingControllerProvider);
    final isSubmitting = onboardingState.isSubmitting;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background decorative gradient blob (Node 382:732)
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
                        // Back Navigation & Top Logo (Node 382:736)
                        Row(
                          children: [
                            InkWell(
                              onTap: isSubmitting ? null : () => context.pop(),
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

                        // Almost Ready Pill / Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10.0,
                            vertical: 4.0,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0E7FF),
                            borderRadius: BorderRadius.circular(6.0),
                          ),
                          child: Text(
                            'ALMOST READY',
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 11.0,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: const Color(0xFF4338CA),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12.0),

                        // Heading 1 (Node 382:741)
                        Text(
                          'Location Details',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 24.0,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF191C1E),
                          ),
                        ),

                        const SizedBox(height: 8.0),

                        // Subtitle (Node 382:744)
                        Text(
                          'Select your location so we can customize your regional experience and class timings.',
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

                        // State Label (Node 382:748)
                        Text(
                          'State *',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 14.0,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(height: 8.0),

                        TextFormField(
                          controller: _stateController,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            hintText: 'e.g. Maharashtra, California, etc.',
                            hintStyle: GoogleFonts.hankenGrotesk(
                              color: const Color(0xFF94A3B8),
                              fontSize: 14.0,
                            ),
                            prefixIcon: const Icon(
                              Icons.map_outlined,
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

                        const SizedBox(height: 20.0),

                        // City Label (Node 382:758)
                        Text(
                          'City *',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 14.0,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(height: 8.0),

                        TextFormField(
                          controller: _cityController,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            hintText: 'e.g. Mumbai, New York, etc.',
                            hintStyle: GoogleFonts.hankenGrotesk(
                              color: const Color(0xFF94A3B8),
                              fontSize: 14.0,
                            ),
                            prefixIcon: const Icon(
                              Icons.location_city_outlined,
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

                        const SizedBox(height: 32.0),

                        // Create Account / Submit Button (Node 382:766)
                        SizedBox(
                          width: double.infinity,
                          height: 52.0,
                          child: ElevatedButton(
                            onPressed: isSubmitting ? null : _handleSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                            ),
                            child: isSubmitting
                                ? const SizedBox(
                                    width: 22.0,
                                    height: 22.0,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: Colors.white,
                                    ),
                                  )
                                : FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Complete Registration',
                                          style: GoogleFonts.hankenGrotesk(
                                            fontSize: 16.0,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 8.0),
                                        const Icon(
                                          Icons.check_circle_rounded,
                                          size: 20.0,
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 16.0),

                        // Terms Notice (Node 382:771)
                        Text(
                          "By completing registration, you agree to TrueLern's Terms of Service and Privacy Policy.",
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 12.0,
                            height: 1.4,
                            color: const Color(0xFF94A3B8),
                          ),
                          textAlign: TextAlign.center,
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
