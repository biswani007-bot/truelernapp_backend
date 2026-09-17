import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../controllers/auth_controller.dart';
import '../controllers/auth_state.dart';

/// SCR-03: Login Screen — Node ID: 71:232 ("Student Login (Redesign)")
/// Exact Figma Dimensions: 390 × 966
///
/// Implements credential authentication against POST /api/auth/login.
/// Preserves verified API authentication while visually matching Figma Node 71:232.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  Timer? _demoTimer;
  String? _identifierError;
  String? _passwordError;

  @override
  void dispose() {
    _demoTimer?.cancel();
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _validateIdentifier() {
    final val = _identifierController.text.trim();
    if (val.isEmpty) {
      _identifierError = 'Please enter your email address.';
    } else {
      final isPhone = RegExp(r'^\+?[0-9]{7,15}$').hasMatch(val);
      final isEmail = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val);
      if (!isEmail && !isPhone) {
        _identifierError = 'Please enter a valid email address.';
      } else {
        _identifierError = null;
      }
    }
  }

  void _validatePassword() {
    final val = _passwordController.text.trim();
    if (val.isEmpty) {
      _passwordError = 'Please enter your password.';
    } else if (val.length < 6) {
      _passwordError = 'Password must be at least 6 characters.';
    } else {
      _passwordError = null;
    }
  }

  Future<void> _submitLogin() async {
    ref.read(authControllerProvider.notifier).resetError();

    setState(() {
      _validateIdentifier();
      _validatePassword();
    });

    if (_identifierError != null || _passwordError != null) {
      return;
    }

    FocusScope.of(context).unfocus();

    final success = await ref.read(authControllerProvider.notifier).login(
          email: _identifierController.text.trim(),
          password: _passwordController.text,
        );

    if (!mounted) return;

    if (success) {
      try {
        context.go(AppRoutePaths.parentDashboard);
      } catch (_) {
        // In isolated widget tests without GoRouter, state update suffices
      }
    }
  }

  void _onDemoSocialLogin() {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              'Sign in successful',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
    );

    _demoTimer?.cancel();
    _demoTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted) {
        try {
          context.go(AppRoutePaths.demoBookingDashboard);
        } catch (_) {}
      }
    });
  }

  void _onGoogleLoginTapped() {
    _onDemoSocialLogin();
  }

  void _onMicrosoftLoginTapped() {
    _onDemoSocialLogin();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isSubmitting = authState is AuthSubmitting;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Decorative abstract blob top-left (Node 71:233)
          Positioned(
            top: -22.0,
            left: -22.0,
            width: 256.0,
            height: 256.0,
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x4DB7C4FF), // rgba(183, 196, 255, 0.3)
              ),
            ),
          ),

          // 2. Decorative blur bottom-right (Node 71:234)
          Positioned(
            bottom: 15.0,
            right: 53.0,
            width: 300.0,
            height: 243.0,
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x66FFDF9F), // rgba(255, 223, 159, 0.4)
              ),
            ),
          ),

          // 3. Main Login Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 448.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Error Banner (if submission failed)
                      if (authState is AuthFailureState) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 16.0),
                          padding: const EdgeInsets.all(AppDimensions.space12),
                          decoration: BoxDecoration(
                            color: AppColors.errorBg,
                            borderRadius: AppDimensions.borderRadius12,
                            border: Border.all(color: AppColors.error),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: AppColors.errorDark,
                                size: 20.0,
                              ),
                              const SizedBox(width: AppDimensions.space8),
                              Expanded(
                                child: Text(
                                  authState.message,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.errorDark,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 16.0),
                                color: AppColors.errorDark,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  ref.read(authControllerProvider.notifier).resetError();
                                },
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Main Login Card (Node 71:238)
                      Container(
                        padding: const EdgeInsets.all(33.0),
                        decoration: BoxDecoration(
                          color: const Color(0xD9FFFFFF), // rgba(255, 255, 255, 0.85)
                          borderRadius: BorderRadius.circular(24.0),
                          border: Border.all(
                            color: const Color(0x4DFFFFFF), // rgba(255, 255, 255, 0.3)
                            width: 1.0,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color.fromRGBO(0, 0, 0, 0.05),
                              blurRadius: 6.0,
                              offset: Offset(0, 4),
                            ),
                            BoxShadow(
                              color: Color.fromRGBO(30, 78, 216, 0.08),
                              blurRadius: 15.0,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // TrueLern Logo (Node 71:241)
                              Image.asset(
                                'assets/images/truelern_logo.png',
                                width: 142.05,
                                height: 48.0,
                                fit: BoxFit.contain,
                              ),

                              const SizedBox(height: 24.0),

                              // Heading 1: "Welcome" (Node 71:244)
                              Text(
                                'Welcome',
                                style: AppTypography.displayMedium.copyWith(
                                  fontSize: 28.0,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.26,
                                  color: const Color(0xFF0F172A),
                                ),
                                textAlign: TextAlign.center,
                              ),

                              const SizedBox(height: 8.0),

                              // Subtitle (Node 71:246)
                              Text(
                                'Sign in to continue your learning\njourney.',
                                style: AppTypography.bodyMedium.copyWith(
                                  fontSize: 17.0,
                                  height: 1.5,
                                  color: const Color(0xFF434655),
                                ),
                                textAlign: TextAlign.center,
                              ),

                              const SizedBox(height: 24.0),

                              // Email Input Field (Node 71:248)
                              Container(
                                height: 54.0,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF7F9FC),
                                  borderRadius: BorderRadius.circular(8.0),
                                  border: Border.all(color: const Color(0xFFC4C5D7)),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color.fromRGBO(0, 0, 0, 0.05),
                                      blurRadius: 2.0,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    const SizedBox(width: 12.0),
                                    SvgPicture.asset(
                                      'assets/icons/whatsapp_icon.svg',
                                      width: 16.0,
                                      height: 16.0,
                                      colorFilter: const ColorFilter.mode(
                                        Color(0xFF747686),
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                    const SizedBox(width: 12.0),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _identifierController,
                                        keyboardType: TextInputType.emailAddress,
                                        style: AppTypography.bodyMedium.copyWith(
                                          color: const Color(0xFF0F172A),
                                          fontSize: 15.0,
                                        ),
                                        decoration: InputDecoration(
                                          isDense: true,
                                          contentPadding: EdgeInsets.zero,
                                          border: InputBorder.none,
                                          enabledBorder: InputBorder.none,
                                          focusedBorder: InputBorder.none,
                                          hintText: 'Email',
                                          hintStyle: AppTypography.bodyMedium.copyWith(
                                            color: const Color(0xFF747686),
                                            fontSize: 15.0,
                                          ),
                                        ),
                                        onChanged: (_) {
                                          if (_identifierError != null) {
                                            setState(() {
                                              _validateIdentifier();
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12.0),
                                  ],
                                ),
                              ),
                              if (_identifierError != null) ...[
                                const SizedBox(height: 6.0),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 4.0),
                                    child: Text(
                                      _identifierError!,
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.errorDark,
                                        fontSize: 13.0,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                ),
                              ],

                              const SizedBox(height: 16.0),

                              // Password Field (Collapsible or present for backend authentication)
                              Container(
                                height: 54.0,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF7F9FC),
                                  borderRadius: BorderRadius.circular(8.0),
                                  border: Border.all(color: const Color(0xFFC4C5D7)),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color.fromRGBO(0, 0, 0, 0.05),
                                      blurRadius: 2.0,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    const SizedBox(width: 12.0),
                                    const Icon(
                                      Icons.lock_outline,
                                      size: 16.0,
                                      color: Color(0xFF747686),
                                    ),
                                    const SizedBox(width: 12.0),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _passwordController,
                                        obscureText: !_isPasswordVisible,
                                        style: AppTypography.bodyMedium.copyWith(
                                          color: const Color(0xFF0F172A),
                                          fontSize: 15.0,
                                        ),
                                        decoration: InputDecoration(
                                          isDense: true,
                                          contentPadding: EdgeInsets.zero,
                                          border: InputBorder.none,
                                          enabledBorder: InputBorder.none,
                                          focusedBorder: InputBorder.none,
                                          hintText: 'Password',
                                          hintStyle: AppTypography.bodyMedium.copyWith(
                                            color: const Color(0xFF747686),
                                            fontSize: 15.0,
                                          ),
                                        ),
                                        onChanged: (_) {
                                          if (_passwordError != null) {
                                            setState(() {
                                              _validatePassword();
                                            });
                                          }
                                        },
                                        onFieldSubmitted: (_) => _submitLogin(),
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        _isPasswordVisible
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        size: 16.0,
                                        color: const Color(0xFF747686),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _isPasswordVisible = !_isPasswordVisible;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              if (_passwordError != null) ...[
                                const SizedBox(height: 6.0),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 4.0),
                                    child: Text(
                                      _passwordError!,
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.errorDark,
                                        fontSize: 13.0,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                ),
                              ],

                              const SizedBox(height: 16.0),

                              // Submit "Continue" CTA Button (Node 71:255)
                              SizedBox(
                                width: double.infinity,
                                height: 48.0,
                                child: ElevatedButton(
                                  onPressed: isSubmitting ? null : _submitLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    elevation: 1.0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                  ),
                                  child: isSubmitting
                                      ? const SizedBox(
                                          width: 20.0,
                                          height: 20.0,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.0,
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                          ),
                                        )
                                      : Text(
                                          'Continue',
                                          style: AppTypography.buttonText.copyWith(
                                            fontSize: 17.0,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),

                              const SizedBox(height: 24.0),

                              // Divider with "Or continue with" pill (Node 71:257)
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  const Divider(
                                    color: Color(0xFFE0E3E5),
                                    thickness: 1.0,
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 17.0,
                                      vertical: 2.0,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(9999.0),
                                      border: Border.all(
                                        color: const Color(0xFFE0E3E5),
                                      ),
                                    ),
                                    child: Text(
                                      'Or continue with',
                                      style: AppTypography.bodySmall.copyWith(
                                        fontSize: 13.0,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF747686),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20.0),

                              // Google Auth Button (Node 71:264)
                              InkWell(
                                onTap: _onGoogleLoginTapped,
                                borderRadius: BorderRadius.circular(12.0),
                                child: Container(
                                  width: double.infinity,
                                  height: 56.0,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12.0),
                                    border: Border.all(color: const Color(0xFFC4C5D7)),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color.fromRGBO(0, 0, 0, 0.05),
                                        blurRadius: 2.0,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        'assets/images/google_icon.png',
                                        width: 24.0,
                                        height: 24.0,
                                        fit: BoxFit.contain,
                                      ),
                                      const SizedBox(width: 12.0),
                                      Text(
                                        'Sign in with Google',
                                        style: AppTypography.titleSmall.copyWith(
                                          color: const Color(0xFF191C1E),
                                          fontSize: 15.0,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.28,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 12.0),

                              // Microsoft Auth Button
                              InkWell(
                                onTap: _onMicrosoftLoginTapped,
                                borderRadius: BorderRadius.circular(12.0),
                                child: Container(
                                  width: double.infinity,
                                  height: 56.0,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12.0),
                                    border: Border.all(color: const Color(0xFFC4C5D7)),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color.fromRGBO(0, 0, 0, 0.05),
                                        blurRadius: 2.0,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SvgPicture.asset(
                                        'assets/icons/microsoft_icon.svg',
                                        width: 20.0,
                                        height: 20.0,
                                      ),
                                      const SizedBox(width: 12.0),
                                      Text(
                                        'Sign in with Microsoft',
                                        style: AppTypography.titleSmall.copyWith(
                                          color: const Color(0xFF191C1E),
                                          fontSize: 15.0,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.28,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
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
        ],
      ),
    );
  }
}
