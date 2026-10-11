import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/update_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'brand_mark.dart';

/// Checks for a newer release and, if there is one, shows what's new with
/// an "Update now" button that opens the download page.
Future<void> promptForUpdateIfAvailable(BuildContext context) async {
  final update = await UpdateService.checkForUpdate();
  if (update == null || !context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (_) => _UpdateDialog(update: update),
  );
}

class _UpdateDialog extends StatelessWidget {
  const _UpdateDialog({required this.update});

  final AppUpdate update;

  Future<void> _openDownloadPage(BuildContext context) async {
    final opened = await launchUrl(Uri.parse(UpdateService.downloadPageUrl), mode: LaunchMode.externalApplication);
    if (!context.mounted) return;
    Navigator.of(context).pop();
    if (!opened) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Open ${UpdateService.downloadPageUrl} in your browser to update.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxNotesHeight = MediaQuery.sizeOf(context).height * 0.3;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(28)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AbanteMark(size: 64, animate: false),
            const SizedBox(height: 8),
            Text('Update available', style: AppTheme.headline(fontSize: 21, weight: FontWeight.w800)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppColors.surfaceSunken, borderRadius: BorderRadius.circular(10)),
              child: Text(
                'v${update.currentVersion}  →  v${update.version}',
                style: AppTheme.stat(fontSize: 12.5, color: AppColors.primary),
              ),
            ),
            if (update.notes.isNotEmpty) ...[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "What's new",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
              ),
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxNotesHeight),
                child: SingleChildScrollView(
                  child: SizedBox(
                    width: double.infinity,
                    child: Text(
                      update.notes,
                      style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _openDownloadPage(context),
                icon: const Icon(Icons.system_update_rounded, size: 20),
                label: const Text('Update now'),
              ),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Later', style: TextStyle(color: AppColors.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Wrap a top-level screen with this to check for updates once it's shown.
class UpdateCheck extends StatefulWidget {
  const UpdateCheck({super.key, required this.child});

  final Widget child;

  @override
  State<UpdateCheck> createState() => _UpdateCheckState();
}

class _UpdateCheckState extends State<UpdateCheck> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) promptForUpdateIfAvailable(context);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
