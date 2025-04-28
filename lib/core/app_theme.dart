import 'package:flutter/material.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
// import 'package:dynamic_color/dynamic_color.dart'; // Unused

/// Contains the theme configuration for the application.
class AppTheme {
  // Define the fallback scheme
  static const FlexScheme _fallbackScheme = FlexScheme.materialBaseline;

  // Define common sub-themes data
  static const FlexSubThemesData _subThemesData = FlexSubThemesData(
      blendOnLevel: 10, // Use lower blend level for light mode
      blendOnColors: false,
      useTextTheme: true,
      useM2StyleDividerInM3: true,
      // Add other sub-theme customizations if needed
    );
  static const FlexSubThemesData _darkSubThemesData = FlexSubThemesData(
      blendOnLevel: 15, // Use higher blend level for dark mode
      blendOnColors: false,
      useTextTheme: true,
      useM2StyleDividerInM3: true,
      // Add other sub-theme customizations if needed
    );

  /// Generates the theme based on optional CorePalette and brightness.
  /// Falls back to a predefined scheme if palette is null.
  static ThemeData getTheme(ColorScheme? dynamicColorScheme, Brightness brightness) {
    // Determine the effective color scheme (dynamic or fallback)
    final ColorScheme effectiveColorScheme = dynamicColorScheme ?? 
      ((brightness == Brightness.light)
          ? FlexColorScheme.light(scheme: _fallbackScheme).colorScheme!
          : FlexColorScheme.dark(scheme: _fallbackScheme).colorScheme!);

    // Determine base typography
    final baseTypography = (brightness == Brightness.light)
        ? Typography.material2021().black
        : Typography.material2021().white;

    // Apply correct text colors based on the effective scheme
    final textTheme = baseTypography.apply(bodyColor: effectiveColorScheme.onSurface);
    final primaryTextTheme = baseTypography.apply(bodyColor: effectiveColorScheme.onPrimary);

    // Build the theme data
    if (brightness == Brightness.light) {
      return FlexThemeData.light(
        colorScheme: effectiveColorScheme, // Use the determined scheme
        surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
        blendLevel: 7,
        subThemesData: _subThemesData,
        textTheme: textTheme, // Apply calculated textTheme
        primaryTextTheme: primaryTextTheme, // Apply calculated primaryTextTheme
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        useMaterial3: true,
        swapLegacyOnMaterial3: true,
      );
    } else { // Brightness.dark
      return FlexThemeData.dark(
        colorScheme: effectiveColorScheme, // Use the determined scheme
        surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
        blendLevel: 13,
        subThemesData: _darkSubThemesData,
        textTheme: textTheme, // Apply calculated textTheme
        primaryTextTheme: primaryTextTheme, // Apply calculated primaryTextTheme
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        useMaterial3: true,
        swapLegacyOnMaterial3: true,
      );
    }
  }

  // Private constructor to prevent instantiation
  AppTheme._();
} 