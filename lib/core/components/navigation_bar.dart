import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme/styles.dart';
import '../theme/theme_colors.dart';

class StraightTransparentNavBar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final VoidCallback onCenterPressed;
  
  const StraightTransparentNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.onCenterPressed,
  });

  @override
  StraightTransparentNavBarState createState() => StraightTransparentNavBarState();
}

class StraightTransparentNavBarState extends State<StraightTransparentNavBar> {

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      height: AppStyles.navBarHeight,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: context.foreground.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppStyles.navBarRadius),
        child: BackdropFilter(
          filter: AppStyles.glassBlur,
          child: Container(
            decoration: BoxDecoration(
              color: context.background.withOpacity(0.3),
              border: Border(
                top: BorderSide(
                  color: context.border.withOpacity(0.15),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                NavBarIcon(
                  text: "Home",
                  icon: CupertinoIcons.home,
                  selected: widget.selectedIndex == 0,
                  onPressed: () => widget.onItemTapped(0),
                  defaultColor: context.mutedForeground,
                  selectedColor: primaryColor,
                ),
                NavBarIcon(
                  text: "Calendar",
                  icon: CupertinoIcons.calendar,
                  selected: widget.selectedIndex == 1,
                  onPressed: () => widget.onItemTapped(1),
                  defaultColor: context.mutedForeground,
                  selectedColor: primaryColor,
                ),
                // Center Timer Button
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor, primaryColor.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppStyles.radiusLG),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: widget.onCenterPressed,
                    icon: Icon(
                      CupertinoIcons.timer,
                      color: context.primaryForeground,
                      size: AppStyles.navBarCenterIconSize,
                    ),
                  ),
                ),
                NavBarIcon(
                  text: "Planner",
                  icon: Icons.event_note_rounded,
                  selected: widget.selectedIndex == 2,
                  onPressed: () => widget.onItemTapped(2),
                  defaultColor: context.mutedForeground,
                  selectedColor: primaryColor,
                ),
                NavBarIcon(
                  text: "Settings",
                  icon: CupertinoIcons.settings,
                  selected: widget.selectedIndex == 3,
                  onPressed: () => widget.onItemTapped(3),
                  defaultColor: context.mutedForeground,
                  selectedColor: primaryColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NavBarIcon extends StatelessWidget {
  final String text;
  final IconData icon;
  final bool selected;
  final Function() onPressed;
  final Color defaultColor;
  final Color selectedColor;
  
  const NavBarIcon({
    super.key,
    required this.text,
    required this.icon,
    required this.selected,
    required this.onPressed,
    this.selectedColor = const Color(0xffFF8527),
    this.defaultColor = Colors.black54,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      icon: Container(
        padding: const EdgeInsets.all(AppStyles.spaceMD),
        decoration: selected ? BoxDecoration(
          color: selectedColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppStyles.radiusMD),
        ) : null,
        child: Icon(
          icon,
          size: AppStyles.navBarIconSize,
          color: selected ? selectedColor : defaultColor,
        ),
      ),
    );
  }
}