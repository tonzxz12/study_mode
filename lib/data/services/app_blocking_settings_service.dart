import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_blocking_settings.dart';

class AppBlockingSettingsService {
  static const String _boxName = 'app_blocking_settings';
  static Box<AppBlockingSettings>? _box;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Initialize Hive box
  static Future<void> initialize() async {
    _box = await Hive.openBox<AppBlockingSettings>(_boxName);
  }

  // Get current user's app blocking settings
  static Future<AppBlockingSettings> getUserSettings(String userId) async {
    await _ensureInitialized();
    
    // Try to get from local storage first
    final settings = _box!.values.where((s) => s.userId == userId).firstOrNull;
    
    if (settings != null) {
      return settings;
    }

    // Create default settings if none exist
    final defaultSettings = AppBlockingSettings(
      id: 'settings',
      userId: userId,
    );

    await saveSettings(defaultSettings);
    return defaultSettings;
  }

  // Save app blocking settings
  static Future<void> saveSettings(AppBlockingSettings settings) async {
    await _ensureInitialized();
    
    // Update timestamp
    final updatedSettings = settings.copyWith(updatedAt: DateTime.now());
    
    // Save to local Hive
    await _box!.put(updatedSettings.id, updatedSettings);
    
    // Sync to Firestore with user-specific document ID
    try {
      final docId = '${updatedSettings.userId}_app_blocking';
      await _firestore
          .collection('settings')
          .doc(docId)
          .set(updatedSettings.toFirestore());
      print('✅ App blocking settings saved to Firestore for user: ${updatedSettings.userId} with ${updatedSettings.blockedApps.length} blocked apps');
    } catch (e) {
      print('❌ Error syncing app blocking settings to Firestore: $e');
    }
  }

  // Update blocked apps list
  static Future<void> updateBlockedApps(String userId, List<String> blockedApps) async {
    final currentSettings = await getUserSettings(userId);
    final updatedSettings = currentSettings.copyWith(blockedApps: blockedApps);
    await saveSettings(updatedSettings);
  }

  // Toggle app blocking on/off
  static Future<void> toggleEnabled(String userId, bool enabled) async {
    final currentSettings = await getUserSettings(userId);
    final updatedSettings = currentSettings.copyWith(isEnabled: enabled);
    await saveSettings(updatedSettings);
  }

  // Update blocking mode
  static Future<void> updateBlockingMode(String userId, String mode) async {
    final currentSettings = await getUserSettings(userId);
    final updatedSettings = currentSettings.copyWith(blockingMode: mode);
    await saveSettings(updatedSettings);
  }

  // Get all settings (for admin/debug purposes)
  static Future<List<AppBlockingSettings>> getAllSettings() async {
    await _ensureInitialized();
    return _box!.values.toList();
  }

  // Delete settings for user
  static Future<void> deleteUserSettings(String userId) async {
    await _ensureInitialized();
    
    final settings = _box!.values.where((s) => s.userId == userId).toList();
    for (final setting in settings) {
      await _box!.delete(setting.id);
      
      // Delete from Firestore
      try {
        final docId = '${setting.userId}_app_blocking';
        await _firestore
            .collection('settings')
            .doc(docId)
            .delete();
      } catch (e) {
        print('❌ Error deleting from Firestore: $e');
      }
    }
  }

  // Sync from Firestore
  static Future<void> syncFromFirestore(String userId) async {
    try {
      // Try to get the user-specific document directly first
      final docId = '${userId}_app_blocking';
      final docSnapshot = await _firestore
          .collection('settings')
          .doc(docId)
          .get();
      
      if (docSnapshot.exists && docSnapshot.data() != null) {
        final settings = AppBlockingSettings.fromFirestore(docSnapshot.data()!);
        await _box!.put(settings.id, settings);
      }
      
      // Also check for any documents with this userId (fallback)
      final querySnapshot = await _firestore
          .collection('settings')
          .where('userId', isEqualTo: userId)
          .get();

      for (final doc in querySnapshot.docs) {
        final settings = AppBlockingSettings.fromFirestore(doc.data());
        await _box!.put(settings.id, settings);
      }
      
      print('✅ App blocking settings synced from Firestore');
    } catch (e) {
      print('❌ Error syncing from Firestore: $e');
    }
  }

  // Ensure box is initialized
  static Future<void> _ensureInitialized() async {
    if (_box == null || !_box!.isOpen) {
      await initialize();
    }
  }

  // Close the box (for cleanup)
  static Future<void> close() async {
    if (_box != null && _box!.isOpen) {
      await _box!.close();
      _box = null;
    }
  }
}