import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

/// Upcoming Competitions card banner corresponding to Figma Node 76:2048.
class CompetitionsBanner extends StatelessWidget {
  final VoidCallback? onRegisterTap;

  const CompetitionsBanner({super.key, this.onRegisterTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title: "Upcoming Competitions" (Node 76:2047)
        Text(
          'Upcoming Competitions',
          style: GoogleFonts.hankenGrotesk(
            fontSize: 21.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A1B23),
            height: 28 / 20,
          ),
        ),
        const SizedBox(height: 16),

        // Deep blue card container (Node 76:2048)
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF0037B1),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000), // rgba(0, 0, 0, 0.1)
                blurRadius: 15,
                offset: Offset(0, 10),
                spreadRadius: -3,
              ),
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 6,
                offset: Offset(0, 4),
                spreadRadius: -4,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Background Trophy watermark (Node 76:2049)
              Positioned(
                bottom: -16,
                right: -16,
                child: Opacity(
                  opacity: 0.35,
                  child: SvgPicture.asset(
                    'assets/icons/trophy_watermark_blue.svg',
                    width: 90,
                    height: 97,
                  ),
                ),
              ),

              // Content Row
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Left Text Column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // TrueLern Logo Icon + COMPETITION tag (Node 76:2052)
                          Row(
                            children: [
                              Image.asset(
                                'assets/images/competition_truelern_logo.png',
                                width: 28,
                                height: 28,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'COMPETITION',
                                  style: GoogleFonts.hankenGrotesk(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withValues(alpha: 0.9),
                                    letterSpacing: 0.8,
                                    height: 16 / 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Heading: TrueLern Grandmaster Quiz (Node 76:2057)
                          Text(
                            'TrueLern\nGrandmaster Quiz',
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 21.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              height: 28 / 20,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Description (Node 76:2059)
                          Text(
                            'Starts in 2 days • Win\nexclusive badges!',
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withValues(alpha: 0.8),
                              height: 20 / 14,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Right CTA: Register Now (Node 76:2061)
                    Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(9999),
                      child: InkWell(
                        key: const Key('register_now_button'),
                        borderRadius: BorderRadius.circular(9999),
                        onTap: onRegisterTap,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          child: Text(
                            'Register Now',
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF0037B1),
                              letterSpacing: 0.1,
                              height: 20 / 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
