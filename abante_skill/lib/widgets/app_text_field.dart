import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    required this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.prefixIcon,
    this.initialValue,
    this.maxLines = 1,
    this.controller,
    this.errorText,
    this.helperText,
    this.onSubmitted,
    this.readOnly = false,
    this.maxLength,
  });

  final String label;
  final String hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final String? initialValue;
  final int maxLines;
  final TextEditingController? controller;
  final String? errorText;
  final String? helperText;
  final ValueChanged<String>? onSubmitted;
  final bool readOnly;
  final int? maxLength;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscured = false;
  TextEditingController? _ownedController;

  TextEditingController get _controller =>
      widget.controller ?? (_ownedController ??= TextEditingController(text: widget.initialValue));

  @override
  void initState() {
    super.initState();
    _obscured = widget.obscureText;
  }

  @override
  void dispose() {
    _ownedController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _controller,
          obscureText: _obscured,
          keyboardType: widget.keyboardType,
          maxLines: widget.obscureText ? 1 : widget.maxLines,
          maxLength: widget.maxLength,
          readOnly: widget.readOnly,
          onSubmitted: widget.onSubmitted,
          style: TextStyle(color: widget.readOnly ? AppColors.textSecondary : AppColors.textPrimary),
          // Empty (not null) autofillHints opts this field out of the
          // platform autofill service, which otherwise paints an ugly
          // yellow highlight/underline on password-manager-eligible fields.
          autofillHints: const [],
          decoration: InputDecoration(
            hintText: widget.hint,
            errorText: widget.errorText,
            helperText: widget.helperText,
            helperMaxLines: 2,
            fillColor: widget.readOnly ? AppColors.surfaceSunken : null,
            prefixIcon: widget.prefixIcon != null
                ? Icon(widget.prefixIcon, size: 20, color: AppColors.textSecondary)
                : null,
            suffixIcon: widget.obscureText
                ? IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      padding: EdgeInsets.zero,
                    ),
                    icon: Icon(
                      _obscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () => setState(() => _obscured = !_obscured),
                  )
                : (widget.readOnly ? Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.textSecondary) : null),
          ),
        ),
      ],
    );
  }
}
