# Core Components

This folder contains reusable UI components for the SIGMA Study app.

## Components

### 📱 Navigation Bar (`navigation_bar.dart`)
- **StraightTransparentNavBar**: Main navigation bar with glassmorphism effect
- **NavBarIcon**: Individual navigation icons with selection states

#### Features:
- Transparent background with blur effect
- 4 navigation items + center FAB
- AppStyles integration for consistent theming
- Support for light/dark themes

#### Usage:
```dart
import 'core/components/components.dart';

StraightTransparentNavBar(
  selectedIndex: _selectedIndex,
  onItemTapped: (index) => setState(() => _selectedIndex = index),
  onCenterPressed: () => Navigator.push(...),
)
```

## Adding New Components

1. Create new component file in this folder
2. Export it in `components.dart`
3. Use AppStyles for consistent styling
4. Document the component here

## Design Principles

- **Consistency**: All components use AppStyles design system
- **Reusability**: Components are generic and configurable
- **Theme Support**: Components work in both light and dark themes
- **Performance**: Components use const constructors where possible