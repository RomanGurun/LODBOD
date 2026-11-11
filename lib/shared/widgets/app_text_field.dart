import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:lodbod/core/theme/tokens.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.initialValue,
    this.label,
    this.hint,
    this.prefixText,
    this.prefixStyle,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.maxLines = 1,
    this.textAlignVertical,
    this.alignLabelWithHint = false,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.autofillHints,
    this.readOnly = false,
    this.onTap,
    this.autofocus = false,
    this.textAlign = TextAlign.start,
    this.letterSpacing,
    this.inputFormatters,
  });

  final TextEditingController? controller;
  final String? initialValue;
  final String? label;
  final String? hint;

  /// Inline prefix (e.g. a country code). Unlike [prefixIcon] it is laid out
  /// on the same baseline as the input text, so it stays aligned while the
  /// label floats.
  final String? prefixText;
  final TextStyle? prefixStyle;

  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int maxLines;

  /// Alignment of the input inside the field. Multiline fields should use
  /// [TextAlignVertical.top] so the text starts at the top of the box.
  final TextAlignVertical? textAlignVertical;

  /// Keeps the floating label/hint at the top for multiline fields instead of
  /// centring it in the middle of the taller box.
  final bool alignLabelWithHint;

  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;
  final bool readOnly;
  final VoidCallback? onTap;
  final bool autofocus;
  final TextAlign textAlign;
  final double? letterSpacing;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      initialValue: controller == null ? initialValue : null,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      maxLines: maxLines,
      textAlignVertical: textAlignVertical,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      autofillHints: autofillHints,
      readOnly: readOnly,
      onTap: onTap,
      autofocus: autofocus,
      textAlign: textAlign,
      inputFormatters: inputFormatters,
      style: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.body,
        color: AppColors.textPrimary,
        letterSpacing: letterSpacing,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        alignLabelWithHint: alignLabelWithHint,
        prefixText: prefixText,
        prefixStyle: prefixStyle,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
      ),
    );
  }
}
