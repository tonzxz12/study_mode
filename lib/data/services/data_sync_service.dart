import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/subject.dart';
import '../models/study_session.dart';
import '../models/task.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/enhanced_firestore_service.dart';

class DataSyncService {
  static const String subjectsBoxName = 'subjects';
  static const String sessionsBoxName = 'study_sessions';
  static const String tasksBoxName = 'tasks';
  
  static Box<Subject>? _subjectsBox;
  static Box<StudySession>? _sessionsBox;
  static Box<Task>? _tasksBox;
  
  static bool _isInitialized = false;

  // Initialize Hive boxes
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Try to open boxes with error recovery
    await _openBoxSafely(subjectsBoxName, () async => _subjectsBox = await Hive.openBox<Subject>(subjectsBoxName));
    await _openBoxSafely(sessionsBoxName, () async => _sessionsBox = await Hive.openBox<StudySession>(sessionsBoxName));
    await _openBoxSafely(tasksBoxName, () async => _tasksBox = await Hive.openBox<Task>(tasksBoxName));
    
    _isInitialized = true;
    debugPrint('✅ DataSyncService initialized');
  }
  
  // Helper method to safely open a Hive box with error recovery
  static Future<void> _openBoxSafely(String boxName, Future<void> Function() openBox) async {
    try {
      await openBox();
    } catch (e) {
      debugPrint('❌ Error opening $boxName box: $e');
      
      // If there's a type casting error, clear the corrupted box and retry
      if (e.toString().contains('type \'Null\' is not a subtype of type \'String\'') ||
          e.toString().contains('type cast')) {
        debugPrint('🔄 Clearing corrupted $boxName box due to type casting error...');
        try {
          await Hive.deleteBoxFromDisk(boxName);
          debugPrint('🗑️ Corrupted $boxName box cleared, reinitializing...');
          
          // Retry opening the box
          await openBox();
          debugPrint('✅ $boxName box reinitialized successfully');
        } catch (clearError) {
          debugPrint('❌ Error clearing corrupted $boxName box: $clearError');
          rethrow;
        }
      } else {
        rethrow;
      }
    }
  }

  // Subject Management
  static Future<void> saveSubject(Subject subject) async {
    await initialize();
    
    try {
      // Save locally first
      await _subjectsBox!.put(subject.id, subject);
      debugPrint('✅ Subject saved locally: ${subject.name}');
      
      // Test Firestore connection first
      final canConnect = await EnhancedFirestoreService.testConnection();
      if (!canConnect) {
        debugPrint('⚠️ Firestore connection failed, data saved locally only');
        return;
      }
      
      // Sync to Firestore with enhanced error handling
      final success = await EnhancedFirestoreService.saveSubject(subject);
      if (success) {
        debugPrint('✅ Subject synced to Firestore: ${subject.name}');
      } else {
        debugPrint('⚠️ Failed to sync subject to Firestore: ${subject.name}');
      }
    } catch (e) {
      debugPrint('❌ Error saving subject: $e');
      rethrow;
    }
  }

  static Future<List<Subject>> getAllSubjects() async {
    await initialize();
    
    try {
      // First, try to load from Firestore (online database)
      debugPrint('📱 Loading subjects from online database (Firestore)...');
      final firestoreSubjects = await EnhancedFirestoreService.getAllSubjects();
      
      if (firestoreSubjects.isNotEmpty) {
        debugPrint('✅ Loaded ${firestoreSubjects.length} subjects from Firestore');
        // Update local storage with fresh data from Firestore
        for (final subject in firestoreSubjects) {
          await _subjectsBox!.put(subject.id, subject);
        }
        return firestoreSubjects;
      } else {
        debugPrint('📦 No subjects found in Firestore, checking local storage...');
      }
      
      // Fallback to local storage if Firestore is empty or fails
      final localSubjects = _subjectsBox!.values.toList();
      debugPrint('📦 Loaded ${localSubjects.length} subjects from local storage');
      return localSubjects;
    } catch (e) {
      debugPrint('❌ Error loading subjects from Firestore, trying local: $e');
      try {
        final localSubjects = _subjectsBox!.values.toList();
        debugPrint('📦 Fallback: Loaded ${localSubjects.length} subjects from local storage');
        return localSubjects;
      } catch (localError) {
        debugPrint('❌ Error getting subjects from local storage too: $localError');
        return [];
      }
    }
  }

  static Future<Subject?> getSubject(String id) async {
    await initialize();
    
    try {
      return _subjectsBox!.get(id);
    } catch (e) {
      debugPrint('❌ Error getting subject: $e');
      return null;
    }
  }

  static Future<void> deleteSubject(String subjectId) async {
    await initialize();
    
    try {
      // Delete locally first
      await _subjectsBox!.delete(subjectId);
      
      // Delete related sessions locally
      final sessions = _sessionsBox!.values.where((s) => s.subjectId == subjectId).toList();
      for (final session in sessions) {
        await _sessionsBox!.delete(session.id);
      }
      
      debugPrint('✅ Subject deleted locally: $subjectId');
      
      // Sync deletion to Firestore
      try {
        await FirestoreService.deleteSubject(subjectId);
        debugPrint('✅ Subject deletion synced to Firestore: $subjectId');
      } catch (e) {
        debugPrint('⚠️ Failed to sync subject deletion to Firestore: $e');
      }
    } catch (e) {
      debugPrint('❌ Error deleting subject: $e');
      rethrow;
    }
  }

  // Study Session Management
  static Future<void> saveStudySession(StudySession session) async {
    await initialize();
    
    try {
      // Save locally first
      await _sessionsBox!.put(session.id, session);
      debugPrint('✅ Study session saved locally: ${session.id}');
      
      // Test Firestore connection first
      final canConnect = await EnhancedFirestoreService.testConnection();
      if (!canConnect) {
        debugPrint('⚠️ Firestore connection failed, study session saved locally only');
        return;
      }
      
      // Sync to Firestore with enhanced error handling
      final success = await EnhancedFirestoreService.saveStudySession(session);
      if (success) {
        debugPrint('✅ Study session synced to Firestore: ${session.id}');
      } else {
        debugPrint('⚠️ Failed to sync study session to Firestore: ${session.id}');
      }
    } catch (e) {
      debugPrint('❌ Error saving study session: $e');
      rethrow;
    }
  }

  static Future<void> updateStudySession(StudySession session) async {
    await initialize();
    
    try {
      // Update locally first
      await _sessionsBox!.put(session.id, session);
      debugPrint('✅ Study session updated locally: ${session.id}');
      
      // Sync update to Firestore
      try {
        await FirestoreService.updateStudySession(session);
        debugPrint('✅ Study session update synced to Firestore: ${session.id}');
      } catch (e) {
        debugPrint('⚠️ Failed to sync study session update to Firestore: $e');
      }
    } catch (e) {
      debugPrint('❌ Error updating study session: $e');
      rethrow;
    }
  }

  static Future<List<StudySession>> getAllStudySessions() async {
    await initialize();
    
    try {
      // First, try to load from Firestore (online database)
      debugPrint('📱 Loading study sessions from online database (Firestore)...');
      final firestoreSessions = await EnhancedFirestoreService.getAllStudySessions();
      
      if (firestoreSessions.isNotEmpty) {
        debugPrint('✅ Loaded ${firestoreSessions.length} sessions from Firestore');
        // Update local storage with fresh data from Firestore
        for (final session in firestoreSessions) {
          await _sessionsBox!.put(session.id, session);
        }
        return firestoreSessions;
      } else {
        debugPrint('📦 No sessions found in Firestore, checking local storage...');
      }
      
      // Fallback to local storage if Firestore is empty or fails
      final localSessions = _sessionsBox!.values.toList();
      debugPrint('📦 Loaded ${localSessions.length} sessions from local storage');
      return localSessions;
    } catch (e) {
      debugPrint('❌ Error loading sessions from Firestore, trying local: $e');
      try {
        final localSessions = _sessionsBox!.values.toList();
        debugPrint('📦 Fallback: Loaded ${localSessions.length} sessions from local storage');
        return localSessions;
      } catch (localError) {
        debugPrint('❌ Error getting sessions from local storage too: $localError');
        return [];
      }
    }
  }

  static Future<List<StudySession>> getSessionsForSubject(String subjectId) async {
    await initialize();
    
    try {
      return _sessionsBox!.values.where((s) => s.subjectId == subjectId).toList();
    } catch (e) {
      debugPrint('❌ Error getting sessions for subject: $e');
      return [];
    }
  }

  static Future<StudySession?> getStudySession(String id) async {
    await initialize();
    
    try {
      return _sessionsBox!.get(id);
    } catch (e) {
      debugPrint('❌ Error getting study session: $e');
      return null;
    }
  }

  // Task Management
  static Future<void> saveTask(Task task) async {
    await initialize();
    
    try {
      // Save locally first
      await _tasksBox!.put(task.id, task);
      debugPrint('✅ Task saved locally: ${task.title}');
      
      // Test Firestore connection first
      final canConnect = await EnhancedFirestoreService.testConnection();
      if (!canConnect) {
        debugPrint('⚠️ Firestore connection failed, task saved locally only');
        return;
      }
      
      // Sync to Firestore with enhanced error handling
      final success = await EnhancedFirestoreService.saveTask(task);
      if (success) {
        debugPrint('✅ Task synced to Firestore: ${task.title}');
      } else {
        debugPrint('⚠️ Failed to sync task to Firestore: ${task.title}');
      }
    } catch (e) {
      debugPrint('❌ Error saving task: $e');
      rethrow;
    }
  }

  static Future<List<Task>> getAllTasks() async {
    await initialize();
    
    try {
      // First, try to load from Firestore (online database)
      debugPrint('📱 Loading tasks from online database (Firestore)...');
      final firestoreTasks = await EnhancedFirestoreService.getAllTasks();
      
      if (firestoreTasks.isNotEmpty) {
        debugPrint('✅ Loaded ${firestoreTasks.length} tasks from Firestore');
        // Update local storage with fresh data from Firestore
        for (final task in firestoreTasks) {
          await _tasksBox!.put(task.id, task);
        }
        return firestoreTasks;
      } else {
        debugPrint('📦 No tasks found in Firestore, checking local storage...');
      }
      
      // Fallback to local storage if Firestore is empty or fails
      final localTasks = _tasksBox!.values.toList();
      debugPrint('📦 Loaded ${localTasks.length} tasks from local storage');
      return localTasks;
    } catch (e) {
      debugPrint('❌ Error loading tasks from Firestore, trying local: $e');
      try {
        final localTasks = _tasksBox!.values.toList();
        debugPrint('📦 Fallback: Loaded ${localTasks.length} tasks from local storage');
        return localTasks;
      } catch (localError) {
        debugPrint('❌ Error getting tasks from local storage too: $localError');
        return [];
      }
    }
  }

  static Future<List<Task>> getTasksForSubject(String subjectId) async {
    await initialize();
    
    try {
      return _tasksBox!.values.where((t) => t.subjectId == subjectId).toList();
    } catch (e) {
      debugPrint('❌ Error getting tasks for subject: $e');
      return [];
    }
  }

  static Future<void> updateTask(Task task) async {
    await initialize();
    
    try {
      // Update locally first
      await _tasksBox!.put(task.id, task);
      debugPrint('✅ Task updated locally: ${task.title}');
      
      // Sync to Firestore
      try {
        await FirestoreService.tasks.doc(task.id).update({
          'title': task.title,
          'description': task.description,
          'subjectId': task.subjectId,
          'priority': task.priority,
          'dueDate': task.dueDate.toIso8601String(),
          'isCompleted': task.isCompleted,
          'updatedAt': DateTime.now().toIso8601String(),
        });
        debugPrint('✅ Task update synced to Firestore: ${task.title}');
      } catch (e) {
        debugPrint('⚠️ Failed to sync task update to Firestore: $e');
      }
    } catch (e) {
      debugPrint('❌ Error updating task: $e');
      rethrow;
    }
  }

  static Future<void> deleteTask(String taskId) async {
    await initialize();
    
    try {
      // Delete locally first
      await _tasksBox!.delete(taskId);
      debugPrint('✅ Task deleted locally: $taskId');
      
      // Sync deletion to Firestore
      try {
        await FirestoreService.tasks.doc(taskId).delete();
        debugPrint('✅ Task deletion synced to Firestore: $taskId');
      } catch (e) {
        debugPrint('⚠️ Failed to sync task deletion to Firestore: $e');
      }
    } catch (e) {
      debugPrint('❌ Error deleting task: $e');
      rethrow;
    }
  }

  // Analytics and Statistics
  static Future<Map<String, dynamic>> getLocalAnalytics() async {
    await initialize();
    
    try {
      final sessions = await getAllStudySessions();
      final subjects = await getAllSubjects();
      final tasks = await getAllTasks();
      
      final completedSessions = sessions.where((s) => s.isCompleted).toList();
      final completedTasks = tasks.where((t) => t.isCompleted).toList();
      
      final totalMinutes = completedSessions.fold<int>(
        0, (sum, session) => sum + session.actualDuration.inMinutes
      );
      
      final averageFocus = completedSessions.isNotEmpty
          ? completedSessions.fold<double>(0, (sum, session) => sum + session.focusScore) / completedSessions.length
          : 0.0;
      
      // Calculate this week's data
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      final thisWeekSessions = completedSessions.where(
        (s) => s.startTime.isAfter(weekAgo)
      ).toList();
      
      final weeklyMinutes = thisWeekSessions.fold<int>(
        0, (sum, session) => sum + session.actualDuration.inMinutes
      );
      
      return {
        'totalSessions': completedSessions.length,
        'totalSubjects': subjects.length,
        'totalTasks': tasks.length,
        'completedTasks': completedTasks.length,
        'taskCompletionRate': tasks.isNotEmpty ? completedTasks.length / tasks.length : 0.0,
        'totalMinutes': totalMinutes,
        'averageFocusScore': averageFocus,
        'weeklyMinutes': weeklyMinutes,
        'weeklySessionCount': thisWeekSessions.length,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('❌ Error getting local analytics: $e');
      return {};
    }
  }

  // Data Export for Research
  static Future<Map<String, dynamic>> exportAllData() async {
    await initialize();
    
    try {
      final localAnalytics = await getLocalAnalytics();
      final sessions = await getAllStudySessions();
      final subjects = await getAllSubjects();
      final tasks = await getAllTasks();
      
      // Also try to get Firestore data if available
      Map<String, dynamic>? firestoreData;
      try {
        firestoreData = await FirestoreService.exportAllUserData();
      } catch (e) {
        debugPrint('⚠️ Could not export Firestore data: $e');
      }
      
      return {
        'exportedAt': DateTime.now().toIso8601String(),
        'appVersion': '1.0.0',
        'dataSource': 'hybrid', // Both local and cloud
        'localData': {
          'subjects': subjects.map((s) => s.toFirestore()).toList(),
          'studySessions': sessions.map((s) => s.toFirestore()).toList(),
          'tasks': tasks.map((t) => t.toFirestore()).toList(),
          'analytics': localAnalytics,
        },
        'firestoreData': firestoreData,
        'summary': {
          'totalSubjects': subjects.length,
          'totalSessions': sessions.length,
          'totalTasks': tasks.length,
          'completedSessions': sessions.where((s) => s.isCompleted).length,
          'completedTasks': tasks.where((t) => t.isCompleted).length,
          'totalStudyMinutes': sessions
              .where((s) => s.isCompleted)
              .fold<int>(0, (sum, s) => sum + s.actualDuration.inMinutes),
        }
      };
    } catch (e) {
      debugPrint('❌ Error exporting all data: $e');
      return {
        'exportedAt': DateTime.now().toIso8601String(),
        'error': e.toString(),
      };
    }
  }

  // Sync status and health checks
  static Future<Map<String, dynamic>> getSyncStatus() async {
    try {
      final localAnalytics = await getLocalAnalytics();
      
      Map<String, dynamic>? firestoreAnalytics;
      bool firestoreConnected = false;
      
      try {
        firestoreAnalytics = await FirestoreService.getStudyAnalytics();
        firestoreConnected = true;
      } catch (e) {
        debugPrint('Firestore not available: $e');
      }
      
      return {
        'local': {
          'connected': _isInitialized,
          'data': localAnalytics,
        },
        'firestore': {
          'connected': firestoreConnected,
          'data': firestoreAnalytics,
        },
        'syncStatus': firestoreConnected ? 'synced' : 'local-only',
        'lastChecked': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('❌ Error getting sync status: $e');
      return {
        'error': e.toString(),
        'lastChecked': DateTime.now().toIso8601String(),
      };
    }
  }

  // Force sync all local data to Firestore
  static Future<void> forceSyncToFirestore() async {
    await initialize();
    
    try {
      final subjects = await getAllSubjects();
      final sessions = await getAllStudySessions();
      final tasks = await getAllTasks();
      
      debugPrint('🔄 Starting force sync to Firestore...');
      debugPrint('📊 Syncing ${subjects.length} subjects, ${sessions.length} sessions, and ${tasks.length} tasks');
      
      // Sync subjects
      for (final subject in subjects) {
        try {
          await FirestoreService.saveSubject(subject);
        } catch (e) {
          debugPrint('❌ Failed to sync subject ${subject.name}: $e');
        }
      }
      
      // Sync sessions
      for (final session in sessions) {
        try {
          await FirestoreService.saveStudySession(session);
        } catch (e) {
          debugPrint('❌ Failed to sync session ${session.id}: $e');
        }
      }
      
      // Sync tasks
      for (final task in tasks) {
        try {
          await saveTask(task); // Use our own method which handles Firestore
        } catch (e) {
          debugPrint('❌ Failed to sync task ${task.id}: $e');
        }
      }
      
      debugPrint('✅ Force sync completed');
    } catch (e) {
      debugPrint('❌ Error during force sync: $e');
      rethrow;
    }
  }
}