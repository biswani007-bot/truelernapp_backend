import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_refresh_indicator.dart';
import '../../domain/entities/user_device_entity.dart';
import '../controllers/user_devices_controller.dart';
import '../controllers/user_devices_state.dart';
import '../widgets/parent_hamburger_drawer.dart';

/// Parent Login & Devices Screen.
///
/// Backed by real API endpoints:
/// - `GET /api/auth/devices` (lists active authenticated sessions)
/// - `DELETE /api/auth/devices?sessionId=:id` (revokes specified session)
class ParentLoginDevicesScreen extends ConsumerStatefulWidget {
  const ParentLoginDevicesScreen({super.key});

  @override
  ConsumerState<ParentLoginDevicesScreen> createState() =>
      _ParentLoginDevicesScreenState();
}

class _ParentLoginDevicesScreenState
    extends ConsumerState<ParentLoginDevicesScreen> {
  static const _svgBackArrow = 'assets/icons/device_back_arrow.svg';
  static const _svgPhoneCurrent = 'assets/icons/device_phone_current.svg';
  static const _svgPhoneOther = 'assets/icons/device_phone_other.svg';
  static const _svgLaptop = 'assets/icons/device_laptop.svg';
  static const _svgSignOut = 'assets/icons/device_sign_out.svg';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userDevicesControllerProvider.notifier).loadDevices();
    });
  }

  void _confirmRevoke(BuildContext context, UserDeviceEntity device) {
    showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Sign Out Device?',
            style: GoogleFonts.hankenGrotesk(
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          content: Text(
            device.isCurrent
                ? 'This is your current device. Signing out will terminate your current session and log you out.'
                : 'Are you sure you want to sign out "${device.displayName}"? The session will be revoked immediately.',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 14,
              color: const Color(0xFF434655),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: Text(
                'Cancel',
                style: GoogleFonts.hankenGrotesk(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFBA1A1A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              child: Text(
                'Sign Out',
                style: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    ).then((confirmed) {
      if (confirmed == true && mounted) {
        ref
            .read(userDevicesControllerProvider.notifier)
            .revokeDevice(device.sessionId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userDevicesControllerProvider);

    ref.listen<UserDevicesState>(userDevicesControllerProvider, (prev, next) {
      if (next is UserDevicesLoaded && next.feedbackMessage != null) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              next.feedbackMessage!,
              style: GoogleFonts.hankenGrotesk(fontSize: 13),
            ),
            backgroundColor: next.isError
                ? AppColors.error
                : const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
        ref.read(userDevicesControllerProvider.notifier).clearFeedback();
      }
    });

    return Scaffold(
      key: const Key('parent_login_devices_screen'),
      drawer: const ParentHamburgerDrawer(),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF3E8FF), Color(0xFFE0F2FE), Color(0xFFFFFFFF)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopHeader(context),
              Expanded(
                child: AppRefreshIndicator(
                  onRefresh: () async {
                    await ref
                        .read(userDevicesControllerProvider.notifier)
                        .loadDevices(forceRefresh: true);
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 448),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            _buildPageTitleSection(),
                            const SizedBox(height: 24),
                            _buildBody(context, state),
                            const SizedBox(height: 48),
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

  Widget _buildTopHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xCCFFFFFF),
        boxShadow: [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          InkWell(
            key: const Key('btn_back_login_devices'),
            borderRadius: BorderRadius.circular(9999),
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutePaths.parentSecurityPrivacy);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              child: SvgPicture.asset(_svgBackArrow, width: 16, height: 16),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                'TrueLern',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 25.5,
                  fontWeight: FontWeight.w700,
                  height: 32 / 24,
                  color: const Color(0xFF191C1E),
                ),
              ),
            ),
          ),
          const SizedBox(width: 32),
        ],
      ),
    );
  }

  Widget _buildPageTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Center(
          child: Text(
            'Login & Devices',
            textAlign: TextAlign.center,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 17,
              fontWeight: FontWeight.w500,
              height: 24 / 16,
              color: const Color(0xFF1A1B23),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Manage the devices that are currently logged into\nyour account.',
            textAlign: TextAlign.center,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 15,
              fontWeight: FontWeight.normal,
              height: 22 / 15,
              color: const Color(0xFF434655),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, UserDevicesState state) {
    if (state is UserDevicesLoading || state is UserDevicesInitial) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (state is UserDevicesError) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFCA5A5)),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              'Failed to load devices',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1B23),
              ),
            ),
            const SizedBox(height: 6),
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
                    .read(userDevicesControllerProvider.notifier)
                    .loadDevices(forceRefresh: true);
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
      );
    }

    if (state is UserDevicesLoaded) {
      if (state.devices.isEmpty) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E1ED)),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.devices_other_rounded,
                size: 48,
                color: Color(0xFF94A3B8),
              ),
              const SizedBox(height: 16),
              Text(
                'No Active Sessions Found',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1B23),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Your account has no other active devices registered.',
                textAlign: TextAlign.center,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 13,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        );
      }

      final current = state.currentDevice;
      final others = state.otherDevices;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (current != null) ...[
            _buildSectionHeader('CURRENT DEVICE'),
            const SizedBox(height: 12),
            _buildCurrentDeviceCard(current),
            const SizedBox(height: 24),
          ],
          _buildSectionHeader('OTHER ACTIVE DEVICES'),
          const SizedBox(height: 12),
          if (others.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E1ED)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    color: Color(0xFF10B981),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No other devices are currently signed into your account.',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 14,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ...others.map(
              (device) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildOtherDeviceCard(
                  context: context,
                  device: device,
                  isRevoking: state.revokingSessionId == device.sessionId,
                ),
              ),
            ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Text(
        title,
        style: GoogleFonts.hankenGrotesk(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: const Color(0xFF747686),
        ),
      ),
    );
  }

  Widget _buildCurrentDeviceCard(UserDeviceEntity device) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E1ED), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildNeumorphicBox(
            iconWidget: SvgPicture.asset(
              _svgPhoneCurrent,
              width: 18,
              height: 26,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${device.displayName} ',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1B23),
                        ),
                      ),
                      TextSpan(
                        text: '(This device)',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Active Now',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtherDeviceCard({
    required BuildContext context,
    required UserDeviceEntity device,
    required bool isRevoking,
  }) {
    final isDesktop =
        device.platform?.toLowerCase().contains('mac') == true ||
        device.platform?.toLowerCase().contains('windows') == true ||
        device.platform?.toLowerCase().contains('linux') == true ||
        device.platform?.toLowerCase().contains('web') == true;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E1ED), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildNeumorphicBox(
            iconWidget: SvgPicture.asset(
              isDesktop ? _svgLaptop : _svgPhoneOther,
              width: 18,
              height: 26,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.displayName,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1B23),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  device.lastActiveFormatted,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.normal,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          if (isRevoking)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFFBA1A1A),
              ),
            )
          else
            InkWell(
              key: Key('revoke_device_${device.sessionId}'),
              borderRadius: BorderRadius.circular(8),
              onTap: () => _confirmRevoke(context, device),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: SvgPicture.asset(
                  _svgSignOut,
                  width: 20,
                  height: 20,
                  fit: BoxFit.contain,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFFBA1A1A),
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNeumorphicBox({required Widget iconWidget}) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          begin: Alignment(-0.82, -0.57),
          end: Alignment(0.82, 0.57),
          colors: [Color(0xFFFFFFFF), Color(0xFFE6E6E6)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFFD1D1D1),
            offset: Offset(3, 3),
            blurRadius: 6,
          ),
          BoxShadow(color: Colors.white, offset: Offset(-3, -3), blurRadius: 6),
        ],
      ),
      alignment: Alignment.center,
      child: iconWidget,
    );
  }
}
