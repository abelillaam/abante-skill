import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

/// Text of the generic placeholder content older app versions showed (and
/// sometimes saved onto a lesson) when the AI request failed. Saved copies
/// are treated as missing so those lessons get their real content.
const legacyPlaceholderExercise = 'Create a variable named age, set it to 20, then write an if / else statement';
const legacyPlaceholderCardHeading = 'Think of it like a light switch';

/// Shown while the AI writes a lesson's content (it may retry for a few
/// seconds if Groq is busy).
class LessonLoading extends StatelessWidget {
  const LessonLoading({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 30, height: 30, child: CircularProgressIndicator(strokeWidth: 2.5)),
            const SizedBox(height: 18),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.5, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown when a lesson's content couldn't be generated, instead of showing
/// unrelated placeholder content.
class LessonLoadError extends StatelessWidget {
  const LessonLoadError({super.key, required this.onRetry, this.secondaryLabel, this.onSecondary});

  final VoidCallback onRetry;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(color: AppColors.surfaceSunken, shape: BoxShape.circle),
              child: Icon(Icons.cloud_off_rounded, size: 38, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(
              "Couldn't load this lesson",
              textAlign: TextAlign.center,
              style: AppTheme.headline(fontSize: 19, weight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'The lesson writer is busy or your connection dropped. Give it a moment and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.45),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: const Text('Try again'),
              ),
            ),
            if (secondaryLabel != null && onSecondary != null) ...[
              const SizedBox(height: 8),
              TextButton(onPressed: onSecondary, child: Text(secondaryLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
