import 'package:abante_skill/widgets/practice_time_tracker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<int> flushed;
  int total() => flushed.fold(0, (a, b) => a + b);

  setUp(() {
    flushed = [];
    PracticeTimeTracker.debugOnFlush = flushed.add;
  });
  tearDown(() => PracticeTimeTracker.debugOnFlush = null);

  Widget app({required bool Function() isActive}) => MaterialApp(
        home: PracticeTimeTracker(isActive: isActive, child: const SizedBox()),
      );

  testWidgets('counts seconds live while on screen, in batches of 5', (tester) async {
    await tester.pumpWidget(app(isActive: () => true));
    await tester.pump(const Duration(seconds: 4));
    expect(total(), 0, reason: 'not saved until a full 5-second batch');
    await tester.pump(const Duration(seconds: 1));
    expect(total(), 5);
    await tester.pump(const Duration(seconds: 5));
    expect(total(), 10);
  });

  testWidgets('saves leftover seconds immediately when the screen closes', (tester) async {
    await tester.pumpWidget(app(isActive: () => true));
    await tester.pump(const Duration(seconds: 7));
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    expect(total(), 7, reason: 'the 2 leftover seconds are flushed on exit');
  });

  testWidgets('does not count while its tab is not selected', (tester) async {
    var selected = false;
    await tester.pumpWidget(app(isActive: () => selected));
    await tester.pump(const Duration(seconds: 30));
    expect(total(), 0);

    selected = true;
    await tester.pump(const Duration(seconds: 6));
    selected = false;
    await tester.pump(const Duration(seconds: 30));
    expect(total(), 6, reason: 'only the 6 seconds on the tab count');
  });

  testWidgets('pauses while the app is in the background', (tester) async {
    await tester.pumpWidget(app(isActive: () => true));
    await tester.pump(const Duration(seconds: 3));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    expect(total(), 3, reason: 'saved right away when leaving the app');
    await tester.pump(const Duration(seconds: 60));
    expect(total(), 3, reason: 'background time is not counted');

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(seconds: 5));
    expect(total(), 8);
  });

  testWidgets('does not count while another screen is on top', (tester) async {
    await tester.pumpWidget(app(isActive: () => true));
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.push(MaterialPageRoute<void>(builder: (_) => const Scaffold()));
    await tester.pumpAndSettle();
    final before = total();
    await tester.pump(const Duration(seconds: 20));
    expect(total(), before);
  });
}
