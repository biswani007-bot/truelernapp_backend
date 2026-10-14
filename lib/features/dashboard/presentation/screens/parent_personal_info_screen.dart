import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../controllers/parent_profile_controller.dart';
import '../controllers/parent_profile_state.dart';
import '../widgets/security_privacy_sub_app_bar.dart';
import '../../../../core/widgets/app_refresh_indicator.dart';

/// Screen 2 — Personal Information.
///
/// Features:
/// - Real backend integration with `GET /api/parent/profile` and `PATCH /api/parent/profile`
/// - Top avatar & summary card
/// - Detailed information rows (Full Name, Email, Phone, WhatsApp, Role/Designation, Address, ID)
/// - "Update Information" action with real PATCH API persistence
class ParentPersonalInfoScreen extends ConsumerStatefulWidget {
  const ParentPersonalInfoScreen({super.key});

  @override
  ConsumerState<ParentPersonalInfoScreen> createState() =>
      _ParentPersonalInfoScreenState();
}

class _ParentPersonalInfoScreenState
    extends ConsumerState<ParentPersonalInfoScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(parentProfileControllerProvider.notifier).loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(parentProfileControllerProvider);

    ref.listen<ParentProfileState>(parentProfileControllerProvider, (
      prev,
      next,
    ) {
      if (next is ParentProfileLoaded) {
        if (next.updateSuccessMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.updateSuccessMessage!),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
          ref.read(parentProfileControllerProvider.notifier).clearMessages();
        } else if (next.updateErrorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.updateErrorMessage!),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
          ref.read(parentProfileControllerProvider.notifier).clearMessages();
        }
      }
    });

    return Scaffold(
      key: const Key('parent_personal_info_screen'),
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
              const SecurityPrivacySubAppBar(title: 'Personal Information'),
              Expanded(child: _buildBody(state)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(ParentProfileState state) {
    if (state is ParentProfileLoading || state is ParentProfileInitial) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state is ParentProfileError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AppColors.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load personal information',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                state.message,
                textAlign: TextAlign.center,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 13,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  ref
                      .read(parentProfileControllerProvider.notifier)
                      .loadProfile(refresh: true);
                },
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (state is ParentProfileLoaded) {
      final profile = state.profile;
      return AppRefreshIndicator(
        onRefresh: () async {
          await ref
              .read(parentProfileControllerProvider.notifier)
              .loadProfile(refresh: true);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Manage your personal information.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: const Color(0xFF64748B),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Top Profile Header Card
                  _buildProfileCard(profile.fullName, profile.email),
                  const SizedBox(height: 24),

                  // Information Rows Card
                  Container(
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
                      children: [
                        _buildInfoRow(
                          icon: Icons.person_outline_rounded,
                          label: 'Full Name',
                          value: profile.fullName,
                          showDivider: true,
                          onTap: () => _openEditModal(
                            context,
                            profile.firstName,
                            profile.lastName,
                            profile.phone,
                            profile.address,
                          ),
                        ),
                        _buildInfoRow(
                          icon: Icons.mail_outline_rounded,
                          label: 'Email Address',
                          value: profile.email,
                          showDivider: true,
                          // Email is account identifier, not modifiable directly
                          showChevron: false,
                        ),
                        _buildInfoRow(
                          icon: Icons.phone_outlined,
                          label: 'Phone Number',
                          value: profile.phone.isNotEmpty
                              ? profile.phone
                              : 'Not provided',
                          showDivider: true,
                          onTap: () => _openEditModal(
                            context,
                            profile.firstName,
                            profile.lastName,
                            profile.phone,
                            profile.address,
                          ),
                        ),
                        _buildInfoRow(
                          icon: Icons.chat_bubble_outline_rounded,
                          label: 'WhatsApp Number',
                          value: profile.phone.isNotEmpty
                              ? profile.phone
                              : 'Not provided',
                          showDivider: true,
                          onTap: () => _openEditModal(
                            context,
                            profile.firstName,
                            profile.lastName,
                            profile.phone,
                            profile.address,
                          ),
                        ),
                        _buildInfoRow(
                          icon: Icons.badge_outlined,
                          label: 'Parent ID',
                          value: profile.parentId.isNotEmpty
                              ? profile.parentId
                              : profile.id,
                          showDivider: true,
                          showChevron: false,
                        ),
                        _buildInfoRow(
                          icon: Icons.work_outline_rounded,
                          label: 'Occupation',
                          value: profile.occupation.isNotEmpty
                              ? profile.occupation
                              : 'Not specified',
                          showDivider: true,
                          showChevron: false,
                        ),
                        _buildInfoRow(
                          icon: Icons.location_on_outlined,
                          label: 'Address',
                          value: profile.fullAddress,
                          showDivider: false,
                          onTap: () => _openEditModal(
                            context,
                            profile.firstName,
                            profile.lastName,
                            profile.phone,
                            profile.address,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Update Information Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: state.isUpdating
                          ? null
                          : () => _openEditModal(
                              context,
                              profile.firstName,
                              profile.lastName,
                              profile.phone,
                              profile.address,
                            ),
                      icon: state.isUpdating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.edit_outlined, size: 20),
                      label: Text(
                        'Update Information',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildProfileCard(String name, String email) {
    final initials = name
        .trim()
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFFE0E7FF),
            child: Text(
              initials.isNotEmpty ? initials : 'P',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  email,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool showDivider,
    VoidCallback? onTap,
    bool showChevron = true,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: const Color(0xFF475569)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F172A),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (showChevron) ...[
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: Color(0xFF94A3B8),
                  ),
                ],
              ],
            ),
          ),
          if (showDivider)
            const Divider(
              height: 1,
              thickness: 1,
              color: Color(0xFFF1F5F9),
              indent: 66,
            ),
        ],
      ),
    );
  }

  void _openEditModal(
    BuildContext context,
    String initialFirst,
    String initialLast,
    String initialPhone,
    String initialAddress,
  ) {
    final firstCtrl = TextEditingController(text: initialFirst);
    final lastCtrl = TextEditingController(text: initialLast);
    final phoneCtrl = TextEditingController(text: initialPhone);
    final addrCtrl = TextEditingController(text: initialAddress);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Edit Personal Information',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: const Icon(Icons.close_rounded, size: 22),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: firstCtrl,
                decoration: InputDecoration(
                  labelText: 'First Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: lastCtrl,
                decoration: InputDecoration(
                  labelText: 'Last Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addrCtrl,
                decoration: InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    await ref
                        .read(parentProfileControllerProvider.notifier)
                        .updateProfile(
                          firstName: firstCtrl.text.trim(),
                          lastName: lastCtrl.text.trim(),
                          phone: phoneCtrl.text.trim(),
                          address: addrCtrl.text.trim(),
                        );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Save Changes'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
