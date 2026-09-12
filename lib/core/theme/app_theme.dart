import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_palette.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get light => _build(Brightness.light);

  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppPalette.cobalt,
          brightness: brightness,
          surface: isDark ? AppPalette.nightSurface : AppPalette.paperBright,
        ).copyWith(
          primary: isDark ? const Color(0xFF9EAAFF) : AppPalette.cobalt,
          onPrimary: isDark ? const Color(0xFF18204B) : Colors.white,
          secondary: isDark ? const Color(0xFF72D8BD) : AppPalette.mint,
          tertiary: isDark ? const Color(0xFFFFA092) : AppPalette.coral,
          surface: isDark ? AppPalette.nightSurface : AppPalette.paperBright,
          onSurface: isDark ? AppPalette.nightText : AppPalette.ink,
          outline: isDark ? AppPalette.nightLine : AppPalette.line,
          outlineVariant: isDark
              ? AppPalette.nightLine.withValues(alpha: 0.72)
              : AppPalette.line,
        );
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark ? AppPalette.night : AppPalette.paper,
      fontFamilyFallback: const ['Microsoft YaHei UI', 'Noto Sans CJK SC'],
    );
    final muted = isDark ? AppPalette.nightMuted : AppPalette.mutedInk;
    final surface = scheme.surface;
    final line = scheme.outlineVariant;

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 20,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
          systemNavigationBarColor: isDark
              ? AppPalette.night
              : AppPalette.paper,
          systemNavigationBarIconBrightness: isDark
              ? Brightness.light
              : Brightness.dark,
        ),
      ),
      cardTheme: CardThemeData(
        margin: EdgeInsets.zero,
        color: surface,
        elevation: 0,
        shadowColor: isDark
            ? Colors.black.withValues(alpha: 0.22)
            : const Color(0x1F26346A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: line),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? AppPalette.nightRaised : surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppPalette.nightRaised : surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: isDark ? 1 : 2,
        highlightElevation: isDark ? 2 : 4,
        shape: const StadiumBorder(),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          side: BorderSide(color: line),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      dividerTheme: DividerThemeData(color: line, thickness: 1, space: 1),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: isDark
            ? AppPalette.nightRaised
            : const Color(0xFFF0EDE5),
        side: BorderSide(color: line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
        labelStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? AppPalette.nightRaised : surface,
        indicatorColor: scheme.primary.withValues(alpha: isDark ? 0.22 : 0.13),
      ),
      textTheme: base.textTheme.copyWith(
        headlineLarge: base.textTheme.headlineLarge?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.7,
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w800,
        ),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(color: muted),
        bodySmall: base.textTheme.bodySmall?.copyWith(color: muted),
      ),
    );
  }
}
