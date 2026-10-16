import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/auth_controller.dart';
import '../controllers/auth_state.dart';
import '../../../onboarding/presentation/controllers/onboarding_controller.dart';

/// Screen B — Set Up Password Login
///
/// Displayed after native Google OAuth authentication if the backend reports
/// that password creation is required (GET /api/parent/security/password-prompt-status).
/// Designed using the exact visual language of Parent(full app)_TreLern.
class PasswordSetupScreen extends ConsumerStatefulWidget {
  const PasswordSetupScreen({super.key});

  @override
  ConsumerState<PasswordSetupScreen> createState() =>
      _PasswordSetupScreenState();
}

class _PasswordSetupScreenState extends ConsumerState<PasswordSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onTextChanged);
    _confirmPasswordController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {
      _errorMessage = null;
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _hasMinLength => _passwordController.text.length >= 8;
  bool get _hasNumberOrSpecial =>
      RegExp(r'[0-9!@#\$&*~._-]').hasMatch(_passwordController.text);
  bool get _passwordsMatch =>
      _passwordController.text.isNotEmpty &&
      _passwordController.text == _confirmPasswordController.text;

  bool get _isFormValid =>
      _hasMinLength && _hasNumberOrSpecial && _passwordsMatch;

  Future<void> _handleSavePassword() async {
    if (!_isFormValid) {
      setState(() {
        if (!_hasMinLength) {
          _errorMessage = 'Password must be at least 8 characters long.';
        } else if (!_hasNumberOrSpecial) {
          _errorMessage =
              'Password must contain at least one number or special character.';
        } else if (!_passwordsMatch) {
          _errorMessage = 'Passwords do not match.';
        }
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    FocusScope.of(context).unfocus();

    try {
      final success = await ref
          .read(authControllerProvider.notifier)
          .setupPassword(
            password: _passwordController.text,
            confirmPassword: _confirmPasswordController.text,
          );

      if (!mounted) return;

      if (success) {
        ref.read(authControllerProvider.notifier).markPasswordSetupCompleted();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password created successfully!'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _navigateNext();
      } else {
        setState(() {
          _errorMessage = 'Could not save password. Please try again.';
          _isSubmitting = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isSubmitting = false;
      });
    }
  }

  void _navigateNext() {
    final authState = ref.read(authControllerProvider);
    if (authState is Authenticated) {
      switch (authState.destination) {
        case AuthDestination.onboardingChild:
          context.go(AppRoutePaths.onboardingChild);
          break;
        case AuthDestination.onboardingInterests:
          context.go(AppRoutePaths.onboardingInterests);
          break;
        case AuthDestination.demoBookingDashboard:
          if (authState.demoData != null) {
            ref
                .read(onboardingControllerProvider.notifier)
                .restoreDemoBookingState(
                  leadId: authState.resolvedLeadId,
                  courseName: authState.resolvedCourseName,
                );
          }
          context.go(AppRoutePaths.demoBookingDashboard);
          break;
        case AuthDestination.studentDashboard:
        case AuthDestination.passwordSetup:
          context.go(AppRoutePaths.parentDashboard);
          break;
      }
    } else {
      context.go(AppRoutePaths.parentDashboard);
    }
  }

  Future<void> _handleMaybeLater() async {
    setState(() => _isSubmitting = true);
    await ref
        .read(authControllerProvider.notifier)
        .dismissPasswordPrompt(action: 'maybe_later');
    if (!mounted) return;
    ref.read(authControllerProvider.notifier).markPasswordSetupCompleted();
    _navigateNext();
  }

  Future<void> _handleDontAskAgain() async {
    setState(() => _isSubmitting = true);
    await ref
        .read(authControllerProvider.notifier)
        .dismissPasswordPrompt(action: 'dont_ask_again');
    if (!mounted) return;
    ref.read(authControllerProvider.notifier).markPasswordSetupCompleted();
    _navigateNext();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background decorative gradient blob
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
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // TrueLern Logo
                          Center(
                            child: Image.asset(
                              'assets/images/truelern_brand_logo.png',
                              height: 44.0,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  Text(
                                    'TrueLern',
                                    style: GoogleFonts.hankenGrotesk(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                    ),
                                  ),
                            ),
                          ),

                          const SizedBox(height: 24.0),

                          // Heading
                          Text(
                            'Create New Password',
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 22.0,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF191C1E),
                            ),
                          ),

                          const SizedBox(height: 8.0),

                          Text(
                            'Set up a secure password to access your TrueLern Parent account with email anytime.',
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 14.0,
                              height: 1.45,
                              color: const Color(0xFF64748B),
                            ),
                          ),

                          if (_errorMessage != null) ...[
                            const SizedBox(height: 16.0),
                            Container(
                              padding: const EdgeInsets.all(12.0),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(10.0),
                                border: Border.all(
                                  color: const Color(0xFFFCA5A5),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline_rounded,
                                    color: Color(0xFFDC2626),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: GoogleFonts.hankenGrotesk(
                                        color: const Color(0xFFDC2626),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 24.0),

                          // Create New Password Label
                          Text(
                            'Create New Password *',
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 14.0,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF334155),
                            ),
                          ),
                          const SizedBox(height: 8.0),

                          // New Password Input
                          TextFormField(
                            controller: _passwordController,
                            obscureText: !_isPasswordVisible,
                            decoration: InputDecoration(
                              hintText: 'Enter new password',
                              hintStyle: GoogleFonts.hankenGrotesk(
                                color: const Color(0xFF94A3B8),
                                fontSize: 14.0,
                              ),
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                                color: Color(0xFF64748B),
                                size: 20,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: const Color(0xFF64748B),
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
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
                          ),

                          const SizedBox(height: 18.0),

                          // Confirm New Password Label
                          Text(
                            'Confirm New Password *',
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 14.0,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF334155),
                            ),
                          ),
                          const SizedBox(height: 8.0),

                          // Confirm Password Input
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: !_isConfirmPasswordVisible,
                            decoration: InputDecoration(
                              hintText: 'Re-enter your password',
                              hintStyle: GoogleFonts.hankenGrotesk(
                                color: const Color(0xFF94A3B8),
                                fontSize: 14.0,
                              ),
                              prefixIcon: const Icon(
                                Icons.lock_clock_outlined,
                                color: Color(0xFF64748B),
                                size: 20,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isConfirmPasswordVisible
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: const Color(0xFF64748B),
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isConfirmPasswordVisible =
                                        !_isConfirmPasswordVisible;
                                  });
                                },
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
                          ),

                          const SizedBox(height: 20.0),

                          // Requirement checklist
                          _buildRequirementItem(
                            label: 'At least 8 characters',
                            isSatisfied: _hasMinLength,
                          ),
                          const SizedBox(height: 6.0),
                          _buildRequirementItem(
                            label: 'At least 1 number or special character',
                            isSatisfied: _hasNumberOrSpecial,
                          ),
                          const SizedBox(height: 6.0),
                          _buildRequirementItem(
                            label: 'Passwords match',
                            isSatisfied: _passwordsMatch,
                          ),

                          const SizedBox(height: 28.0),

                          // Save Password Button
                          SizedBox(
                            width: double.infinity,
                            height: 50.0,
                            child: ElevatedButton(
                              onPressed: _isSubmitting
                                  ? null
                                  : _handleSavePassword,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                              ),
                              child: _isSubmitting
                                  ? const SizedBox(
                                      width: 22.0,
                                      height: 22.0,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      'Save Password',
                                      style: GoogleFonts.hankenGrotesk(
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 16.0),

                          // Maybe Later / Don't Ask Again
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            runSpacing: 4.0,
                            children: [
                              TextButton(
                                onPressed: _isSubmitting
                                    ? null
                                    : _handleMaybeLater,
                                child: Text(
                                  'Maybe Later',
                                  style: GoogleFonts.hankenGrotesk(
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: _isSubmitting
                                    ? null
                                    : _handleDontAskAgain,
                                child: Text(
                                  "Don't Ask Again",
                                  style: GoogleFonts.hankenGrotesk(
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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

  Widget _buildRequirementItem({
    required String label,
    required bool isSatisfied,
  }) {
    return Row(
      children: [
        Icon(
          isSatisfied
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          size: 16.0,
          color: isSatisfied
              ? const Color(0xFF10B981)
              : const Color(0xFF94A3B8),
        ),
        const SizedBox(width: 8.0),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 13.0,
              color: isSatisfied
                  ? const Color(0xFF0F766E)
                  : const Color(0xFF64748B),
              fontWeight: isSatisfied ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}
