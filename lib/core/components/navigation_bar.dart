import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme/styles.dart';

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
      decoration: AppStyles.navBarDecoration,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppStyles.navBarRadius),
        child: BackdropFilter(
          filter: AppStyles.glassBlur,
          child: Container(
            decoration: AppStyles.glassDecoration,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                NavBarIcon(
                  text: "Home",
                  icon: CupertinoIcons.home,
                  selected: widget.selectedIndex == 0,
                  onPressed: () => widget.onItemTapped(0),
                  defaultColor: AppStyles.glassIconDefault,
                  selectedColor: primaryColor,
                ),
                NavBarIcon(
                  text: "Calendar",
                  icon: CupertinoIcons.calendar,
                  selected: widget.selectedIndex == 1,
                  onPressed: () => widget.onItemTapped(1),
                  defaultColor: AppStyles.glassIconDefault,
                  selectedColor: primaryColor,
                ),
                // Center Timer Button
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: AppStyles.fabDecoration(primaryColor),
                  child: IconButton(
                    onPressed: widget.onCenterPressed,
                    icon: Icon(
                      CupertinoIcons.timer,
                      color: AppStyles.white,
                      size: AppStyles.navBarCenterIconSize,
                    ),
                  ),
                ),
                NavBarIcon(
                  text: "Planner",
                  icon: Icons.event_note_rounded,
                  selected: widget.selectedIndex == 2,
                  onPressed: () => widget.onItemTapped(2),
                  defaultColor: AppStyles.glassIconDefault,
                  selectedColor: primaryColor,
                ),
                NavBarIcon(
                  text: "Settings",
                  icon: CupertinoIcons.settings,
                  selected: widget.selectedIndex == 3,
                  onPressed: () => widget.onItemTapped(3),
                  defaultColor: AppStyles.glassIconDefault,
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
        decoration: selected ? AppStyles.selectedNavIconDecoration : null,
        child: Icon(
          icon,
          size: AppStyles.navBarIconSize,
          color: selected ? selectedColor : defaultColor,
        ),
      ),
    );
  }
}