import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/calendar_event.dart';

class CalendarService {
  static const String _boxName = 'calendar_events';
  static const String _collectionName = 'calendar';
  
  // Get Hive box for local storage
  static Future<Box<CalendarEvent>> _getBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      return await Hive.openBox<CalendarEvent>(_boxName);
    }
    return Hive.box<CalendarEvent>(_boxName);
  }

  // Initialize the service
  static Future<void> initialize() async {
    try {
      await _getBox();
      print('✅ CalendarService initialized successfully');
    } catch (e) {
      print('❌ Error initializing CalendarService: $e');
    }
  }

  // Add a new calendar event
  static Future<void> addCalendarEvent(CalendarEvent event) async {
    try {
      // Save to local Hive storage
      final box = await _getBox();
      await box.put(event.id, event);
      
      // Save to Firestore
      await FirebaseFirestore.instance
          .collection(_collectionName)
          .doc(event.id)
          .set(event.toFirestore());
      
      print('✅ Calendar event added: ${event.title}');
    } catch (e) {
      print('❌ Error adding calendar event: $e');
      rethrow;
    }
  }

  // Update an existing calendar event
  static Future<void> updateCalendarEvent(CalendarEvent event) async {
    try {
      // Update in local Hive storage
      final box = await _getBox();
      await box.put(event.id, event);
      
      // Update in Firestore
      await FirebaseFirestore.instance
          .collection(_collectionName)
          .doc(event.id)
          .update(event.toFirestore());
      
      print('✅ Calendar event updated: ${event.title}');
    } catch (e) {
      print('❌ Error updating calendar event: $e');
      rethrow;
    }
  }

  // Delete a calendar event
  static Future<void> deleteCalendarEvent(String eventId) async {
    try {
      // Delete from local Hive storage
      final box = await _getBox();
      await box.delete(eventId);
      
      // Delete from Firestore
      await FirebaseFirestore.instance
          .collection(_collectionName)
          .doc(eventId)
          .delete();
      
      print('✅ Calendar event deleted: $eventId');
    } catch (e) {
      print('❌ Error deleting calendar event: $e');
      rethrow;
    }
  }

  // Get all calendar events for a user
  static Future<List<CalendarEvent>> getAllCalendarEvents(String userId) async {
    try {
      final box = await _getBox();
      final events = box.values
          .where((event) => event.userId == userId)
          .toList();
      
      return events;
    } catch (e) {
      print('❌ Error getting calendar events: $e');
      return [];
    }
  }

  // Get calendar events for a specific date
  static Future<List<CalendarEvent>> getCalendarEventsForDate(String userId, DateTime date) async {
    try {
      final box = await _getBox();
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      final events = box.values
          .where((event) => 
              event.userId == userId &&
              event.startTime.isAfter(startOfDay) &&
              event.startTime.isBefore(endOfDay))
          .toList();
      
      // Sort by start time
      events.sort((a, b) => a.startTime.compareTo(b.startTime));
      
      return events;
    } catch (e) {
      print('❌ Error getting calendar events for date: $e');
      return [];
    }
  }

  // Get incomplete calendar events for today
  static Future<List<CalendarEvent>> getTodaysIncompleteEvents(String userId) async {
    final today = DateTime.now();
    final events = await getCalendarEventsForDate(userId, today);
    
    return events.where((event) => !event.isCompleted).toList();
  }

  // Mark calendar event as completed
  static Future<void> markEventCompleted(String eventId) async {
    try {
      final box = await _getBox();
      final event = box.get(eventId);
      
      if (event != null) {
        final updatedEvent = event.copyWith(isCompleted: true);
        await updateCalendarEvent(updatedEvent);
        print('✅ Calendar event marked as completed: ${event.title}');
      }
    } catch (e) {
      print('❌ Error marking calendar event as completed: $e');
      rethrow;
    }
  }

  // Sync local data with Firestore
  static Future<void> syncWithFirestore(String userId) async {
    try {
      // Get events from Firestore
      final querySnapshot = await FirebaseFirestore.instance
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .get();
      
      final box = await _getBox();
      
      // Update local storage with Firestore data
      for (final doc in querySnapshot.docs) {
        final event = CalendarEvent.fromFirestore(doc.data());
        await box.put(event.id, event);
      }
      
      print('✅ Calendar data synced with Firestore');
    } catch (e) {
      print('❌ Error syncing calendar data: $e');
    }
  }

  // Clean up - close box
  static Future<void> cleanup() async {
    try {
      if (Hive.isBoxOpen(_boxName)) {
        await Hive.box<CalendarEvent>(_boxName).close();
      }
    } catch (e) {
      print('❌ Error during CalendarService cleanup: $e');
    }
  }
}