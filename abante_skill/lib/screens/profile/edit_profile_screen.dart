import 'package:flutter/material.dart';

import '../../models/user_profile.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_text_field.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.profile});

  final UserProfile profile;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final _nameController = TextEditingController(text: widget.profile.name);
  late final _usernameController = TextEditingController(text: widget.profile.username);
  late final _emailController = TextEditingController(text: widget.profile.email);
  late final _bioController = TextEditingController(text: widget.profile.bio);

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _openChangePhotoSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
            ),
            _PhotoOptionTile(
              icon: Icons.photo_camera_outlined,
              label: 'Take Photo',
              onTap: () => Navigator.of(sheetContext).pop(),
            ),
            _PhotoOptionTile(
              icon: Icons.photo_library_outlined,
              label: 'Choose from Gallery',
              onTap: () => Navigator.of(sheetContext).pop(),
            ),
            _PhotoOptionTile(
              icon: Icons.delete_outline_rounded,
              label: 'Remove Photo',
              color: AppColors.error,
              onTap: () => Navigator.of(sheetContext).pop(),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    final updated = UserProfile(
      name: _nameController.text.trim().isEmpty ? widget.profile.name : _nameController.text.trim(),
      username: _usernameController.text.trim().isEmpty ? widget.profile.username : _usernameController.text.trim(),
      email: _emailController.text.trim().isEmpty ? widget.profile.email : _emailController.text.trim(),
      bio: _bioController.text.trim(),
      streakDays: widget.profile.streakDays,
      totalXp: widget.profile.totalXp,
      lessonsCompleted: widget.profile.lessonsCompleted,
      weekCompleted: widget.profile.weekCompleted,
    );
    Navigator.of(context).pop(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Edit Profile'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: GestureDetector(
                  onTap: _openChangePhotoSheet,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          widget.profile.name.substring(0, 1).toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.background, width: 3),
                          ),
                          child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: _openChangePhotoSheet,
                  child: const Text('Change Photo'),
                ),
              ),
              const SizedBox(height: 16),
              AppTextField(label: 'Name', hint: 'Your full name', controller: _nameController, prefixIcon: Icons.person_outline_rounded),
              const SizedBox(height: 18),
              AppTextField(label: 'Username', hint: 'username', controller: _usernameController, prefixIcon: Icons.alternate_email_rounded),
              const SizedBox(height: 18),
              AppTextField(
                label: 'Email',
                hint: 'you@example.com',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.mail_outline_rounded,
              ),
              const SizedBox(height: 18),
              AppTextField(label: 'Bio', hint: 'Tell us a bit about yourself', controller: _bioController, maxLines: 3),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: _save,
                child: const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoOptionTile extends StatelessWidget {
  const _PhotoOptionTile({required this.icon, required this.label, required this.onTap, this.color});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color ?? AppColors.textPrimary),
      title: Text(
        label,
        style: TextStyle(fontWeight: FontWeight.w600, color: color ?? AppColors.textPrimary),
      ),
    );
  }
}
