import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'core/theme/styles.dart';
import 'core/components/components.dart';
import 'core/services/app_blocking_service.dart';
import 'features/calendar/calendar_screen.dart';
import 'features/timer/timer_screen.dart';
import 'features/planner/planner_screen.dart';
import 'features/settings/settings_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize app blocking service
  await AppBlockingService.initialize();
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SIGMA Study',
      theme: AppStyles.lightTheme,
      darkTheme: AppStyles.darkTheme,
      themeMode: ThemeMode.system, // Follows system theme
      home: const MainAppWithNavigation(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainAppWithNavigation extends StatefulWidget {
  const MainAppWithNavigation({super.key});

  @override
  State<MainAppWithNavigation> createState() => _MainAppWithNavigationState();
}

class _MainAppWithNavigationState extends State<MainAppWithNavigation> with WidgetsBindingObserver {
  int _selectedIndex = 0; // Start with Home

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Ensure persistent monitoring when app starts
    AppBlockingService.ensurePersistentMonitoring();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        // App came back to foreground - ensure monitoring continues
        AppBlockingService.ensurePersistentMonitoring();
        print('App resumed - Background monitoring ensured');
        break;
      case AppLifecycleState.paused:
        // App going to background - this is when blocking should be most active
        AppBlockingService.ensurePersistentMonitoring();
        print('App paused - Background monitoring active');
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        // App minimized or closed - background service should continue
        print('App inactive/detached - Background monitoring continues');
        break;
      case AppLifecycleState.hidden:
        print('App hidden - Background monitoring continues');
        break;
    }
  }

  // Method to get current screen content
  Widget _getCurrentScreen() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomePlaceholder(); // HOME
      case 1:
        return const CalendarScreen(); // CALENDAR
      case 2:
        return const PlannerScreen(); // PLANNER
      case 3:
        return const SettingsScreen(); // SETTINGS
      default:
        return _buildHomePlaceholder();
    }
  }

  // Handle center FAB action
  void _onCenterFabPressed() {
    // Navigate to Timer screen or show timer dialog
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TimerScreen()),
    );
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
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section with SIGMA and Start Button
              Container(
                padding: const EdgeInsets.fromLTRB(
                  AppStyles.spaceXL, 
                  AppStyles.spaceLG, 
                  AppStyles.spaceXL, 
                  AppStyles.spaceXL
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // SIGMA Title with Logo
                    Expanded(
                      child: Row(
                        children: [
                          // Sigma Logo
                          Container(
                            padding: const EdgeInsets.all(AppStyles.spaceXS),
                            decoration: BoxDecoration(
                              color: AppStyles.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppStyles.radiusMD),
                            ),
                            child: Image.asset(
                              'assets/images/sigma.png',
                              width: 40,
                              height: 40,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                // Fallback to an icon if image fails to load
                                return Icon(
                                  Icons.psychology_rounded,
                                  size: 32,
                                  color: AppStyles.primary,
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: AppStyles.spaceMD),
                          // SIGMA Text
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RichText(
                                  text: TextSpan(
                                    style: AppStyles.screenTitle.copyWith(
                                      height: 1.1,
                                      letterSpacing: -0.5,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'SIGMA\n',
                                        style: TextStyle(
                                          color: AppStyles.primary,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      TextSpan(
                                        text: 'Your Study Mate',
                                        style: TextStyle(
                                          color: AppStyles.foreground,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Start Button
                    ElevatedButton(
                      onPressed: () => _onCenterFabPressed(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppStyles.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppStyles.spaceLG,
                          vertical: AppStyles.spaceMD
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppStyles.radiusXL),
                        ),
                        elevation: 2,
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.timer_rounded, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Start',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppStyles.spaceXL),

              // Dashboard Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppStyles.spaceXL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Today's Overview
                    Text(
                      'Today\'s Overview',
                      style: AppStyles.sectionHeader.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppStyles.spaceMD),
                    
                    // Stats Row - Responsive
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth > 600) {
                          // Wide screen: 4 cards in a row
                          return Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  title: 'Study Time',
                                  value: '2h 45m',
                                  subtitle: 'Today',
                                  icon: Icons.timer_rounded,
                                  color: TimerStyles.focusColor,
                                ),
                              ),
                              const SizedBox(width: AppStyles.spaceSM),
                              Expanded(
                                child: _buildStatCard(
                                  title: 'Sessions',
                                  value: '4',
                                  subtitle: 'Completed',
                                  icon: Icons.check_circle_rounded,
                                  color: AppStyles.success,
                                ),
                              ),
                              const SizedBox(width: AppStyles.spaceSM),
                              Expanded(
                                child: _buildStatCard(
                                  title: 'Focus Score',
                                  value: '87%',
                                  subtitle: 'This week',
                                  icon: Icons.psychology_rounded,
                                  color: PlannerStyles.subjectColor,
                                ),
                              ),
                              const SizedBox(width: AppStyles.spaceSM),
                              Expanded(
                                child: _buildStatCard(
                                  title: 'Streak',
                                  value: '12',
                                  subtitle: 'Days',
                                  icon: Icons.local_fire_department_rounded,
                                  color: AppStyles.warning,
                                ),
                              ),
                            ],
                          );
                        } else {
                          // Mobile: 2 cards in a row, 2 rows
                          return Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatCard(
                                      title: 'Study Time',
                                      value: '2h 45m',
                                      subtitle: 'Today',
                                      icon: Icons.timer_rounded,
                                      color: TimerStyles.focusColor,
                                    ),
                                  ),
                                  const SizedBox(width: AppStyles.spaceSM),
                                  Expanded(
                                    child: _buildStatCard(
                                      title: 'Sessions',
                                      value: '4',
                                      subtitle: 'Completed',
                                      icon: Icons.check_circle_rounded,
                                      color: AppStyles.success,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppStyles.spaceSM),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatCard(
                                      title: 'Focus Score',
                                      value: '87%',
                                      subtitle: 'This week',
                                      icon: Icons.psychology_rounded,
                                      color: PlannerStyles.subjectColor,
                                    ),
                                  ),
                                  const SizedBox(width: AppStyles.spaceSM),
                                  Expanded(
                                    child: _buildStatCard(
                                      title: 'Streak',
                                      value: '12',
                                      subtitle: 'Days',
                                      icon: Icons.local_fire_department_rounded,
                                      color: AppStyles.warning,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        }
                      },
                    ),
                    
                    const SizedBox(height: AppStyles.spaceXL),
                    
                    // Weekly Progress - Shadcn Style
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppStyles.spaceLG),
                      decoration: BoxDecoration(
                        color: AppStyles.card,
                        borderRadius: BorderRadius.circular(AppStyles.radiusMD),
                        border: Border.all(
                          color: AppStyles.border,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppStyles.black.withOpacity(0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.trending_up_rounded,
                                color: AppStyles.mutedForeground,
                                size: 18,
                              ),
                              const SizedBox(width: AppStyles.spaceXS),
                              Text(
                                'Weekly Progress',
                                style: AppStyles.subsectionHeader.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppStyles.spaceMD),
                          _buildProgressBar('Mathematics', 0.85, AppStyles.primary),
                          const SizedBox(height: AppStyles.spaceSM),
                          _buildProgressBar('Physics', 0.72, CalendarStyles.eventColor),
                          const SizedBox(height: AppStyles.spaceSM),
                          _buildProgressBar('Chemistry', 0.68, PlannerStyles.subjectColor),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: AppStyles.spaceXL),
                    
                    // Today's Schedule - Shadcn Style
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppStyles.spaceLG),
                      decoration: BoxDecoration(
                        color: AppStyles.card,
                        borderRadius: BorderRadius.circular(AppStyles.radiusMD),
                        border: Border.all(
                          color: AppStyles.border,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppStyles.black.withOpacity(0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.schedule_rounded,
                                color: AppStyles.mutedForeground,
                                size: 18,
                              ),
                              const SizedBox(width: AppStyles.spaceXS),
                              Text(
                                'Today\'s Schedule',
                                style: AppStyles.subsectionHeader.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'Oct 5',
                                style: AppStyles.bodySmall.copyWith(
                                  color: AppStyles.mutedForeground,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppStyles.spaceMD),
                          _buildScheduleItem('09:00', 'Mathematics', 'Calculus Review', AppStyles.primary),
                          _buildScheduleItem('11:00', 'Physics', 'Quantum Mechanics', CalendarStyles.eventColor),
                          _buildScheduleItem('14:00', 'Chemistry', 'Organic Chemistry Lab', PlannerStyles.subjectColor),
                          _buildScheduleItem('16:00', 'Break', 'Free time', AppStyles.mutedForeground, isBreak: true),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: AppStyles.spaceXL),
                    
                    // Quick Insights - Shadcn Style
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppStyles.spaceLG),
                      decoration: BoxDecoration(
                        color: AppStyles.accent.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(AppStyles.radiusMD),
                        border: Border.all(
                          color: AppStyles.primary.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppStyles.spaceXS),
                            decoration: BoxDecoration(
                              color: AppStyles.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppStyles.radiusSM),
                            ),
                            child: Icon(
                              Icons.lightbulb_rounded,
                              color: AppStyles.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: AppStyles.spaceSM),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Study Tip',
                                  style: AppStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppStyles.primary,
                                  ),
                                ),
                                const SizedBox(height: AppStyles.spaceXS),
                                Text(
                                  'You\'re on track! Consider taking a 15-minute break between sessions for optimal focus.',
                                  style: AppStyles.bodySmall.copyWith(
                                    color: AppStyles.foreground,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppStyles.spaceXXL * 2), // Extra space for navbar
            ],
          ),
        ),
      ),
    );
  }

  // Stat Card Helper - Shadcn Style
  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppStyles.spaceLG),
      decoration: BoxDecoration(
        color: AppStyles.card,
        borderRadius: BorderRadius.circular(AppStyles.radiusMD),
        border: Border.all(
          color: AppStyles.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppStyles.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppStyles.mutedForeground,
                ),
              ),
              Icon(
                icon,
                color: AppStyles.mutedForeground,
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: AppStyles.spaceXS),
          Text(
            value,
            style: AppStyles.sectionHeader.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.0,
              fontSize: 22,
            ),
          ),
          Text(
            subtitle,
            style: AppStyles.bodySmall.copyWith(
              color: AppStyles.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }

  // Progress Bar Helper - Shadcn Style
  Widget _buildProgressBar(String subject, double progress, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              subject,
              style: AppStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: AppStyles.bodySmall.copyWith(
                color: AppStyles.mutedForeground,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppStyles.spaceXS),
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: AppStyles.muted,
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Schedule Item Helper - Shadcn Style
  Widget _buildScheduleItem(String time, String subject, String topic, Color color, {bool isBreak = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppStyles.spaceSM),
      child: Row(
        children: [
          Container(
            width: 50,
            padding: const EdgeInsets.symmetric(
              vertical: AppStyles.spaceXS,
              horizontal: AppStyles.spaceXS,
            ),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppStyles.radiusSM),
            ),
            child: Text(
              time,
              style: AppStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w500,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: AppStyles.spaceSM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject,
                  style: AppStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                    color: isBreak ? AppStyles.mutedForeground : AppStyles.foreground,
                  ),
                ),
                if (!isBreak && topic.isNotEmpty) ...[
                  Text(
                    topic,
                    style: AppStyles.bodySmall.copyWith(
                      color: AppStyles.mutedForeground,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!isBreak)
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }







  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: _getCurrentScreen(),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(
          bottom: AppStyles.navBarMargin, 
          left: AppStyles.navBarMargin, 
          right: AppStyles.navBarMargin
        ),
        child: StraightTransparentNavBar(
          selectedIndex: _selectedIndex,
          onItemTapped: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          onCenterPressed: _onCenterFabPressed,
        ),
      ),
    );
  }
}



