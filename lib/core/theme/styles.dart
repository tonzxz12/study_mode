import 'package:flutter/material.dart';
import 'dart:ui';

/// Central design system for SIGMA Study app
/// Modern design system inspired by Tailwind CSS with green accent theme
/// Contains all colors, text styles, decorations, and design constants
class AppStyles {
  // Private constructor to prevent instantiation
  AppStyles._();

  // ================================
  // LIGHT THEME COLORS
  // ================================
  
  /// Background colors
  static const Color background = Color(0xFFF0F8FF); // Alice Blue background
  static const Color foreground = Color(0xFF374151); // Dark grey text
  static const Color card = Color(0xFFFFFFFF); // White cards
  static const Color cardForeground = Color(0xFF374151); // Card text
  
  /// Primary brand colors (Green theme)
  static const Color primary = Color(0xFF22C55E); // Vibrant green
  static const Color primaryForeground = Color(0xFFFFFFFF); // White on primary
  
  /// Secondary colors
  static const Color secondary = Color(0xFFE0F2FE); // Light cyan
  static const Color secondaryForeground = Color(0xFF4B5563); // Grey on secondary
  
  /// Neutral colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color muted = Color(0xFFF3F4F6); // Light grey
  static const Color mutedForeground = Color(0xFF6B7280); // Medium grey
  
  /// Accent colors
  static const Color accent = Color(0xFFD1FAE5); // Light green
  static const Color accentForeground = Color(0xFF374151); // Dark text on accent
  
  /// Status colors
  static const Color destructive = Color(0xFFEF4444); // Red for destructive actions
  static const Color destructiveForeground = Color(0xFFFFFFFF); // White on destructive
  static const Color success = Color(0xFF22C55E); // Same as primary green
  static const Color warning = Color(0xFFF59E0B); // Amber warning
  static const Color info = Color(0xFF3B82F6); // Blue info
  
  /// UI element colors
  static const Color border = Color(0xFFE5E7EB); // Light border
  static const Color input = Color(0xFFE5E7EB); // Input field border
  static const Color ring = Color(0xFF22C55E); // Focus ring (primary green)
  
  /// Chart colors (Green variations)
  static const Color chart1 = Color(0xFF22C55E); // Primary green
  static const Color chart2 = Color(0xFF10B981); // Emerald
  static const Color chart3 = Color(0xFF059669); // Darker emerald
  static const Color chart4 = Color(0xFF047857); // Even darker emerald
  static const Color chart5 = Color(0xFF065F46); // Darkest emerald

  // ================================
  // DARK THEME COLORS
  // ================================
  
  /// Dark theme background colors
  static const Color darkBackground = Color(0xFF0F172A); // Slate 900
  static const Color darkForeground = Color(0xFFD1D5DB); // Light grey text
  static const Color darkCard = Color(0xFF1E293B); // Slate 800
  static const Color darkCardForeground = Color(0xFFD1D5DB); // Light text on dark cards
  
  /// Dark theme primary colors
  static const Color darkPrimary = Color(0xFF34D399); // Lighter green for dark mode
  static const Color darkPrimaryForeground = Color(0xFF0F172A); // Dark text on light green
  
  /// Dark theme secondary colors
  static const Color darkSecondary = Color(0xFF2D3748); // Dark grey
  static const Color darkSecondaryForeground = Color(0xFFA1A1AA); // Light grey
  
  /// Dark theme neutral colors
  static const Color darkMuted = Color(0xFF19212E); // Very dark blue-grey
  static const Color darkMutedForeground = Color(0xFF6B7280); // Medium grey
  
  /// Dark theme accent colors
  static const Color darkAccent = Color(0xFF374151); // Dark grey
  static const Color darkAccentForeground = Color(0xFFA1A1AA); // Light grey
  
  /// Dark theme UI colors
  static const Color darkBorder = Color(0xFF4B5563); // Medium grey border
  static const Color darkInput = Color(0xFF4B5563); // Input border
  static const Color darkRing = Color(0xFF34D399); // Focus ring (light green)

  // ================================
  // FEATURE-SPECIFIC COLORS
  // ================================
  
  /// Timer colors
  static const Color timerFocus = Color(0xFF22C55E); // Primary green for focus
  static const Color timerBreak = Color(0xFFF59E0B); // Amber for breaks
  static const Color timerPause = Color(0xFF6B7280); // Grey for paused
  
  /// Calendar colors
  static const Color calendarToday = Color(0xFF22C55E); // Primary green
  static const Color calendarEvent = Color(0xFF3B82F6); // Blue for events
  static const Color calendarWeekend = Color(0xFF6B7280); // Grey for weekends
  
  /// Planner colors
  static const Color plannerSubject = Color(0xFF8B5CF6); // Purple for subjects
  static const Color plannerTask = Color(0xFF22C55E); // Green for tasks
  static const Color plannerOverdue = Color(0xFFEF4444); // Red for overdue
  
  /// Settings colors
  static const Color settingsSection = Color(0xFF6B7280); // Grey for sections
  static const Color settingsActive = Color(0xFF22C55E); // Green for active settings

  // ================================
  // GLASSMORPHISM COLORS
  // ================================
  
  /// Glassmorphism effect colors (updated for modern theme)
  static Color glassBg = white.withOpacity(0.15);
  static Color glassBorder = white.withOpacity(0.2);
  static Color glassIconDefault = white.withOpacity(0.7);
  static Color glassIconSelected = white;
  static Color glassShadow = black.withOpacity(0.1);
  
  // ================================
  // TEXT STYLES
  // ================================
  
  /// App bar and screen titles
  static const TextStyle screenTitle = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 28,
    color: foreground,
    letterSpacing: 1.5,
  );
  
  /// Section headers
  static const TextStyle sectionHeader = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: foreground,
    letterSpacing: 0.5,
  );
  
  /// Subsection headers
  static const TextStyle subsectionHeader = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: foreground,
  );
  
  /// Body text styles
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: foreground,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: secondaryForeground,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: mutedForeground,
  );
  
  /// Caption and helper text
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: mutedForeground,
  );
  
  /// Button text styles
  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: primaryForeground,
  );
  
  static const TextStyle buttonTextSecondary = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: primary,
  );
  
  /// Status text styles
  static const TextStyle statusActive = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: success,
  );
  
  static const TextStyle statusInactive = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: mutedForeground,
  );

  // ================================
  // SPACING & DIMENSIONS
  // ================================
  
  /// Standard spacing values
  static const double spaceXS = 4.0;
  static const double spaceSM = 8.0;
  static const double spaceMD = 16.0;
  static const double spaceLG = 24.0;
  static const double spaceXL = 32.0;
  static const double spaceXXL = 40.0;
  
  /// Border radius values (matching Tailwind CSS)
  static const double radius = 8.0; // Base radius (0.5rem)
  static const double radiusSM = 8.0; // Small radius
  static const double radiusMD = 12.0; // Medium radius 
  static const double radiusLG = 24.0; // Large radius (rounded-3xl)
  static const double radiusXL = 32.0; // Extra large radius
  static const double radiusXXL = 48.0; // Extra extra large
  static const double radiusRound = 100.0; // Fully rounded
  
  /// Navigation bar dimensions
  static const double navBarHeight = 70.0;
  static const double navBarRadius = 25.0;
  static const double navBarMargin = 20.0;
  static const double navBarIconSize = 24.0;
  static const double navBarCenterIconSize = 24.0;
  
  /// Card dimensions
  static const double cardRadius = 16.0;
  static const double cardElevation = 2.0;
  static const double cardPadding = 20.0;

  // ================================
  // SHADOWS & EFFECTS
  // ================================
  
  /// Standard box shadows (matching Tailwind CSS)
  static final List<BoxShadow> shadowXS = [
    BoxShadow(
      color: black.withOpacity(0.05),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];
  
  static final List<BoxShadow> shadowSM = [
    BoxShadow(
      color: black.withOpacity(0.10),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: black.withOpacity(0.10),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];
  
  static final List<BoxShadow> shadowMD = [
    BoxShadow(
      color: black.withOpacity(0.10),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: black.withOpacity(0.10),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];
  
  static final List<BoxShadow> shadowLG = [
    BoxShadow(
      color: black.withOpacity(0.10),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: black.withOpacity(0.10),
      blurRadius: 6,
      offset: const Offset(0, 4),
    ),
  ];
  
  static final List<BoxShadow> shadowXL = [
    BoxShadow(
      color: black.withOpacity(0.10),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: black.withOpacity(0.10),
      blurRadius: 10,
      offset: const Offset(0, 8),
    ),
  ];
  
  static final List<BoxShadow> shadow2XL = [
    BoxShadow(
      color: black.withOpacity(0.25),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];
  
  /// Glassmorphism effects
  static final List<BoxShadow> glassShadows = shadowLG;
  
  static final ImageFilter glassBlur = ImageFilter.blur(sigmaX: 15, sigmaY: 15);
  static final ImageFilter glassBlurHeavy = ImageFilter.blur(sigmaX: 20, sigmaY: 20);

  // ================================
  // CONTAINER DECORATIONS
  // ================================
  
  /// Standard card decoration
  static BoxDecoration cardDecoration = BoxDecoration(
    color: card,
    borderRadius: BorderRadius.circular(cardRadius),
    boxShadow: shadowSM,
  );
  
  /// Glassmorphism container decoration
  static BoxDecoration glassDecoration = BoxDecoration(
    color: glassBg,
    borderRadius: BorderRadius.circular(navBarRadius),
    border: Border.all(
      color: glassBorder,
      width: 1,
    ),
  );
  
  /// Navigation bar decoration (without blur - applied separately)
  static BoxDecoration navBarDecoration = BoxDecoration(
    borderRadius: BorderRadius.circular(navBarRadius),
    boxShadow: shadowLG,
  );
  
  /// Floating Action Button decoration
  static BoxDecoration fabDecoration(Color primaryColor) => BoxDecoration(
    shape: BoxShape.circle,
    gradient: LinearGradient(
      colors: [
        primaryColor.withOpacity(0.8),
        primaryColor,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    boxShadow: [
      BoxShadow(
        color: primaryColor.withOpacity(0.3),
        spreadRadius: 0,
        blurRadius: 10,
        offset: const Offset(0, 3),
      ),
    ],
  );
  
  /// Selected nav icon decoration
  static BoxDecoration selectedNavIconDecoration = BoxDecoration(
    shape: BoxShape.circle,
    color: white.withOpacity(0.25),
    border: Border.all(
      color: white.withOpacity(0.4),
      width: 1.5,
    ),
  );

  // ================================
  // GRADIENTS
  // ================================
  
  /// Primary gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, chart3],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [plannerSubject, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  /// Status gradients
  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF66BB6A), success],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFFFB74D), warning],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ================================
  // THEME DATA
  // ================================
  
  /// Light theme
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: background,
    appBarTheme: const AppBarTheme(
      backgroundColor: card,
      foregroundColor: foreground,
      elevation: 0,
      titleTextStyle: screenTitle,
    ),
    cardTheme: CardThemeData(
      color: card,
      elevation: cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusLG),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: primaryForeground,
        padding: const EdgeInsets.symmetric(
          horizontal: spaceLG,
          vertical: spaceMD,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLG),
        ),
        textStyle: buttonText,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primary,
        padding: const EdgeInsets.symmetric(
          horizontal: spaceLG,
          vertical: spaceMD,
        ),
        textStyle: buttonTextSecondary,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: muted,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusLG),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusLG),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusLG),
        borderSide: BorderSide(color: ring, width: 2),
      ),
      contentPadding: const EdgeInsets.all(spaceMD),
    ),
  );

  /// Dark theme
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: darkPrimary,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: darkBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: darkCard,
      foregroundColor: darkForeground,
      elevation: 0,
      titleTextStyle: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 28,
        color: darkForeground,
        letterSpacing: 1.5,
      ),
    ),
    cardTheme: CardThemeData(
      color: darkCard,
      elevation: cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusLG),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: darkPrimary,
        foregroundColor: darkPrimaryForeground,
        padding: const EdgeInsets.symmetric(
          horizontal: spaceLG,
          vertical: spaceMD,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLG),
        ),
        textStyle: buttonText,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: darkPrimary,
        padding: const EdgeInsets.symmetric(
          horizontal: spaceLG,
          vertical: spaceMD,
        ),
        textStyle: buttonTextSecondary,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkMuted,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusLG),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusLG),
        borderSide: BorderSide(color: darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusLG),
        borderSide: BorderSide(color: darkRing, width: 2),
      ),
      contentPadding: const EdgeInsets.all(spaceMD),
    ),
  );

  // ================================
  // HELPER METHODS
  // ================================
  
  /// Get color with opacity
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }
  
  /// Get responsive text size
  static double getResponsiveTextSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 350) {
      return baseSize * 0.9;
    } else if (screenWidth > 400) {
      return baseSize * 1.1;
    }
    return baseSize;
  }
  
  /// Get responsive spacing
  static double getResponsiveSpacing(BuildContext context, double baseSpacing) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 350) {
      return baseSpacing * 0.8;
    } else if (screenWidth > 400) {
      return baseSpacing * 1.2;
    }
    return baseSpacing;
  }
  
  /// Create glassmorphism container
  static Widget glassContainer({
    required Widget child,
    double? width,
    double? height,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double borderRadius = 20,
    double blurSigma = 15,
    Color? backgroundColor,
    Color? borderColor,
  }) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: glassShadows,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: backgroundColor ?? glassBg,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: borderColor ?? glassBorder,
                width: 1,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Feature-specific style classes
class TimerStyles {
  static const Color focusColor = AppStyles.timerFocus;
  static const Color breakColor = AppStyles.timerBreak;
  
  static const TextStyle timerText = TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.bold,
    color: AppStyles.foreground,
  );
  
  static const TextStyle sessionText = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppStyles.secondaryForeground,
  );
}

class CalendarStyles {
  static const Color eventColor = AppStyles.calendarEvent;
  static const Color todayColor = AppStyles.calendarToday;
  
  static const TextStyle dateText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppStyles.foreground,
  );
  
  static const TextStyle eventText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppStyles.white,
  );
}

class PlannerStyles {
  static const Color subjectColor = AppStyles.plannerSubject;
  static const Color taskColor = AppStyles.plannerTask;
  
  static const TextStyle subjectText = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppStyles.foreground,
  );
  
  static const TextStyle taskText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppStyles.secondaryForeground,
  );
}

class SettingsStyles {
  static const Color settingColor = AppStyles.settingsSection;
  
  static const TextStyle settingTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppStyles.foreground,
  );
  
  static const TextStyle settingSubtitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppStyles.mutedForeground,
  );
}