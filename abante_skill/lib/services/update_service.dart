import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

/// A newer published version of the app.
class AppUpdate {
  const AppUpdate({required this.version, required this.notes, required this.currentVersion});

  final String version;
  final String notes;
  final String currentVersion;
}

/// Checks GitHub Releases for a newer build of the app. Each release is
/// published by `.github/workflows/release.yml`, tagged `v<version>` from
/// pubspec.yaml, with the APK attached and release-notes.md as its notes.
class UpdateService {
  UpdateService._();

  static const _repo = 'abelillaam/abante-skill';

  /// The download website (GitHub Pages) that always serves the latest APK.
  static const downloadPageUrl = 'https://abelillaam.github.io/abante-skill/';

  static bool _checkedThisLaunch = false;

  /// Returns the latest release if it's newer than this install, else null.
  /// Only checks once per app launch, and only on Android (the APK is
  /// Android-only). Never throws — no internet just means no prompt.
  static Future<AppUpdate?> checkForUpdate() async {
    if (_checkedThisLaunch || kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    _checkedThisLaunch = true;
    try {
      final info = await PackageInfo.fromPlatform();
      final response = await http
          .get(
            Uri.parse('https://api.github.com/repos/$_repo/releases/latest'),
            headers: {'Accept': 'application/vnd.github+json'},
          )
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;

      final release = jsonDecode(response.body) as Map<String, dynamic>;
      final latest = (release['tag_name'] as String? ?? '').replaceFirst(RegExp('^v'), '');
      if (latest.isEmpty || !isNewer(latest, info.version)) return null;

      return AppUpdate(
        version: latest,
        notes: _plainNotes(release['body'] as String? ?? ''),
        currentVersion: info.version,
      );
    } catch (_) {
      return null;
    }
  }

  /// Whether dotted version [a] (e.g. "1.2.0") is newer than [b].
  @visibleForTesting
  static bool isNewer(String a, String b) {
    List<int> parse(String v) => v.split('+').first.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    final x = parse(a);
    final y = parse(b);
    for (var i = 0; i < 3; i++) {
      final xi = i < x.length ? x[i] : 0;
      final yi = i < y.length ? y[i] : 0;
      if (xi != yi) return xi > yi;
    }
    return false;
  }

  /// Turns the release's Markdown notes into readable plain text.
  static String _plainNotes(String markdown) {
    final lines = markdown
        .replaceAll('\r', '')
        .split('\n')
        .map(
          (line) => line
              .replaceFirst(RegExp(r'^#+\s*'), '')
              .replaceFirst(RegExp(r'^\s*[-*]\s+'), '• ')
              .replaceAll('**', '')
              .replaceAll('`', ''),
        )
        .toList();
    return lines.join('\n').trim();
  }
}
