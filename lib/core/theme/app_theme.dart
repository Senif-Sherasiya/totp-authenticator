import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Design tokens: a soft off-white / near-black neutral scale plus one accent.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.surface,
    required this.fill,
    required this.label,
    required this.secondary,
    required this.tertiary,
    required this.divider,
    required this.accent,
    required this.onAccent,
    required this.warning,
    required this.danger,
  });

  final Color background;
  final Color surface;
  final Color fill;
  final Color label;
  final Color secondary;
  final Color tertiary;
  final Color divider;
  final Color accent;
  final Color onAccent;
  final Color warning;
  final Color danger;

  static const light = AppColors(
    background: Color(0xFFF2F2F7), // systemGroupedBackground
    surface: Color(0xFFFFFFFF), // secondarySystemGroupedBackground
    fill: Color(0xFFE5E5EA), // systemGray5
    label: Color(0xFF000000),
    secondary: Color(0x993C3C43), // secondaryLabel
    tertiary: Color(0xFF8E8E93), // systemGray
    divider: Color(0xFFC6C6C8), // opaqueSeparator
    accent: Color(0xFF007AFF), // systemBlue
    onAccent: Color(0xFFFFFFFF),
    warning: Color(0xFFC93400), // accessible systemOrange
    danger: Color(0xFFFF3B30), // systemRed
  );

  static const dark = AppColors(
    background: Color(0xFF000000), // systemGroupedBackground
    surface: Color(0xFF1C1C1E), // secondarySystemGroupedBackground
    fill: Color(0xFF2C2C2E), // systemGray5
    label: Color(0xFFFFFFFF),
    secondary: Color(0x99EBEBF5), // secondaryLabel
    tertiary: Color(0xFF8E8E93), // systemGray
    divider: Color(0xFF38383A), // opaqueSeparator
    accent: Color(0xFF0A84FF), // systemBlue
    onAccent: Color(0xFFFFFFFF),
    warning: Color(0xFFFF9F0A), // systemOrange
    danger: Color(0xFFFF453A), // systemRed
  );

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(AppColors? other, double t) => t < 0.5 ? this : other ?? this;
}

extension AppColorsContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}

/// Shared spacing and shape constants.
class Gap {
  static const page = 20.0;
  static const radius = 12.0;
  static const minTap = 44.0;
}

ThemeData buildTheme(Brightness b) {
  final c = b == Brightness.dark ? AppColors.dark : AppColors.light;
  final scheme = ColorScheme.fromSeed(seedColor: c.accent, brightness: b)
      .copyWith(
        primary: c.accent,
        onPrimary: c.onAccent,
        surface: c.background,
        onSurface: c.label,
        error: c.danger,
      );
  final shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(Gap.radius),
  );
  OutlineInputBorder border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(Gap.radius),
        borderSide: BorderSide(color: color, width: width),
      );

  return ThemeData(
    useMaterial3: true,
    brightness: b,
    colorScheme: scheme,
    extensions: [c],
    scaffoldBackgroundColor: c.background,
    canvasColor: c.background,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    dividerColor: c.divider,
    dividerTheme: DividerThemeData(
      color: c.divider,
      thickness: 0.5,
      space: 0.5,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      },
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: c.background,
      foregroundColor: c.label,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      toolbarHeight: 48,
      titleTextStyle: TextStyle(
        color: c.label,
        fontSize: 17,
        fontWeight: FontWeight.w600,
      ),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: c.accent,
      selectionColor: c.accent.withValues(alpha: 0.25),
      selectionHandleColor: c.accent,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: TextStyle(color: c.tertiary),
      errorStyle: TextStyle(color: c.danger, fontSize: 13, height: 1.3),
      errorMaxLines: 3,
      border: border(c.divider),
      enabledBorder: border(c.divider),
      focusedBorder: border(c.accent, 1.5),
      errorBorder: border(c.danger),
      focusedErrorBorder: border(c.danger, 1.5),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: c.accent,
        foregroundColor: c.onAccent,
        disabledBackgroundColor: c.fill,
        disabledForegroundColor: c.tertiary,
        minimumSize: const Size.fromHeight(50),
        shape: shape,
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: c.label,
        minimumSize: const Size.fromHeight(50),
        side: BorderSide(color: c.divider),
        shape: shape,
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: c.accent,
        minimumSize: const Size(Gap.minTap, Gap.minTap),
        shape: shape,
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: c.secondary,
        minimumSize: const Size(Gap.minTap, Gap.minTap),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: c.accent,
      foregroundColor: c.onAccent,
      elevation: 1.5,
      focusElevation: 1.5,
      hoverElevation: 2,
      highlightElevation: 1,
      shape: const CircleBorder(),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titleTextStyle: TextStyle(
        color: c.label,
        fontSize: 17,
        fontWeight: FontWeight.w600,
      ),
      contentTextStyle: TextStyle(
        color: c.secondary,
        fontSize: 15,
        height: 1.4,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: c.label,
      contentTextStyle: TextStyle(color: c.background, fontSize: 15),
      shape: shape,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: c.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 6,
      shape: shape,
      textStyle: TextStyle(color: c.label, fontSize: 17),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: c.accent,
      inactiveTrackColor: c.fill,
      thumbColor: c.accent,
      overlayColor: c.accent.withValues(alpha: 0.12),
      valueIndicatorColor: c.label,
      valueIndicatorTextStyle: TextStyle(color: c.background),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        side: BorderSide.none,
        backgroundColor: c.fill,
        foregroundColor: c.secondary,
        selectedBackgroundColor: c.surface,
        selectedForegroundColor: c.label,
        minimumSize: const Size(0, 44),
        shape: shape,
      ),
    ),
    expansionTileTheme: ExpansionTileThemeData(
      shape: const Border(),
      collapsedShape: const Border(),
      iconColor: c.secondary,
      collapsedIconColor: c.secondary,
      tilePadding: EdgeInsets.zero,
      childrenPadding: EdgeInsets.zero,
    ),
  );
}
