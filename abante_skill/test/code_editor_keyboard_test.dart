import 'package:abante_skill/main.dart';
import 'package:abante_skill/screens/lesson/ide_workspace_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('Code editor stays usable while the keyboard is open', (tester) async {
    // A typical phone (393x851 dp) with a 300 dp on-screen keyboard.
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MyApp(home: IdeWorkspaceScreen(lesson: null)));
    await tester.pump();
    expect(find.text('Run Code'), findsOneWidget);

    // Focus the editor and raise the keyboard.
    await tester.tap(find.byType(TextField));
    tester.view.viewInsets = const FakeViewPadding(bottom: 300 * 2.75);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Compact writing mode: big buttons and task card give way to a slim
    // keyboard toolbar, so the editor keeps real space to type in.
    expect(find.text('Run Code'), findsNothing);
    expect(find.byIcon(Icons.keyboard_hide_rounded), findsOneWidget);
    final editorHeight = tester.getSize(find.byType(TextField)).height;
    expect(editorHeight, greaterThan(250), reason: 'editor was only ${editorHeight}dp tall');

    // Quick keys insert at the cursor.
    final before = tester.widget<TextField>(find.byType(TextField)).controller!.text;
    await tester.tap(find.text('Tab'));
    await tester.pump();
    final after = tester.widget<TextField>(find.byType(TextField)).controller!.text;
    expect(after.length, before.length + 4);

    // Hiding the keyboard restores the normal layout.
    await tester.tap(find.byIcon(Icons.keyboard_hide_rounded));
    tester.view.resetViewInsets();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Run Code'), findsOneWidget);
  });
}
