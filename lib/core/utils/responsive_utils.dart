import 'package:flutter/material.dart';

/// Responsive utilities for creating adaptive layouts across all screen sizes
/// Supports mobile, tablet, and desktop breakpoints with Material 3 design principles
class ResponsiveUtils {
  ResponsiveUtils._();

  // Breakpoints following Material 3 guidelines
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 840;
  static const double desktopBreakpoint = 1200;

  // Screen size categories
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreakpoint;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileBreakpoint &&
      MediaQuery.of(context).size.width < desktopBreakpoint;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktopBreakpoint;

  static bool isSmallMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 360;

  static bool isLargeMobile(BuildContext context) =>
      MediaQuery.of(context).size.width >= 360 &&
      MediaQuery.of(context).size.width < mobileBreakpoint;

  // Responsive values based on screen size
  static T responsive<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context)) return desktop ?? tablet ?? mobile;
    if (isTablet(context)) return tablet ?? mobile;
    return mobile;
  }

  // Responsive padding
  static EdgeInsets responsivePadding(BuildContext context) {
    return responsive(
      context,
      mobile: const EdgeInsets.all(16),
      tablet: const EdgeInsets.all(24),
      desktop: const EdgeInsets.all(32),
    );
  }

  // Responsive horizontal padding
  static EdgeInsets responsiveHorizontalPadding(BuildContext context) {
    return responsive(
      context,
      mobile: const EdgeInsets.symmetric(horizontal: 16),
      tablet: const EdgeInsets.symmetric(horizontal: 32),
      desktop: const EdgeInsets.symmetric(horizontal: 48),
    );
  }

  // Responsive content width (for centering content on large screens)
  static double getContentWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return responsive(
      context,
      mobile: screenWidth,
      tablet: screenWidth * 0.85,
      desktop: screenWidth.clamp(0, 1200),
    );
  }

  // Responsive dialog width
  static double getDialogWidth(BuildContext context) {
    return responsive(
      context,
      mobile: MediaQuery.of(context).size.width * 0.9,
      tablet: 600,
      desktop: 700,
    );
  }

  // Responsive font scaling
  static double getFontScale(BuildContext context) {
    return responsive(
      context,
      mobile: 1.0,
      tablet: 1.1,
      desktop: 1.2,
    );
  }

  // Responsive spacing
  static double getSpacing(BuildContext context, double baseSpacing) {
    return responsive(
      context,
      mobile: baseSpacing,
      tablet: baseSpacing * 1.2,
      desktop: baseSpacing * 1.4,
    );
  }

  // Grid column count based on screen size
  static int getGridColumns(BuildContext context) {
    return responsive(
      context,
      mobile: 1,
      tablet: 2,
      desktop: 3,
    );
  }

  // Responsive card width for grid layouts
  static double getCardWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return responsive(
      context,
      mobile: screenWidth - 32,
      tablet: (screenWidth - 64) / 2 - 12,
      desktop: (screenWidth.clamp(0, 1200) - 96) / 3 - 16,
    );
  }

  // Safe area insets for different screen orientations
  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return EdgeInsets.only(
      left: mediaQuery.padding.left + 16,
      right: mediaQuery.padding.right + 16,
      top: mediaQuery.padding.top + 8,
      bottom: mediaQuery.padding.bottom + 16,
    );
  }

  // Responsive app bar height
  static double getAppBarHeight(BuildContext context) {
    return responsive(
      context,
      mobile: kToolbarHeight,
      tablet: kToolbarHeight + 8,
      desktop: kToolbarHeight + 16,
    );
  }

  // Responsive bottom navigation height
  static double getBottomNavHeight(BuildContext context) {
    return responsive(
      context,
      mobile: kBottomNavigationBarHeight,
      tablet: kBottomNavigationBarHeight + 8,
      desktop: kBottomNavigationBarHeight + 16,
    );
  }

  // Responsive timer circle size
  static double getTimerCircleSize(BuildContext context) {
    return responsive(
      context,
      mobile: 280,
      tablet: 340,
      desktop: 400,
    );
  }

  // Responsive modal constraints
  static BoxConstraints getModalConstraints(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return BoxConstraints(
      maxWidth: getDialogWidth(context),
      maxHeight: screenSize.height * 0.8,
      minHeight: 200,
    );
  }

  // Check if device is in landscape mode
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  // Get responsive layout direction for flex widgets
  static Axis getFlexDirection(BuildContext context) {
    return isLandscape(context) && isMobile(context) ? Axis.horizontal : Axis.vertical;
  }

  // Responsive text scaling for accessibility
  static TextStyle scaleTextStyle(BuildContext context, TextStyle style) {
    final scale = getFontScale(context);
    return style.copyWith(
      fontSize: (style.fontSize ?? 14) * scale,
    );
  }
}

/// Extension to easily access responsive utilities from BuildContext
extension ResponsiveExtension on BuildContext {
  bool get isMobile => ResponsiveUtils.isMobile(this);
  bool get isTablet => ResponsiveUtils.isTablet(this);
  bool get isDesktop => ResponsiveUtils.isDesktop(this);
  bool get isSmallMobile => ResponsiveUtils.isSmallMobile(this);
  bool get isLargeMobile => ResponsiveUtils.isLargeMobile(this);
  bool get isLandscape => ResponsiveUtils.isLandscape(this);
  
  EdgeInsets get responsivePadding => ResponsiveUtils.responsivePadding(this);
  EdgeInsets get responsiveHorizontalPadding => ResponsiveUtils.responsiveHorizontalPadding(this);
  double get contentWidth => ResponsiveUtils.getContentWidth(this);
  double get dialogWidth => ResponsiveUtils.getDialogWidth(this);
  double get fontScale => ResponsiveUtils.getFontScale(this);
  int get gridColumns => ResponsiveUtils.getGridColumns(this);
  double get cardWidth => ResponsiveUtils.getCardWidth(this);
  double get timerCircleSize => ResponsiveUtils.getTimerCircleSize(this);
  BoxConstraints get modalConstraints => ResponsiveUtils.getModalConstraints(this);
  Axis get flexDirection => ResponsiveUtils.getFlexDirection(this);
  
  T responsive<T>({
    required T mobile,
    T? tablet,
    T? desktop,
  }) => ResponsiveUtils.responsive(this, mobile: mobile, tablet: tablet, desktop: desktop);
  
  double spacing(double baseSpacing) => ResponsiveUtils.getSpacing(this, baseSpacing);
  TextStyle scaleTextStyle(TextStyle style) => ResponsiveUtils.scaleTextStyle(this, style);
}