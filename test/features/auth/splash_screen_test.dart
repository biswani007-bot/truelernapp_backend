import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:truelearn/features/auth/presentation/screens/splash_screen.dart';

void main() {
  testWidgets('SplashScreen renders Figma SCR-01 elements accurately', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const Scaffold(body: Text('Onboarding')),
        ),
        GoRoute(
          path: '/parent',
          builder: (context, state) =>
              const Scaffold(body: Text('Parent Dashboard')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );

    // Verify version text
    expect(find.text('v1.0.0'), findsOneWidget);

    // Verify main TrueLern logo
    expect(find.byType(Image), findsOneWidget);

    // Verify 7 ghosted floating background SVG icons
    expect(find.byType(SvgPicture), findsNWidgets(7));

    // Verify NO invented progress indicators
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    // Fast-forward bootstrap delay
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pumpAndSettle();

    // Verify navigated to onboarding
    expect(find.text('Onboarding'), findsOneWidget);
  });
}
