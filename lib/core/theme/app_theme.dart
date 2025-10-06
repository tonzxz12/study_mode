import 'package:flutter/material.dart';

/// SIGMA Premium Design System
/// Expert-crafted color palette and styling for a professional app experience
class AppColors {
  // Premium Brand Colors
  static const Color sigmaBlue = Color(0xFF0066FF);
  static const Color sigmaPurple = Color(0xFF7C3AED);
  static const Color sigmaGreen = Color(0xFF00D9FF);
  static const Color sigmaAccent = Color(0xFF00C896);
  static const Color sigmaOrange = Color(0xFFFF8A00);
  static const Color sigmaYellow = Color(0xFFFFB800);
  static const Color sigmaPink = Color(0xFFFF6B9D);
  
  // Neutral Palette
  static const Color neutral900 = Color(0xFF1A1A1A);
  static const Color neutral800 = Color(0xFF2D2D2D);
  static const Color neutral700 = Color(0xFF404040);
  static const Color neutral600 = Color(0xFF525252);
  static const Color neutral500 = Color(0xFF737373);
  static const Color neutral400 = Color(0xFFA3A3A3);
  static const Color neutral300 = Color(0xFFD4D4D4);
  static const Color neutral200 = Color(0xFFE5E5E5);
  static const Color neutral100 = Color(0xFFF5F5F5);
  static const Color neutral50 = Color(0xFFFAFAFA);
  
  // Surface Colors
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF8F9FA);
  static const Color surfaceContainer = Color(0xFFF1F3F4);
  static const Color surfaceContainerHigh = Color(0xFFE8EAED);
  
  // Glass Effect Colors
  static Color glassBackground = Colors.white.withOpacity(0.7);
  static Color glassBorder = Colors.white.withOpacity(0.3);
  static Color glassOverlay = Colors.white.withOpacity(0.1);
  
  // Semantic Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  
  // Gradient Definitions
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [sigmaBlue, sigmaGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient heroGradient = LinearGradient(
    colors: [sigmaBlue, sigmaGreen, sigmaPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient successGradient = LinearGradient(
    colors: [sigmaAccent, sigmaGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient warningGradient = LinearGradient(
    colors: [sigmaOrange, sigmaYellow],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient purpleGradient = LinearGradient(
    colors: [sigmaPurple, sigmaPink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Background Gradients
  static LinearGradient get backgroundGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      sigmaBlue.withOpacity(0.05),
      sigmaGreen.withOpacity(0.05),
      sigmaPurple.withOpacity(0.05),
    ],
  );
  
  static LinearGradient get appBarGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      sigmaBlue.withOpacity(0.1),
      sigmaGreen.withOpacity(0.1),
    ],
  );
}

/// Premium Typography System
class AppTypography {
  static const String primaryFont = 'Inter';
  static const String displayFont = 'Poppins';
  
  // Display Styles
  static const TextStyle displayLarge = TextStyle(
    fontFamily: displayFont,
    fontSize: 57,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.25,
    height: 1.12,
  );
  
  static const TextStyle displayMedium = TextStyle(
    fontFamily: displayFont,
    fontSize: 45,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    height: 1.16,
  );
  
  static const TextStyle displaySmall = TextStyle(
    fontFamily: displayFont,
    fontSize: 36,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.22,
  );
  
  // Headline Styles
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: displayFont,
    fontSize: 32,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.25,
  );
  
  static const TextStyle headlineMedium = TextStyle(
    fontFamily: displayFont,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.29,
  );
  
  static const TextStyle headlineSmall = TextStyle(
    fontFamily: primaryFont,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.33,
  );
  
  // Title Styles
  static const TextStyle titleLarge = TextStyle(
    fontFamily: primaryFont,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.27,
  );
  
  static const TextStyle titleMedium = TextStyle(
    fontFamily: primaryFont,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
    height: 1.50,
  );
  
  static const TextStyle titleSmall = TextStyle(
    fontFamily: primaryFont,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.10,
    height: 1.43,
  );
  
  // Label Styles
  static const TextStyle labelLarge = TextStyle(
    fontFamily: primaryFont,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.10,
    height: 1.43,
  );
  
  static const TextStyle labelMedium = TextStyle(
    fontFamily: primaryFont,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.50,
    height: 1.33,
  );
  
  static const TextStyle labelSmall = TextStyle(
    fontFamily: primaryFont,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.50,
    height: 1.45,
  );
  
  // Body Styles
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: primaryFont,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.50,
    height: 1.50,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: primaryFont,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    height: 1.43,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontFamily: primaryFont,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.40,
    height: 1.33,
  );
}

/// Premium Spacing System
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;
  
  // Component Spacing
  static const double cardPadding = 20.0;
  static const double sectionSpacing = 32.0;
  static const double itemSpacing = 16.0;
  static const double buttonHeight = 48.0;
  static const double buttonPadding = 16.0;
}

/// Premium Border Radius System
class AppRadius {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double full = 999.0;
  
  // Component Radius
  static const double card = 20.0;
  static const double button = 16.0;
  static const double input = 12.0;
  static const double dialog = 20.0;
}

/// Shadow System
class AppShadows {
  static List<BoxShadow> get soft => [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> get medium => [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 15,
      offset: const Offset(0, 6),
    ),
  ];
  
  static List<BoxShadow> get strong => [
    BoxShadow(
      color: Colors.black.withOpacity(0.15),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];
  
  static List<BoxShadow> get glow => [
    BoxShadow(
      color: AppColors.sigmaBlue.withOpacity(0.3),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];
  
  static List<BoxShadow> get glowAccent => [
    BoxShadow(
      color: AppColors.sigmaGreen.withOpacity(0.3),
      blurRadius: 15,
      offset: const Offset(0, 6),
    ),
  ];
}

/// Main Theme Configuration
class AppTheme {
  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      // Color Scheme
      colorScheme: ColorScheme.light(
        primary: AppColors.sigmaBlue,
        secondary: AppColors.sigmaGreen,
        tertiary: AppColors.sigmaPurple,
        surface: AppColors.surface,
        surfaceVariant: AppColors.surfaceVariant,
        onSurface: AppColors.neutral900,
        onSurfaceVariant: AppColors.neutral700,
        outline: AppColors.neutral300,
        shadow: Colors.black.withOpacity(0.1),
      ),
      
      // App Bar Theme
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        titleTextStyle: AppTypography.headlineMedium.copyWith(
          color: AppColors.neutral900,
        ),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(
            color: AppColors.neutral200,
            width: 1,
          ),
        ),
        margin: const EdgeInsets.all(0),
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.sigmaBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.buttonPadding,
            vertical: 12,
          ),
          minimumSize: const Size(0, AppSpacing.buttonHeight),
          textStyle: AppTypography.labelLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.sigmaBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.buttonPadding,
            vertical: 8,
          ),
          textStyle: AppTypography.labelLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(
            color: AppColors.neutral300,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(
            color: AppColors.sigmaBlue,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 12,
        ),
        labelStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.neutral600,
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.neutral500,
        ),
      ),
      
      // Dialog Theme
      dialogTheme: DialogThemeData(
        elevation: 8,
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.dialog),
        ),
        titleTextStyle: AppTypography.titleLarge.copyWith(
          color: AppColors.neutral900,
        ),
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.neutral700,
        ),
      ),
      
      // Text Theme
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge.copyWith(
          color: AppColors.neutral900,
        ),
        displayMedium: AppTypography.displayMedium.copyWith(
          color: AppColors.neutral900,
        ),
        displaySmall: AppTypography.displaySmall.copyWith(
          color: AppColors.neutral900,
        ),
        headlineLarge: AppTypography.headlineLarge.copyWith(
          color: AppColors.neutral900,
        ),
        headlineMedium: AppTypography.headlineMedium.copyWith(
          color: AppColors.neutral900,
        ),
        headlineSmall: AppTypography.headlineSmall.copyWith(
          color: AppColors.neutral900,
        ),
        titleLarge: AppTypography.titleLarge.copyWith(
          color: AppColors.neutral900,
        ),
        titleMedium: AppTypography.titleMedium.copyWith(
          color: AppColors.neutral800,
        ),
        titleSmall: AppTypography.titleSmall.copyWith(
          color: AppColors.neutral800,
        ),
        bodyLarge: AppTypography.bodyLarge.copyWith(
          color: AppColors.neutral700,
        ),
        bodyMedium: AppTypography.bodyMedium.copyWith(
          color: AppColors.neutral700,
        ),
        bodySmall: AppTypography.bodySmall.copyWith(
          color: AppColors.neutral600,
        ),
        labelLarge: AppTypography.labelLarge.copyWith(
          color: AppColors.neutral800,
        ),
        labelMedium: AppTypography.labelMedium.copyWith(
          color: AppColors.neutral600,
        ),
        labelSmall: AppTypography.labelSmall.copyWith(
          color: AppColors.neutral600,
        ),
      ),
      
      // Scaffold Background
      scaffoldBackgroundColor: AppColors.neutral50,
    );
  }
  
  // Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      // Color Scheme
      colorScheme: ColorScheme.dark(
        primary: AppColors.sigmaBlue,
        secondary: AppColors.sigmaGreen,
        tertiary: AppColors.sigmaPurple,
        surface: AppColors.neutral900,
        surfaceVariant: AppColors.neutral800,
        onSurface: AppColors.neutral100,
        onSurfaceVariant: AppColors.neutral300,
        outline: AppColors.neutral600,
        shadow: Colors.black.withOpacity(0.3),
      ),
      
      // App Bar Theme
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        titleTextStyle: AppTypography.headlineMedium.copyWith(
          color: AppColors.neutral100,
        ),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.neutral900,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(
            color: AppColors.neutral700,
            width: 1,
          ),
        ),
        margin: const EdgeInsets.all(0),
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.sigmaBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.buttonPadding,
            vertical: 12,
          ),
          minimumSize: const Size(0, AppSpacing.buttonHeight),
          textStyle: AppTypography.labelLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.sigmaGreen,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.buttonPadding,
            vertical: 8,
          ),
          textStyle: AppTypography.labelLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.neutral800,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(
            color: AppColors.neutral600,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(
            color: AppColors.sigmaGreen,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 12,
        ),
        labelStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.neutral400,
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.neutral500,
        ),
      ),
      
      // Dialog Theme
      dialogTheme: DialogThemeData(
        elevation: 8,
        backgroundColor: AppColors.neutral900,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.dialog),
        ),
        titleTextStyle: AppTypography.titleLarge.copyWith(
          color: AppColors.neutral100,
        ),
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.neutral300,
        ),
      ),
      
      // Text Theme
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge.copyWith(
          color: AppColors.neutral100,
        ),
        displayMedium: AppTypography.displayMedium.copyWith(
          color: AppColors.neutral100,
        ),
        displaySmall: AppTypography.displaySmall.copyWith(
          color: AppColors.neutral100,
        ),
        headlineLarge: AppTypography.headlineLarge.copyWith(
          color: AppColors.neutral100,
        ),
        headlineMedium: AppTypography.headlineMedium.copyWith(
          color: AppColors.neutral100,
        ),
        headlineSmall: AppTypography.headlineSmall.copyWith(
          color: AppColors.neutral100,
        ),
        titleLarge: AppTypography.titleLarge.copyWith(
          color: AppColors.neutral100,
        ),
        titleMedium: AppTypography.titleMedium.copyWith(
          color: AppColors.neutral200,
        ),
        titleSmall: AppTypography.titleSmall.copyWith(
          color: AppColors.neutral200,
        ),
        bodyLarge: AppTypography.bodyLarge.copyWith(
          color: AppColors.neutral300,
        ),
        bodyMedium: AppTypography.bodyMedium.copyWith(
          color: AppColors.neutral300,
        ),
        bodySmall: AppTypography.bodySmall.copyWith(
          color: AppColors.neutral400,
        ),
        labelLarge: AppTypography.labelLarge.copyWith(
          color: AppColors.neutral200,
        ),
        labelMedium: AppTypography.labelMedium.copyWith(
          color: AppColors.neutral400,
        ),
        labelSmall: AppTypography.labelSmall.copyWith(
          color: AppColors.neutral400,
        ),
      ),
      
      // Scaffold Background
      scaffoldBackgroundColor: AppColors.neutral900,
    );
  }
}

/// Premium Glass Morphism Styles
class GlassStyles {
  static BoxDecoration get primary => BoxDecoration(
    color: AppColors.glassBackground,
    borderRadius: BorderRadius.circular(AppRadius.card),
    border: Border.all(
      color: AppColors.glassBorder,
      width: 1,
    ),
    boxShadow: AppShadows.soft,
  );
  
  static BoxDecoration get card => BoxDecoration(
    color: Colors.white.withOpacity(0.9),
    borderRadius: BorderRadius.circular(AppRadius.card),
    border: Border.all(
      color: Colors.white.withOpacity(0.5),
      width: 1,
    ),
    boxShadow: AppShadows.soft,
  );
  
  static BoxDecoration get overlay => BoxDecoration(
    color: AppColors.glassOverlay,
    borderRadius: BorderRadius.circular(AppRadius.md),
    border: Border.all(
      color: AppColors.glassBorder,
      width: 1,
    ),
  );
}

/// Gradient Button Styles
class GradientStyles {
  static BoxDecoration get primary => BoxDecoration(
    gradient: AppColors.primaryGradient,
    borderRadius: BorderRadius.circular(AppRadius.button),
    boxShadow: [
      BoxShadow(
        color: AppColors.sigmaBlue.withOpacity(0.3),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );
  
  static BoxDecoration get success => BoxDecoration(
    gradient: AppColors.successGradient,
    borderRadius: BorderRadius.circular(AppRadius.button),
    boxShadow: AppShadows.glowAccent,
  );
  
  static BoxDecoration get warning => BoxDecoration(
    gradient: AppColors.warningGradient,
    borderRadius: BorderRadius.circular(AppRadius.button),
    boxShadow: [
      BoxShadow(
        color: AppColors.sigmaOrange.withOpacity(0.3),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );
}
