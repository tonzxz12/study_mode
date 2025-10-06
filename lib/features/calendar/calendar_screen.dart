import 'package:flutter/material.dart';
import '../../core/theme/styles.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppStyles.primary.withOpacity(0.05),
            AppStyles.background,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section with Calendar Title and Month Badge
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
                              color: AppStyles.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppStyles.radiusMD),
                            ),
                            child: Icon(
                              Icons.calendar_today_rounded,
                              size: 32,
                              color: AppStyles.primary,
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
                                    color: AppStyles.primary,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  'Your Study Schedule',
                                  style: TextStyle(
                                    color: AppStyles.foreground,
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
                    // Month Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppStyles.spaceLG,
                        vertical: AppStyles.spaceMD
                      ),
                      decoration: BoxDecoration(
                        color: AppStyles.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppStyles.radiusXL),
                        border: Border.all(
                          color: AppStyles.primary.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'Oct 2025',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppStyles.primary,
                        ),
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
                    // Calendar Overview
                    Text(
                      'Calendar Overview',
                      style: AppStyles.sectionHeader.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppStyles.spaceMD),
                    
                    // Quick Stats Row - Responsive
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                title: 'This Week',
                                value: '18h',
                                subtitle: 'Study time',
                                icon: Icons.schedule_rounded,
                                color: AppStyles.primary,
                              ),
                            ),
                            const SizedBox(width: AppStyles.spaceSM),
                            Expanded(
                              child: _buildStatCard(
                                title: 'Today',
                                value: '4',
                                subtitle: 'Sessions',
                                icon: Icons.check_circle_rounded,
                                color: AppStyles.success,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    
                    const SizedBox(height: AppStyles.spaceXL),
                    
                    // Mini Calendar - Shadcn Style
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppStyles.spaceLG),
                      decoration: BoxDecoration(
                        color: AppStyles.card,
                        borderRadius: BorderRadius.circular(AppStyles.radiusMD),
                        border: Border.all(
                          color: AppStyles.border,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppStyles.black.withOpacity(0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_view_month_rounded,
                                    color: AppStyles.mutedForeground,
                                    size: 18,
                                  ),
                                  const SizedBox(width: AppStyles.spaceXS),
                                  Text(
                                    'October 2025',
                                    style: AppStyles.subsectionHeader.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: AppStyles.muted.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(AppStyles.radiusSM),
                                    ),
                                    child: IconButton(
                                      onPressed: () => _changeMonth(-1),
                                      icon: Icon(
                                        Icons.chevron_left_rounded,
                                        color: AppStyles.mutedForeground,
                                        size: 18,
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 32,
                                        minHeight: 32,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppStyles.spaceXS),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: AppStyles.muted.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(AppStyles.radiusSM),
                                    ),
                                    child: IconButton(
                                      onPressed: () => _changeMonth(1),
                                      icon: Icon(
                                        Icons.chevron_right_rounded,
                                        color: AppStyles.mutedForeground,
                                        size: 18,
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 32,
                                        minHeight: 32,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: AppStyles.spaceMD),
                          // Weekday headers
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                                .map((day) => Text(
                                      day,
                                      style: AppStyles.bodySmall.copyWith(
                                        fontWeight: FontWeight.w500,
                                        color: AppStyles.mutedForeground,
                                      ),
                                    ))
                                .toList(),
                          ),
                          const SizedBox(height: AppStyles.spaceSM),
                          // Calendar grid
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 7,
                              childAspectRatio: 1,
                              mainAxisSpacing: 4,
                              crossAxisSpacing: 4,
                            ),
                            itemCount: 35,
                            itemBuilder: (context, index) {
                              int day = index - 5; // Start from day 1 on index 6
                              bool isCurrentMonth = day > 0 && day <= 31;
                              bool isToday = day == _selectedDate.day;
                              bool hasEvent = [5, 12, 18, 25].contains(day);
                              
                              return GestureDetector(
                                onTap: isCurrentMonth ? () => _selectDate(day) : null,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isToday ? AppStyles.primary : Colors.transparent,
                                    borderRadius: BorderRadius.circular(AppStyles.radiusSM),
                                  ),
                                  child: Stack(
                                    children: [
                                      Center(
                                        child: Text(
                                          isCurrentMonth ? day.toString() : '',
                                          style: AppStyles.bodySmall.copyWith(
                                            color: isToday 
                                                ? Colors.white 
                                                : AppStyles.foreground,
                                            fontWeight: isToday 
                                                ? FontWeight.w600 
                                                : FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                      if (hasEvent && isCurrentMonth)
                                        Positioned(
                                          bottom: 2,
                                          right: 2,
                                          child: Container(
                                            width: 6,
                                            height: 6,
                                            decoration: BoxDecoration(
                                              color: isToday 
                                                  ? Colors.white 
                                                  : AppStyles.primary,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: AppStyles.spaceXL),
                    
                    // Calendar Insights - Shadcn Style (matching home screen)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppStyles.spaceLG),
                      decoration: BoxDecoration(
                        color: AppStyles.accent.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(AppStyles.radiusMD),
                        border: Border.all(
                          color: AppStyles.primary.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppStyles.spaceXS),
                            decoration: BoxDecoration(
                              color: AppStyles.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppStyles.radiusSM),
                            ),
                            child: Icon(
                              Icons.calendar_month_rounded,
                              color: AppStyles.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: AppStyles.spaceSM),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Calendar Tip',
                                  style: AppStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppStyles.primary,
                                  ),
                                ),
                                const SizedBox(height: AppStyles.spaceXS),
                                Text(
                                  'You have 3 study sessions scheduled today. Stay consistent with your routine!',
                                  style: AppStyles.bodySmall.copyWith(
                                    color: AppStyles.foreground,
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
                    
                    // Today's Agenda
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppStyles.spaceLG),
                      decoration: BoxDecoration(
                        color: AppStyles.card,
                        borderRadius: BorderRadius.circular(AppStyles.radiusMD),
                        border: Border.all(
                          color: AppStyles.border,
                          width: 1,
                        ),
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
                              Icon(
                                Icons.today_rounded,
                                color: AppStyles.mutedForeground,
                                size: 18,
                              ),
                              const SizedBox(width: AppStyles.spaceXS),
                              Text(
                                'Today\'s Agenda',
                                style: AppStyles.subsectionHeader.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'Oct ${_selectedDate.day}',
                                style: AppStyles.bodySmall.copyWith(
                                  color: AppStyles.mutedForeground,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppStyles.spaceMD),
                          _buildAgendaItem(
                            '09:00',
                            'Mathematics',
                            'Calculus & Integration',
                            AppStyles.primary,
                          ),
                          _buildAgendaItem(
                            '11:00',
                            'Physics',
                            'Quantum Mechanics',
                            CalendarStyles.eventColor,
                          ),
                          _buildAgendaItem(
                            '14:00',
                            'Chemistry',
                            'Organic Chemistry Lab',
                            PlannerStyles.subjectColor,
                          ),
                          _buildAgendaItem(
                            '16:00',
                            'Break',
                            'Study break & review',
                            AppStyles.mutedForeground,
                            isBreak: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppStyles.spaceXXL * 2), // Extra space for navbar
            ],
          ),
        ),
      ),
    );
  }

  // Helper Methods
  void _changeMonth(int direction) {
    setState(() {
      _focusedDate = DateTime(
        _focusedDate.year,
        _focusedDate.month + direction,
        1,
      );
    });
  }

  void _selectDate(int day) {
    setState(() {
      _selectedDate = DateTime(
        _focusedDate.year,
        _focusedDate.month,
        day,
      );
    });
  }

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
        color: AppStyles.card,
        borderRadius: BorderRadius.circular(AppStyles.radiusMD),
        border: Border.all(
          color: AppStyles.border,
          width: 1,
        ),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppStyles.mutedForeground,
                ),
              ),
              Icon(
                icon,
                color: AppStyles.mutedForeground,
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
              color: AppStyles.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgendaItem(
    String time,
    String subject,
    String topic,
    Color color, {
    bool isBreak = false,
  }) {
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
                    color: isBreak ? AppStyles.mutedForeground : AppStyles.foreground,
                  ),
                ),
                if (!isBreak && topic.isNotEmpty) ...[
                  Text(
                    topic,
                    style: AppStyles.bodySmall.copyWith(
                      color: AppStyles.mutedForeground,
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
}