import 'package:flutter/material.dart';

import 'tokens.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.primary,
      onPrimary: AppColors.textOnPrimary,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      error: AppColors.error,
    );

    final base = ThemeData(
      useMaterial3: true,
      fontFamily: AppTypography.fontFamily,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.screen,
    );

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      borderSide: const BorderSide(color: AppColors.border),
    );

    return base.copyWith(
      textTheme: _textTheme(base.textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.screen,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: AppTypography.fontFamily,
          color: AppColors.textTitle,
          fontSize: AppTypography.title,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
      ),
      dividerColor: AppColors.divider,
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.md,
        ),
        hintStyle: const TextStyle(
          color: AppColors.textHint,
          fontSize: AppTypography.body,
        ),
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: AppTypography.body,
        ),
        floatingLabelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: AppTypography.caption,
        ),
        prefixIconColor: AppColors.textSecondary,
        suffixIconColor: AppColors.textSecondary,
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: inputBorder.copyWith(
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: inputBorder.copyWith(
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.45),
          minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          textStyle: const TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontWeight: FontWeight.w600,
            fontSize: AppTypography.section,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          backgroundColor: AppColors.surface,
          minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          textStyle: const TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontWeight: FontWeight.w600,
            fontSize: AppTypography.body,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontWeight: FontWeight.w600,
            fontSize: AppTypography.body,
          ),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.surface;
        }),
        side: const BorderSide(color: AppColors.border, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.xs),
        ),
        visualDensity: VisualDensity.compact,
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primarySoft,
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusPill),
        ),
        labelStyle: const TextStyle(
          fontFamily: AppTypography.fontFamily,
          color: AppColors.textSecondary,
          fontSize: AppTypography.caption,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.sm,
          vertical: AppSizes.xs,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: const TextStyle(
          fontFamily: AppTypography.fontFamily,
          color: AppColors.textOnPrimary,
          fontSize: AppTypography.body,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        titleTextStyle: const TextStyle(
          fontFamily: AppTypography.fontFamily,
          color: AppColors.textTitle,
          fontSize: AppTypography.title,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: const TextStyle(
          fontFamily: AppTypography.fontFamily,
          color: AppColors.textSecondary,
          fontSize: AppTypography.body,
          height: 1.4,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSizes.radiusXl),
          ),
        ),
        showDragHandle: true,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: AppSizes.bottomNavHeight,
        indicatorColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: AppTypography.micro,
            fontWeight: FontWeight.w500,
            color: AppColors.textTertiary,
          ),
        ),
        iconTheme: WidgetStateProperty.all(
          const IconThemeData(
            size: AppSizes.bottomNavIcon,
            color: AppColors.textTertiary,
          ),
        ),
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base) {
    return base.copyWith(
      displayLarge: _style(base.displayLarge, AppTypography.display,
          FontWeight.w700, AppColors.textTitle, -0.8),
      displayMedium: _style(
          base.displayMedium, 28, FontWeight.w700, AppColors.textTitle, -0.6),
      displaySmall: _style(base.displaySmall, AppTypography.headline,
          FontWeight.w700, AppColors.textTitle, -0.4),
      headlineMedium: _style(
          base.headlineMedium, 24, FontWeight.w700, AppColors.textTitle, -0.3),
      headlineSmall: _style(base.headlineSmall, AppTypography.title,
          FontWeight.w700, AppColors.textTitle, -0.2),
      titleLarge: _style(
          base.titleLarge, 20, FontWeight.w600, AppColors.textTitle, -0.2),
      titleMedium: _style(base.titleMedium, AppTypography.section,
          FontWeight.w600, AppColors.textTitle, 0),
      titleSmall: _style(base.titleSmall, AppTypography.body, FontWeight.w600,
          AppColors.textTitle, 0),
      bodyLarge: _style(base.bodyLarge, AppTypography.body, FontWeight.w400,
          AppColors.textPrimary, 0),
      bodyMedium: _style(base.bodyMedium, AppTypography.body, FontWeight.w400,
          AppColors.textPrimary, 0),
      bodySmall: _style(base.bodySmall, AppTypography.caption, FontWeight.w400,
          AppColors.textSecondary, 0),
      labelLarge: _style(base.labelLarge, AppTypography.body, FontWeight.w600,
          AppColors.textPrimary, 0),
      labelMedium: _style(base.labelMedium, AppTypography.caption,
          FontWeight.w600, AppColors.textPrimary, 0),
      labelSmall: _style(base.labelSmall, AppTypography.micro, FontWeight.w600,
          AppColors.textSecondary, 0),
    );
  }

  static TextStyle _style(
    TextStyle? base,
    double size,
    FontWeight weight,
    Color color,
    double letterSpacing,
  ) {
    return (base ?? const TextStyle()).copyWith(
      fontFamily: AppTypography.fontFamily,
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
      height: 1.25,
    );
  }
}
