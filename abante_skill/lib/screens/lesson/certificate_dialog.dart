import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

const _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

String formatCertificateDate(DateTime date) => '${_monthNames[date.month - 1]} ${date.day}, ${date.year}';

Future<void> showCertificateDialog(
  BuildContext context, {
  required String unitTitle,
  required String userName,
  required DateTime earnedAt,
}) {
  return showDialog(
    context: context,
    builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: CertificateCard(unitTitle: unitTitle, userName: userName, earnedAt: earnedAt, showCloseButton: true),
    ),
  );
}

/// A simple completion certificate for a finished lesson unit — shown as a
/// celebratory popup right after finishing a unit, and re-shown later from
/// the Profile screen's certificate list.
class CertificateCard extends StatelessWidget {
  const CertificateCard({
    super.key,
    required this.unitTitle,
    required this.userName,
    required this.earnedAt,
    this.showCloseButton = false,
  });

  final String unitTitle;
  final String userName;
  final DateTime earnedAt;
  final bool showCloseButton;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25), width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(Icons.workspace_premium_rounded, color: AppColors.primary, size: 38),
          ),
          const SizedBox(height: 18),
          Text(
            'CERTIFICATE OF COMPLETION',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          Text(
            unitTitle,
            textAlign: TextAlign.center,
            style: AppTheme.headline(fontSize: 20, weight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Text('Awarded to', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 2),
          Text(userName, style: AppTheme.headline(fontSize: 16, weight: FontWeight.w700)),
          const SizedBox(height: 10),
          Text(formatCertificateDate(earnedAt), style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
          if (showCloseButton) ...[
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Nice!'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
