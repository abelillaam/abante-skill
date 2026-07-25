import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

class OutOfHeartsScreen extends StatelessWidget {
  const OutOfHeartsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.heart.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.heart_broken_rounded, color: AppColors.heart, size: 60),
              ),
              const SizedBox(height: 28),
              Text(
                "You're out of hearts",
                style: AppTheme.headline(fontSize: 24, weight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              const Text(
                'Take a breather! Review earlier lessons to earn hearts back, or wait for them to refill.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.schedule_rounded, size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      'Next heart in 2h 14m',
                      style: AppTheme.stat(fontSize: 13, color: AppColors.textSecondary, weight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Review Previous Lessons'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Back to Dashboard'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
