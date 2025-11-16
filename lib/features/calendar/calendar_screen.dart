import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/styles.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/services/firestore_service.dart';

import '../../data/services/calendar_service.dart';
import '../../data/services/data_sync_service.dart';

import '../../data/models/calendar_event.dart';
import '../../data/models/subject.dart';
import '../../data/models/task.dart';




class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();

  List<CalendarEvent> _calendarEvents = [];
  List<CalendarEvent> _displayedSchedule = []; // All schedules or filtered ones
  List<Subject> _subjects = [];
  List<Task> _tasks = [];
  bool _showAllSchedules = true; // Default to show all schedules
  
  // Get current user ID from Firebase Auth
  String get _currentUserId {
    final firebaseUserId = FirestoreService.currentUserId;
    if (firebaseUserId != null && firebaseUserId.isNotEmpty) {
      return firebaseUserId;
    }
    // No fallback - user must be authenticated
    throw Exception('No authenticated user found. Please log in.');
  }

  @override
  void initState() {
    super.initState();
    _loadCalendarEvents();
    _loadSubjectsAndTasks();
  }

  Future<void> _loadCalendarEvents() async {
    try {
      await CalendarService.initialize();
      
      // Sync with Firebase to get latest data
      await CalendarService.syncWithFirestore(_currentUserId);
      
      final events = await CalendarService.getAllCalendarEvents(_currentUserId);
      
      setState(() {
        _calendarEvents = events;
        _updateDisplayedSchedule();
      });
      
      print('✅ Loaded ${events.length} calendar events from Firebase');
    } catch (e) {
      print('Error loading calendar events: $e');
    }
  }

  Future<void> _loadSubjectsAndTasks() async {
    try {
      final subjects = await DataSyncService.getAllSubjects();
      final tasks = await DataSyncService.getAllTasks();
      
      setState(() {
        _subjects = subjects;
        _tasks = tasks;
      });
      
      print('✅ Loaded ${subjects.length} subjects and ${tasks.length} tasks');
    } catch (e) {
      print('❌ Error loading subjects and tasks: $e');
    }
  }

  // Method to refresh all data
  Future<void> _refreshAllData() async {
    await Future.wait([
      _loadCalendarEvents(),
      _loadSubjectsAndTasks(),
    ]);
  }





  // Calculate this week's study time from real data
  String _getThisWeekStudyTime() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    
    final weekEvents = _calendarEvents.where((event) {
      return event.startTime.isAfter(startOfWeek) && 
             event.startTime.isBefore(endOfWeek);
    }).toList();
    
    final totalMinutes = weekEvents.fold<int>(0, (sum, event) => sum + event.durationMinutes);
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  // Get today's session count
  String _getTodaySessionCount() {
    final today = DateTime.now();
    final todayEvents = _calendarEvents
        .where((event) => _isSameDay(event.startTime, today))
        .length;
    return todayEvents.toString();
  }



  // Generate list of dates for dropdown (30 days back, 30 days forward)
  List<DateTime> _getAvailableDates() {
    final today = DateTime.now();
    final dates = <DateTime>[];
    
    for (int i = -30; i <= 30; i++) {
      final date = today.add(Duration(days: i));
      // Normalize to date only (remove time component)
      dates.add(DateTime(date.year, date.month, date.day));
    }
    
    return dates;
  }

  // Format date for dropdown display
  String _formatDateForDropdown(DateTime date) {
    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));
    final yesterday = today.subtract(const Duration(days: 1));
    
    if (_isSameDay(date, today)) {
      return 'Today (${date.day}/${date.month}/${date.year})';
    } else if (_isSameDay(date, tomorrow)) {
      return 'Tomorrow (${date.day}/${date.month}/${date.year})';
    } else if (_isSameDay(date, yesterday)) {
      return 'Yesterday (${date.day}/${date.month}/${date.year})';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _updateDisplayedSchedule() {
    if (_showAllSchedules) {
      _displayedSchedule = List.from(_calendarEvents);
    } else {
      _displayedSchedule = _calendarEvents
          .where((event) => _isSameDay(event.startTime, _selectedDate))
          .toList();
    }
    
    // Sort by start time
    _displayedSchedule.sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  String _getSubjectName(String subjectId) {
    final subject = _subjects.firstWhere(
      (s) => s.id == subjectId,
      orElse: () => Subject(id: '', name: 'Unknown Subject', userId: '', color: '#0000FF'),
    );
    return subject.name;
  }

  String _getTaskTitle(String taskId) {
    final task = _tasks.firstWhere(
      (t) => t.id == taskId,
      orElse: () => Task(id: '', title: 'Unknown Task', subjectId: '', userId: '', dueDate: DateTime.now()),
    );
    return task.title;
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }



  void _addScheduleItem() {
    showDialog(
      context: context,
      builder: (context) => _ScheduleDialog(
        selectedDate: _selectedDate,
        subjects: _subjects,
        tasks: _tasks,
        onSave: (title, description, dateTimeString, durationMinutes, subjectId, taskId) async {
          // dateTimeString now contains the formatted date and time
          final parts = dateTimeString.split('|');
          final datePart = parts[0]; // YYYY-MM-DD
          final timePart = parts[1]; // HH:MM
          
          final dateSegments = datePart.split('-');
          final timeSegments = timePart.split(':');
          
          final startTime = DateTime(
            int.parse(dateSegments[0]), // year
            int.parse(dateSegments[1]), // month
            int.parse(dateSegments[2]), // day
            int.parse(timeSegments[0]), // hour
            int.parse(timeSegments[1]), // minute
          );
          
          final newEvent = CalendarEvent(
            id: const Uuid().v4(),
            title: title,
            description: description,
            startTime: startTime,
            durationMinutes: durationMinutes,
            userId: _currentUserId,
            subjectId: subjectId,
            taskId: taskId,
          );
          
          // Save to calendar service
          await CalendarService.addCalendarEvent(newEvent);
          
          // Refresh subjects and tasks data
          await _loadSubjectsAndTasks();
          
          // Reload events and update UI
          await _loadCalendarEvents();
          
          print('✅ Calendar event saved and data refreshed');
        },
      ),
    );
  }



  void _editScheduleItem(CalendarEvent event) {
    showDialog(
      context: context,
      builder: (context) => _ScheduleDialog(
        selectedDate: _selectedDate,
        calendarEvent: event,
        subjects: _subjects,
        tasks: _tasks,
        onSave: (title, description, dateTimeString, durationMinutes, subjectId, taskId) async {
          // dateTimeString now contains the formatted date and time
          final parts = dateTimeString.split('|');
          final datePart = parts[0]; // YYYY-MM-DD
          final timePart = parts[1]; // HH:MM
          
          final dateSegments = datePart.split('-');
          final timeSegments = timePart.split(':');
          
          final startTime = DateTime(
            int.parse(dateSegments[0]), // year
            int.parse(dateSegments[1]), // month
            int.parse(dateSegments[2]), // day
            int.parse(timeSegments[0]), // hour
            int.parse(timeSegments[1]), // minute
          );
          
          final updatedEvent = event.copyWith(
            title: title,
            description: description,
            startTime: startTime,
            durationMinutes: durationMinutes,
            subjectId: subjectId,
            taskId: taskId,
          );
          
          // Update in calendar service
          await CalendarService.updateCalendarEvent(updatedEvent);
          
          // Refresh subjects and tasks data
          await _loadSubjectsAndTasks();
          
          // Reload events and update UI
          await _loadCalendarEvents();
          
          print('✅ Calendar event updated and data refreshed');
        },
      ),
    );
  }

  void _deleteScheduleItem(String eventId) async {
    try {
      await CalendarService.deleteCalendarEvent(eventId);
      await _loadCalendarEvents();
    } catch (e) {
      print('Error deleting calendar event: $e');
    }
  }

  void _toggleScheduleItem(String eventId) async {
    try {
      await CalendarService.markEventCompleted(eventId);
      await _loadCalendarEvents();
    } catch (e) {
      print('Error toggling completion: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _refreshAllData,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Header Section with Calendar Title and Add Button
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
                    // Calendar Title with Icon
                    Expanded(
                      child: Row(
                        children: [
                          // Calendar Icon
                          Container(
                            padding: const EdgeInsets.all(AppStyles.spaceXS),
                            decoration: BoxDecoration(
                              color: context.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppStyles.radiusMD),
                            ),
                            child: Icon(
                              Icons.calendar_today_rounded,
                              size: 32,
                              color: context.primary,
                            ),
                          ),
                          const SizedBox(width: AppStyles.spaceMD),
                          // Calendar Text
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Calendar',
                                  style: AppStyles.screenTitle.copyWith(
                                    height: 1.1,
                                    letterSpacing: -0.5,
                                    color: context.primary,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  'Study Schedule',
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
                    // Add Button
                    ElevatedButton(
                      onPressed: _addScheduleItem,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.primary,
                        foregroundColor: context.primaryForeground,
                        padding: EdgeInsets.symmetric(
                          horizontal: MediaQuery.of(context).size.width < 400 ? AppStyles.spaceMD : AppStyles.spaceLG,
                          vertical: AppStyles.spaceMD,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppStyles.radiusXL),
                        ),
                        elevation: 2,
                      ),
                      child: MediaQuery.of(context).size.width < 400 
                        ? const Icon(Icons.add_rounded, size: 20)
                        : const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_rounded, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Add',
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

              // Calendar Content - Better Layout
              Container(
                margin: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width < 400 
                    ? AppStyles.spaceMD 
                    : AppStyles.spaceXL,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  // Quick Stats Row - Modern Design
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          title: 'This Week',
                          value: _getThisWeekStudyTime().isEmpty ? '0h' : _getThisWeekStudyTime(),
                          subtitle: 'Study time',
                          icon: Icons.schedule_rounded,
                          color: AppStyles.primary,
                        ),
                      ),
                      const SizedBox(width: AppStyles.spaceMD),
                      Expanded(
                        child: _buildStatCard(
                          title: 'Today',
                          value: _getTodaySessionCount() == '0' ? '0' : _getTodaySessionCount(),
                          subtitle: 'Sessions',
                          icon: Icons.check_circle_rounded,
                          color: context.success,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: AppStyles.spaceXL),
                  
                  // Schedule Container - Modern Card Style
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
                        Column(
                          children: [
                            // Header row with title and toggle
                            Row(
                              children: [
                                Icon(
                                  Icons.today_rounded,
                                  color: context.mutedForeground,
                                  size: 18,
                                ),
                                const SizedBox(width: AppStyles.spaceXS),
                                Expanded(
                                  child: Text(
                                    _showAllSchedules ? 'All Schedules' : 'Schedule for Date',
                                    style: AppStyles.subsectionHeader.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                // Modern Filter Toggle
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: context.muted,
                                    borderRadius: BorderRadius.circular(AppStyles.radiusMD),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _showAllSchedules = true;
                                            _updateDisplayedSchedule();
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: AppStyles.spaceSM,
                                            vertical: AppStyles.spaceXS,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _showAllSchedules ? context.card : Colors.transparent,
                                            borderRadius: BorderRadius.circular(AppStyles.radiusSM),
                                            boxShadow: _showAllSchedules ? context.shadowSM : null,
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.view_list_rounded,
                                                size: 16,
                                                color: _showAllSchedules ? context.primary : context.mutedForeground,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'All',
                                                style: AppStyles.bodySmall.copyWith(
                                                  color: _showAllSchedules ? context.foreground : context.mutedForeground,
                                                  fontWeight: _showAllSchedules ? FontWeight.w600 : FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _showAllSchedules = false;
                                            _updateDisplayedSchedule();
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: AppStyles.spaceSM,
                                            vertical: AppStyles.spaceXS,
                                          ),
                                          decoration: BoxDecoration(
                                            color: !_showAllSchedules ? context.card : Colors.transparent,
                                            borderRadius: BorderRadius.circular(AppStyles.radiusSM),
                                            boxShadow: !_showAllSchedules ? context.shadowSM : null,
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.calendar_today,
                                                size: 16,
                                                color: !_showAllSchedules ? context.primary : context.mutedForeground,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Date',
                                                style: AppStyles.bodySmall.copyWith(
                                                  color: !_showAllSchedules ? context.foreground : context.mutedForeground,
                                                  fontWeight: !_showAllSchedules ? FontWeight.w600 : FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            // Date dropdown (only show when filtering by date)
                            if (!_showAllSchedules) ...[
                              const SizedBox(height: AppStyles.spaceMD),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppStyles.spaceMD,
                                  vertical: AppStyles.spaceSM,
                                ),
                                decoration: BoxDecoration(
                                  color: context.card,
                                  borderRadius: BorderRadius.circular(AppStyles.radiusMD),
                                  border: Border.all(
                                    color: context.border,
                                    width: 1,
                                  ),
                                  boxShadow: context.shadowSM,
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<DateTime>(
                                    value: DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day),
                                    isExpanded: true,
                                    hint: Text(
                                      'Select Date',
                                      style: AppStyles.bodyMedium.copyWith(
                                        color: context.mutedForeground,
                                      ),
                                    ),
                                    icon: Icon(
                                      Icons.keyboard_arrow_down,
                                      color: context.primary,
                                    ),
                                    style: AppStyles.bodyMedium.copyWith(
                                      color: context.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    items: _getAvailableDates().map((DateTime date) {
                                      return DropdownMenuItem<DateTime>(
                                        value: date,
                                        child: Text(
                                          _formatDateForDropdown(date),
                                          style: AppStyles.bodyMedium.copyWith(
                                            color: context.foreground,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (DateTime? newDate) {
                                      if (newDate != null) {
                                        setState(() {
                                          _selectedDate = newDate;
                                          _updateDisplayedSchedule();
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: AppStyles.spaceMD),
                        // Dynamic schedule display
                        ...(_displayedSchedule.isEmpty 
                          ? [Container(
                              padding: const EdgeInsets.all(AppStyles.spaceXXL),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(AppStyles.spaceLG),
                                    decoration: BoxDecoration(
                                      color: context.muted,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.calendar_month_rounded,
                                      size: 48,
                                      color: context.mutedForeground,
                                    ),
                                  ),
                                  const SizedBox(height: AppStyles.spaceLG),
                                  Text(
                                    _showAllSchedules ? 'No schedules yet' : 'No schedule for this date',
                                    style: AppStyles.bodyLarge.copyWith(
                                      color: context.foreground,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: AppStyles.spaceXS),
                                  Text(
                                    'Create your first schedule to get started',
                                    style: AppStyles.bodyMedium.copyWith(
                                      color: context.mutedForeground,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )]
                          : _displayedSchedule.map((item) => _buildScheduleItem(item)).toList()),
                      ],
                    ),
                  ),
                  
                    SizedBox(height: MediaQuery.of(context).size.width < 600 
                      ? AppStyles.spaceXXL * 3 // Mobile - extra space for floating navbar
                      : AppStyles.spaceXL), // Tablet/Desktop - less space needed
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper Methods

  // Stat Card Helper - Shadcn Style (matching home screen)
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



  Widget _buildScheduleItem(CalendarEvent event) {
    final isCompleted = event.isCompleted;
    final timeStr = '${event.startTime.hour.toString().padLeft(2, '0')}:${event.startTime.minute.toString().padLeft(2, '0')}';
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppStyles.spaceMD),
      padding: const EdgeInsets.all(AppStyles.spaceLG),
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(AppStyles.radiusMD),
        border: Border.all(
          color: isCompleted 
              ? context.success.withOpacity(0.3)
              : context.border,
          width: 1,
        ),
        boxShadow: context.shadowSM,
      ),
      child: Row(
        children: [
          Checkbox(
            value: isCompleted,
            onChanged: (_) => _toggleScheduleItem(event.id),
            activeColor: context.success,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: AppStyles.spaceMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: AppStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    color: isCompleted 
                        ? context.mutedForeground
                        : context.foreground,
                  ),
                ),
                if (event.description.isNotEmpty)
                  Text(
                    event.description,
                    style: AppStyles.bodySmall.copyWith(
                      color: context.mutedForeground,
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                // Subject and Task info
                if (event.subjectId != null || event.taskId != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (event.subjectId != null) ...[
                        Icon(
                          Icons.book_rounded,
                          size: 14,
                          color: context.primary.withOpacity(0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getSubjectName(event.subjectId!),
                          style: AppStyles.bodySmall.copyWith(
                            color: context.primary.withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      if (event.subjectId != null && event.taskId != null)
                        Text(
                          ' • ',
                          style: AppStyles.bodySmall.copyWith(
                            color: AppStyles.mutedForeground,
                          ),
                        ),
                      if (event.taskId != null) ...[
                        Icon(
                          Icons.assignment_rounded,
                          size: 14,
                          color: AppStyles.warning.withOpacity(0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getTaskTitle(event.taskId!),
                          style: AppStyles.bodySmall.copyWith(
                            color: AppStyles.warning.withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
                const SizedBox(height: 4),
                Wrap(
                  children: [
                    // Show date when displaying all schedules
                    if (_showAllSchedules) ...[
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: context.mutedForeground,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${event.startTime.day}/${event.startTime.month}/${event.startTime.year}',
                        style: AppStyles.bodySmall.copyWith(
                          color: context.mutedForeground,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '•',
                        style: AppStyles.bodySmall.copyWith(
                          color: context.mutedForeground,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: context.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      timeStr,
                      style: AppStyles.bodySmall.copyWith(
                        color: context.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '•',
                      style: AppStyles.bodySmall.copyWith(
                        color: context.mutedForeground,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${event.durationMinutes}min',
                      style: AppStyles.bodySmall.copyWith(
                        color: context.mutedForeground,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (action) {
              switch (action) {
                case 'edit':
                  _editScheduleItem(event);
                  break;
                case 'delete':
                  _deleteScheduleItem(event.id);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_rounded, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            child: Icon(
              Icons.more_vert_rounded,
              color: context.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }


}

class _ScheduleDialog extends StatefulWidget {
  final DateTime selectedDate;
  final CalendarEvent? calendarEvent;
  final List<Subject> subjects;
  final List<Task> tasks;
  final Function(String title, String description, String time, int durationMinutes, String? subjectId, String? taskId) onSave;

  const _ScheduleDialog({
    required this.selectedDate,
    this.calendarEvent,
    required this.subjects,
    required this.tasks,
    required this.onSave,
  });

  @override
  State<_ScheduleDialog> createState() => _ScheduleDialogState();
}

class _ScheduleDialogState extends State<_ScheduleDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  TimeOfDay _selectedTime = TimeOfDay.now();
  DateTime _selectedDate = DateTime.now();
  int _targetDurationMinutes = 25; // Default 25 minutes
  String? _selectedSubjectId;
  String? _selectedTaskId;
  List<Task> _availableTasks = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.calendarEvent?.title ?? '');
    _descriptionController = TextEditingController(text: widget.calendarEvent?.description ?? '');
    _targetDurationMinutes = widget.calendarEvent?.durationMinutes ?? 25;
    _selectedSubjectId = widget.calendarEvent?.subjectId;
    _selectedTaskId = widget.calendarEvent?.taskId;
    _selectedDate = widget.calendarEvent?.startTime ?? widget.selectedDate;
    
    if (widget.calendarEvent != null) {
      _selectedTime = TimeOfDay(
        hour: widget.calendarEvent!.startTime.hour,
        minute: widget.calendarEvent!.startTime.minute,
      );
    }
    
    _updateAvailableTasks();
  }

  void _updateAvailableTasks() {
    if (_selectedSubjectId != null) {
      _availableTasks = widget.tasks.where((task) => task.subjectId == _selectedSubjectId).toList();
    } else {
      _availableTasks = [];
    }
    
    // If current task is not in available tasks, reset selection
    if (_selectedTaskId != null && !_availableTasks.any((task) => task.id == _selectedTaskId)) {
      _selectedTaskId = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.calendarEvent == null ? 'Add Schedule Item' : 'Edit Schedule Item'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Title *',
              hintText: 'Study session, assignment, etc.',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Additional details...',
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          // Subject Selection
          DropdownButtonFormField<String>(
            value: _selectedSubjectId,
            decoration: const InputDecoration(
              labelText: 'Subject (Optional)',
              prefixIcon: Icon(Icons.book_rounded),
            ),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('No subject selected'),
              ),
              ...widget.subjects.map((subject) => DropdownMenuItem<String>(
                value: subject.id,
                child: Text(subject.name),
              )).toList(),
            ],
            onChanged: (value) {
              setState(() {
                _selectedSubjectId = value;
                _selectedTaskId = null; // Reset task selection
                _updateAvailableTasks();
              });
            },
          ),
          const SizedBox(height: 16),
          // Task Selection
          DropdownButtonFormField<String>(
            value: _selectedTaskId,
            decoration: const InputDecoration(
              labelText: 'Task (Optional)',
              prefixIcon: Icon(Icons.assignment_rounded),
            ),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('No task selected'),
              ),
              ..._availableTasks.map((task) => DropdownMenuItem<String>(
                value: task.id,
                child: Text(task.title),
              )).toList(),
            ],
            onChanged: _selectedSubjectId != null ? (value) {
              setState(() {
                _selectedTaskId = value;
              });
            } : null,
          ),
          const SizedBox(height: 16),
          // Date Selection
          Row(
            children: [
              Icon(Icons.calendar_today, color: context.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Date: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  style: AppStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                onPressed: _selectDate,
                child: const Text('Change'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Time Selection
          Row(
            children: [
              Icon(Icons.access_time, color: context.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Time: ${_selectedTime.format(context)}',
                  style: AppStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                onPressed: _selectTime,
                child: const Text('Change'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.timer_rounded, color: context.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Duration: ${_targetDurationMinutes} minutes',
                  style: AppStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _targetDurationMinutes > 5 ? () => setState(() => _targetDurationMinutes -= 5) : null,
                icon: const Icon(Icons.remove),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: context.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_targetDurationMinutes}min',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: context.primary,
                  ),
                ),
              ),
              IconButton(
                onPressed: _targetDurationMinutes < 180 ? () => setState(() => _targetDurationMinutes += 5) : null,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _save() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a title'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    widget.onSave(
      _titleController.text.trim(),
      _descriptionController.text.trim(),
      '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}|${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
      _targetDurationMinutes,
      _selectedSubjectId,
      _selectedTaskId,
    );
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}