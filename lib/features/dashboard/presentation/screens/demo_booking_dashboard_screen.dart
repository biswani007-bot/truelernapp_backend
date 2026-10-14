import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/demo_booking_confirmation_popup.dart';
import '../widgets/parent_hamburger_drawer.dart';

/// Screen recreating Demo Booking Dashboard (Node 72:477 in Figma).
/// Displays upcoming free demo slots and benefits with exact Figma styles.
class DemoBookingDashboardScreen extends StatefulWidget {
  const DemoBookingDashboardScreen({super.key});

  @override
  State<DemoBookingDashboardScreen> createState() =>
      _DemoBookingDashboardScreenState();
}

class _DemoBookingDashboardScreenState
    extends State<DemoBookingDashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const ParentHamburgerDrawer(activeItem: ''),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF0E6FF), // rgb(240, 230, 255)
              Color(0xFFE6F0FF), // rgb(230, 240, 255)
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Header - TopAppBar (Node 72:501)
              _buildTopAppBar(context),

              // Main Scrollable Area (Node 72:511)
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 768.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Section - Hero Card (Node 72:512)
                          _buildHeroCard(),

                          const SizedBox(height: 24.0),

                          // Slots Section (Node 72:522)
                          _buildSlotsSection(context),

                          const SizedBox(height: 24.0),

                          // Benefits Section (Node 72:578)
                          _buildBenefitsSection(),

                          const SizedBox(height: 16.0),

                          // Footer Note (Node 72:597)
                          _buildFooterNote(),

                          const SizedBox(height: 56.0),
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

  Widget _buildTopAppBar(BuildContext context) {
    return Container(
      height: 56.0,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left menu button (Node 72:502)
          InkWell(
            key: const Key('demo_dashboard_hamburger_button'),
            onTap: () {
              _scaffoldKey.currentState?.openDrawer();
            },
            borderRadius: BorderRadius.circular(9999.0),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SvgPicture.asset(
                'assets/icons/demo_menu.svg',
                width: 18.0,
                height: 12.0,
              ),
            ),
          ),

          // Heading 1 - "Dashboard" (Node 72:505)
          Text(
            'Dashboard',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 25.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF191C1E),
              height: 32 / 24,
            ),
          ),

          // Right notification button (Node 72:507)
          InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(9999.0),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  SvgPicture.asset(
                    'assets/icons/demo_bell.svg',
                    width: 16.0,
                    height: 20.0,
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8.0,
                      height: 8.0,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
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

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 2.0,
            offset: Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Image with FREE DEMO badge (Node 72:513)
          SizedBox(
            height: 192.0,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/demo_hero.png',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 192.0,
                ),
                Positioned(
                  left: 16.0,
                  top: 16.0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 4.0,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B),
                      borderRadius: BorderRadius.circular(9999.0),
                    ),
                    child: Text(
                      'FREE DEMO',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.55,
                        color: const Color(0xFF191C1E),
                        height: 16 / 11,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Title and subtitle container (Node 72:517)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ACE Public Speaking Program',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 21.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                    height: 28 / 20,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  'Free Demo • Age 5-8 Years',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 15.0,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF475569),
                    height: 20 / 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Heading & Child Selector Row (Node 72:523)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Next Available Slots',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 21.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF191C1E),
                height: 28 / 20,
              ),
            ),
            // Child Selector (Node 72:526)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 17.0,
                vertical: 9.0,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(9999.0),
                border: Border.all(
                  color: const Color.fromRGBO(196, 197, 215, 0.3),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.05),
                    blurRadius: 1.0,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 24.0,
                    height: 24.0,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F4F7),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF747686)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'TC',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: const Color(0xFF0037B1),
                        height: 16 / 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Text(
                    'Pps son',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 13.0,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                      color: const Color(0xFF191C1E),
                      height: 16 / 12,
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  SvgPicture.asset(
                    'assets/icons/demo_chevron_down.svg',
                    width: 9.0,
                    height: 5.55,
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16.0),

        // Slot Card 1 (Node 72:536)
        _buildSlotCard(
          dayLabel: 'TODAY',
          timeValue: '10:00',
          period: 'PM',
          onBookTap: () {
            showDemoBookingConfirmationPopup(
              context,
              selectedDemo: 'ACE Public Speaking',
              dateTime: 'Today at 8:00 PM',
              teacher: 'Ms. Sarah',
            );
          },
        ),

        const SizedBox(height: 16.0),

        // Slot Card 2 (Node 72:551)
        _buildSlotCard(
          dayLabel: 'TOMORROW',
          timeValue: '7:00',
          period: 'PM',
          onBookTap: () {
            showDemoBookingConfirmationPopup(
              context,
              selectedDemo: 'ACE Public Speaking',
              dateTime: 'Tomorrow at 7:00 PM',
              teacher: 'Ms. Sarah',
            );
          },
        ),

        const SizedBox(height: 16.0),

        // "Can't find a suitable slot?" (Node 72:566)
        Text(
          "Can't find a suitable slot?",
          style: GoogleFonts.hankenGrotesk(
            fontSize: 15.0,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF475569),
            height: 20 / 14,
          ),
        ),

        const SizedBox(height: 8.0),

        // Button - Custom Date Card (Node 72:568)
        InkWell(
          onTap: () {
            showDemoBookingConfirmationPopup(
              context,
              selectedDemo: 'ACE Public Speaking',
              dateTime: 'Today at 8:00 PM',
              teacher: 'Ms. Sarah',
            );
          },
          borderRadius: BorderRadius.circular(12.0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(17.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                color: const Color.fromRGBO(196, 197, 215, 0.1),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.05),
                  blurRadius: 1.0,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40.0,
                      height: 40.0,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F4F7),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      alignment: Alignment.center,
                      child: SvgPicture.asset(
                        'assets/icons/demo_calendar.svg',
                        width: 18.0,
                        height: 20.0,
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    Text(
                      'Choose Preferred Date & Time',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 17.0,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF191C1E),
                        height: 24 / 16,
                      ),
                    ),
                  ],
                ),
                SvgPicture.asset(
                  'assets/icons/demo_chevron_right.svg',
                  width: 7.4,
                  height: 12.0,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSlotCard({
    required String dayLabel,
    required String timeValue,
    required String period,
    VoidCallback? onBookTap,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: const Color.fromRGBO(196, 197, 215, 0.1)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 1.0,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day label (e.g. TODAY / TOMORROW)
          Text(
            dayLabel,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.55,
              color: const Color(0xFF0037B1),
              height: 16 / 11,
            ),
          ),

          const SizedBox(height: 8.0),

          // Time value + PM
          SizedBox(
            height: 56.0,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  timeValue,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 48.0,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.96,
                    color: const Color(0xFF191C1E),
                    height: 56 / 48,
                  ),
                ),
                const SizedBox(width: 4.0),
                Text(
                  period,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 17.0,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF434655),
                    height: 24 / 16,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8.0),

          // CTA: Book this demo
          InkWell(
            key: Key('book_demo_button_${dayLabel.toLowerCase()}'),
            onTap: onBookTap,
            borderRadius: BorderRadius.circular(8.0),
            child: Container(
              width: double.infinity,
              height: 44.0,
              decoration: BoxDecoration(
                color: const Color(0xFF1E4ED8),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Book this demo',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 15.0,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.1,
                      color: const Color(0xFFCAD3FF),
                      height: 20 / 14,
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  SvgPicture.asset(
                    'assets/icons/demo_arrow_right.svg',
                    width: 13.33,
                    height: 13.33,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsSection() {
    return Column(
      children: [
        // 1. Free live demo (Node 72:579)
        _buildBenefitCard(
          bgColor: const Color(0x336CF8BB), // rgba(108, 248, 187, 0.2)
          borderColor: const Color(0x4D6CF8BB), // rgba(108, 248, 187, 0.3)
          circleBgColor: const Color(0x666CF8BB), // rgba(108, 248, 187, 0.4)
          iconAsset: 'assets/icons/demo_video.svg',
          iconWidth: 20.0,
          iconHeight: 16.0,
          title: 'Free live demo',
        ),

        const SizedBox(height: 8.0),

        // 2. Expert faculty (Node 72:585)
        _buildBenefitCard(
          bgColor: const Color(0x1AF59E0B), // rgba(245, 158, 11, 0.1)
          borderColor: const Color(0x33F59E0B), // rgba(245, 158, 11, 0.2)
          circleBgColor: const Color(0x33F59E0B), // rgba(245, 158, 11, 0.2)
          iconAsset: 'assets/icons/demo_graduation.svg',
          iconWidth: 22.0,
          iconHeight: 18.0,
          title: 'Expert faculty',
        ),

        const SizedBox(height: 8.0),

        // 3. 45-minute session (Node 72:591)
        _buildBenefitCard(
          bgColor: const Color(0x0D0037B1), // rgba(0, 55, 177, 0.05)
          borderColor: const Color(0x1A0037B1), // rgba(0, 55, 177, 0.1)
          circleBgColor: const Color(0x1A0037B1), // rgba(0, 55, 177, 0.1)
          iconAsset: 'assets/icons/demo_clock.svg',
          iconWidth: 20.0,
          iconHeight: 20.0,
          title: '45-minute session',
        ),
      ],
    );
  }

  Widget _buildBenefitCard({
    required Color bgColor,
    required Color borderColor,
    required Color circleBgColor,
    required String iconAsset,
    required double iconWidth,
    required double iconHeight,
    required String title,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 40.0,
            height: 40.0,
            decoration: BoxDecoration(
              color: circleBgColor,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: SvgPicture.asset(
              iconAsset,
              width: iconWidth,
              height: iconHeight,
            ),
          ),
          const SizedBox(width: 16.0),
          Text(
            title,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 17.0,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF191C1E),
              height: 24 / 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterNote() {
    return Center(
      child: Text(
        'FREE DEMO • 45 MINS • EXPERT INSTRUCTOR\n• NO COMMITMENT',
        textAlign: TextAlign.center,
        style: GoogleFonts.hankenGrotesk(
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.1,
          color: const Color(0xFF475569),
          height: 22 / 11,
        ),
      ),
    );
  }
}
