import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/user_profile.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/profile_avatar.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.profile});

  final UserProfile profile;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final _nameController = TextEditingController(text: widget.profile.name);
  late final _usernameController = TextEditingController(text: widget.profile.username);
  late final _bioController = TextEditingController(text: widget.profile.bio);
  late String? _photoBase64 = widget.profile.photoBase64;
  String? _usernameError;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      // Small and compressed on purpose: the photo is stored inline in the
      // user's Firestore document, which has a 1 MB limit.
      final file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 256,
        maxHeight: 256,
        imageQuality: 70,
        preferredCameraDevice: CameraDevice.front,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() => _photoBase64 = base64Encode(bytes));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(source == ImageSource.camera
              ? "Couldn't open the camera. Check that Abante has camera permission."
              : "Couldn't open your photos. Check that Abante has photo permission."),
        ),
      );
    }
  }

  void _openChangePhotoSheet() {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
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
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _pickPhoto(ImageSource.camera);
                },
              ),
              _PhotoOptionTile(
                icon: Icons.photo_library_outlined,
                label: 'Choose from Gallery',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _pickPhoto(ImageSource.gallery);
                },
              ),
              if (_photoBase64 != null)
                _PhotoOptionTile(
                  icon: Icons.delete_outline_rounded,
                  label: 'Remove Photo',
                  color: AppColors.error,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    setState(() => _photoBase64 = null);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    final username = _usernameController.text.trim().replaceAll('@', '');
    if (username.isNotEmpty && !RegExp(r'^[A-Za-z0-9_.]{3,24}$').hasMatch(username)) {
      setState(() => _usernameError = '3–24 letters, numbers, dots or underscores');
      return;
    }
    final name = _nameController.text.trim();
    final updated = widget.profile.copyWith(
      name: name.isEmpty ? widget.profile.name : name,
      username: username.isEmpty ? widget.profile.username : username,
      bio: _bioController.text.trim(),
      photoBase64: _photoBase64,
      clearPhoto: _photoBase64 == null,
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
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                        child: ProfileAvatar(initial: widget.profile.initial, photoBase64: _photoBase64, radius: 46),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.background, width: 3),
                          ),
                          child: Icon(Icons.camera_alt_rounded, size: 14, color: AppColors.onPrimary),
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
              AppTextField(
                label: 'Name',
                hint: 'Your full name',
                controller: _nameController,
                prefixIcon: Icons.person_outline_rounded,
                maxLength: 40,
              ),
              const SizedBox(height: 10),
              AppTextField(
                label: 'Username',
                hint: 'username',
                controller: _usernameController,
                prefixIcon: Icons.alternate_email_rounded,
                errorText: _usernameError,
              ),
              const SizedBox(height: 18),
              AppTextField(
                label: 'Email',
                hint: 'you@example.com',
                initialValue: widget.profile.email,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.mail_outline_rounded,
                readOnly: true,
                helperText: 'This is the email you log in with.',
              ),
              const SizedBox(height: 18),
              AppTextField(
                label: 'Bio',
                hint: 'Tell us a bit about yourself',
                controller: _bioController,
                maxLines: 3,
                maxLength: 160,
              ),
              const SizedBox(height: 20),
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
