# SIGMA Study App - Design System Documentation

## AppStyles Usage Guide

The `AppStyles` class in `lib/core/theme/styles.dart` contains all the design tokens and styling for your SIGMA Study app.

## 🎨 Color Palette

### Primary Colors
```dart
AppStyles.primaryBlue        // Main brand color
AppStyles.primaryBlueLight   // Lighter variant
AppStyles.primaryBlueDark    // Darker variant
```

### Feature Colors
```dart
AppStyles.timerGreen         // Timer focus sessions
AppStyles.timerRed           // Timer break sessions
AppStyles.calendarBlue       // Calendar events
AppStyles.plannerPurple      // Planner items
AppStyles.settingsGrey       // Settings items
```

### Neutral Colors
```dart
AppStyles.white              // Pure white
AppStyles.black              // Pure black
AppStyles.grey50             // Background color
AppStyles.grey100 to grey900 // Various grey shades
```

### Glassmorphism Colors
```dart
AppStyles.glassBg            // Transparent background
AppStyles.glassBorder        // Border for glass effect
AppStyles.glassIconDefault   // Default icon color on glass
AppStyles.glassIconSelected  // Selected icon color on glass
```

## 📝 Typography

### Headers
```dart
AppStyles.screenTitle        // Main screen titles (28px, bold)
AppStyles.sectionHeader      // Section headers (20px, bold)
AppStyles.subsectionHeader   // Subsection headers (18px, w600)
```

### Body Text
```dart
AppStyles.bodyLarge          // Large body text (16px)
AppStyles.bodyMedium         // Medium body text (14px)
AppStyles.bodySmall          // Small body text (12px)
AppStyles.caption            // Caption text (12px, grey)
```

### Buttons
```dart
AppStyles.buttonText         // Primary button text
AppStyles.buttonTextSecondary // Secondary button text
```

## 📏 Spacing & Dimensions

### Spacing
```dart
AppStyles.spaceXS            // 4px
AppStyles.spaceSM            // 8px
AppStyles.spaceMD            // 16px
AppStyles.spaceLG            // 24px
AppStyles.spaceXL            // 32px
AppStyles.spaceXXL           // 40px
```

### Border Radius
```dart
AppStyles.radiusXS           // 4px
AppStyles.radiusSM           // 8px
AppStyles.radiusMD           // 12px
AppStyles.radiusLG           // 16px
AppStyles.radiusXL           // 20px
AppStyles.radiusXXL          // 24px
AppStyles.radiusRound        // 100px (circular)
```

### Navigation Bar
```dart
AppStyles.navBarHeight       // 70px
AppStyles.navBarRadius       // 25px
AppStyles.navBarMargin       // 20px
AppStyles.navBarIconSize     // 24px
```

## 🎨 Decorations & Effects

### Standard Decorations
```dart
AppStyles.cardDecoration     // Standard card styling
AppStyles.glassDecoration    // Glassmorphism container
AppStyles.navBarDecoration   // Navigation bar styling
AppStyles.selectedNavIconDecoration // Selected nav icon styling
```

### Shadows
```dart
AppStyles.shadowLight        // Light shadow for cards
AppStyles.shadowMedium       // Medium shadow for elevated elements
AppStyles.shadowHeavy        // Heavy shadow for prominent elements
AppStyles.glassShadows       // Shadows for glassmorphism
```

### Blur Effects
```dart
AppStyles.glassBlur          // Standard blur (15px)
AppStyles.glassBlurHeavy     // Heavy blur (20px)
```

## 🎨 Gradients
```dart
AppStyles.primaryGradient    // Blue gradient
AppStyles.secondaryGradient  // Purple-blue gradient
AppStyles.successGradient    // Green gradient
AppStyles.warningGradient    // Orange gradient
```

## 🛠️ Helper Methods

### Glassmorphism Container
```dart
AppStyles.glassContainer(
  child: YourWidget(),
  padding: EdgeInsets.all(20),
  borderRadius: 25,
  blurSigma: 15,
)
```

### Responsive Sizing
```dart
AppStyles.getResponsiveTextSize(context, 16.0)
AppStyles.getResponsiveSpacing(context, 20.0)
```

### Color with Opacity
```dart
AppStyles.withOpacity(AppStyles.primaryBlue, 0.5)
```

## 🎯 Feature-Specific Styles

### Timer Styles
```dart
TimerStyles.focusColor       // Green for focus sessions
TimerStyles.breakColor       // Red for break sessions
TimerStyles.timerText        // Large timer display text
TimerStyles.sessionText      // Session type text
```

### Calendar Styles
```dart
CalendarStyles.eventColor    // Event background color
CalendarStyles.todayColor    // Today indicator color
CalendarStyles.dateText      // Date number text
CalendarStyles.eventText     // Event text on colored background
```

### Planner Styles
```dart
PlannerStyles.subjectColor   // Subject header color
PlannerStyles.taskColor      // Task text color
PlannerStyles.subjectText    // Subject title text style
PlannerStyles.taskText       // Task item text style
```

### Settings Styles
```dart
SettingsStyles.settingColor  // Settings icon color
SettingsStyles.settingTitle  // Setting option title
SettingsStyles.settingSubtitle // Setting option description
```

## 📱 Usage Examples

### Basic Card
```dart
Container(
  decoration: AppStyles.cardDecoration,
  padding: EdgeInsets.all(AppStyles.cardPadding),
  child: Column(
    children: [
      Text('Title', style: AppStyles.subsectionHeader),
      SizedBox(height: AppStyles.spaceMD),
      Text('Content', style: AppStyles.bodyMedium),
    ],
  ),
)
```

### Glassmorphism Container
```dart
AppStyles.glassContainer(
  padding: EdgeInsets.all(AppStyles.spaceLG),
  child: Row(
    children: [
      Icon(Icons.home, color: AppStyles.glassIconDefault),
      SizedBox(width: AppStyles.spaceMD),
      Text('Home', style: AppStyles.bodyMedium),
    ],
  ),
)
```

### Themed Button
```dart
ElevatedButton(
  onPressed: () {},
  style: ElevatedButton.styleFrom(
    backgroundColor: AppStyles.primaryBlue,
    padding: EdgeInsets.symmetric(
      horizontal: AppStyles.spaceLG,
      vertical: AppStyles.spaceMD,
    ),
  ),
  child: Text('Button', style: AppStyles.buttonText),
)
```

## 🎨 App Theme
The app uses `AppStyles.lightTheme` which automatically applies these styles to Material components.

```dart
MaterialApp(
  theme: AppStyles.lightTheme,
  home: YourHomePage(),
)
```

This ensures consistent styling across all Material widgets like buttons, cards, text fields, etc.

## 🔄 Future Enhancements
- Dark theme support (`AppStyles.darkTheme`)
- Additional color schemes
- Animation curves and durations
- Platform-specific adjustments
- Accessibility improvements