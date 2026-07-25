import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'ocean_bubbles.dart';
import 'wave_clipper.dart';

/// Shared shell for the auth screens: a gradient wave header with a back
/// button and title, and a flat white body below for the form content.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          WaveBand(
            color: AppColors.primaryDark,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(8, 8, 24, 44),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: AppColors.splashGradient,
                ),
              ),
              child: Stack(
                children: [
                  const Positioned(top: -10, right: 24, child: OceanBubble(size: 46, opacity: 0.14)),
                  const Positioned(top: 46, right: 84, child: OceanBubble(size: 20, opacity: 0.18)),
                  SafeArea(
                    bottom: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconButton(
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.16),
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: AppTheme.headline(fontSize: 28, weight: FontWeight.w800, color: Colors.white),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                subtitle,
                                style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.85)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
