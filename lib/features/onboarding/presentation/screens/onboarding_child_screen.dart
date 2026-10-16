import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/controllers/auth_state.dart';
import '../../../dashboard/data/models/add_child_request_dto.dart';
import '../../../dashboard/data/repositories/dashboard_repository_impl.dart';
import '../../../dashboard/presentation/controllers/children_controller.dart';
import '../controllers/onboarding_controller.dart';

/// Screen C / Step 1: Child Details (Web Onboarding Card Reference & Figma Node 47:1045)
/// STEP 1 OF 4 in Parent(full app)_TreLern onboarding flow.
///
/// Matches Web Google Sign-In onboarding reference:
/// - Green/teal icon near the top
/// - Heading: Welcome to TrueLern
/// - Subtitle: Add your child's details to set up their learning profile.
/// - First Name field
/// - Last Name field
/// - Child's Age selector (as required by the lead API contract)
/// - Full-width blue Continue button
class OnboardingChildScreen extends ConsumerStatefulWidget {
  const OnboardingChildScreen({super.key});

  @override
  ConsumerState<OnboardingChildScreen> createState() =>
      _OnboardingChildScreenState();
}

class _OnboardingChildScreenState extends ConsumerState<OnboardingChildScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  int? _selectedAge;
  String? _error;
  bool _isSubmitting = false;

  static const List<int> _kAvailableAges = [
    4,
    5,
    6,
    7,
    8,
    9,
    10,
    11,
    12,
    13,
    14,
    15,
    16,
    17,
    18,
  ];

  @override
  void initState() {
    super.initState();
    final current = ref.read(onboardingControllerProvider);
    if (current.childFirstName.isNotEmpty || current.childLastName.isNotEmpty) {
      _firstNameController.text = current.childFirstName;
      _lastNameController.text = current.childLastName;
    } else if (current.childName.isNotEmpty) {
      final parts = current.childName.trim().split(RegExp(r'\s+'));
      _firstNameController.text = parts.first;
      if (parts.length > 1) {
        _lastNameController.text = parts.sublist(1).join(' ');
      }
    }
    _selectedAge = current.childAge ?? 8;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _onContinue() async {
    if (_isSubmitting) return;

    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();

    if (firstName.isEmpty) {
      setState(() => _error = "Please enter your child's first name.");
      return;
    }

    if (firstName.length < 2) {
      setState(() => _error = "First name must be at least 2 characters.");
      return;
    }

    if (lastName.isEmpty) {
      setState(() => _error = "Please enter your child's last name.");
      return;
    }

    if (_selectedAge == null) {
      setState(() => _error = "Please select your child's age.");
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    final now = DateTime.now();
    final birthYear = now.year - _selectedAge!;
    final dobStr = '$birthYear-06-15';
    final authState = ref.read(authControllerProvider);

    if (authState is Authenticated) {
      try {
        final req = AddChildRequestDto(
          firstName: firstName,
          lastName: lastName,
          gender: 'male',
          relationshipType: 'guardian',
          dateOfBirth: dobStr,
        );

        final createdChild = await ref
            .read(addChildRepositoryProvider)
            .addChild(req);

        await ref
            .read(childrenControllerProvider.notifier)
            .loadChildren(isRefresh: true);
        ref
            .read(childrenControllerProvider.notifier)
            .setActiveChild(createdChild.studentId);

        ref
            .read(onboardingControllerProvider.notifier)
            .updateChildDetails(
              childFirstName: firstName,
              childLastName: lastName,
              childName: '${createdChild.firstName} ${createdChild.lastName}'
                  .trim(),
              childAge: _selectedAge!,
            );

        if (!mounted) return;

        if (context.canPop()) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${createdChild.displayName} has been added successfully!',
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.pop(createdChild);
        } else {
          context.push(AppRoutePaths.onboardingInterests);
        }
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isSubmitting = false;
          _error = e
              .toString()
              .replaceFirst(RegExp(r'^.*\(message: '), '')
              .replaceFirst(RegExp(r',.*$'), '')
              .replaceFirst(RegExp(r'^Exception:\s*'), '');
        });
      }
    } else {
      ref
          .read(onboardingControllerProvider.notifier)
          .updateChildDetails(
            childFirstName: firstName,
            childLastName: lastName,
            childName: '$firstName $lastName'.trim(),
            childAge: _selectedAge!,
          );

      if (!mounted) return;
      if (context.canPop()) {
        context.pop();
      } else {
        context.push(AppRoutePaths.onboardingInterests);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF0F5FF), Color(0xFFFAFAFC)],
          ),
        ),
        child: Stack(
          children: [
            // Background decorative gradient blob (Node 382:694)
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
                          // Back Navigation & Top Logo
                          Row(
                            children: [
                              InkWell(
                                onTap: () {
                                  if (context.canPop()) {
                                    context.pop();
                                  } else {
                                    context.go(AppRoutePaths.login);
                                  }
                                },
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

                          const SizedBox(height: 24.0),

                          // Green/teal icon near top matching web screenshot
                          Center(
                            child: Container(
                              width: 60.0,
                              height: 60.0,
                              decoration: BoxDecoration(
                                color: const Color(0xFFCCFBF1), // soft teal
                                borderRadius: BorderRadius.circular(18.0),
                                border: Border.all(
                                  color: const Color(0xFF99F6E4),
                                  width: 1.5,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color.fromRGBO(13, 148, 136, 0.12),
                                    blurRadius: 16.0,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.school_rounded,
                                  color: Color(0xFF0D9488),
                                  size: 30.0,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 18.0),

                          // Heading: Welcome to TrueLern
                          Center(
                            child: Text(
                              'Welcome to TrueLern',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 24.0,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF191C1E),
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),

                          const SizedBox(height: 8.0),

                          // Subtitle: Add your child's details to set up their learning profile.
                          Center(
                            child: Text(
                              "Add your child's details to set up their learning profile.",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 14.0,
                                height: 1.45,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ),

                          if (_error != null) ...[
                            const SizedBox(height: 14.0),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10.0),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(8.0),
                                border: Border.all(
                                  color: const Color(0xFFFCA5A5),
                                ),
                              ),
                              child: Text(
                                _error!,
                                style: GoogleFonts.hankenGrotesk(
                                  color: const Color(0xFFDC2626),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 24.0),

                          // First Name Label
                          Text(
                            "First Name *",
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 14.0,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF334155),
                            ),
                          ),
                          const SizedBox(height: 8.0),

                          // First Name Input
                          TextFormField(
                            controller: _firstNameController,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              hintText: 'e.g. Alex',
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

                          const SizedBox(height: 18.0),

                          // Last Name Label
                          Text(
                            "Last Name *",
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 14.0,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF334155),
                            ),
                          ),
                          const SizedBox(height: 8.0),

                          // Last Name Input
                          TextFormField(
                            controller: _lastNameController,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              hintText: 'e.g. Jenkins',
                              hintStyle: GoogleFonts.hankenGrotesk(
                                color: const Color(0xFF94A3B8),
                                fontSize: 14.0,
                              ),
                              prefixIcon: const Icon(
                                Icons.badge_outlined,
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

                          const SizedBox(height: 18.0),

                          // Child's Age Label (Required by Lead API Contract)
                          Text(
                            "Child's Age *",
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 14.0,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF334155),
                            ),
                          ),
                          const SizedBox(height: 8.0),

                          // Child's Age Dropdown
                          DropdownButtonFormField<int>(
                            initialValue: _selectedAge,
                            isExpanded: true,
                            decoration: InputDecoration(
                              hintText: 'Select age',
                              hintStyle: GoogleFonts.hankenGrotesk(
                                color: const Color(0xFF94A3B8),
                                fontSize: 14.0,
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
                            icon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Color(0xFF64748B),
                            ),
                            items: _kAvailableAges.map((age) {
                              return DropdownMenuItem<int>(
                                value: age,
                                child: Text(
                                  '$age years old',
                                  style: GoogleFonts.hankenGrotesk(
                                    fontSize: 14.0,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedAge = val;
                                _error = null;
                              });
                            },
                          ),

                          const SizedBox(height: 28.0),

                          // STEP 1 OF 4 indicator
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
                              'STEP 1 OF 4',
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 11.0,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16.0),

                          // Continue Button
                          SizedBox(
                            width: double.infinity,
                            height: 50.0,
                            child: ElevatedButton(
                              onPressed: _isSubmitting ? null : _onContinue,
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
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
      ),
    );
  }
}
