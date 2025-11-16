import 'package:flutter/material.dart';
import '../../data/services/data_sync_service.dart';
import '../../data/models/study_session.dart';
import '../../core/services/firestore_service.dart';
import '../../core/theme/styles.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<StudySession> _recentSessions = [];
  Duration _todayStudyTime = Duration.zero;
  int _currentStreak = 0;
  Duration _weeklyStudyTime = Duration.zero;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      await _loadRecentSessions();
      await _calculateTodayStudyTime();
      await _calculateWeeklyStudyTime();
      await _calculateStreak();
    } catch (e) {
      print('Error loading dashboard data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadRecentSessions() async {
    try {
      final sessions = await DataSyncService.getAllStudySessions();
      final userId = FirestoreService.currentUserId;
      if (userId != null) {
        final userSessions = sessions.where((s) => s.userId == userId).toList();
        userSessions.sort((a, b) => b.startTime.compareTo(a.startTime));
        setState(() {
          _recentSessions = userSessions.take(5).toList();
        });
      }
    } catch (e) {
      print('Error loading recent sessions: $e');
    }
  }

  Future<void> _calculateTodayStudyTime() async {
    try {
      final today = DateTime.now();
      final todaySessions = _recentSessions.where((session) {
        return session.startTime.day == today.day &&
            session.startTime.month == today.month &&
            session.startTime.year == today.year &&
            session.endTime != null;
      }).toList();
      
      Duration total = Duration.zero;
      for (final session in todaySessions) {
        if (session.endTime != null) {
          total += session.endTime!.difference(session.startTime);
        }
      }
      
      setState(() {
        _todayStudyTime = total;
      });
    } catch (e) {
      print('Error calculating today study time: $e');
    }
  }

  Future<void> _calculateWeeklyStudyTime() async {
    try {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 7));
      
      final weeklySessions = _recentSessions.where((session) {
        return session.startTime.isAfter(weekStart) &&
            session.startTime.isBefore(weekEnd) &&
            session.endTime != null;
      }).toList();
      
      Duration total = Duration.zero;
      for (final session in weeklySessions) {
        if (session.endTime != null) {
          total += session.endTime!.difference(session.startTime);
        }
      }
      
      setState(() {
        _weeklyStudyTime = total;
      });
    } catch (e) {
      print('Error calculating weekly study time: $e');
    }
  }

  Future<void> _calculateStreak() async {
    try {
      final now = DateTime.now();
      int streak = 0;
      
      for (int i = 0; i < 365; i++) {
        final date = now.subtract(Duration(days: i));
        final hasSessionOnDate = _recentSessions.any((session) {
          return session.startTime.day == date.day &&
              session.startTime.month == date.month &&
              session.startTime.year == date.year &&
              session.endTime != null;
        });
        
        if (hasSessionOnDate) {
          streak++;
        } else {
          break;
        }
      }
      
      setState(() {
        _currentStreak = streak;
      });
    } catch (e) {
      print('Error calculating streak: $e');
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  String _getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppStyles.background,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppStyles.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppStyles.spaceLG),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Dashboard',
                style: AppStyles.sectionHeader,
              ),
              
              const SizedBox(height: AppStyles.spaceXL),
              
              // Stats Row
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'Today',
                      value: _formatDuration(_todayStudyTime),
                      subtitle: 'Study time',
                      icon: Icons.access_time,
                      color: AppStyles.primary,
                    ),
                  ),
                  const SizedBox(width: AppStyles.spaceMD),
                  Expanded(
                    child: _buildStatCard(
                      title: 'Streak',
                      value: '$_currentStreak days',
                      subtitle: 'Current',
                      icon: Icons.local_fire_department,
                      color: AppStyles.warning,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: AppStyles.spaceLG),
              
              // Progress Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppStyles.spaceLG),
                decoration: BoxDecoration(
                  color: AppStyles.card,
                  borderRadius: BorderRadius.circular(AppStyles.radiusMD),
                  border: Border.all(color: AppStyles.border),
                  boxShadow: [
                    BoxShadow(
                      color: AppStyles.black.withOpacity(0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weekly Progress',
                      style: AppStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppStyles.spaceMD),
                    LinearProgressIndicator(
                      value: _weeklyStudyTime.inHours / 20, // Target 20h per week
                      backgroundColor: AppStyles.muted,
                      valueColor: AlwaysStoppedAnimation<Color>(AppStyles.primary),
                    ),
                    const SizedBox(height: AppStyles.spaceSM),
                    Text(
                      '${_formatDuration(_weeklyStudyTime)} / 20h this week',
                      style: AppStyles.bodyMedium.copyWith(
                        color: AppStyles.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: AppStyles.spaceLG),
              
              // Recent Sessions
              Text(
                'Recent Sessions',
                style: AppStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              
              const SizedBox(height: AppStyles.spaceMD),
              
              Expanded(
                child: _recentSessions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 64,
                            color: AppStyles.mutedForeground,
                          ),
                          const SizedBox(height: AppStyles.spaceMD),
                          Text(
                            'No study sessions yet',
                            style: AppStyles.bodyLarge.copyWith(
                              color: AppStyles.mutedForeground,
                            ),
                          ),
                          const SizedBox(height: AppStyles.spaceSM),
                          Text(
                            'Start a study session to see your progress here!',
                            style: AppStyles.bodyMedium.copyWith(
                              color: AppStyles.mutedForeground,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadDashboardData,
                      child: ListView.builder(
                        itemCount: _recentSessions.length,
                        itemBuilder: (context, index) {
                          final session = _recentSessions[index];
                          final duration = session.endTime != null
                              ? session.endTime!.difference(session.startTime)
                              : Duration.zero;
                          return _buildSessionItem(
                            session.title.isNotEmpty ? session.title : 'Study Session',
                            _formatDuration(duration),
                            _getRelativeTime(session.startTime),
                          );
                        },
                      ),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
        color: AppStyles.card,
        borderRadius: BorderRadius.circular(AppStyles.radiusMD),
        border: Border.all(color: AppStyles.border),
        boxShadow: [
          BoxShadow(
            color: AppStyles.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: AppStyles.spaceSM),
              Text(
                title,
                style: AppStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppStyles.mutedForeground,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppStyles.spaceSM),
          Text(
            value,
            style: AppStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          Text(
            subtitle,
            style: AppStyles.bodySmall.copyWith(
              color: AppStyles.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionItem(String title, String duration, String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppStyles.spaceSM),
      padding: const EdgeInsets.all(AppStyles.spaceMD),
      decoration: BoxDecoration(
        color: AppStyles.card,
        borderRadius: BorderRadius.circular(AppStyles.radiusSM),
        border: Border.all(color: AppStyles.border),
        boxShadow: [
          BoxShadow(
            color: AppStyles.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppStyles.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppStyles.spaceSM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '$duration • $time',
                  style: AppStyles.bodySmall.copyWith(
                    color: AppStyles.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}