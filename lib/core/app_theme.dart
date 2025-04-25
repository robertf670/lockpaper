import 'package:dynamic_color/dynamic_color.dart'; // Import CorePalette
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

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
  static ThemeData getTheme(ColorScheme? colorScheme, Brightness brightness) {
    if (colorScheme != null) {
      // colorScheme exists: Use it directly
      print('Generating theme from provided ColorScheme ($brightness)');
      // final ColorScheme baseColorScheme = ColorScheme.fromSeed( // REMOVE
      //   seedColor: Color(palette.primary.get(40)), // REMOVE
      //   brightness: brightness, // REMOVE
      // ); // REMOVE

      if (brightness == Brightness.light) {
        return FlexThemeData.light(
          colorScheme: colorScheme, // UPDATE
          surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
          blendLevel: 7,
          subThemesData: _subThemesData,
          visualDensity: FlexColorScheme.comfortablePlatformDensity,
          useMaterial3: true,
          swapLegacyOnMaterial3: true,
        );
      } else {
        return FlexThemeData.dark(
          colorScheme: colorScheme, // UPDATE
          surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
          blendLevel: 13,
          subThemesData: _darkSubThemesData,
          visualDensity: FlexColorScheme.comfortablePlatformDensity,
          useMaterial3: true,
          swapLegacyOnMaterial3: true,
        );
      }
    } else {
      // colorScheme is null: Use the fallback scheme directly
      print('Provided ColorScheme not available, using fallback scheme ($brightness)');
      if (brightness == Brightness.light) {
        return FlexThemeData.light(
          scheme: _fallbackScheme,
          surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
          blendLevel: 7,
          subThemesData: _subThemesData,
          visualDensity: FlexColorScheme.comfortablePlatformDensity,
          useMaterial3: true,
          swapLegacyOnMaterial3: true,
        );
      } else {
        return FlexThemeData.dark(
          scheme: _fallbackScheme,
          surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
          blendLevel: 13,
          subThemesData: _darkSubThemesData,
          visualDensity: FlexColorScheme.comfortablePlatformDensity,
          useMaterial3: true,
          swapLegacyOnMaterial3: true,
        );
      }
    }
  }

  // Private constructor to prevent instantiation
  AppTheme._();
} 