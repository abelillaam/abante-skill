import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/user_profile.dart';
import '../../services/app_settings.dart';
import '../../services/certificate_repository.dart';
import '../../services/curriculum_repository.dart';
import '../../services/google_auth_service.dart';
import '../../services/push_notification_service.dart';
import '../../services/session_service.dart';
import '../../services/streak_repository.dart';
import '../../services/user_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/animated_counter.dart';
import '../../widgets/pressable_scale.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/streak_card.dart';
import '../../widgets/wave_clipper.dart';
import '../auth/auth_flow.dart';
import '../lesson/certificate_dialog.dart';
import '../splash_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authUser = FirebaseAuth.instance.currentUser;
  late UserProfile _profile = _authUser != null ? UserRepository.defaultProfileFor(_authUser) : mockProfile;
  Map<String, DateTime> _certificates = {};
  bool _notifications = AppSettings.notifications;
  bool _sound = AppSettings.soundEffects;
  bool _darkMode = AppSettings.darkMode;

  @override
  void initState() {
    super.initState();
    SessionService.refreshTick.addListener(_reload);
    _reload();
  }

  @override
  void dispose() {
    SessionService.refreshTick.removeListener(_reload);
    super.dispose();
  }

  /// Reloads stats and certificates — this tab stays alive under the bottom
  /// nav, so it must pick up XP/lessons/streak earned elsewhere.
  void _reload() {
    _loadSavedProfile();
    _loadCertificates();
  }

  Future<void> _loadSavedProfile() async {
    final user = _authUser;
    if (user == null) return;
    final saved = await UserRepository.loadProfile(user);
    if (mounted && saved != null) setState(() => _profile = saved);
  }

  Future<void> _loadCertificates() async {
    final user = _authUser;
    if (user == null) return;
    final earned = await CertificateRepository.loadEarned(user);
    if (mounted) setState(() => _certificates = earned);
  }

  void _openCertificate(String unitId, String unitTitle) {
    final earnedAt = _certificates[unitId];
    if (earnedAt == null) return;
    showCertificateDialog(context, unitTitle: unitTitle, userName: _profile.name, earnedAt: earnedAt);
  }

  Future<void> _openEditProfile() async {
    final updated = await Navigator.of(context).push<UserProfile>(
      MaterialPageRoute(builder: (_) => EditProfileScreen(profile: _profile)),
    );
    if (updated == null || !mounted) return;
    setState(() => _profile = updated);
    final user = _authUser;
    if (user == null) return;
    try {
      await UserRepository.saveProfile(user, updated);
      SessionService.requestRefresh();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't save your profile. Check your connection and try again.")),
      );
    }
  }

  Future<void> _setNotifications(bool value) async {
    setState(() => _notifications = value);
    await PushNotificationService.setEnabled(value);
  }

  Future<void> _setSound(bool value) async {
    setState(() => _sound = value);
    await AppSettings.setSoundEffects(value);
    if (value) Sfx.correct();
  }

  Future<void> _setDarkMode(bool value) async {
    setState(() => _darkMode = value);
    await AppSettings.setDarkMode(value);
  }

  void _confirmLogOut() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log out?'),
        content: const Text("You'll need to log back in to continue your streak."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await SessionService.signOut();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const SplashScreen()),
                (route) => false,
              );
            },
            child: Text('Log out', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete account?'),
        content: const Text(
          'This permanently deletes your profile, curriculum, and progress. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _deleteAccount();
            },
            child: Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  /// Confirms the person's identity right before deleting. Firebase only
  /// lets an account be deleted shortly after signing in, and doing this
  /// first means we never delete their data and then fail to delete the
  /// account itself.
  Future<bool> _reauthenticate(User user) async {
    if (GoogleAuthService.hasPassword(user) && user.email != null) {
      final password = await promptForPassword(
        context,
        title: 'Confirm it’s you',
        message: 'Enter your password to permanently delete your account.',
        actionLabel: 'Delete forever',
        destructive: true,
      );
      if (password == null || password.isEmpty) return false;
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: user.email!, password: password),
      );
      return true;
    }
    if (GoogleAuthService.isGoogleUser(user)) {
      await GoogleAuthService.reauthenticate(user);
      return true;
    }
    return true;
  }

  Future<void> _deleteAccount() async {
    final user = _authUser;
    if (user == null) return;

    try {
      if (!await _reauthenticate(user)) return;
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyAuthError(e))));
      return;
    } catch (_) {
      return; // Google prompt cancelled.
    }
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await UserRepository.deleteUser(user.uid);
      await user.delete();
      SessionService.clearLocalState();
      await GoogleAuthService.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SplashScreen()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyAuthError(e))));
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context).pop(); // close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete account. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: [
            _ProfileHeader(profile: _profile, onEdit: _openEditProfile),
            const SizedBox(height: 24),
            StreakCard(
              days: _authUser != null ? StreakRepository.streakDays : _profile.streakDays,
              weekCompleted: _authUser != null ? StreakRepository.weekCompleted : _profile.weekCompleted,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    icon: Icons.bolt_rounded,
                    color: AppColors.primary,
                    value: _profile.totalXp,
                    label: 'Total XP',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatTile(
                    icon: Icons.check_circle_rounded,
                    color: AppColors.success,
                    value: _profile.lessonsCompleted,
                    label: 'Lessons Done',
                  ),
                ),
              ],
            ),
            if (CurriculumRepository.units.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Certificates',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(color: AppColors.textPrimary.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 6)),
                  ],
                ),
                child: Column(
                  children: [
                    for (final unit in CurriculumRepository.units) ...[
                      if (unit != CurriculumRepository.units.first) const Divider(height: 1, indent: 16, endIndent: 16),
                      _CertificateTile(
                        title: unit.title,
                        earnedAt: _certificates[unit.id],
                        onTap: _certificates.containsKey(unit.id) ? () => _openCertificate(unit.id, unit.title) : null,
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              'Preferences',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(color: AppColors.textPrimary.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 6)),
                ],
              ),
              child: Column(
                children: [
                  _SettingSwitchTile(
                    icon: Icons.notifications_none_rounded,
                    label: 'Notifications',
                    value: _notifications,
                    onChanged: _setNotifications,
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _SettingSwitchTile(
                    icon: Icons.volume_up_outlined,
                    label: 'Sound Effects',
                    value: _sound,
                    onChanged: _setSound,
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _SettingSwitchTile(
                    icon: Icons.dark_mode_outlined,
                    label: 'Dark Mode',
                    value: _darkMode,
                    onChanged: _setDarkMode,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            PressableScale(
              child: Material(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: _confirmLogOut,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(color: AppColors.textPrimary.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 6)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
                      SizedBox(width: 12),
                      Text(
                        'Log Out',
                        style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            ),
            const SizedBox(height: 12),
            PressableScale(
              child: Material(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: _confirmDeleteAccount,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(color: AppColors.textPrimary.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 6)),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.delete_forever_rounded, color: AppColors.error, size: 20),
                        SizedBox(width: 12),
                        Text(
                          'Delete Account',
                          style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile, required this.onEdit});

  final UserProfile profile;
  final VoidCallback onEdit;

  static const _avatarRadius = 44.0;
  static const _bannerHeight = 108.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: _bannerHeight + _avatarRadius,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              WaveBand(
                color: AppColors.primaryDark,
                elevation: 10,
                child: Container(
                  height: _bannerHeight,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: AppColors.splashGradient,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: _bannerHeight - _avatarRadius,
                left: 0,
                right: 0,
                child: Center(
                  child: Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: AppColors.background, shape: BoxShape.circle),
                        child: ProfileAvatar(
                          initial: profile.initial,
                          photoBase64: profile.photoBase64,
                          radius: _avatarRadius,
                        ),
                      ),
                      Positioned(
                        right: 4,
                        bottom: 4,
                        child: GestureDetector(
                          onTap: onEdit,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.background, width: 3),
                            ),
                            child: Icon(Icons.edit_rounded, size: 14, color: AppColors.onPrimary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          profile.name,
          style: AppTheme.headline(fontSize: 20, weight: FontWeight.w800),
        ),
        const SizedBox(height: 2),
        Text(
          '@${profile.username}',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        if (profile.bio.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            profile.bio,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.5, color: AppColors.textSecondary, height: 1.4),
          ),
        ],
        const SizedBox(height: 16),
        PressableScale(
          child: OutlinedButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.person_outline_rounded, size: 18),
            label: const Text('Edit Profile'),
            style: OutlinedButton.styleFrom(minimumSize: const Size(180, 44)),
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.icon, required this.color, required this.value, required this.label});

  final IconData icon;
  final Color color;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: AppColors.textPrimary.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          AnimatedCounter(value: value, style: AppTheme.stat(fontSize: 17)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _CertificateTile extends StatelessWidget {
  const _CertificateTile({required this.title, required this.earnedAt, required this.onTap});

  final String title;
  final DateTime? earnedAt;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final earned = earnedAt != null;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              earned ? Icons.workspace_premium_rounded : Icons.workspace_premium_outlined,
              size: 20,
              color: earned ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: earned ? AppColors.textPrimary : AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    earned ? 'Earned ${formatCertificateDate(earnedAt!)}' : 'Complete this unit to earn it',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            if (earned) Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _SettingSwitchTile extends StatelessWidget {
  const _SettingSwitchTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
