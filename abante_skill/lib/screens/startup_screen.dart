import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/session_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_mark.dart';
import 'auth/auth_flow.dart';
import 'splash_screen.dart';

/// First screen on launch. Firebase remembers who was signed in, so a
/// returning user goes straight back into the app with their progress
/// instead of having to log in every time.
class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key});

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const SplashScreen()));
      return;
    }
    setState(() => _failed = false);
    final entered = await enterApp(context, user);
    if (!entered && mounted) setState(() => _failed = true);
  }

  Future<void> _signOut() async {
    await SessionService.signOut();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const SplashScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.splashGradient,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AbanteMark(size: 112),
              const SizedBox(height: 28),
              if (!_failed)
                SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.onHero),
                )
              else ...[
                Text(
                  "Couldn't load your progress",
                  style: AppTheme.headline(fontSize: 18, weight: FontWeight.w800, color: AppColors.onHero),
                ),
                const SizedBox(height: 6),
                Text(
                  'Check your internet connection.',
                  style: TextStyle(fontSize: 14, color: AppColors.onHero.withValues(alpha: 0.75)),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 220,
                  child: FilledButton(onPressed: _start, child: const Text('Try Again')),
                ),
                TextButton(
                  onPressed: _signOut,
                  child: Text('Log out', style: TextStyle(color: AppColors.onHero)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
