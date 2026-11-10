import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.maxLines = 1,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.autofillHints,
    this.readOnly = false,
    this.onTap,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int maxLines;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      maxLines: maxLines,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      autofillHints: autofillHints,
      readOnly: readOnly,
      onTap: onTap,
      style: const TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.body,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
      ),
    );
  }
}
