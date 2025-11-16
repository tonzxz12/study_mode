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
import 'core/services/enhanced_firestore_service.dart';
import 'data/services/calendar_service.dart';
import 'package:uuid/uuid.dart';

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
  List<CalendarEvent> _upcomingEvents = [];
  List<StudySession> _allSessions = [];
  Duration _totalStudyTime = Duration.zero;
  Duration _allTimeStudyTime = Duration.zero;
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
      print('🔑 Current User ID: $currentUserId');
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }
      
      // Initialize services first
      await DataSyncService.initialize();
      await CalendarService.initialize();
      
      // Load subjects directly from online database (Firestore)
      _subjects = await DataSyncService.getAllSubjects();
      print('✅ Loaded ${_subjects.length} subjects from online database');
      for (final subject in _subjects) {
        print('   - Subject: ${subject.name} (ID: ${subject.id})');
      }
      
      // Load tasks from online database (Firestore)
      _tasks = await DataSyncService.getAllTasks();
      print('✅ Loaded ${_tasks.length} tasks from online database');
      
      // Check if this is a new user or data loading issue
      if (_subjects.isEmpty && _tasks.isEmpty && _allSessions.isEmpty) {
        print('📊 No data found for user: $currentUserId');
        print('💡 This could mean:');
        print('   - New user account (no data created yet)');
        print('   - Data sync issue with Firestore');
        print('   - User ID mismatch');
        print('🚀 Next steps: Add subjects in Planner, then start studying!');
      } else {
        print('🚀 Data loaded successfully! User has existing study history.');
      }
      
      // Load all calendar events (both past and future for comprehensive view)
      try {
        await CalendarService.syncWithFirestore(currentUserId);
        final allEvents = await CalendarService.getAllCalendarEvents(currentUserId);
        // Show ALL events from the user (no date filtering)
        _upcomingEvents = allEvents.toList();
        print('✅ Loaded ${_upcomingEvents.length} total events (all-time)');
        for (final event in _upcomingEvents.take(3)) {
          print('   - Event: ${event.title} on ${event.startTime} (Subject: ${event.subjectId})');
        }
      } catch (calendarError) {
        print('⚠️ Error loading calendar events: $calendarError');
        _upcomingEvents = [];
      }
      
      // Load all study sessions from online database (Firestore)
      try {
        final allSessions = await DataSyncService.getAllStudySessions();
        _allSessions = allSessions.where((session) {
          return session.userId == currentUserId;
        }).toList();
        print('✅ Loaded ${_allSessions.length} total sessions from online database (all-time)');
        for (final session in _allSessions.take(5)) {
          print('   - Session: ${session.subjectId} - ${session.actualDuration.inMinutes}min on ${session.startTime}');
        }
        
        // Calculate all-time study time
        _totalStudyTime = _allSessions.fold(Duration.zero, (total, session) => total + session.actualDuration);
        print('📊 All-time study time: ${_totalStudyTime.inMinutes} minutes');
        
        // All-time study time
        _allTimeStudyTime = _totalStudyTime;
        print('📊 Total study time: ${_allTimeStudyTime.inMinutes} minutes');
      } catch (sessionError) {
        print('⚠️ Error loading study sessions from online database: $sessionError');
        _allSessions = [];
        _totalStudyTime = Duration.zero;
        _allTimeStudyTime = Duration.zero;
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
      
      // Final summary of loaded data
      print('\n📊 === FINAL DATA SUMMARY ===');
      print('📚 Subjects: ${_subjects.length}');
      print('📋 Tasks: ${_tasks.length}');
      print('📅 Events: ${_upcomingEvents.length}');
      print('🎯 Sessions: ${_allSessions.length}');
      print('⏱️ Total study time: ${_allTimeStudyTime.inHours}h ${_allTimeStudyTime.inMinutes % 60}m');
      print('🔥 Current streak: $_currentStreak days');
      print('=========================\n');
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading real data: $e');
      print('Stack trace: ${StackTrace.current}');
      // Still set loading to false and show what data we have
      setState(() {
        _isLoading = false;
      });
      // Try to load some fallback data from online database
      try {
        final currentUserId = FirestoreService.currentUserId;
        print('🔄 Attempting fallback data loading from online database...');
        final allSubjects = await DataSyncService.getAllSubjects();
        final allSessions = await DataSyncService.getAllStudySessions();
        
        _subjects = allSubjects;
        _allSessions = allSessions.where((session) => session.userId == currentUserId).toList();
        _totalStudyTime = _allSessions.fold(Duration.zero, (total, session) => total + session.actualDuration);
        _allTimeStudyTime = _totalStudyTime;
        
        print('🔄 Loaded fallback data from online database: ${_subjects.length} subjects, ${_allSessions.length} sessions');
      } catch (fallbackError) {
        print('❌ Fallback loading from online database also failed: $fallbackError');
      }
    }
  }

  Future<int> _calculateStudyStreak() async {
    try {
      final now = DateTime.now();
      int streak = 0;
      
      // Use already loaded sessions instead of reloading
      final sessions = _allSessions;
      print('🔍 Calculating streak from ${sessions.length} total sessions');
      
      for (int i = 0; i < 365; i++) { // Check up to 1 year back
        final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
        final daySessions = sessions.where((session) {
          final sessionDate = DateTime(session.startTime.year, session.startTime.month, session.startTime.day);
          return sessionDate.isAtSameMomentAs(date) && session.actualDuration.inMinutes >= 25;
        }).toList();
        
        if (daySessions.isNotEmpty) {
          streak++;
          if (i == 0) print('🔥 Today: ${daySessions.length} qualifying sessions');
        } else {
          if (i == 0) print('🔥 Today: 0 qualifying sessions - streak ends');
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
                    // All-Time Overview
                    Text(
                      'All-Time Overview',
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
                        final allTimeHours = _allTimeStudyTime.inHours;
                        final allTimeMinutes = _allTimeStudyTime.inMinutes % 60;
                        final allTimeStr = allTimeHours > 0 ? '${allTimeHours}h ${allTimeMinutes}m' : '${allTimeMinutes}m';
                        
                        // Calculate overall progress (all-time sessions completion rate)
                        final totalSessions = _allSessions.length;
                        final completedSessions = _allSessions.where((s) => s.actualDuration >= s.targetDuration).length;
                        final focusScore = totalSessions > 0 ? 
                          min(100, (completedSessions * 100 / totalSessions).round()) : 0;
                        
                        print('📊 Stats calculation: ${totalSessions} total sessions, ${completedSessions} completed, ${focusScore}% focus score');
                        
                        if (constraints.maxWidth > 600) {
                          // Wide screen: 4 cards in a row
                          return Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  title: 'Total Time',
                                  value: allTimeStr.isEmpty ? '0m' : allTimeStr,
                                  subtitle: 'All-time',
                                  icon: Icons.timer_rounded,
                                  color: context.timerFocus,
                                ),
                              ),
                              const SizedBox(width: AppStyles.spaceSM),
                              Expanded(
                                child: _buildStatCard(
                                  title: 'Sessions',
                                  value: '${_allSessions.length}',
                                  subtitle: 'Total',
                                  icon: Icons.check_circle_rounded,
                                  color: context.success,
                                ),
                              ),
                              const SizedBox(width: AppStyles.spaceSM),
                              Expanded(
                                child: _buildStatCard(
                                  title: 'Focus Score',
                                  value: '${focusScore}%',
                                  subtitle: 'Completion',
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
                                      title: 'Total Time',
                                      value: allTimeStr.isEmpty ? '0m' : allTimeStr,
                                      subtitle: 'All-time',
                                      icon: Icons.timer_rounded,
                                      color: context.timerFocus,
                                    ),
                                  ),
                                  const SizedBox(width: AppStyles.spaceSM),
                                  Expanded(
                                    child: _buildStatCard(
                                      title: 'Sessions',
                                      value: '${_allSessions.length}',
                                      subtitle: 'Total',
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
                                      subtitle: 'Completion',
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
                                'Subject Progress',
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
                                'All Events',
                                style: AppStyles.subsectionHeader.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${_upcomingEvents.length} events',
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
                    
                    const SizedBox(height: AppStyles.spaceXL),
                    
                    // Debug Database Test Button
                    Container(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _testFirestoreConnection,
                        icon: const Icon(Icons.cloud_sync_rounded, size: 20),
                        label: const Text('Test Database Connection'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.primary,
                          foregroundColor: context.primaryForeground,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppStyles.spaceLG,
                            vertical: AppStyles.spaceMD,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppStyles.radiusMD),
                          ),
                        ),
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
    print('📊 Building subject progress: ${_subjects.length} subjects, ${_allSessions.length} sessions');
    
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
    for (int i = 0; i < _subjects.take(5).length; i++) {  // Show up to 5 subjects
      final subject = _subjects[i];
      
      // Calculate all-time progress based on completed vs total sessions for this subject
      final subjectSessions = _allSessions.where((s) => s.subjectId == subject.id).toList();
      print('   - ${subject.name}: ${subjectSessions.length} sessions');
      
      double progress;
      if (subjectSessions.isEmpty) {
        progress = 0.0;
      } else {
        final completedSessions = subjectSessions.where((s) => s.actualDuration >= s.targetDuration).length;
        progress = completedSessions / subjectSessions.length;
      }
      
      final color = Color(int.parse(subject.color.replaceFirst('#', '0xff')));
      
      bars.add(_buildProgressBar(subject.name, progress, color));
      if (i < _subjects.take(5).length - 1) {
        bars.add(const SizedBox(height: AppStyles.spaceSM));
      }
    }
    return bars;
  }
  
  List<Widget> _buildTodaySchedule() {
    if (_upcomingEvents.isEmpty) {
      return [
        Text(
          'No events found. Add events in the Calendar to see them here.',
          style: AppStyles.bodySmall.copyWith(
            color: context.mutedForeground,
          ),
        ),
      ];
    }
    
    List<Widget> scheduleItems = [];
    // Sort events by start time (chronological order - newest first)
    final sortedEvents = _upcomingEvents.toList()..sort((a, b) => b.startTime.compareTo(a.startTime));
    print('📅 Displaying ${sortedEvents.length} events (sorted by date)');
    
    // Show more events (up to 6 instead of 4)
    for (final event in sortedEvents.take(6)) {
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
    print('🔍 Getting study tip - Sessions: ${_allSessions.length}, Study time: ${_totalStudyTime.inMinutes}min, Streak: $_currentStreak');
    
    if (_blockingSettings?.isEnabled == true) {
      final blockedCount = _blockingSettings?.blockedApps.length ?? 0;
      return 'App blocking is active with $blockedCount apps blocked. Stay focused!';
    }
    
    if (_currentStreak > 7) {
      return 'Amazing! You\'re on a $_currentStreak-day streak. Keep the momentum going!';
    }
    
    if (_allSessions.isEmpty) {
      return _subjects.isEmpty 
        ? 'Welcome to SIGMA! Go to Planner to add your first subject, then start studying.'
        : 'You have ${_subjects.length} subjects ready. Tap Start to begin your first study session!';
    }
    
    if (_totalStudyTime.inMinutes < 25) {
      return 'Great start! Continue building your study habit with consistent sessions.';
    }
    
    if (_allSessions.length >= 10) {
      return 'Excellent progress! You\'ve completed ${_allSessions.length} study sessions.';
    }
    
    return 'You\'re making progress! Total study time: ${(_totalStudyTime.inHours > 0) ? "${_totalStudyTime.inHours}h ${_totalStudyTime.inMinutes % 60}m" : "${_totalStudyTime.inMinutes}m"}';
  }
  
  Future<void> _testFirestoreConnection() async {
    print('🔍 Testing Firestore database connection...');
    
    try {
      final currentUserId = FirestoreService.currentUserId;
      if (currentUserId == null) {
        print('❌ No authenticated user!');
        return;
      }
      
      print('👤 User ID: $currentUserId');
      
      // Test connection
      final canConnect = await EnhancedFirestoreService.testConnection();
      print('🔍 Connection test: ${canConnect ? '✅ SUCCESS' : '❌ FAILED'}');
      
      if (!canConnect) return;
      
      // Test creating a subject
      final testSubject = Subject(
        id: const Uuid().v4(),
        name: 'Test Subject ${DateTime.now().millisecondsSinceEpoch}',
        color: '#2196F3',
        description: 'Test subject from home screen',
        userId: currentUserId,
        createdAt: DateTime.now(),
      );
      
      final saveSuccess = await EnhancedFirestoreService.saveSubject(testSubject);
      print('💾 Save test: ${saveSuccess ? '✅ SUCCESS' : '❌ FAILED'}');
      
      // Test fetching data
      final subjects = await EnhancedFirestoreService.getAllSubjects();
      final tasks = await EnhancedFirestoreService.getAllTasks();
      final sessions = await EnhancedFirestoreService.getAllStudySessions();
      
      print('📊 Fetch results:');
      print('  📚 Subjects: ${subjects.length}');
      print('  📋 Tasks: ${tasks.length}');
      print('  📆 Sessions: ${sessions.length}');
      
      // Reload the UI data
      await _loadRealData();
      
    } catch (e) {
      print('❌ Database test error: $e');
    }
  }



  // Test Firestore Connection Method
  
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



