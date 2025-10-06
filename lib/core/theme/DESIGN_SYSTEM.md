# SIGMA Study App - Modern Design System

## Tailwind CSS Inspired Design System

The `AppStyles` class has been updated with a modern green-themed design system inspired by Tailwind CSS v4, sourced from tweakcn.com.

## 🎨 Color Palette

### Light Theme Primary Colors
```dart
AppStyles.background         // #F0F8FF - Alice Blue background
AppStyles.foreground         // #374151 - Dark grey text
AppStyles.card               // #FFFFFF - White cards
AppStyles.primary            // #22C55E - Vibrant green (main brand)
AppStyles.primaryForeground  // #FFFFFF - White text on primary
```

### Secondary & Accent Colors
```dart
AppStyles.secondary          // #E0F2FE - Light cyan
AppStyles.secondaryForeground // #4B5563 - Grey text on secondary
AppStyles.accent             // #D1FAE5 - Light green accent
AppStyles.accentForeground   // #374151 - Dark text on accent
```

### Status Colors
```dart
AppStyles.success            // #22C55E - Success green (same as primary)
AppStyles.warning            // #F59E0B - Amber warning
AppStyles.info               // #3B82F6 - Blue info
AppStyles.destructive        // #EF4444 - Red destructive actions
```

### UI Element Colors
```dart
AppStyles.border             // #E5E7EB - Light border
AppStyles.input              // #E5E7EB - Input field borders
AppStyles.ring               // #22C55E - Focus ring (primary green)
AppStyles.muted              // #F3F4F6 - Muted background
AppStyles.mutedForeground    // #6B7280 - Muted text
```

### Chart Colors (Green Variations)
```dart
AppStyles.chart1             // #22C55E - Primary green
AppStyles.chart2             // #10B981 - Emerald
AppStyles.chart3             // #059669 - Darker emerald
AppStyles.chart4             // #047857 - Even darker emerald
AppStyles.chart5             // #065F46 - Darkest emerald
```

## 🌙 Dark Theme Support

The app now includes a comprehensive dark theme:

```dart
AppStyles.darkBackground     // #0F172A - Slate 900
AppStyles.darkForeground     // #D1D5DB - Light grey text
AppStyles.darkCard           // #1E293B - Slate 800
AppStyles.darkPrimary        // #34D399 - Lighter green for dark mode
AppStyles.darkBorder         // #4B5563 - Medium grey borders
```

## 📏 Updated Spacing & Radius

### Border Radius (Matching Tailwind CSS)
```dart
AppStyles.radius             // 8.0px - Base radius (0.5rem)
AppStyles.radiusSM           // 4.0px - Small radius (radius - 4px)
AppStyles.radiusMD           // 6.0px - Medium radius (radius - 2px)
AppStyles.radiusLG           // 8.0px - Large radius (base)
AppStyles.radiusXL           // 12.0px - Extra large (radius + 4px)
AppStyles.radiusRound        // 100.0px - Fully rounded
```

### Box Shadows (Tailwind CSS Inspired)
```dart
AppStyles.shadowXS           // Extra small shadow
AppStyles.shadowSM           // Small shadow with dual layers
AppStyles.shadowMD           // Medium shadow
AppStyles.shadowLG           // Large shadow
AppStyles.shadowXL           // Extra large shadow
AppStyles.shadow2XL          // 2XL shadow
```

## 🎯 Feature-Specific Colors

### Timer Colors
```dart
TimerStyles.focusColor       // #22C55E - Green for focus sessions
TimerStyles.breakColor       // #F59E0B - Amber for breaks
AppStyles.timerPause         // #6B7280 - Grey for paused state
```

### Calendar Colors
```dart
CalendarStyles.todayColor    // #22C55E - Primary green for today
CalendarStyles.eventColor    // #3B82F6 - Blue for events
AppStyles.calendarWeekend    // #6B7280 - Grey for weekends
```

### Planner Colors
```dart
PlannerStyles.subjectColor   // #8B5CF6 - Purple for subjects
PlannerStyles.taskColor      // #22C55E - Green for tasks
AppStyles.plannerOverdue     // #EF4444 - Red for overdue items
```

### Settings Colors
```dart
SettingsStyles.settingColor  // #6B7280 - Grey for sections
AppStyles.settingsActive     // #22C55E - Green for active settings
```

## 🎨 Theme Usage

### Automatic Theme Switching
The app now supports automatic theme switching based on system preferences:

```dart
MaterialApp(
  theme: AppStyles.lightTheme,
  darkTheme: AppStyles.darkTheme,
  themeMode: ThemeMode.system, // Follows system theme
)
```

### Manual Theme Selection
You can also force a specific theme:

```dart
// Force light theme
themeMode: ThemeMode.light

// Force dark theme  
themeMode: ThemeMode.dark
```

## ✨ Modern Features

### Glassmorphism Support
The glassmorphism effects have been maintained with the new color scheme:

```dart
AppStyles.glassContainer(
  child: YourWidget(),
  padding: EdgeInsets.all(AppStyles.spaceLG),
  borderRadius: AppStyles.radiusXL,
)
```

### Enhanced Shadows
New shadow system matching Tailwind CSS:

```dart
Container(
  decoration: BoxDecoration(
    boxShadow: AppStyles.shadowLG, // Modern layered shadows
    borderRadius: BorderRadius.circular(AppStyles.radiusLG),
  ),
)
```

### Consistent Typography
All text styles updated to work with both light and dark themes:

```dart
Text('Title', style: AppStyles.screenTitle)  // Adapts to theme
Text('Body', style: AppStyles.bodyMedium)    // Theme-aware colors
```

## 🚀 Migration Benefits

### From Old System
- **Better contrast ratios** for accessibility
- **Modern green theme** instead of blue
- **Comprehensive dark mode** support
- **Tailwind CSS consistency** for web familiarity
- **Enhanced shadows** with multiple layers
- **Improved typography** hierarchy

### Performance
- All colors are `const` for better performance
- Efficient theme switching
- Optimized shadow calculations
- Cached decorations and styles

This updated design system provides a modern, accessible, and maintainable foundation for your SIGMA Study app! 🎨✨