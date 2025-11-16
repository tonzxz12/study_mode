import 'dart:math';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'firebase_options.dart';
import 'data/models/subject.dart';
import 'data/models/study_session.dart';
import 'data/models/app_settings.dart';
import 'data/models/task.dart';
import 'data/models/calendar_event.dart';
import 'data/models/user.dart';
import 'data/models/app_blocking_settings.dart';
import 'data/adapters/duration_adapter.dart';
import 'data/services/data_sync_service.dart';
import 'data/services/app_blocking_settings_service.dart';
import 'core/services/firestore_service.dart';
import 'data/services/calendar_service.dart';

import 'core/theme/styles.dart';
import 'core/theme/theme_colors.dart';
import 'core/components/components.dart';
import 'core/utils/responsive_utils.dart';
import 'core/providers/theme_provider.dart';

import 'features/calendar/calendar_screen.dart';
import 'features/timer/timer_screen.dart';
import 'features/planner/planner_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/auth/auth_wrapper.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive for local data storage
  await Hive.initFlutter();
  
  // Register Hive adapters
  Hive.registerAdapter(SubjectAdapter());
  Hive.registerAdapter(StudySessionAdapter());
  Hive.registerAdapter(AppSettingsAdapter());
  Hive.registerAdapter(TaskAdapter());
  Hive.registerAdapter(CalendarEventAdapter());
  Hive.registerAdapter(UserAdapter());
  Hive.registerAdapter(AppBlockingSettingsAdapter());
  Hive.registerAdapter(DurationAdapter());
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize DataSyncService for hybrid local/cloud storage
  try {
    await DataSyncService.initialize();
    print('✅ DataSyncService initialized for student data collection');
  } catch (e) {
    print('⚠️ DataSyncService initialization failed: $e');
  }
  
  // Initialize AppBlockingSettingsService
  try {
    await AppBlockingSettingsService.initialize();
    print('✅ AppBlockingSettingsService initialized');
  } catch (e) {
    print('⚠️ AppBlockingSettingsService initialization failed: $e');
  }
  
  // Initialize app blocking service safely
  // Temporarily disabled to fix foreground service notification crash
  // try {
  //   await AppBlockingService.initialize();
  // } catch (e) {
  //   print('Error initializing app blocking service: $e');
  // }
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    
    return MaterialApp(
      title: 'SIGMA Study',
      theme: AppStyles.lightTheme,
      darkTheme: AppStyles.darkTheme,
      themeMode: themeMode, // Uses theme provider
      home: const AuthWrapper(),
      routes: {
        '/home': (context) => const MainAppWithNavigation(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainAppWithNavigation extends ConsumerStatefulWidget {
  const MainAppWithNavigation({super.key});

  @override
  ConsumerState<MainAppWithNavigation> createState() => _MainAppWithNavigationState();
}

class _MainAppWithNavigationState extends ConsumerState<MainAppWithNavigation> with WidgetsBindingObserver {
  int _selectedIndex = 0; // Start with Home
  
  // Real data variables
  List<Subject> _subjects = [];
  List<Task> _tasks = [];
  List<CalendarEvent> _todayEvents = [];
  List<StudySession> _todaySessions = [];
  Duration _todayStudyTime = Duration.zero;
  Duration _weeklyStudyTime = Duration.zero;
  int _currentStreak = 0;
  bool _isLoading = true;
  AppBlockingSettings? _blockingSettings;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadRealData();
    // Temporarily disabled app blocking background service
    // Ensure persistent monitoring when app starts
    // AppBlockingService.ensurePersistentMonitoring();
  }

  Future<void> _loadRealData() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Get current user ID
      final currentUserId = FirestoreService.currentUserId;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }
      
      // Initialize services first
      await DataSyncService.initialize();
      await CalendarService.initialize();
      
      // Load subjects first
      _subjects = await DataSyncService.getAllSubjects();
      print('✅ Loaded ${_subjects.length} subjects');
      
      // Sync with Firestore if data seems limited
      if (_subjects.length < 3) {
        try {
          await DataSyncService.forceSyncToFirestore();
          _subjects = await DataSyncService.getAllSubjects();
          print('🔄 Synced and reloaded ${_subjects.length} subjects from Firestore');
        } catch (syncError) {
          print('⚠️ Could not sync with Firestore: $syncError');
        }
      }
      
      // Load tasks  
      _tasks = await DataSyncService.getAllTasks();
      print('✅ Loaded ${_tasks.length} tasks');
      
      // Load today's calendar events with sync
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      try {
        await CalendarService.syncWithFirestore(currentUserId);
        final allEvents = await CalendarService.getAllCalendarEvents(currentUserId);
        _todayEvents = allEvents.where((event) {
          final eventDate = DateTime(event.startTime.year, event.startTime.month, event.startTime.day);
          return eventDate == today;
        }).toList();
        print('✅ Loaded ${_todayEvents.length} today events');
      } catch (calendarError) {
        print('⚠️ Error loading calendar events: $calendarError');
        _todayEvents = [];
      }
      
      // Load study sessions for today
      try {
        final allSessions = await DataSyncService.getAllStudySessions();
        _todaySessions = allSessions.where((session) {
          final sessionDate = DateTime(session.startTime.year, session.startTime.month, session.startTime.day);
          return sessionDate == today && session.userId == currentUserId;
        }).toList();
        print('✅ Loaded ${_todaySessions.length} today sessions');
        
        // Calculate today's study time
        _todayStudyTime = _todaySessions.fold(Duration.zero, (total, session) => total + session.actualDuration);
        print('📊 Today study time: ${_todayStudyTime.inMinutes} minutes');
        
        // Calculate weekly study time
        final weekStart = today.subtract(Duration(days: today.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 7));
        final weeklySessions = allSessions.where((session) {
          return session.startTime.isAfter(weekStart) && 
                 session.startTime.isBefore(weekEnd) &&
                 session.userId == currentUserId;
        }).toList();
        _weeklyStudyTime = weeklySessions.fold(Duration.zero, (total, session) => total + session.actualDuration);
        print('📊 Weekly study time: ${_weeklyStudyTime.inMinutes} minutes');
      } catch (sessionError) {
        print('⚠️ Error loading study sessions: $sessionError');
        _todaySessions = [];
        _todayStudyTime = Duration.zero;
        _weeklyStudyTime = Duration.zero;
      }
      
      // Calculate current streak
      _currentStreak = await _calculateStudyStreak();
      print('🔥 Calculated streak: $_currentStreak days');
      
      // Load app blocking settings
      try {
        _blockingSettings = await AppBlockingSettingsService.getUserSettings(currentUserId);
        print('✅ Loaded blocking settings: ${_blockingSettings?.isEnabled}');
      } catch (blockingError) {
        print('⚠️ Error loading blocking settings: $blockingError');
        _blockingSettings = null;
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading real data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<int> _calculateStudyStreak() async {
    try {
      final now = DateTime.now();
      int streak = 0;
      
      for (int i = 0; i < 365; i++) { // Check up to 1 year back
        final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
        final allDaySessions = await DataSyncService.getAllStudySessions();
        final sessions = allDaySessions.where((session) {
          final sessionDate = DateTime(session.startTime.year, session.startTime.month, session.startTime.day);
          return sessionDate == date;
        }).toList();
        
        if (sessions.isNotEmpty && sessions.any((s) => s.actualDuration.inMinutes >= 25)) {
          // At least 25 minutes of study (1 pomodoro)
          streak++;
        } else {
          break;
        }
      }
      
      return streak;
    } catch (e) {
      print('Error calculating streak: $e');
      return 0;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Temporarily disabled app blocking background service
    /*
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
    */
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
      color: context.background,
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
                              color: context.primary.withOpacity(0.1),
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
                                  color: context.primary,
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
                                          color: context.primary,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      TextSpan(
                                        text: 'Your Study Mate',
                                        style: TextStyle(
                                          color: context.foreground,
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
                        backgroundColor: context.primary,
                        foregroundColor: context.primaryForeground,
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
                    _isLoading ? const Center(
                      child: CircularProgressIndicator(),
                    ) : LayoutBuilder(
                      builder: (context, constraints) {
                        final todayHours = _todayStudyTime.inHours;
                        final todayMinutes = _todayStudyTime.inMinutes % 60;
                        final todayTimeStr = todayHours > 0 ? '${todayHours}h ${todayMinutes}m' : '${todayMinutes}m';
                        
                        // Calculate weekly progress (simple calculation for now)
                        final focusScore = _weeklyStudyTime.inMinutes > 0 ? 
                          min(100, (_weeklyStudyTime.inMinutes * 100 / (7 * 60)).round()) : 0;
                        
                        if (constraints.maxWidth > 600) {
                          // Wide screen: 4 cards in a row
                          return Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  title: 'Study Time',
                                  value: todayTimeStr.isEmpty ? '0m' : todayTimeStr,
                                  subtitle: 'Today',
                                  icon: Icons.timer_rounded,
                                  color: context.timerFocus,
                                ),
                              ),
                              const SizedBox(width: AppStyles.spaceSM),
                              Expanded(
                                child: _buildStatCard(
                                  title: 'Sessions',
                                  value: '${_todaySessions.length}',
                                  subtitle: 'Completed',
                                  icon: Icons.check_circle_rounded,
                                  color: context.success,
                                ),
                              ),
                              const SizedBox(width: AppStyles.spaceSM),
                              Expanded(
                                child: _buildStatCard(
                                  title: 'Focus Score',
                                  value: '${focusScore}%',
                                  subtitle: 'This week',
                                  icon: Icons.psychology_rounded,
                                  color: context.primary,
                                ),
                              ),
                              const SizedBox(width: AppStyles.spaceSM),
                              Expanded(
                                child: _buildStatCard(
                                  title: 'Streak',
                                  value: '$_currentStreak',
                                  subtitle: 'Days',
                                  icon: Icons.local_fire_department_rounded,
                                  color: context.warning,
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
                                      value: todayTimeStr.isEmpty ? '0m' : todayTimeStr,
                                      subtitle: 'Today',
                                      icon: Icons.timer_rounded,
                                      color: context.timerFocus,
                                    ),
                                  ),
                                  const SizedBox(width: AppStyles.spaceSM),
                                  Expanded(
                                    child: _buildStatCard(
                                      title: 'Sessions',
                                      value: '${_todaySessions.length}',
                                      subtitle: 'Completed',
                                      icon: Icons.check_circle_rounded,
                                      color: context.success,
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
                                      value: '${focusScore}%',
                                      subtitle: 'This week',
                                      icon: Icons.psychology_rounded,
                                      color: context.primary,
                                    ),
                                  ),
                                  const SizedBox(width: AppStyles.spaceSM),
                                  Expanded(
                                    child: _buildStatCard(
                                      title: 'Streak',
                                      value: '$_currentStreak',
                                      subtitle: 'Days',
                                      icon: Icons.local_fire_department_rounded,
                                      color: context.warning,
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
                        color: context.card,
                        borderRadius: BorderRadius.circular(AppStyles.radiusMD),
                        border: Border.all(
                          color: context.border,
                          width: 1,
                        ),
                        boxShadow: context.shadowSM,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.trending_up_rounded,
                                color: context.mutedForeground,
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
                          ..._buildSubjectProgressBars(),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: AppStyles.spaceXL),
                    
                    // Today's Schedule - Shadcn Style
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppStyles.spaceLG),
                      decoration: BoxDecoration(
                        color: context.card,
                        borderRadius: BorderRadius.circular(AppStyles.radiusMD),
                        border: Border.all(
                          color: context.border,
                          width: 1,
                        ),
                        boxShadow: context.shadowSM,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.schedule_rounded,
                                color: context.mutedForeground,
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
                                '${DateTime.now().day} ${_getMonthName(DateTime.now().month)}',
                                style: AppStyles.bodySmall.copyWith(
                                  color: context.mutedForeground,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppStyles.spaceMD),
                          ..._buildTodaySchedule(),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: AppStyles.spaceXL),
                    
                    // Quick Insights - Shadcn Style
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppStyles.spaceLG),
                      decoration: BoxDecoration(
                        color: context.accent,
                        borderRadius: BorderRadius.circular(AppStyles.radiusMD),
                        border: Border.all(
                          color: context.border,
                          width: 1,
                        ),
                        boxShadow: context.shadowSM,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppStyles.spaceXS),
                            decoration: BoxDecoration(
                              color: context.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppStyles.radiusSM),
                            ),
                            child: Icon(
                              Icons.lightbulb_rounded,
                              color: context.primary,
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
                                    color: context.primary,
                                  ),
                                ),
                                const SizedBox(height: AppStyles.spaceXS),
                                Text(
                                  _getStudyTip(),
                                  style: AppStyles.bodySmall.copyWith(
                                    color: context.foreground,
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

              SizedBox(height: context.responsive(
                mobile: AppStyles.spaceXXL * 3, // Extra space for floating navbar
                tablet: AppStyles.spaceXXL * 2,
                desktop: AppStyles.spaceXL,
              )),
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
        color: context.card,
        borderRadius: BorderRadius.circular(AppStyles.radiusMD),
        border: Border.all(
          color: context.border,
          width: 1,
        ),
        boxShadow: context.shadowSM,
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
                  color: context.mutedForeground,
                ),
              ),
              Icon(
                icon,
                color: context.mutedForeground,
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
              color: context.mutedForeground,
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
                color: context.mutedForeground,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppStyles.spaceXS),
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: context.muted,
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

  // Helper methods for real data display
  List<Widget> _buildSubjectProgressBars() {
    if (_subjects.isEmpty) {
      return [
        Text(
          'No subjects found. Add subjects in the Planner to see progress.',
          style: AppStyles.bodySmall.copyWith(
            color: context.mutedForeground,
          ),
        ),
      ];
    }
    
    List<Widget> bars = [];
    for (int i = 0; i < _subjects.take(3).length; i++) {
      final subject = _subjects[i];
      
      // Calculate progress based on completed vs total sessions for this subject
      final subjectSessions = _todaySessions.where((s) => s.subjectId == subject.id).toList();
      final progress = subjectSessions.isEmpty ? 0.0 : 
        subjectSessions.where((s) => s.actualDuration >= s.targetDuration).length / subjectSessions.length;
      
      final color = Color(int.parse(subject.color.replaceFirst('#', '0xff')));
      
      bars.add(_buildProgressBar(subject.name, progress, color));
      if (i < _subjects.take(3).length - 1) {
        bars.add(const SizedBox(height: AppStyles.spaceSM));
      }
    }
    return bars;
  }
  
  List<Widget> _buildTodaySchedule() {
    if (_todayEvents.isEmpty) {
      return [
        Text(
          'No events scheduled for today. Add events in the Calendar.',
          style: AppStyles.bodySmall.copyWith(
            color: context.mutedForeground,
          ),
        ),
      ];
    }
    
    List<Widget> scheduleItems = [];
    final sortedEvents = _todayEvents.toList()..sort((a, b) => a.startTime.compareTo(b.startTime));
    
    for (final event in sortedEvents.take(4)) {
      // Find subject by ID, or create a default one if not found
      Subject? subject;
      try {
        subject = _subjects.firstWhere((s) => s.id == event.subjectId);
      } catch (e) {
        // If subject not found, create a default subject
        subject = Subject(
          id: event.subjectId ?? 'general',
          name: event.subjectId != null && event.subjectId!.isNotEmpty ? 
                'Subject ${event.subjectId}' : 'General Study',
          userId: FirestoreService.currentUserId ?? 'unknown',
          color: '#6366F1',
          createdAt: DateTime.now(),
        );
        print('⚠️ Subject not found for event ${event.title}, using default: ${subject.name}');
      }
      
      final time = '${event.startTime.hour.toString().padLeft(2, '0')}:${event.startTime.minute.toString().padLeft(2, '0')}';
      final color = Color(int.parse(subject.color.replaceFirst('#', '0xff')));
      
      scheduleItems.add(
        _buildScheduleItem(
          time,
          subject.name,
          event.title,
          color,
        ),
      );
    }
    
    return scheduleItems;
  }
  
  String _getStudyTip() {
    if (_blockingSettings?.isEnabled == true) {
      final blockedCount = _blockingSettings?.blockedApps.length ?? 0;
      return 'App blocking is active with $blockedCount apps blocked. Stay focused!';
    }
    
    if (_currentStreak > 7) {
      return 'Amazing! You\'re on a $_currentStreak-day streak. Keep the momentum going!';
    }
    
    if (_todayStudyTime.inMinutes < 25) {
      return 'Start with a 25-minute focus session to build momentum for the day.';
    }
    
    if (_todaySessions.length >= 4) {
      return 'Great progress! Consider taking a longer break to recharge.';
    }
    
    return 'You\'re on track! Consider taking a 15-minute break between sessions for optimal focus.';
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
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
                    color: isBreak ? context.mutedForeground : context.foreground,
                  ),
                ),
                if (!isBreak && topic.isNotEmpty) ...[
                  Text(
                    topic,
                    style: AppStyles.bodySmall.copyWith(
                      color: context.mutedForeground,
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
      body: _buildResponsiveBody(context),
      bottomNavigationBar: context.isMobile ? Container(
        margin: EdgeInsets.only(
          bottom: context.responsive(
            mobile: AppStyles.navBarMargin,
            tablet: AppStyles.navBarMargin + 8,
            desktop: AppStyles.navBarMargin + 16,
          ), 
          left: context.responsive(
            mobile: AppStyles.navBarMargin,
            tablet: AppStyles.navBarMargin + 4,
            desktop: AppStyles.navBarMargin + 8,
          ), 
          right: context.responsive(
            mobile: AppStyles.navBarMargin,
            tablet: AppStyles.navBarMargin + 4,
            desktop: AppStyles.navBarMargin + 8,
          ),
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
      ) : null,
    );
  }

  Widget _buildResponsiveBody(BuildContext context) {
    // For desktop/tablet, use a different layout
    if (context.isDesktop || context.isTablet) {
      return Row(
        children: [
          // Navigation sidebar for larger screens
          Container(
            width: context.responsive(mobile: 200, tablet: 250, desktop: 280),
            decoration: BoxDecoration(
              color: context.card,
              border: Border(
                right: BorderSide(
                  color: context.border.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
            child: _buildNavigationSidebar(context),
          ),
          // Main content
          Expanded(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: context.responsive(
                  mobile: double.infinity,
                  tablet: 800,
                  desktop: 1200,
                ),
              ),
              child: _getCurrentScreen(),
            ),
          ),
        ],
      );
    }

    // Mobile layout - just return the current screen
    return _getCurrentScreen();
  }

  Widget _buildNavigationSidebar(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: context.responsivePadding,
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(context.spacing(8)),
                decoration: BoxDecoration(
                  color: context.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.asset(
                  'assets/images/sigma.png',
                  width: context.responsive(mobile: 28, tablet: 32, desktop: 36),
                  height: context.responsive(mobile: 28, tablet: 32, desktop: 36),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.psychology_rounded,
                      size: context.responsive(mobile: 24, tablet: 28, desktop: 32),
                      color: context.primary,
                    );
                  },
                ),
              ),
              SizedBox(width: context.spacing(12)),
              Text(
                'SIGMA',
                style: context.scaleTextStyle(
                  AppStyles.sectionHeader.copyWith(
                    color: context.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Navigation items
        Expanded(
          child: ListView(
            padding: context.responsiveHorizontalPadding,
            children: [
              _buildSidebarItem(
                context,
                icon: Icons.home_rounded,
                label: 'Home',
                isSelected: _selectedIndex == 0,
                onTap: () => setState(() => _selectedIndex = 0),
              ),
              SizedBox(height: context.spacing(8)),
              _buildSidebarItem(
                context,
                icon: Icons.calendar_month_rounded,
                label: 'Calendar',
                isSelected: _selectedIndex == 1,
                onTap: () => setState(() => _selectedIndex = 1),
              ),
              SizedBox(height: context.spacing(8)),
              _buildSidebarItem(
                context,
                icon: Icons.assignment_rounded,
                label: 'Planner',
                isSelected: _selectedIndex == 2,
                onTap: () => setState(() => _selectedIndex = 2),
              ),
              SizedBox(height: context.spacing(8)),
              _buildSidebarItem(
                context,
                icon: Icons.settings_rounded,
                label: 'Settings',
                isSelected: _selectedIndex == 3,
                onTap: () => setState(() => _selectedIndex = 3),
              ),
            ],
          ),
        ),
        
        // Timer button at bottom
        Container(
          padding: context.responsivePadding,
          child: ElevatedButton(
            onPressed: _onCenterFabPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: context.primary,
              foregroundColor: context.primaryForeground,
              padding: EdgeInsets.symmetric(
                horizontal: context.spacing(20),
                vertical: context.spacing(16),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.timer_rounded,
                  size: context.responsive(mobile: 18, tablet: 20, desktop: 24),
                ),
                SizedBox(width: context.spacing(8)),
                Text(
                  'Start Timer',
                  style: context.scaleTextStyle(
                    AppStyles.buttonText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSidebarItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.spacing(16),
          vertical: context.spacing(12),
        ),
        decoration: BoxDecoration(
          color: isSelected ? context.primary.withOpacity(0.1) : null,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(
            color: context.primary.withOpacity(0.3),
            width: 1,
          ) : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: context.responsive(mobile: 18, tablet: 20, desktop: 24),
              color: isSelected ? context.primary : context.mutedForeground,
            ),
            SizedBox(width: context.spacing(12)),
            Text(
              label,
              style: context.scaleTextStyle(
                AppStyles.bodyMedium.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? context.primary : context.foreground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



