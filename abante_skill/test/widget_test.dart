import 'package:flutter_test/flutter_test.dart';

import 'package:abante_skill/main.dart';

void main() {
  testWidgets('Splash screen shows logo and both entry buttons', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Abante Skill'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.text('I Already Have an Account'), findsOneWidget);

    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    expect(find.text('Sign up flow goes here'), findsOneWidget);
  });
}
