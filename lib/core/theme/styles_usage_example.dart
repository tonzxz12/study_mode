// Example of how to use AppStyles throughout your app

import 'package:flutter/material.dart';
import 'styles.dart';

class StylesUsageExample extends StatelessWidget {
  const StylesUsageExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.grey50,
      appBar: AppBar(
        title: Text(
          'SIGMA Study',
          style: AppStyles.screenTitle,
        ),
        backgroundColor: AppStyles.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppStyles.spaceLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Text(
              'Today\'s Progress',
              style: AppStyles.sectionHeader,
            ),
            const SizedBox(height: AppStyles.spaceMD),
            
            // Card using styles
            Container(
              decoration: AppStyles.cardDecoration,
              padding: const EdgeInsets.all(AppStyles.cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Study Session',
                    style: AppStyles.bodyLarge,
                  ),
                  const SizedBox(height: AppStyles.spaceSM),
                  Text(
                    'Focus time: 25 minutes',
                    style: AppStyles.bodyMedium,
                  ),
                  const SizedBox(height: AppStyles.spaceSM),
                  Text(
                    'Status: Active',
                    style: AppStyles.statusActive,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppStyles.spaceLG),
            
            // Timer-specific styles example
            Container(
              decoration: AppStyles.cardDecoration,
              padding: const EdgeInsets.all(AppStyles.cardPadding),
              child: Column(
                children: [
                  Text(
                    '25:00',
                    style: TimerStyles.timerText,
                  ),
                  const SizedBox(height: AppStyles.spaceSM),
                  Text(
                    'Focus Session',
                    style: TimerStyles.sessionText,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppStyles.spaceLG),
            
            // Glassmorphism container example
            AppStyles.glassContainer(
              padding: const EdgeInsets.all(AppStyles.spaceLG),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Icon(
                    Icons.home,
                    color: AppStyles.glassIconDefault,
                    size: AppStyles.navBarIconSize,
                  ),
                  Icon(
                    Icons.calendar_today,
                    color: AppStyles.primaryBlue,
                    size: AppStyles.navBarIconSize,
                  ),
                  Icon(
                    Icons.timer,
                    color: AppStyles.glassIconDefault,
                    size: AppStyles.navBarIconSize,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppStyles.spaceLG),
            
            // Buttons using theme
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    child: const Text('Start Timer'),
                  ),
                ),
                const SizedBox(width: AppStyles.spaceMD),
                Expanded(
                  child: TextButton(
                    onPressed: () {},
                    child: const Text('Settings'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Example of custom themed widgets
class CustomCard extends StatelessWidget {
  final Widget child;
  final String? title;
  
  const CustomCard({
    super.key,
    required this.child,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppStyles.cardDecoration,
      padding: const EdgeInsets.all(AppStyles.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: AppStyles.subsectionHeader,
            ),
            const SizedBox(height: AppStyles.spaceMD),
          ],
          child,
        ],
      ),
    );
  }
}

class FeatureButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  
  const FeatureButton({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.8),
            color,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppStyles.radiusMD),
        boxShadow: AppStyles.shadowMedium,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppStyles.radiusMD),
          child: Container(
            padding: const EdgeInsets.all(AppStyles.spaceLG),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: AppStyles.white,
                  size: 32,
                ),
                const SizedBox(height: AppStyles.spaceSM),
                Text(
                  title,
                  style: AppStyles.buttonText,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}