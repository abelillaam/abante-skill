import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';

import '../services/streak_repository.dart';

/// Counts time toward the daily goal while [child] is genuinely being used:
/// its screen is the one on top, the app is in the foreground (not locked
/// or in the background), and [isActive] says so (e.g. its tab is
/// selected). Time is added every few seconds, so progress shows up live,
/// and flushed immediately when the screen closes or the app is paused.
class PracticeTimeTracker extends StatefulWidget {
  const PracticeTimeTracker({super.key, required this.child, this.isActive});

  final Widget child;

  /// Extra condition for counting, checked every second. Null means always.
  final bool Function()? isActive;

  /// Receives counted seconds instead of saving them (tests only).
  @visibleForTesting
  static void Function(int seconds)? debugOnFlush;

  @override
  State<PracticeTimeTracker> createState() => _PracticeTimeTrackerState();
}

class _PracticeTimeTrackerState extends State<PracticeTimeTracker> with WidgetsBindingObserver {
  static const _flushEvery = 5; // seconds

  Timer? _ticker;
  int _pending = 0;
  bool _appInForeground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final state = WidgetsBinding.instance.lifecycleState;
    _appInForeground = state == null || state == AppLifecycleState.resumed;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  bool get _counting {
    if (!_appInForeground || !mounted) return false;
    if (!(ModalRoute.of(context)?.isCurrent ?? true)) return false; // Another screen is on top.
    return widget.isActive?.call() ?? true;
  }

  void _tick() {
    if (!_counting) {
      if (_pending > 0) _flush();
      return;
    }
    _pending++;
    if (_pending >= _flushEvery) _flush();
  }

  void _flush({bool syncNow = false}) {
    final seconds = _pending;
    _pending = 0;
    if (seconds <= 0 && !syncNow) return;
    final debugOnFlush = PracticeTimeTracker.debugOnFlush;
    if (debugOnFlush != null) {
      if (seconds > 0) debugOnFlush(seconds);
      return;
    }
    if (Firebase.apps.isEmpty) return; // Not set up (e.g. in widget tests).
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    unawaited(StreakRepository.addSeconds(user, seconds, syncNow: syncNow));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appInForeground = state == AppLifecycleState.resumed;
    // Leaving the app (switching away, locking, swiping it closed): save now
    // so no time is lost.
    if (!_appInForeground) _flush(syncNow: true);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _flush(syncNow: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
