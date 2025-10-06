import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/navigation_provider.dart';
import '../../features/timer/timer_screen.dart';
import '../../features/calendar/calendar_screen.dart';
import '../../features/planner/planner_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../theme/styles.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationProvider);
    
    return Scaffold(
      body: _getPage(currentIndex),
      bottomNavigationBar: CurvedBottomNavBar(
        currentIndex: currentIndex,
        onTap: (index) {
          ref.read(navigationProvider.notifier).setIndex(index);
        },
      ),
    );
  }

  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return _buildHomePlaceholder();
      case 1:
        return const CalendarScreen();
      case 2:
        return const PlannerScreen();
      case 3:
        return const SettingsScreen();
      default:
        return _buildHomePlaceholder();
    }
  }

  Widget _buildHomePlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppStyles.primary.withOpacity(0.05),
            AppStyles.background,
          ],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.home,
                size: 64,
                color: AppStyles.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Home',
                style: AppStyles.screenTitle,
              ),
              const SizedBox(height: 8),
              Text(
                'Welcome to SIGMA Study',
                style: AppStyles.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CurvedBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CurvedBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: CustomPaint(
        painter: CurvedNavPainter(
          backgroundColor: Theme.of(context).colorScheme.surface,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              context: context,
              index: 0,
              icon: CupertinoIcons.home,
              label: 'Home',
            ),
            _buildNavItem(
              context: context,
              index: 1,
              icon: CupertinoIcons.chart_bar_square,
              label: 'Dashboard',
            ),
            // Center floating action button
            Container(
              width: 60,
              height: 60,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: () => onTap(2),
                icon: Icon(
                  CupertinoIcons.timer,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: 28,
                ),
              ),
            ),
            _buildNavItem(
              context: context,
              index: 3,
              icon: CupertinoIcons.calendar,
              label: 'Calendar',
            ),
            _buildNavItem(
              context: context,
              index: 4,
              icon: CupertinoIcons.settings,
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = currentIndex == index;
    final color = isSelected 
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurface.withOpacity(0.6);
    
    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected 
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: isSelected ? 26 : 22,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CurvedNavPainter extends CustomPainter {
  final Color backgroundColor;

  CurvedNavPainter({required this.backgroundColor});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    Path path = Path();
    
    // Start from left
    path.moveTo(0, 20);
    
    // Curve to center-left
    path.quadraticBezierTo(size.width * 0.2, 0, size.width * 0.35, 0);
    
    // Create the curve for FAB
    path.quadraticBezierTo(size.width * 0.4, 0, size.width * 0.4, 20);
    path.arcToPoint(
      Offset(size.width * 0.6, 20),
      radius: const Radius.circular(20),
      clockwise: false,
    );
    path.quadraticBezierTo(size.width * 0.6, 0, size.width * 0.65, 0);
    
    // Curve to right
    path.quadraticBezierTo(size.width * 0.8, 0, size.width, 20);
    
    // Complete the rectangle
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}