import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/user_profile.dart';
import '../../services/user_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/animated_counter.dart';
import '../../widgets/pressable_scale.dart';
import '../../widgets/streak_card.dart';
import '../../widgets/wave_clipper.dart';
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
  bool _notifications = true;
  bool _sound = true;
  bool _darkMode = false;

  @override
  void initState() {
    super.initState();
    _loadSavedProfile();
  }

  Future<void> _loadSavedProfile() async {
    final user = _authUser;
    if (user == null) return;
    final saved = await UserRepository.loadProfile(user);
    if (mounted && saved != null) setState(() => _profile = saved);
  }

  Future<void> _openEditProfile() async {
    final updated = await Navigator.of(context).push<UserProfile>(
      MaterialPageRoute(builder: (_) => EditProfileScreen(profile: _profile)),
    );
    if (updated != null) {
      setState(() => _profile = updated);
      final user = _authUser;
      if (user != null) {
        try {
          await UserRepository.saveProfile(user, updated);
        } catch (_) {
          // Local update already applied; a sync hiccup shouldn't block the UI.
        }
      }
    }
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
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const SplashScreen()),
                (route) => false,
              );
            },
            child: const Text('Log out', style: TextStyle(color: AppColors.error)),
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
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    final user = _authUser;
    if (user == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await UserRepository.deleteUser(user.uid);
      await user.delete();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SplashScreen()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // close loading dialog
      final message = e.code == 'requires-recent-login'
          ? 'For security, please log out and log back in, then try deleting your account again.'
          : e.message ?? 'Could not delete account. Try again.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
            StreakCard(days: _profile.streakDays, weekCompleted: _profile.weekCompleted),
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
            const SizedBox(height: 24),
            const Text(
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
                    onChanged: (v) => setState(() => _notifications = v),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _SettingSwitchTile(
                    icon: Icons.volume_up_outlined,
                    label: 'Sound Effects',
                    value: _sound,
                    onChanged: (v) => setState(() => _sound = v),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _SettingSwitchTile(
                    icon: Icons.dark_mode_outlined,
                    label: 'Dark Mode',
                    value: _darkMode,
                    onChanged: (v) => setState(() => _darkMode = v),
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
                  child: const Row(
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
                    child: const Row(
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
                  decoration: const BoxDecoration(
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
                        decoration: const BoxDecoration(color: AppColors.background, shape: BoxShape.circle),
                        child: CircleAvatar(
                          radius: _avatarRadius,
                          backgroundColor: AppColors.primary,
                          child: Text(
                            profile.name.substring(0, 1).toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800),
                          ),
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
                            child: const Icon(Icons.edit_rounded, size: 14, color: Colors.white),
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
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        if (profile.bio.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            profile.bio,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13.5, color: AppColors.textSecondary, height: 1.4),
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
          Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
        ],
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
            child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ),
          Switch(value: value, onChanged: onChanged, activeThumbColor: AppColors.primary),
        ],
      ),
    );
  }
}
