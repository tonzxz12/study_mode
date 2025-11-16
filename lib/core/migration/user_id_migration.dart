import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';

/// One-time migration script to update user IDs from 'user_1' to Firebase Auth user ID
class UserIdMigration {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Migrates all documents with userId 'user_1' to the current Firebase Auth user ID
  static Future<void> migrateUserData() async {
    final currentUserId = FirestoreService.currentUserId;
    
    if (currentUserId == null || currentUserId.isEmpty) {
      print('❌ No authenticated user found. Cannot perform migration.');
      return;
    }

    print('🔄 Starting migration from "user_1" to "$currentUserId"');

    try {
      // Migrate calendar events
      await _migrateCollection('calendarEvents', currentUserId);
      
      // Migrate subjects
      await _migrateCollection('subjects', currentUserId);
      
      // Migrate tasks  
      await _migrateCollection('tasks', currentUserId);
      
      // Migrate study sessions
      await _migrateCollection('studySessions', currentUserId);

      print('✅ Migration completed successfully!');
    } catch (e) {
      print('❌ Migration failed: $e');
      rethrow;
    }
  }

  static Future<void> _migrateCollection(String collectionName, String newUserId) async {
    print('🔄 Migrating $collectionName...');
    
    // Query documents with userId 'user_1'
    final querySnapshot = await _firestore
        .collection(collectionName)
        .where('userId', isEqualTo: 'user_1')
        .get();

    if (querySnapshot.docs.isEmpty) {
      print('   No documents found with userId "user_1" in $collectionName');
      return;
    }

    print('   Found ${querySnapshot.docs.length} documents to migrate in $collectionName');

    // Update each document
    final batch = _firestore.batch();
    
    for (var doc in querySnapshot.docs) {
      batch.update(doc.reference, {'userId': newUserId});
    }

    await batch.commit();
    print('   ✅ Migrated ${querySnapshot.docs.length} documents in $collectionName');
  }
}