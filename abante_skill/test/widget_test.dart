import 'package:abante_skill/main.dart';
import 'package:abante_skill/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUpAll(() {
    // Tests run offline; fall back to the default font instead of fetching.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('Splash shows the brand and both entry buttons', (tester) async {
    await tester.pumpWidget(const MyApp(home: SplashScreen()));
    await tester.pump();

    expect(find.text('Abante'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.text('I Already Have an Account'), findsOneWidget);
  });

  testWidgets('Get Started opens the onboarding questionnaire', (tester) async {
    // A phone-sized screen, like the layout is designed for.
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MyApp(home: SplashScreen()));
    await tester.pump();

    await tester.tap(find.text('Get Started'));
    // The logo floats forever, so pump fixed frames instead of settling.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('What do you want to learn?'), findsOneWidget);
    expect(find.text('Python'), findsOneWidget);

    // "Next" stays disabled until an option is picked.
    final next = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Next'));
    expect(next.onPressed, isNull);

    await tester.tap(find.text('Python'));
    await tester.pump();
    final enabledNext = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Next'));
    expect(enabledNext.onPressed, isNotNull);
  });
}
