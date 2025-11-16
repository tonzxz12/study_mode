import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/subject.dart';
import '../../data/models/study_session.dart';
import 'package:flutter/foundation.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  static String? get currentUserId => _auth.currentUser?.uid;

  // Collections
  static CollectionReference get users => _firestore.collection('users');
  static CollectionReference get studySessions => _firestore.collection('study_sessions');
  static CollectionReference get subjects => _firestore.collection('subjects');
  static CollectionReference get tasks => _firestore.collection('tasks');

  // User Management
  static Future<void> createUserDocument(User user, String fullName) async {
    if (currentUserId == null) return;
    
    try {
      await users.doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'displayName': fullName,
        'createdAt': FieldValue.serverTimestamp(),
        'lastActiveAt': FieldValue.serverTimestamp(),
        'totalStudyTime': 0, // in minutes
        'totalSessions': 0,
        'subjectsCount': 0,
        'averageFocusScore': 0.0,
        'studyStreak': 0,
      });
      debugPrint('✅ User document created successfully for ${user.email}');
    } catch (e) {
      debugPrint('❌ Error creating user document: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    if (currentUserId == null) return null;
    
    try {
      final doc = await users.doc(currentUserId!).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting user data: $e');
      return null;
    }
  }

  static Future<void> updateUserStats() async {
    if (currentUserId == null) return;
    
    try {
      // Get all user's study sessions
      final sessionsSnapshot = await studySessions
          .where('userId', isEqualTo: currentUserId)
          .where('isCompleted', isEqualTo: true)
          .get();
      
      // Calculate statistics
      int totalMinutes = 0;
      double totalFocusScore = 0.0;
      int completedSessions = 0;
      
      for (var doc in sessionsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['actualDuration'] != null) {
          totalMinutes += (data['actualDuration'] as num).toInt();
        }
        if (data['focusScore'] != null) {
          totalFocusScore += (data['focusScore'] as num).toDouble();
        }
        completedSessions++;
      }
      
      // Get subjects count
      final subjectsSnapshot = await subjects
          .where('userId', isEqualTo: currentUserId)
          .get();
      
      final averageFocusScore = completedSessions > 0 ? totalFocusScore / completedSessions : 0.0;
      
      // Update user document
      await users.doc(currentUserId!).update({
        'totalStudyTime': totalMinutes,
        'totalSessions': completedSessions,
        'subjectsCount': subjectsSnapshot.docs.length,
        'averageFocusScore': averageFocusScore,
        'lastActiveAt': FieldValue.serverTimestamp(),
      });
      
      debugPrint('✅ User stats updated: ${totalMinutes}min, ${completedSessions} sessions');
    } catch (e) {
      debugPrint('❌ Error updating user stats: $e');
    }
  }

  // Subject Management
  static Future<void> saveSubject(Subject subject) async {
    if (currentUserId == null) return;
    
    try {
      await subjects.doc(subject.id).set({
        'id': subject.id,
        'userId': currentUserId,
        'name': subject.name,
        'color': subject.color,
        'description': subject.description,
        'createdAt': Timestamp.fromDate(subject.createdAt),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Update user subject count
      await updateUserStats();
      debugPrint('✅ Subject saved: ${subject.name}');
    } catch (e) {
      debugPrint('❌ Error saving subject: $e');
      rethrow;
    }
  }

  static Future<void> deleteSubject(String subjectId) async {
    if (currentUserId == null) return;
    
    try {
      // Delete subject
      await subjects.doc(subjectId).delete();
      
      // Delete related study sessions
      final sessionsSnapshot = await studySessions
          .where('userId', isEqualTo: currentUserId)
          .where('subjectId', isEqualTo: subjectId)
          .get();
      
      final batch = _firestore.batch();
      for (var doc in sessionsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      
      // Update user stats
      await updateUserStats();
      debugPrint('✅ Subject and related sessions deleted: $subjectId');
    } catch (e) {
      debugPrint('❌ Error deleting subject: $e');
      rethrow;
    }
  }

  // Study Session Management
  static Future<void> saveStudySession(StudySession session) async {
    if (currentUserId == null) return;
    
    try {
      await studySessions.doc(session.id).set({
        'id': session.id,
        'userId': currentUserId,
        'subjectId': session.subjectId,
        'startTime': Timestamp.fromDate(session.startTime),
        'endTime': session.endTime != null ? Timestamp.fromDate(session.endTime!) : null,
        'targetDuration': session.targetDuration.inMinutes,
        'actualDuration': session.actualDuration.inMinutes,
        'notes': session.notes,
        'isCompleted': session.isCompleted,
        'focusScore': session.focusScore,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Update user stats after session completion
      if (session.isCompleted) {
        await updateUserStats();
      }
      
      debugPrint('✅ Study session saved: ${session.id}');
    } catch (e) {
      debugPrint('❌ Error saving study session: $e');
      rethrow;
    }
  }

  static Future<void> updateStudySession(StudySession session) async {
    if (currentUserId == null) return;
    
    try {
      await studySessions.doc(session.id).update({
        'endTime': session.endTime != null ? Timestamp.fromDate(session.endTime!) : null,
        'actualDuration': session.actualDuration.inMinutes,
        'notes': session.notes,
        'isCompleted': session.isCompleted,
        'focusScore': session.focusScore,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Update user stats after session completion
      if (session.isCompleted) {
        await updateUserStats();
      }
      
      debugPrint('✅ Study session updated: ${session.id}');
    } catch (e) {
      debugPrint('❌ Error updating study session: $e');
      rethrow;
    }
  }

  // Analytics & Research Data
  static Future<List<Map<String, dynamic>>> getUserStudySessions({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (currentUserId == null) return [];
    
    try {
      Query query = studySessions
          .where('userId', isEqualTo: currentUserId)
          .orderBy('startTime', descending: true);
      
      if (startDate != null) {
        query = query.where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      
      if (endDate != null) {
        query = query.where('startTime', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }
      
      final snapshot = await query.get();
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      }).toList();
    } catch (e) {
      debugPrint('❌ Error getting study sessions: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> getStudyAnalytics() async {
    if (currentUserId == null) return {};
    
    try {
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      final monthAgo = now.subtract(const Duration(days: 30));
      
      // This week's sessions
      final weekSessions = await getUserStudySessions(startDate: weekAgo);
      
      // This month's sessions
      final monthSessions = await getUserStudySessions(startDate: monthAgo);
      
      // Calculate analytics
      final weekMinutes = weekSessions.fold<int>(0, (sum, session) => 
          sum + ((session['actualDuration'] as num?)?.toInt() ?? 0));
      
      final monthMinutes = monthSessions.fold<int>(0, (sum, session) => 
          sum + ((session['actualDuration'] as num?)?.toInt() ?? 0));
      
      final avgFocusThisWeek = weekSessions.isNotEmpty 
          ? weekSessions.fold<double>(0, (sum, session) => 
              sum + ((session['focusScore'] as num?)?.toDouble() ?? 0)) / weekSessions.length
          : 0.0;
      
      return {
        'weeklyMinutes': weekMinutes,
        'monthlyMinutes': monthMinutes,
        'weeklySessionCount': weekSessions.length,
        'monthlySessionCount': monthSessions.length,
        'averageFocusThisWeek': avgFocusThisWeek,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('❌ Error getting study analytics: $e');
      return {};
    }
  }

  // Research Data Export (for student data gathering)
  static Future<Map<String, dynamic>> exportAllUserData() async {
    if (currentUserId == null) return {};
    
    try {
      final userData = await getUserData();
      final sessions = await getUserStudySessions();
      final analytics = await getStudyAnalytics();
      
      // Get subjects
      final subjectsSnapshot = await subjects
          .where('userId', isEqualTo: currentUserId)
          .get();
      
      final subjectsData = subjectsSnapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      }).toList();
      
      return {
        'userId': currentUserId,
        'exportedAt': DateTime.now().toIso8601String(),
        'userData': userData,
        'subjects': subjectsData,
        'studySessions': sessions,
        'analytics': analytics,
        'totalSessions': sessions.length,
        'totalSubjects': subjectsData.length,
      };
    } catch (e) {
      debugPrint('❌ Error exporting user data: $e');
      return {};
    }
  }

  // App Settings Sync
  static Future<void> updateUserSettings(Map<String, dynamic> settings) async {
    if (currentUserId == null) return;
    
    try {
      await users.doc(currentUserId!).update({
        'settings': settings,
        'settingsUpdatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ User settings updated');
    } catch (e) {
      debugPrint('❌ Error updating user settings: $e');
    }
  }

  static Future<Map<String, dynamic>?> getUserSettings() async {
    if (currentUserId == null) return null;
    
    try {
      final doc = await users.doc(currentUserId!).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        return data?['settings'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting user settings: $e');
      return null;
    }
  }
}