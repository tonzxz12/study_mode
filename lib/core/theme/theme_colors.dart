import 'package:flutter/material.dart';

/// Extension to get theme-aware colors from context
/// This allows all pages to automatically adapt to light/dark themes
extension ThemeColors on BuildContext {
  /// Get colors that adapt to the current theme
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
  
  /// Background colors - adapt to theme
  Color get background => colorScheme.surface;
  Color get foreground => colorScheme.onSurface;
  Color get card => colorScheme.surfaceContainerHigh;
  Color get cardForeground => colorScheme.onSurface;
  
  /// Primary colors - adapt to theme
  Color get primary => colorScheme.primary;
  Color get primaryForeground => colorScheme.onPrimary;
  
  /// Secondary colors - adapt to theme
  Color get secondary => colorScheme.secondary;
  Color get secondaryForeground => colorScheme.onSecondary;
  
  /// Neutral colors - adapt to theme
  Color get muted => colorScheme.surfaceContainerLow;
  Color get mutedForeground => colorScheme.onSurfaceVariant;
  
  /// Accent colors - adapt to theme
  Color get accent => colorScheme.secondaryContainer;
  Color get accentForeground => colorScheme.onSecondaryContainer;
  
  /// Status colors - adapt to theme
  Color get destructive => colorScheme.error;
  Color get destructiveForeground => colorScheme.onError;
  Color get success => isDarkMode ? const Color(0xFF34D399) : const Color(0xFF22C55E);
  Color get warning => isDarkMode ? const Color(0xFFFBBF24) : const Color(0xFFF59E0B);
  Color get info => colorScheme.primary;
  
  /// UI element colors - adapt to theme
  Color get border => colorScheme.outline;
  Color get input => colorScheme.outline;
  Color get ring => colorScheme.primary;
  
  /// Timer colors - adapt to theme
  Color get timerFocus => success;
  Color get timerBreak => warning;
  Color get timerPause => mutedForeground;
  
  /// Calendar colors - adapt to theme  
  Color get calendarToday => primary;
  Color get calendarEvent => info;
  
  /// Planner colors - adapt to theme
  Color get plannerSubject => primary;
  Color get plannerTask => secondary;
  
  /// Settings colors - adapt to theme
  Color get settingsSection => secondary;
  
  /// Shadows that adapt to theme
  List<BoxShadow> get shadowSM => isDarkMode ? [
    BoxShadow(
      color: Colors.black.withOpacity(0.3),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ] : [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];
  
  List<BoxShadow> get shadowMD => isDarkMode ? [
    BoxShadow(
      color: Colors.black.withOpacity(0.3),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ] : [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];
  
  List<BoxShadow> get shadowLG => isDarkMode ? [
    BoxShadow(
      color: Colors.black.withOpacity(0.3),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ] : [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];
}

/// Static theme-aware color helpers for when context is not available
class ThemeAwareColors {
  static Color backgroundFor(BuildContext context) => context.background;
  static Color foregroundFor(BuildContext context) => context.foreground;
  static Color primaryFor(BuildContext context) => context.primary;
  static Color cardFor(BuildContext context) => context.card;
  static Color borderFor(BuildContext context) => context.border;
  static Color mutedFor(BuildContext context) => context.muted;
  static Color mutedForegroundFor(BuildContext context) => context.mutedForeground;
  static Color successFor(BuildContext context) => context.success;
  static Color warningFor(BuildContext context) => context.warning;
  static Color destructiveFor(BuildContext context) => context.destructive;
}