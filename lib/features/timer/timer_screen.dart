import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import '../../core/theme/styles.dart';
import '../../core/theme/theme_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/study_session.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/enhanced_firestore_service.dart';
import '../../data/services/calendar_service.dart';
import '../../data/models/calendar_event.dart';
import '../../data/models/subject.dart';
import '../../data/models/task.dart';

import 'package:uuid/uuid.dart';

import '../../core/utils/responsive_utils.dart';
import '../../core/widgets/responsive_dialog.dart';

import '../../core/services/app_blocking_service.dart';
import '../../data/services/app_blocking_settings_service.dart';
// import 'package:usage_stats/usage_stats.dart';  // Temporarily disabled
import '../../core/migration/user_id_migration.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  Timer? _timer;
  int _currentSeconds = 1500; // 25 minutes default
  int _initialSeconds = 1500;
  bool _isRunning = false;
  bool _isStudyTime = true;
  int _completedPomodoros = 0;
  bool _alarmEnabled = true;
  
  // Customizable durations - now loaded from preferences
  int _studyDuration = 25 * 60; // 25 minutes default
  int _shortBreakDuration = 5 * 60; // 5 minutes default
  int _longBreakDuration = 15 * 60; // 15 minutes default

  // Session tracking
  StudySession? _activeSession;
  DateTime? _sessionStartTime;
  List<CalendarEvent> _availableCalendarSessions = [];
  CalendarEvent? _selectedCalendarSession;
  List<Subject> _subjects = [];
  List<Task> _tasks = [];
  
  // Get current user ID from Firebase Auth
  String get _currentUserId {
    final firebaseUserId = FirestoreService.currentUserId;
    if (firebaseUserId != null && firebaseUserId.isNotEmpty) {
      return firebaseUserId;
    }
    // No fallback - user must be authenticated
    throw Exception('No authenticated user found. Please log in.');
  }
  
  // App blocking
  bool _appBlockingEnabled = false;
  List<String> _selectedBlockedApps = [];
  // List<UsageInfo> _installedApps = [];  // Temporarily disabled
  List<dynamic> _installedApps = [];  // Placeholder

  @override
  void initState() {
    super.initState();
    _initializeTimer();
    
    // Also try to load schedules after a short delay in case of timing issues
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _availableCalendarSessions.isEmpty) {
        print('⏰ Delayed schedule load attempt...');
        _loadAvailableSchedules();
      }
    });
  }

  Future<void> _initializeTimer() async {
    print('🚀 Initializing timer screen...');
    
    // Check authentication first
    if (_currentUserId == 'anonymous_user') {
      print('⚠️ No authenticated user found!');
    } else {
      print('✅ Authenticated user: $_currentUserId');
    }
    
    // Load timer settings first (these are local, should always work)
    try {
      await _loadTimerSettings();
      print('✅ Timer settings loaded');
    } catch (e) {
      print('⚠️ Timer settings failed: $e');
    }
    
    // Load schedules (this is the critical one)
    try {
      await _loadAvailableSchedules();
      print('✅ Schedules loaded');
    } catch (e) {
      print('❌ Schedule loading failed: $e');
      // Try once more after a delay
      try {
        await Future.delayed(const Duration(seconds: 2));
        await _loadAvailableSchedules();
        print('✅ Schedules loaded on retry');
      } catch (retryError) {
        print('❌ Schedule retry also failed: $retryError');
      }
    }
    
    // Load app blocking settings
    try {
      await _loadAppBlockingSettings();
      await AppBlockingService.initialize();
      print('✅ App blocking initialized');
    } catch (e) {
      print('⚠️ App blocking failed: $e');
    }
    
    print('✅ Timer initialization complete');
  }



  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadTimerSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _studyDuration = prefs.getInt('study_duration') ?? (25 * 60);
        _shortBreakDuration = prefs.getInt('short_break_duration') ?? (5 * 60);
        _longBreakDuration = prefs.getInt('long_break_duration') ?? (15 * 60);
        _alarmEnabled = prefs.getBool('alarm_enabled') ?? true;
        
        // Update current timer if not running
        if (!_isRunning && _isStudyTime) {
          _currentSeconds = _studyDuration;
          _initialSeconds = _studyDuration;
        }
      });
    } catch (e) {
      print('Error loading timer settings: $e');
    }
  }

  Future<void> _saveTimerSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('study_duration', _studyDuration);
      await prefs.setInt('short_break_duration', _shortBreakDuration);
      await prefs.setInt('long_break_duration', _longBreakDuration);
      await prefs.setBool('alarm_enabled', _alarmEnabled);
      
      // Save app blocking settings using the new service
      final userId = _currentUserId;
      final currentSettings = await AppBlockingSettingsService.getUserSettings(userId);
      final updatedSettings = currentSettings.copyWith(
        isEnabled: _appBlockingEnabled,
        blockedApps: _selectedBlockedApps,
      );
      await AppBlockingSettingsService.saveSettings(updatedSettings);
      print('✅ Saved app blocking settings: ${_selectedBlockedApps.length} apps');
    } catch (e) {
      print('Error saving timer settings: $e');
    }
  }

  Future<void> _loadAppBlockingSettings() async {
    try {
      final userId = _currentUserId;
      final settings = await AppBlockingSettingsService.getUserSettings(userId);
      setState(() {
        _appBlockingEnabled = settings.isEnabled;
        _selectedBlockedApps = List<String>.from(settings.blockedApps);
      });
      await _loadInstalledApps();
      print('✅ Loaded app blocking settings: ${settings.blockedApps.length} apps');
    } catch (e) {
      print('Error loading app blocking settings: $e');
    }
  }

  Future<void> _loadInstalledApps() async {
    try {
      // Temporarily disabled usage_stats functionality
      // if (await AppBlockingService.hasUsagePermission()) {
      //   final now = DateTime.now();
      //   final yesterday = now.subtract(const Duration(days: 1));
      //   final usageStats = await UsageStats.queryUsageStats(yesterday, now);
      //   
      //   setState(() {
      //     _installedApps = usageStats.where((app) => 
      //       app.packageName != null && 
      //       app.packageName!.isNotEmpty &&
      //       !app.packageName!.startsWith('com.android.') &&
      //       !app.packageName!.startsWith('com.google.android.')
      //     ).toList();
      //   });
      
      setState(() {
        _installedApps = [];  // Temporarily empty
      });
    } catch (e) {
      print('Error loading installed apps: $e');
    }
  }

  Future<void> _loadAvailableSchedules() async {
    try {
      print('🔄 Starting to load available schedules...');
      print('🔍 Current userId from FirebaseAuth: "$_currentUserId"');
      print('🔍 FirebaseAuth.currentUser: ${FirestoreService.currentUserId}');
      
      // Step 1: Initialize CalendarService with retry
      for (int attempt = 1; attempt <= 3; attempt++) {
        try {
          await CalendarService.initialize();
          print('✅ CalendarService initialized (attempt $attempt)');
          break;
        } catch (e) {
          print('⚠️ CalendarService init failed (attempt $attempt): $e');
          if (attempt == 3) rethrow;
          await Future.delayed(Duration(seconds: attempt));
        }
      }
      
      // Step 2: Try both local and Firestore data sources
      List<CalendarEvent> allEvents = [];
      
      // First try: Get from CalendarService (includes sync)
      try {
        await CalendarService.syncWithFirestore(_currentUserId);
        print('✅ Synced with Firestore');
        
        allEvents = await CalendarService.getAllCalendarEvents(_currentUserId);
        print('🔍 CalendarService returned: ${allEvents.length} events');
      } catch (e) {
        print('⚠️ CalendarService failed: $e');
      }
      
      // Second try: Direct Firestore query if CalendarService failed
      if (allEvents.isEmpty) {
        try {
          print('🔄 Trying direct Firestore query as fallback...');
          allEvents = await _getEventsFromFirestore();
          print('🔥 Direct Firestore returned: ${allEvents.length} events');
        } catch (e) {
          print('⚠️ Direct Firestore also failed: $e');
        }
      }
      
      // Step 3: Debug all events found
      print('🔍 Total events found: ${allEvents.length}');
      for (final event in allEvents) {
        print('🔍 Event: "${event.title}", UserID: "${event.userId}", Completed: ${event.isCompleted}, Date: ${event.startTime}');
      }
      
      // Step 4: Filter events - be more lenient with filtering
      final availableSchedules = <CalendarEvent>[];
      for (final event in allEvents) {
        // More lenient filtering - check both exact match and trimmed match
        final userIdMatch = event.userId == _currentUserId || event.userId.trim() == _currentUserId.trim();
        
        if (userIdMatch && !event.isCompleted) {
          availableSchedules.add(event);
          print('✅ Added schedule: "${event.title}" (${event.startTime})');
        } else {
          print('❌ Filtered out: "${event.title}" (UserID: "${event.userId}", Match: $userIdMatch, Completed: ${event.isCompleted})');
        }
      }
      
      print('🔍 Final filtered schedules: ${availableSchedules.length}');
      
      // Step 5: Sort by date
      availableSchedules.sort((a, b) => a.startTime.compareTo(b.startTime));
      
      // Step 6: Load supporting data
      List<Subject> subjects = [];
      List<Task> tasks = [];
      
      try {
        subjects = await EnhancedFirestoreService.getAllSubjects();
        tasks = await EnhancedFirestoreService.getAllTasks();
        print('📚 Loaded ${subjects.length} subjects and ${tasks.length} tasks');
      } catch (e) {
        print('⚠️ Error loading subjects/tasks: $e');
      }
      
      // Step 7: Update UI
      if (mounted) {
        setState(() {
          _availableCalendarSessions = availableSchedules;
          _subjects = subjects;
          _tasks = tasks;
        });
        print('📅 UI updated with ${availableSchedules.length} available schedules');
      }
    } catch (e) {
      print('⚠️ Error loading available schedules: $e');
      print('🔄 Trying direct Firestore fallback...');
      
      // Fallback: Try direct Firestore query
      try {
        await _loadSchedulesFromFirestore();
      } catch (fallbackError) {
        print('❌ Firestore fallback also failed: $fallbackError');
        if (mounted) {
          setState(() {
            _availableCalendarSessions = [];
            _subjects = [];
            _tasks = [];
          });
        }
      }
    }
  }

  // Helper method for direct Firestore queries
  Future<List<CalendarEvent>> _getEventsFromFirestore() async {
    try {
      print('🔥 Querying Firestore directly...');
      
      // Try multiple query approaches
      List<QuerySnapshot> queryResults = [];
      
      // Query 1: Exact userId match
      try {
        final exact = await FirebaseFirestore.instance
            .collection('calendar')
            .where('userId', isEqualTo: _currentUserId)
            .get();
        queryResults.add(exact);
        print('🔥 Exact match query: ${exact.docs.length} docs');
      } catch (e) {
        print('⚠️ Exact query failed: $e');
      }
      
      // Query 2: Get all documents if exact match fails
      if (queryResults.isEmpty || queryResults.first.docs.isEmpty) {
        try {
          final all = await FirebaseFirestore.instance
              .collection('calendar')
              .get();
          queryResults.add(all);
          print('🔥 All documents query: ${all.docs.length} docs');
        } catch (e) {
          print('⚠️ All documents query failed: $e');
        }
      }
      
      final List<CalendarEvent> firestoreEvents = [];
      
      for (final querySnapshot in queryResults) {
        for (final doc in querySnapshot.docs) {
          try {
            final data = doc.data() as Map<String, dynamic>;
            print('🔥 Document ${doc.id}: ${data.keys.join(', ')}');
            print('🔥 UserId in doc: "${data['userId']}" vs target: "$_currentUserId"');
            
            final event = CalendarEvent.fromFirestore(data);
            firestoreEvents.add(event);
            print('✅ Parsed event: "${event.title}" for user "${event.userId}"');
          } catch (parseError) {
            print('❌ Error parsing document ${doc.id}: $parseError');
            print('❌ Document data: ${doc.data()}');
          }
        }
      }
      
      return firestoreEvents;
    } catch (e) {
      print('❌ Direct Firestore query failed: $e');
      return [];
    }
  }
  
  // Fallback method to directly query Firestore (legacy)
  Future<void> _loadSchedulesFromFirestore() async {
    try {
      final firestoreEvents = await _getEventsFromFirestore();
      
      // Filter incomplete events
      final availableSchedules = firestoreEvents.where((event) {
        final userIdMatch = event.userId == _currentUserId || event.userId.trim() == _currentUserId.trim();
        return userIdMatch && !event.isCompleted;
      }).toList();
      
      availableSchedules.sort((a, b) => a.startTime.compareTo(b.startTime));
      
      // Load subjects and tasks
      final subjects = await EnhancedFirestoreService.getAllSubjects();
      final tasks = await EnhancedFirestoreService.getAllTasks();
      
      if (mounted) {
        setState(() {
          _availableCalendarSessions = availableSchedules;
          _subjects = subjects;
          _tasks = tasks;
        });
        print('📅 Firestore fallback loaded ${availableSchedules.length} schedules');
      }
    } catch (e) {
      print('❌ Direct Firestore query failed: $e');
      rethrow;
    }
  }

  void _selectCalendarSession(CalendarEvent? session) {
    setState(() {
      _selectedCalendarSession = session;
      
      // Load duration from calendar session
      if (session != null) {
        final durationMinutes = session.durationMinutes;
        _studyDuration = durationMinutes * 60; // Convert to seconds
        
        // Update current timer if not running
        if (!_isRunning && _isStudyTime) {
          _currentSeconds = _studyDuration;
          _initialSeconds = _studyDuration;
        }
        
        // Save the updated duration
        _saveTimerSettings();
        print('📅 Loaded ${durationMinutes}min duration from calendar session: ${session.title}');
      }
    });
  }

  Future<void> _startTimerSession() async {
    // Record the actual start time
    setState(() {
      _sessionStartTime = DateTime.now();
    });

    // Create active study session (even without calendar session)
    try {
      String sessionTitle = 'Study Session';
      String sessionNotes = '';
      String? calendarEventId;
      
      if (_selectedCalendarSession != null) {
        sessionTitle = _selectedCalendarSession!.title;
        sessionNotes = _selectedCalendarSession!.description;
        calendarEventId = _selectedCalendarSession!.id;
      }

      // Try to get subjects, but don't fail if database has issues
      String subjectId = 'general';
      try {
        final subjects = await EnhancedFirestoreService.getAllSubjects();
        if (subjects.isNotEmpty) {
          final matchingSubject = subjects.where(
            (s) => sessionTitle.toLowerCase().contains(s.name.toLowerCase())
          ).firstOrNull;
          subjectId = matchingSubject?.id ?? subjects.first.id;
        }
      } catch (e) {
        print('Warning: Could not load subjects, using default: $e');
      }

      _activeSession = StudySession(
        id: const Uuid().v4(),
        subjectId: subjectId,
        userId: _currentUserId, // Use authenticated user ID
        startTime: _sessionStartTime!,
        targetDuration: Duration(seconds: _initialSeconds), // Use initial duration
        title: sessionTitle,
        notes: sessionNotes,
        calendarEventId: calendarEventId,
        blockedApps: List<String>.from(_selectedBlockedApps),
      );

      // Start app blocking if enabled
      if (_appBlockingEnabled && _selectedBlockedApps.isNotEmpty) {
        await AppBlockingService.blockApps(_selectedBlockedApps);
        print('📱 App blocking started for ${_selectedBlockedApps.length} apps');
      }
      
      print('✅ Started study session: "$sessionTitle" at ${_sessionStartTime!.toLocal()}');
    } catch (e) {
      print('❌ Error creating active session: $e');
      // Continue anyway - timer can work without session tracking
    }
  }

  Future<void> _completeTimerSession() async {
    if (_sessionStartTime != null) {
      final endTime = DateTime.now();
      final actualDuration = endTime.difference(_sessionStartTime!);
      
      try {
        // Create completed session with actual time data
        // Stop app blocking if it was enabled
        if (_appBlockingEnabled && _selectedBlockedApps.isNotEmpty) {
          // await AppBlockingService.stopMonitoring();  // Temporarily disabled
          print('📱 App blocking stopped');
        }

        final completedSession = (_activeSession ?? StudySession(
          id: const Uuid().v4(),
          subjectId: 'general',
          userId: _currentUserId, // Use authenticated user ID
          startTime: _sessionStartTime!,
          targetDuration: Duration(seconds: _initialSeconds),
          title: _selectedCalendarSession?.title ?? 'Study Session',
          notes: _selectedCalendarSession?.description ?? '',
          calendarEventId: _selectedCalendarSession?.id,
          blockedApps: List<String>.from(_selectedBlockedApps),
        )).copyWith(
          endTime: endTime,
          isCompleted: true,
          focusScore: _calculateFocusScore(),
        );

        // Try to save to Firestore
        try {
          final success = await EnhancedFirestoreService.saveStudySession(completedSession);
          if (!success) print('⚠️ Failed to save session to online database');
          print('✅ Session saved to database: "${completedSession.title}"');
          print('📊 Actual study time: ${actualDuration.inMinutes} minutes ${actualDuration.inSeconds % 60} seconds');
        } catch (e) {
          print('⚠️ Could not save to database: $e');
        }
        
        // Mark calendar event as completed if applicable
        if (_selectedCalendarSession != null) {
          await _markCalendarEventCompleted();
        }
        
        // Show success message with actual time
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Session completed! Studied for ${actualDuration.inMinutes}m ${actualDuration.inSeconds % 60}s'
            ),
            backgroundColor: context.success,
            duration: const Duration(seconds: 4),
          ),
        );
        
        // Reset for next session
        setState(() {
          _activeSession = null;
          _sessionStartTime = null;
          _selectedCalendarSession = null;
        });
        
        // Refresh available sessions
        try {
          _loadAvailableSchedules();
        } catch (e) {
          print('Warning: Could not refresh sessions: $e');
        }
        
      } catch (e) {
        print('❌ Error completing session: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Session completed but could not save: $e'),
            backgroundColor: context.warning,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } else {
      print('⚠️ No active session to complete');
    }
  }

  double _calculateFocusScore() {
    if (_sessionStartTime == null) return 0.0;
    
    final actualDuration = DateTime.now().difference(_sessionStartTime!);
    final targetDuration = Duration(seconds: _initialSeconds);
    
    // Calculate focus score based on how close actual time is to target
    final completionRatio = actualDuration.inSeconds / targetDuration.inSeconds;
    
    // Perfect score for completing the full session
    // Reduced score for early completion or overtime
    double score;
    if (completionRatio >= 0.95 && completionRatio <= 1.05) {
      // Near perfect completion (95-105% of target)
      score = 100.0;
    } else if (completionRatio >= 0.8 && completionRatio <= 1.2) {
      // Good completion (80-120% of target)
      score = 85.0;
    } else if (completionRatio >= 0.6) {
      // Decent completion (60%+ of target)
      score = 70.0;
    } else {
      // Low completion (<60% of target)
      score = (completionRatio * 100).clamp(0.0, 60.0);
    }
    
    print('🏆 Focus Score: ${score.toInt()}% (${actualDuration.inMinutes}m/${targetDuration.inMinutes}m)');
    return score;
  }

  Future<void> _markCalendarEventCompleted() async {
    if (_selectedCalendarSession == null) return;
    
    try {
      await CalendarService.markEventCompleted(_selectedCalendarSession!.id);
      print('✅ Marked calendar event as completed: ${_selectedCalendarSession!.title}');
    } catch (e) {
      print('Error marking calendar event completed: $e');
    }
  }

  Future<String> _getCompletionTimeText(CalendarEvent event) async {
    try {
      // Get all study sessions for this user
      final allSessions = await EnhancedFirestoreService.getAllStudySessions();
      
      // Find all study sessions associated with this calendar event
      final associatedSessions = allSessions.where((session) {
        return session.userId == _currentUserId && 
               session.calendarEventId == event.id && 
               session.isCompleted && 
               session.endTime != null;
      }).toList();
      
      if (associatedSessions.isNotEmpty) {
        // Calculate total minutes from all sessions
        int totalMinutes = 0;
        DateTime? latestEndTime;
        
        for (final session in associatedSessions) {
          if (session.endTime != null) {
            totalMinutes += session.actualDuration.inMinutes;
            if (latestEndTime == null || session.endTime!.isAfter(latestEndTime)) {
              latestEndTime = session.endTime;
            }
          }
        }
        
        final sessionCount = associatedSessions.length;
        final sessionText = sessionCount == 1 ? 'session' : 'sessions';
        
        if (latestEndTime != null) {
          return '${totalMinutes}m (${sessionCount} ${sessionText}) • ${latestEndTime.hour.toString().padLeft(2, '0')}:${latestEndTime.minute.toString().padLeft(2, '0')}';
        } else {
          return '${totalMinutes}m (${sessionCount} ${sessionText})';
        }
      }
      
      // Fallback to event start time if no session found
      return 'Done at ${event.startTime.hour.toString().padLeft(2, '0')}:${event.startTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      print('Error getting completion time: $e');
      return 'Completed';
    }
  }

  void _startTimer() {
    if (_timer != null) return;
    
    // Check if schedule is selected (mandatory)
    if (_isStudyTime && _selectedCalendarSession == null) {
      _showScheduleRequiredDialog();
      return;
    }
    
    // Start session if it's study time and we have a selected session
    if (_isStudyTime) {
      _startTimerSession();
    }
    
    setState(() => _isRunning = true);
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_currentSeconds > 0) {
          _currentSeconds--;
        } else {
          _onTimerComplete();
        }
      });
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    _timer = null;
    setState(() => _isRunning = false);
  }

  void _resetTimer() {
    _timer?.cancel();
    _timer = null;
    setState(() {
      _isRunning = false;
      _currentSeconds = _initialSeconds;
    });
  }

  void _showScheduleRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppStyles.radiusMD),
        ),
        title: Row(
          children: [
            Icon(
              Icons.schedule_rounded,
              color: AppStyles.warning,
              size: 24,
            ),
            const SizedBox(width: AppStyles.spaceMD),
            Text(
              'Schedule Required',
              style: AppStyles.subsectionHeader.copyWith(
                color: context.foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Please select a schedule from your calendar before starting the timer.',
              style: AppStyles.bodyMedium.copyWith(
                color: context.foreground,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppStyles.spaceMD),
            Container(
              padding: const EdgeInsets.all(AppStyles.spaceMD),
              decoration: BoxDecoration(
                color: context.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppStyles.radiusSM),
                border: Border.all(
                  color: context.warning.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_rounded,
                    color: AppStyles.warning,
                    size: 16,
                  ),
                  const SizedBox(width: AppStyles.spaceXS),
                  Expanded(
                    child: Text(
                      'This helps track your study progress and ensures focused learning.',
                      style: AppStyles.bodySmall.copyWith(
                        color: AppStyles.warning,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: TextStyle(
                color: context.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _finishSession() {
    if (!_isRunning || !_isStudyTime) return;
    
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finish Session'),
        content: const Text('Are you sure you want to finish this study session early?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _completeSessionEarly();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppStyles.success,
              foregroundColor: context.primaryForeground,
            ),
            child: const Text('Finish'),
          ),
        ],
      ),
    );
  }

  void _completeSessionEarly() {
    _timer?.cancel();
    _timer = null;
    
    setState(() {
      _isRunning = false;
    });
    
    // Complete the session with actual time spent
    _completeTimerSession();
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            const Text('Session completed early!'),
          ],
        ),
        backgroundColor: AppStyles.success,
        duration: const Duration(seconds: 2),
      ),
    );
    
    print('✅ Session finished early by user');
  }

  void _onTimerComplete() {
    _timer?.cancel();
    _timer = null;
    
    // Save study session if it was a study session
    if (_isStudyTime) {
      _completeTimerSession();
    }
    
    // Play alarm notification
    if (_alarmEnabled) {
      _playAlarm();
    }
    
    setState(() {
      _isRunning = false;
      if (_isStudyTime) {
        _completedPomodoros++;
        // Switch to break
        _isStudyTime = false;
        _currentSeconds = _completedPomodoros % 4 == 0 
            ? _longBreakDuration 
            : _shortBreakDuration;
        _initialSeconds = _currentSeconds;
      } else {
        // Switch to study
        _isStudyTime = true;
        _currentSeconds = _studyDuration;
        _initialSeconds = _studyDuration;
      }
    });
    
    // Show completion dialog
    _showCompletionDialog();
  }

  void _playAlarm() {
    // Vibration feedback
    HapticFeedback.heavyImpact();
    
    // Show notification
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _isStudyTime ? Icons.coffee_rounded : Icons.psychology_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _isStudyTime 
                    ? '🎉 Study session complete! Time for a break.'
                    : '⚡ Break time over! Ready to focus?',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: _isStudyTime ? context.success : context.primary,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              _isStudyTime ? Icons.celebration_rounded : Icons.psychology_rounded,
              color: _isStudyTime ? context.success : context.primary,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              _isStudyTime ? 'Session Complete!' : 'Break Complete!',
              style: AppStyles.sectionHeader.copyWith(
                fontSize: 20,
              ),
            ),
          ],
        ),
        content: Text(
          _isStudyTime 
              ? 'Great job! You completed a ${_studyDuration ~/ 60}-minute focus session. Ready for a ${(_completedPomodoros % 4 == 0 ? _longBreakDuration : _shortBreakDuration) ~/ 60}-minute break?'
              : 'Break time is over! Ready to start your next ${_studyDuration ~/ 60}-minute focus session?',
          style: AppStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Keep the timer stopped
            },
            child: const Text('Wait'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _startTimer(); // Auto-start next session
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _isStudyTime ? context.warning : context.primary,
            ),
            child: Text(_isStudyTime ? 'Start Break' : 'Start Focus'),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    double progress = _initialSeconds > 0 ? (_initialSeconds - _currentSeconds) / _initialSeconds : 0;
    
    return Scaffold(
      backgroundColor: context.background,
      body: Container(
        color: context.background,
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              // Timer Content
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppStyles.spaceXL, 
                  AppStyles.spaceXL + 60, // Add top padding for back button
                  AppStyles.spaceXL, 
                  AppStyles.spaceXL
                ),
                child: Column(
                  children: [
                    // Enhanced Progress Stats
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Completed',
                            _completedPomodoros.toString(),
                            'Sessions',
                            Icons.check_circle_rounded,
                            context.success,
                          ),
                        ),
                        const SizedBox(width: AppStyles.spaceMD),
                        Expanded(
                          child: _buildStatCard(
                            'Current',
                            _isStudyTime ? '${_studyDuration ~/ 60}min' : '${_initialSeconds ~/ 60}min',
                            'Duration',
                            Icons.timer_rounded,
                            _isStudyTime ? AppStyles.primary : AppStyles.warning,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: AppStyles.spaceXL),
                    
                    // Calendar Session Selector - Always show when in study mode
                    if (_isStudyTime)
                      _buildSessionSelector(),
                    
                    const SizedBox(height: AppStyles.spaceXL),
                    
                    // Enhanced Timer Circle
                    Container(
                      width: context.timerCircleSize,
                      height: context.timerCircleSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (_isStudyTime && _selectedCalendarSession == null && !_isRunning) 
                          ? context.muted.withOpacity(0.3)
                          : context.card,
                        border: Border.all(
                          color: (_isStudyTime && _selectedCalendarSession == null && !_isRunning) 
                            ? AppStyles.muted.withOpacity(0.2)
                            : context.border.withOpacity(0.3),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppStyles.black.withOpacity(0.12),
                            blurRadius: 40,
                            offset: const Offset(0, 20),
                          ),
                          BoxShadow(
                            color: AppStyles.black.withOpacity(0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                          BoxShadow(
                            color: (_isStudyTime ? context.primary : context.warning).withOpacity(0.15),
                            blurRadius: 32,
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Enhanced Progress Ring
                          SizedBox(
                            width: 300,
                            height: 300,
                            child: CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 10,
                              backgroundColor: AppStyles.muted.withOpacity(0.2),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _isStudyTime ? context.primary : context.warning,
                              ),
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                          // Enhanced Time Display
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _formatTime(_currentSeconds),
                                style: AppStyles.screenTitle.copyWith(
                                  fontSize: 64,
                                  fontWeight: FontWeight.w900,
                                  height: 1.0,
                                  letterSpacing: -3,
                                  color: (_isStudyTime && _selectedCalendarSession == null && !_isRunning)
                                    ? context.mutedForeground
                                    : context.foreground,
                                ),
                              ),
                              const SizedBox(height: AppStyles.spaceMD),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppStyles.spaceLG,
                                  vertical: AppStyles.spaceSM,
                                ),
                                decoration: BoxDecoration(
                                  color: (_isStudyTime ? context.primary : context.warning).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: (_isStudyTime ? context.primary : context.warning).withOpacity(0.3),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (_isStudyTime ? context.primary : context.warning).withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _isStudyTime ? Icons.psychology_rounded : Icons.coffee_rounded,
                                      color: _isStudyTime ? context.primary : context.warning,
                                      size: 16,
                                    ),
                                    const SizedBox(width: AppStyles.spaceXS),
                                    Text(
                                      _isStudyTime ? 'Focus Mode' : 'Break Mode',
                                      style: AppStyles.bodyMedium.copyWith(
                                        color: _isStudyTime ? context.primary : context.warning,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_appBlockingEnabled && _selectedBlockedApps.isNotEmpty && _isRunning && _isStudyTime) ...[
                                const SizedBox(height: AppStyles.spaceSM),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppStyles.spaceMD,
                                    vertical: AppStyles.spaceXS,
                                  ),
                                  decoration: BoxDecoration(
                                    color: context.destructive.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: context.destructive.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.block_rounded,
                                        color: AppStyles.destructive,
                                        size: 14,
                                      ),
                                      const SizedBox(width: AppStyles.spaceXS),
                                      Text(
                                        '${_selectedBlockedApps.length} apps blocked',
                                        style: AppStyles.bodySmall.copyWith(
                                          color: context.destructive,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: AppStyles.spaceXXL * 2),
                    
                    // Enhanced Control Buttons - 2x2 Grid
                    Column(
                      children: [
                        // First row - Main controls
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Reset button
                            _buildControlButton(
                              onPressed: _resetTimer,
                              icon: Icons.refresh_rounded,
                              backgroundColor: context.card,
                              foregroundColor: context.mutedForeground,
                              borderColor: context.border,
                            ),
                            
                            const SizedBox(width: AppStyles.spaceXL),
                            
                            // Play/Pause button
                            _buildControlButton(
                              onPressed: _isRunning ? _pauseTimer : _startTimer,
                              icon: _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              backgroundColor: (_isStudyTime && _selectedCalendarSession == null && !_isRunning)
                                ? context.muted
                                : (_isStudyTime ? context.primary : context.warning),
                              foregroundColor: (_isStudyTime && _selectedCalendarSession == null && !_isRunning)
                                ? context.mutedForeground
                                : context.primaryForeground,
                              isLarge: true,
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: AppStyles.spaceLG),
                        
                        // Second row - Additional controls
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Finish button (show placeholder if not running to maintain layout)
                            _buildControlButton(
                              onPressed: (_isRunning && _isStudyTime) ? _finishSession : () {},
                              icon: Icons.check_rounded,
                              backgroundColor: (_isRunning && _isStudyTime) 
                                  ? context.success 
                                  : context.card.withOpacity(0.5),
                              foregroundColor: (_isRunning && _isStudyTime) 
                                  ? context.primaryForeground 
                                  : context.mutedForeground.withOpacity(0.5),
                              borderColor: (_isRunning && _isStudyTime) 
                                  ? context.success 
                                  : context.border.withOpacity(0.5),
                            ),
                            
                            const SizedBox(width: AppStyles.spaceXL),
                            
                            // Settings button
                            _buildControlButton(
                              onPressed: _showTimerSettings,
                              icon: Icons.settings_rounded,
                              backgroundColor: context.card,
                              foregroundColor: context.mutedForeground,
                              borderColor: context.border,
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: AppStyles.spaceXXL),
                  ],
                ),
              ),
              
              // Floating Back Button
              Positioned(
                top: AppStyles.spaceLG,
                left: AppStyles.spaceXL,
                child: Container(
                  decoration: BoxDecoration(
                    color: context.card.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(AppStyles.radiusMD),
                    border: Border.all(
                      color: context.border.withOpacity(0.6),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppStyles.black.withOpacity(0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: AppStyles.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: context.foreground,
                      size: 22,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle, IconData icon, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(AppStyles.spaceLG),
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(AppStyles.radiusLG),
        border: Border.all(
          color: context.border.withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppStyles.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: accentColor.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 0),
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
                  fontWeight: FontWeight.w600,
                  color: context.mutedForeground,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: accentColor,
                  size: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppStyles.spaceSM),
          Text(
            value,
            style: AppStyles.sectionHeader.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.0,
              fontSize: 26,
              color: context.foreground,
            ),
          ),
          const SizedBox(height: AppStyles.spaceXS),
          Text(
            subtitle,
            style: AppStyles.bodySmall.copyWith(
              color: context.mutedForeground,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required VoidCallback onPressed,
    required IconData icon,
    required Color backgroundColor,
    required Color foregroundColor,
    Color? borderColor,
    bool isLarge = false,
  }) {
    return Container(
      width: isLarge ? 88 : 72,
      height: isLarge ? 88 : 72,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(isLarge ? 44 : 36),
        border: borderColor != null ? Border.all(
          color: borderColor,
          width: 1.5,
        ) : null,
        boxShadow: [
          BoxShadow(
            color: AppStyles.black.withOpacity(isLarge ? 0.15 : 0.1),
            blurRadius: isLarge ? 20 : 12,
            offset: Offset(0, isLarge ? 8 : 4),
          ),
          if (isLarge) BoxShadow(
            color: backgroundColor.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(isLarge ? 44 : 36),
          child: Center(
            child: Icon(
              icon,
              color: foregroundColor,
              size: isLarge ? 40 : 32,
            ),
          ),
        ),
      ),
    );
  }

  void _showTimerSettings() {
    showResponsiveDialog(
      context,
      title: Row(
        children: [
          Icon(
            Icons.tune_rounded,
            color: AppStyles.primary,
            size: context.responsive(mobile: 20, tablet: 24, desktop: 28),
          ),
          SizedBox(width: context.spacing(12)),
          Text(
            'Timer Settings',
            style: context.scaleTextStyle(AppStyles.sectionHeader),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildResponsiveDurationSetting(
            'Focus Duration',
            _studyDuration ~/ 60,
            (value) {
              setState(() {
                _studyDuration = value * 60;
                if (_isStudyTime && !_isRunning) {
                  _currentSeconds = _studyDuration;
                  _initialSeconds = _studyDuration;
                }
              });
              _saveTimerSettings();
            },
            Icons.psychology_rounded,
            context.primary,
          ),

          SizedBox(height: context.spacing(20)),
          _buildAppBlockingSetting(),
          SizedBox(height: context.spacing(16)),
          _buildResponsiveSwitchTile(),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            padding: context.responsive(
              mobile: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              tablet: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              desktop: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          ),
          child: Text(
            'Cancel',
            style: context.scaleTextStyle(AppStyles.buttonTextSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            _saveTimerSettings();
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle, color: context.primaryForeground),
                    SizedBox(width: context.spacing(12)),
                    Text(
                      'Timer settings saved!',
                      style: context.scaleTextStyle(AppStyles.bodyMedium.copyWith(color: context.primaryForeground)),
                    ),
                  ],
                ),
                backgroundColor: context.success,
                behavior: SnackBarBehavior.floating,
                margin: context.responsivePadding,
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            padding: context.responsive(
              mobile: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              tablet: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              desktop: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          ),
          child: Text(
            'Save',
            style: context.scaleTextStyle(AppStyles.buttonText),
          ),
        ),
      ],
    );
  }



  Widget _buildSessionSelector() {
    return Container(
      padding: const EdgeInsets.all(AppStyles.spaceLG),
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(AppStyles.radiusMD),
        border: Border.all(color: context.border),
        boxShadow: context.shadowSM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppStyles.spaceXS),
                decoration: BoxDecoration(
                  color: context.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppStyles.radiusSM),
                ),
                child: Icon(
                  Icons.calendar_today_rounded,
                  color: context.primary,
                  size: 16,
                ),
              ),
              const SizedBox(width: AppStyles.spaceMD),
              Expanded(
                child: Text(
                  'Study Schedule',
                  style: AppStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.foreground,
                  ),
                ),
              ),
              // Refresh button with loading state
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    // Show loading feedback
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(context.primaryForeground),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text('Refreshing schedules...'),
                          ],
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                    
                    // Force refresh
                    await _loadAvailableSchedules();
                    
                    // Show result feedback
                    if (mounted) {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            _availableCalendarSessions.isEmpty 
                              ? 'No schedules found. Check your calendar.'
                              : 'Found ${_availableCalendarSessions.length} schedule(s)!'
                          ),
                          backgroundColor: _availableCalendarSessions.isEmpty 
                            ? AppStyles.warning 
                            : context.success,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(AppStyles.radiusSM),
                  child: Container(
                    padding: const EdgeInsets.all(AppStyles.spaceXS),
                    child: Icon(
                      Icons.refresh_rounded,
                      color: context.mutedForeground,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppStyles.spaceMD),
          
          // Modern Dropdown
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppStyles.spaceMD,
              vertical: AppStyles.spaceSM,
            ),
            decoration: BoxDecoration(
              color: context.background,
              borderRadius: BorderRadius.circular(AppStyles.radiusMD),
              border: Border.all(
                color: _selectedCalendarSession != null 
                  ? context.primary.withOpacity(0.3)
                  : context.border,
                width: 1,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<CalendarEvent?>(
                value: _selectedCalendarSession,
                isExpanded: true,
                hint: Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      color: context.warning,
                      size: 16,
                    ),
                    const SizedBox(width: AppStyles.spaceXS),
                    Text(
                      'Please select a schedule to start',
                      style: AppStyles.bodyMedium.copyWith(
                        color: context.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  color: context.mutedForeground,
                ),
                items: [
                  // Calendar events
                  if (_availableCalendarSessions.isEmpty)
                    DropdownMenuItem<CalendarEvent?>(
                      value: null,
                      enabled: false,
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: context.mutedForeground,
                            size: 16,
                          ),
                          const SizedBox(width: AppStyles.spaceXS),
                          Text(
                            'No schedules available',
                            style: AppStyles.bodyMedium.copyWith(
                              color: context.mutedForeground,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._availableCalendarSessions.map((event) {
                      final subject = _subjects.firstWhere(
                        (s) => s.id == event.subjectId,
                        orElse: () => Subject(
                          id: 'unknown',
                          name: 'General',
                          color: '#2563EB',
                          userId: _currentUserId,
                          createdAt: DateTime.now(),
                        ),
                      );
                      
                      final task = event.taskId != null 
                        ? _tasks.firstWhere(
                            (t) => t.id == event.taskId,
                            orElse: () => Task(
                              id: 'unknown',
                              title: 'General Task',
                              subjectId: event.subjectId ?? 'unknown',
                              userId: _currentUserId,
                              createdAt: DateTime.now(),
                              dueDate: DateTime.now(),
                            ),
                          )
                        : null;
                      
                      return DropdownMenuItem<CalendarEvent?>(
                        value: event,
                        child: Row(
                          children: [
                            Stack(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: event.isCompleted 
                                      ? AppStyles.success 
                                      : Color(int.parse(subject.color.replaceFirst('#', '0xff'))),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                if (event.isCompleted)
                                  Positioned(
                                    right: -1,
                                    top: -1,
                                    child: Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: AppStyles.success,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: context.border,
                                          width: 1,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.check,
                                        size: 4,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: AppStyles.spaceXS),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    event.title,
                                    style: AppStyles.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: [
                                        // Date badge
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: context.mutedForeground.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            '${event.startTime.day}/${event.startTime.month}',
                                            style: AppStyles.bodySmall.copyWith(
                                              color: context.mutedForeground,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: AppStyles.spaceXS),
                                        // Show completion time if completed, otherwise start time
                                        if (event.isCompleted) 
                                          FutureBuilder<String>(
                                            future: _getCompletionTimeText(event),
                                            builder: (context, snapshot) {
                                              return Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppStyles.success.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.check_circle,
                                                      color: AppStyles.success,
                                                      size: 12,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      snapshot.data ?? 'Completed',
                                                      style: AppStyles.bodySmall.copyWith(
                                                        color: AppStyles.success,
                                                        fontWeight: FontWeight.w600,
                                                        fontSize: 10,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          )
                                        else
                                          Text(
                                            '${event.startTime.hour.toString().padLeft(2, '0')}:${event.startTime.minute.toString().padLeft(2, '0')}',
                                            style: AppStyles.bodySmall.copyWith(
                                              color: AppStyles.mutedForeground,
                                            ),
                                          ),
                                      const SizedBox(width: AppStyles.spaceXS),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppStyles.primary.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '${event.durationMinutes}min',
                                          style: AppStyles.bodySmall.copyWith(
                                            color: AppStyles.primary,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                      if (task != null) ...[
                                        const SizedBox(width: AppStyles.spaceXS),
                                        Expanded(
                                          child: Text(
                                            ' • ${task.title}',
                                            style: AppStyles.bodySmall.copyWith(
                                              color: AppStyles.mutedForeground,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                ],
                onChanged: (CalendarEvent? newSession) {
                  _selectCalendarSession(newSession);
                },
              ),
            ),
          ),
          
          
          // No schedules message
          if (_availableCalendarSessions.isEmpty) ...[
            const SizedBox(height: AppStyles.spaceMD),
            Container(
              padding: const EdgeInsets.all(AppStyles.spaceMD),
              decoration: BoxDecoration(
                color: AppStyles.muted.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppStyles.radiusSM),
                border: Border.all(
                  color: context.border,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.calendar_month_rounded,
                    color: AppStyles.mutedForeground,
                    size: 24,
                  ),
                  const SizedBox(height: AppStyles.spaceXS),
                  Text(
                    'No schedules available',
                    style: AppStyles.bodyMedium.copyWith(
                      color: AppStyles.mutedForeground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Go to Calendar to add study schedules',
                    style: AppStyles.bodySmall.copyWith(
                      color: AppStyles.mutedForeground,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ]
          // Selected session info
          else if (_selectedCalendarSession != null) ...[
            const SizedBox(height: AppStyles.spaceMD),
            Container(
              padding: const EdgeInsets.all(AppStyles.spaceMD),
              decoration: BoxDecoration(
                color: context.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppStyles.radiusSM),
                border: Border.all(
                  color: context.primary.withOpacity(0.3),
                ),
                boxShadow: context.shadowSM,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: AppStyles.primary,
                    size: 20,
                  ),
                  const SizedBox(width: AppStyles.spaceMD),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ready to focus on:',
                          style: AppStyles.bodySmall.copyWith(
                            color: context.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          _selectedCalendarSession!.title,
                          style: AppStyles.bodyLarge.copyWith(
                            color: context.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResponsiveDurationSetting(
    String title,
    int minutes,
    Function(int) onChanged,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: context.responsive(
        mobile: const EdgeInsets.all(12),
        tablet: const EdgeInsets.all(16),
        desktop: const EdgeInsets.all(20),
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(
          context.responsive(mobile: 12, tablet: 16, desktop: 20),
        ),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon, 
                color: color, 
                size: context.responsive(mobile: 20, tablet: 24, desktop: 28),
              ),
              SizedBox(width: context.spacing(12)),
              Expanded(
                child: Text(
                  title,
                  style: context.scaleTextStyle(
                    AppStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: context.spacing(12)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildResponsiveIconButton(
                icon: Icons.remove_rounded,
                onPressed: minutes > 5 ? () => onChanged(minutes - 5) : null,
                color: color,
              ),
              SizedBox(width: context.spacing(16)),
              Container(
                padding: context.responsive(
                  mobile: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  tablet: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  desktop: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Text(
                  '${minutes}min',
                  style: context.scaleTextStyle(
                    AppStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ),
              SizedBox(width: context.spacing(16)),
              _buildResponsiveIconButton(
                icon: Icons.add_rounded,
                onPressed: minutes < 120 ? () => onChanged(minutes + 5) : null,
                color: color,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveIconButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required Color color,
  }) {
    return Container(
      width: context.responsive(mobile: 40, tablet: 44, desktop: 48),
      height: context.responsive(mobile: 40, tablet: 44, desktop: 48),
      decoration: BoxDecoration(
        color: onPressed != null ? color.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: onPressed != null ? color.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
        ),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: onPressed != null ? color : Colors.grey,
          size: context.responsive(mobile: 18, tablet: 20, desktop: 22),
        ),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildResponsiveSwitchTile() {
    return Container(
      padding: context.responsive(
        mobile: const EdgeInsets.all(16),
        tablet: const EdgeInsets.all(20),
        desktop: const EdgeInsets.all(24),
      ),
      decoration: BoxDecoration(
        color: AppStyles.card,
        borderRadius: BorderRadius.circular(
          context.responsive(mobile: 12, tablet: 16, desktop: 20),
        ),
        border: Border.all(
          color: context.border.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: AppStyles.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.notifications_rounded,
            color: _alarmEnabled ? context.primary : context.mutedForeground,
            size: context.responsive(mobile: 24, tablet: 28, desktop: 32),
          ),
          SizedBox(width: context.spacing(16)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Alarm Notifications',
                  style: context.scaleTextStyle(
                    AppStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(height: context.spacing(4)),
                Text(
                  'Get notified when sessions end',
                  style: context.scaleTextStyle(
                    AppStyles.bodySmall.copyWith(
                      color: AppStyles.mutedForeground,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: context.responsive(mobile: 1.0, tablet: 1.1, desktop: 1.2),
            child: Switch(
              value: _alarmEnabled,
              onChanged: (value) => setState(() => _alarmEnabled = value),
              activeColor: AppStyles.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBlockingSetting() {
    return Container(
      padding: EdgeInsets.all(context.spacing(16)),
      decoration: BoxDecoration(
        color: AppStyles.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.border, width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.block_rounded,
                color: AppStyles.destructive,
                size: context.responsive(mobile: 20, tablet: 24, desktop: 28),
              ),
              SizedBox(width: context.spacing(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'App Blocking',
                      style: context.scaleTextStyle(AppStyles.bodyLarge),
                    ),
                    Text(
                      'Block distracting apps during study sessions',
                      style: context.scaleTextStyle(
                        AppStyles.bodySmall.copyWith(
                          color: AppStyles.mutedForeground,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Transform.scale(
                scale: context.responsive(mobile: 1.0, tablet: 1.1, desktop: 1.2),
                child: Switch(
                  value: _appBlockingEnabled,
                  onChanged: (value) async {
                    if (value && !await AppBlockingService.hasUsagePermission()) {
                      await AppBlockingService.requestUsagePermission();
                      return;
                    }
                    setState(() => _appBlockingEnabled = value);
                    _saveTimerSettings();
                  },
                  activeColor: AppStyles.destructive,
                ),
              ),
            ],
          ),
          if (_appBlockingEnabled) ...[
            SizedBox(height: context.spacing(12)),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${_selectedBlockedApps.length} apps selected',
                    style: context.scaleTextStyle(AppStyles.bodySmall),
                  ),
                ),
                TextButton.icon(
                  onPressed: _showAppSelectionDialog,
                  icon: Icon(
                    Icons.apps_rounded,
                    size: context.responsive(mobile: 16, tablet: 18, desktop: 20),
                  ),
                  label: Text(
                    'Select Apps',
                    style: context.scaleTextStyle(AppStyles.buttonTextSecondary),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showAppSelectionDialog() async {
    // Load apps if not already loaded
    if (_installedApps.isEmpty) {
      await _loadInstalledApps();
    }

    if (!mounted) return;

    showResponsiveDialog(
      context,
      title: Row(
        children: [
          Icon(
            Icons.apps_rounded,
            color: AppStyles.destructive,
            size: context.responsive(mobile: 20, tablet: 24, desktop: 28),
          ),
          SizedBox(width: context.spacing(12)),
          Text(
            'Select Apps to Block',
            style: context.scaleTextStyle(AppStyles.sectionHeader),
          ),
        ],
      ),
      content: Container(
        width: context.responsive(
          mobile: double.maxFinite,
          tablet: 400,
          desktop: 500,
        ),
        height: context.responsive(
          mobile: 400,
          tablet: 500,
          desktop: 600,
        ),
        child: _installedApps.isEmpty 
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppStyles.mutedForeground,
                  ),
                  SizedBox(height: context.spacing(16)),
                  Text(
                    'No apps found or permission needed',
                    style: context.scaleTextStyle(AppStyles.bodyMedium),
                  ),
                  SizedBox(height: context.spacing(8)),
                  TextButton(
                    onPressed: () async {
                      await AppBlockingService.requestUsagePermission();
                      await _loadInstalledApps();
                    },
                    child: Text('Grant Permission'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _installedApps.length,
              itemBuilder: (context, index) {
                final app = _installedApps[index];
                final isSelected = _selectedBlockedApps.contains(app.packageName);
                
                return CheckboxListTile(
                  title: Text(
                    app.packageName ?? 'Unknown App',
                    style: context.scaleTextStyle(AppStyles.bodyMedium),
                  ),
                  subtitle: Text(
                    'Package: ${app.packageName}',
                    style: context.scaleTextStyle(AppStyles.bodySmall.copyWith(
                      color: AppStyles.mutedForeground,
                    )),
                  ),
                  value: isSelected,
                  onChanged: (bool? value) async {
                    setState(() {
                      if (value == true) {
                        _selectedBlockedApps.add(app.packageName!);
                      } else {
                        _selectedBlockedApps.remove(app.packageName);
                      }
                    });
                    
                    // Save immediately when app is toggled
                    try {
                      final userId = _currentUserId;
                      print('🔄 Toggling app ${app.packageName} - New list: $_selectedBlockedApps');
                      await AppBlockingSettingsService.updateBlockedApps(userId, _selectedBlockedApps);
                      print('✅ Updated blocked apps for user $userId: ${_selectedBlockedApps.length} apps - ${_selectedBlockedApps.join(', ')}');
                    } catch (e) {
                      print('❌ Error updating blocked apps: $e');
                    }
                  },
                  activeColor: AppStyles.destructive,
                );
              },
            ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: context.scaleTextStyle(AppStyles.buttonTextSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            _saveTimerSettings();
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppStyles.destructive,
            foregroundColor: AppStyles.primaryForeground,
          ),
          child: Text(
            'Save',
            style: context.scaleTextStyle(AppStyles.buttonText),
          ),
        ),
      ],
    );
  }
}
