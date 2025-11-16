import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../data/models/subject.dart';
import '../../data/models/study_session.dart';
import '../../data/models/task.dart';

class EnhancedFirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  static String? get currentUserId => _auth.currentUser?.uid;

  // Test connection to Firestore
  static Future<bool> testConnection() async {
    try {
      debugPrint('🧪 Testing Firestore connection...');
      
      if (currentUserId == null) {
        debugPrint('❌ No authenticated user for Firestore test');
        return false;
      }

      // Try to read from Firestore
      final testDoc = await _firestore
          .collection('test')
          .doc('connection_test')
          .get();
      
      debugPrint('✅ Firestore connection test successful');
      return true;
    } catch (e) {
      debugPrint('❌ Firestore connection test failed: $e');
      debugPrint('📋 Error type: ${e.runtimeType}');
      
      if (e is FirebaseException) {
        debugPrint('📋 Firebase error code: ${e.code}');
        debugPrint('📋 Firebase error message: ${e.message}');
      }
      return false;
    }
  }

  // Enhanced Subject CRUD Operations
  static Future<bool> saveSubject(Subject subject) async {
    if (currentUserId == null) {
      debugPrint('❌ Cannot save subject: No authenticated user');
      return false;
    }

    try {
      debugPrint('💾 Attempting to save subject: ${subject.name}');
      
      final docRef = _firestore.collection('subjects').doc(subject.id);
      
      await docRef.set({
        'id': subject.id,
        'userId': currentUserId,
        'name': subject.name,
        'color': subject.color,
        'description': subject.description,
        'createdAt': Timestamp.fromDate(subject.createdAt),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Subject saved successfully to Firestore: ${subject.name}');
      
      // Verify the save by reading it back
      final savedDoc = await docRef.get();
      if (savedDoc.exists) {
        debugPrint('✅ Subject verification successful: ${savedDoc.data()}');
        return true;
      } else {
        debugPrint('⚠️ Subject saved but verification failed');
        return false;
      }
      
    } catch (e) {
      debugPrint('❌ Error saving subject to Firestore: $e');
      debugPrint('📋 Subject data: {id: ${subject.id}, name: ${subject.name}, userId: $currentUserId}');
      
      if (e is FirebaseException) {
        debugPrint('📋 Firebase error code: ${e.code}');
        debugPrint('📋 Firebase error message: ${e.message}');
      }
      return false;
    }
  }

  static Future<List<Subject>> getAllSubjects() async {
    if (currentUserId == null) {
      debugPrint('❌ Cannot get subjects: No authenticated user');
      return [];
    }

    try {
      debugPrint('📖 Fetching subjects from Firestore for user: $currentUserId');
      
      final querySnapshot = await _firestore
          .collection('subjects')
          .where('userId', isEqualTo: currentUserId)
          .orderBy('createdAt', descending: false)
          .get();

      final subjects = querySnapshot.docs.map((doc) {
        final data = doc.data();
        debugPrint('📄 Subject document data: $data');
        
        return Subject(
          id: data['id'],
          name: data['name'],
          color: data['color'],
          description: data['description'] ?? '',
          userId: data['userId'] ?? 'current_user',
          createdAt: (data['createdAt'] as Timestamp).toDate(),
        );
      }).toList();

      debugPrint('✅ Retrieved ${subjects.length} subjects from Firestore');
      return subjects.cast<Subject>();

    } catch (e) {
      debugPrint('❌ Error getting subjects from Firestore: $e');
      if (e is FirebaseException) {
        debugPrint('📋 Firebase error code: ${e.code}');
        debugPrint('📋 Firebase error message: ${e.message}');
      }
      return [];
    }
  }

  static Future<bool> deleteSubject(String subjectId) async {
    if (currentUserId == null) {
      debugPrint('❌ Cannot delete subject: No authenticated user');
      return false;
    }

    try {
      debugPrint('🗑️ Deleting subject: $subjectId');
      
      // Delete the subject
      await _firestore.collection('subjects').doc(subjectId).delete();
      
      // Delete related study sessions
      final sessionsQuery = await _firestore
          .collection('study_sessions')
          .where('userId', isEqualTo: currentUserId)
          .where('subjectId', isEqualTo: subjectId)
          .get();

      final batch = _firestore.batch();
      for (var doc in sessionsQuery.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      debugPrint('✅ Subject and related sessions deleted successfully');
      return true;

    } catch (e) {
      debugPrint('❌ Error deleting subject: $e');
      return false;
    }
  }

  // Enhanced Study Session CRUD Operations
  static Future<bool> saveStudySession(StudySession session) async {
    if (currentUserId == null) {
      debugPrint('❌ Cannot save study session: No authenticated user');
      return false;
    }

    try {
      debugPrint('💾 Attempting to save study session: ${session.id}');
      
      final docRef = _firestore.collection('study_sessions').doc(session.id);
      
      final sessionData = {
        'id': session.id,
        'userId': currentUserId,
        'subjectId': session.subjectId,
        'startTime': Timestamp.fromDate(session.startTime),
        'endTime': session.endTime != null ? Timestamp.fromDate(session.endTime!) : null,
        'targetDurationMinutes': session.targetDuration.inMinutes,
        'notes': session.notes,
        'isCompleted': session.isCompleted,
        'focusScore': session.focusScore,
        'createdAt': FieldValue.serverTimestamp(),
      };

      debugPrint('📋 Session data to save: $sessionData');

      await docRef.set(sessionData);

      debugPrint('✅ Study session saved successfully to Firestore: ${session.id}');
      
      // Verify the save
      final savedDoc = await docRef.get();
      if (savedDoc.exists) {
        debugPrint('✅ Study session verification successful: ${savedDoc.data()}');
        return true;
      } else {
        debugPrint('⚠️ Study session saved but verification failed');
        return false;
      }
      
    } catch (e) {
      debugPrint('❌ Error saving study session to Firestore: $e');
      debugPrint('📋 Session data: {id: ${session.id}, subjectId: ${session.subjectId}, userId: $currentUserId}');
      
      if (e is FirebaseException) {
        debugPrint('📋 Firebase error code: ${e.code}');
        debugPrint('📋 Firebase error message: ${e.message}');
      }
      return false;
    }
  }

  static Future<List<StudySession>> getAllStudySessions() async {
    if (currentUserId == null) {
      debugPrint('❌ Cannot get study sessions: No authenticated user');
      return [];
    }

    try {
      debugPrint('📖 Fetching study sessions from Firestore for user: $currentUserId');
      
      final querySnapshot = await _firestore
          .collection('study_sessions')
          .where('userId', isEqualTo: currentUserId)
          .orderBy('startTime', descending: true)
          .get();

      final sessions = querySnapshot.docs.map((doc) {
        final data = doc.data();
        debugPrint('📄 Study session document data: $data');
        
        return StudySession(
          id: data['id'],
          subjectId: data['subjectId'],
          userId: data['userId'] ?? 'current_user',
          startTime: (data['startTime'] as Timestamp).toDate(),
          endTime: data['endTime'] != null ? (data['endTime'] as Timestamp).toDate() : null,
          targetDuration: Duration(minutes: data['targetDurationMinutes'] ?? 60),
          notes: data['notes'] ?? '',
          isCompleted: data['isCompleted'] ?? false,
          focusScore: (data['focusScore'] ?? 0.0).toDouble(),
        );
      }).toList();

      debugPrint('✅ Retrieved ${sessions.length} study sessions from Firestore');
      return sessions.cast<StudySession>();

    } catch (e) {
      debugPrint('❌ Error getting study sessions from Firestore: $e');
      if (e is FirebaseException) {
        debugPrint('📋 Firebase error code: ${e.code}');
        debugPrint('📋 Firebase error message: ${e.message}');
      }
      return [];
    }
  }

  // Enhanced Task CRUD Operations
  static Future<bool> saveTask(Task task) async {
    if (currentUserId == null) {
      debugPrint('❌ Cannot save task: No authenticated user');
      return false;
    }

    try {
      debugPrint('💾 Attempting to save task: ${task.title}');
      
      final docRef = _firestore.collection('tasks').doc(task.id);
      
      await docRef.set({
        'id': task.id,
        'userId': currentUserId,
        'title': task.title,
        'description': task.description,
        'subjectId': task.subjectId,
        'dueDate': Timestamp.fromDate(task.dueDate),
        'isCompleted': task.isCompleted,
        'priority': task.priority,
        'createdAt': Timestamp.fromDate(task.createdAt),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Task saved successfully to Firestore: ${task.title}');
      
      // Verify the save
      final savedDoc = await docRef.get();
      if (savedDoc.exists) {
        debugPrint('✅ Task verification successful: ${savedDoc.data()}');
        return true;
      } else {
        debugPrint('⚠️ Task saved but verification failed');
        return false;
      }
      
    } catch (e) {
      debugPrint('❌ Error saving task to Firestore: $e');
      debugPrint('📋 Task data: {id: ${task.id}, title: ${task.title}, userId: $currentUserId}');
      
      if (e is FirebaseException) {
        debugPrint('📋 Firebase error code: ${e.code}');
        debugPrint('📋 Firebase error message: ${e.message}');
      }
      return false;
    }
  }

  static Future<List<Task>> getAllTasks() async {
    if (currentUserId == null) {
      debugPrint('❌ Cannot get tasks: No authenticated user');
      return [];
    }

    try {
      debugPrint('📖 Fetching tasks from Firestore for user: $currentUserId');
      
      final querySnapshot = await _firestore
          .collection('tasks')
          .where('userId', isEqualTo: currentUserId)
          .orderBy('createdAt', descending: false)
          .get();

      final tasks = querySnapshot.docs.map((doc) {
        final data = doc.data();
        debugPrint('📄 Task document data: $data');
        
        return Task(
          id: data['id'],
          title: data['title'],
          description: data['description'] ?? '',
          subjectId: data['subjectId'],
          userId: data['userId'] ?? 'current_user',
          dueDate: (data['dueDate'] as Timestamp).toDate(),
          isCompleted: data['isCompleted'] ?? false,
          priority: data['priority'] ?? 'Medium',
          createdAt: (data['createdAt'] as Timestamp).toDate(),
        );
      }).toList();

      debugPrint('✅ Retrieved ${tasks.length} tasks from Firestore');
      return tasks.cast<Task>();

    } catch (e) {
      debugPrint('❌ Error getting tasks from Firestore: $e');
      if (e is FirebaseException) {
        debugPrint('📋 Firebase error code: ${e.code}');
        debugPrint('📋 Firebase error message: ${e.message}');
      }
      return [];
    }
  }

  // Debug function to list all user data
  static Future<void> debugListAllUserData() async {
    if (currentUserId == null) {
      debugPrint('❌ Cannot debug: No authenticated user');
      return;
    }

    debugPrint('🔍 === DEBUG: Listing all user data ===');
    debugPrint('👤 Current user ID: $currentUserId');

    try {
      // List subjects
      final subjects = await getAllSubjects();
      debugPrint('📚 Subjects (${subjects.length}):');
      for (final subject in subjects) {
        debugPrint('  - ${subject.name} (${subject.id})');
      }

      // List sessions
      final sessions = await getAllStudySessions();
      debugPrint('📖 Study Sessions (${sessions.length}):');
      for (final session in sessions) {
        debugPrint('  - ${session.id}: ${session.notes} (Subject: ${session.subjectId})');
      }

      // List tasks
      final tasks = await getAllTasks();
      debugPrint('✅ Tasks (${tasks.length}):');
      for (final task in tasks) {
        debugPrint('  - ${task.title} (${task.id})');
      }

    } catch (e) {
      debugPrint('❌ Error during debug listing: $e');
    }
    
    debugPrint('🔍 === END DEBUG ===');
  }
}