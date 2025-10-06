import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade50,
      child: SafeArea(
        bottom: false, // Don't apply safe area to bottom since we have fixed nav
        child: Column(
          children: [
            // Custom Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  const Text(
                    'Dashboard',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                      color: Colors.black87,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.dashboard, size: 16, color: Colors.blue.shade700),
                        const SizedBox(width: 4),
                        Text(
                          'Active',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Dashboard Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.dashboard_rounded,
                              size: 80,
                              color: Colors.blue.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Welcome to Your Dashboard',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Your study progress and stats will appear here',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
        decoration: BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.sigmaBlue.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.waving_hand,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back!',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Ready to boost your productivity?',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Study Statistics Cards
              Text(
                'Your Progress',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.neutral900,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ShadcnMetricCard(
                      title: 'Today',
                      value: '2h 30m',
                      icon: Icons.timer_outlined,
                      color: AppColors.sigmaBlue,
                      trend: '+15m',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ShadcnMetricCard(
                      title: 'This Week',
                      value: '18h 45m',
                      icon: Icons.calendar_today_outlined,
                      color: AppColors.sigmaGreen,
                      trend: '+3h 20m',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ShadcnMetricCard(
                      title: 'Streak',
                      value: '7 days',
                      icon: Icons.local_fire_department_outlined,
                      color: AppColors.sigmaOrange,
                      trend: '+2 days',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ShadcnMetricCard(
                      title: 'Pomodoros',
                      value: '23',
                      icon: Icons.emoji_events_outlined,
                      color: AppColors.sigmaPurple,
                      trend: '+5',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Quick Navigation Section
              Text(
                'Quick Access',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.neutral900,
                ),
              ),
              const SizedBox(height: 16),

              // Navigation Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: [
                  _buildNavigationCard(
                    context,
                    title: 'Home',
                    icon: Icons.home_outlined,
                    color: AppColors.sigmaBlue,
                    route: '/',
                  ),
                  _buildNavigationCard(
                    context,
                    title: 'Timer',
                    icon: Icons.timer_outlined,
                    color: AppColors.sigmaGreen,
                    route: '/timer',
                  ),
                  _buildNavigationCard(
                    context,
                    title: 'Planner',
                    icon: Icons.calendar_today_outlined,
                    color: AppColors.sigmaPurple,
                    route: '/planner',
                  ),
                  _buildNavigationCard(
                    context,
                    title: 'Analytics',
                    icon: Icons.analytics_outlined,
                    color: AppColors.sigmaOrange,
                    route: '/dashboard',
                  ),
                  _buildNavigationCard(
                    context,
                    title: 'Settings',
                    icon: Icons.settings_outlined,
                    color: AppColors.neutral600,
                    route: '/settings',
                  ),
                  _buildNavigationCard(
                    context,
                    title: 'Profile',
                    icon: Icons.person_outline,
                    color: AppColors.sigmaPink,
                    route: '/settings',
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Study Mode Controls Section
              Text(
                'Focus Mode',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.neutral900,
                ),
              ),
              const SizedBox(height: 16),

              // Study Mode Status Card
              ShadcnCard(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.sigmaBlue.withOpacity(0.05),
                        AppColors.sigmaGreen.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.block_rounded,
                              color: AppColors.error,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Focus Mode',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.neutral900,
                                  ),
                                ),
                                Text(
                                  'Currently Inactive',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.neutral600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: false,
                            onChanged: (value) => _toggleStudyMode(value),
                            activeColor: AppColors.sigmaGreen,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Block distracting apps during study sessions to maintain focus and boost productivity.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.neutral700,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: ShadcnButton(
                              text: 'Manage Apps',
                              icon: Icons.apps,
                              variant: ButtonVariant.outline,
                              onPressed: () => _showBlockedAppsManager(),
                              fullWidth: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ShadcnButton(
                              text: 'Permissions',
                              icon: Icons.security,
                              variant: ButtonVariant.outline,
                              onPressed: () => _showPermissionsDialog(),
                              fullWidth: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Blocked Apps Quick View
              ShadcnCard(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.sigmaBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.apps,
                              color: AppColors.sigmaBlue,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Currently Blocked Apps',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.neutral900,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => _showBlockedAppsManager(),
                            child: Text(
                              'Manage',
                              style: TextStyle(color: AppColors.sigmaBlue),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildBlockedAppsList(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Analytics Section
              Text(
                'Analytics',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.neutral900,
                ),
              ),
              const SizedBox(height: 16),
              // Weekly Progress Chart
              ShadcnCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.bar_chart_outlined,
                          color: AppColors.sigmaBlue,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Weekly Study Hours',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.neutral900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: _buildWeeklyChart(context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Subject Progress
              ShadcnCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.school_outlined,
                          color: AppColors.sigmaGreen,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Subject Progress',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.neutral900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSubjectProgress('Mathematics', 0.85, AppColors.sigmaBlue),
                    const SizedBox(height: 12),
                    _buildSubjectProgress('Physics', 0.72, AppColors.sigmaGreen),
                    const SizedBox(height: 12),
                    _buildSubjectProgress('Chemistry', 0.58, AppColors.sigmaOrange),
                    const SizedBox(height: 12),
                    _buildSubjectProgress('Biology', 0.91, AppColors.sigmaPurple),
                    const SizedBox(height: 12),
                    _buildSubjectProgress('English', 0.67, AppColors.sigmaPink),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Recent Activity
              ShadcnCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.history_outlined,
                          color: AppColors.sigmaOrange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Recent Activity',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.neutral900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildActivityItem(
                      context,
                      'Completed Physics study session',
                      '2 hours ago',
                      Icons.check_circle_outline,
                      AppColors.success,
                    ),
                    const SizedBox(height: 12),
                    _buildActivityItem(
                      context,
                      'Started Mathematics assignment',
                      '4 hours ago',
                      Icons.assignment_outlined,
                      AppColors.sigmaBlue,
                    ),
                    const SizedBox(height: 12),
                    _buildActivityItem(
                      context,
                      'Took a 15-minute break',
                      '6 hours ago',
                      Icons.coffee_outlined,
                      AppColors.sigmaOrange,
                    ),
                    const SizedBox(height: 12),
                    _buildActivityItem(
                      context,
                      'Added Chemistry exam to calendar',
                      '2 days ago',
                      Icons.calendar_today_outlined,
                      AppColors.sigmaPurple,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Quick Actions
              ShadcnCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.flash_on_outlined,
                          color: AppColors.sigmaGreen,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Quick Actions',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.neutral900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ShadcnButton(
                            text: 'Start Timer',
                            icon: Icons.play_arrow,
                            onPressed: () => context.go('/timer'),
                            fullWidth: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ShadcnButton(
                            text: 'Add Task',
                            icon: Icons.add,
                            variant: ButtonVariant.outline,
                            onPressed: () => context.go('/planner'),
                            fullWidth: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildWeeklyChart(BuildContext context) {
    final data = [
      {'day': 'Mon', 'hours': 3.5},
      {'day': 'Tue', 'hours': 2.8},
      {'day': 'Wed', 'hours': 4.2},
      {'day': 'Thu', 'hours': 1.9},
      {'day': 'Fri', 'hours': 3.7},
      {'day': 'Sat', 'hours': 5.1},
      {'day': 'Sun', 'hours': 2.3},
    ];

    final maxHours = data.map((e) => e['hours'] as double).reduce((a, b) => a > b ? a : b);

    return data.map((item) {
      final hours = item['hours'] as double;
      final height = (hours / maxHours) * 160;

      return Column(
        children: [
          Container(
            width: 30,
            height: height,
            decoration: BoxDecoration(
              color: AppColors.sigmaBlue,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item['day'] as String,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          Text(
            '${hours}h',
            style: TextStyle(
              fontSize: 10,
              color: AppColors.neutral600,
            ),
          ),
        ],
      );
    }).toList();
  }

  Widget _buildSubjectProgress(String subject, double progress, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              subject,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: AppColors.neutral300,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }

  Widget _buildActivityItem(BuildContext context, String title, String time, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                time,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.neutral600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _toggleStudyMode(bool enabled) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(enabled
          ? 'Focus Mode activated! Distracting apps are now blocked.'
          : 'Focus Mode deactivated. All apps are accessible.'
        ),
        backgroundColor: enabled ? AppColors.sigmaGreen : AppColors.neutral600,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showBlockedAppsManager() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.apps, color: Colors.red),
            SizedBox(width: 8),
            Text('Manage Blocked Apps'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select apps to block during study sessions:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    _buildAppItem('Instagram', Icons.camera_alt, true),
                    _buildAppItem('TikTok', Icons.music_video, true),
                    _buildAppItem('YouTube', Icons.play_circle, false),
                    _buildAppItem('Twitter', Icons.message, true),
                    _buildAppItem('Facebook', Icons.facebook, false),
                    _buildAppItem('WhatsApp', Icons.message, false),
                    _buildAppItem('Spotify', Icons.music_note, false),
                    _buildAppItem('Netflix', Icons.movie, true),
                    _buildAppItem('Games', Icons.sports_esports, true),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Blocked apps updated successfully')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildAppItem(String name, IconData icon, bool isBlocked) {
    return ListTile(
      leading: Icon(icon, color: isBlocked ? AppColors.error : AppColors.neutral500),
      title: Text(name),
      trailing: Switch(
        value: isBlocked,
        onChanged: (value) {
          // This would update the blocked status in a real implementation
        },
        activeColor: AppColors.sigmaGreen,
      ),
    );
  }

  void _showPermissionsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.security, color: Colors.orange),
            SizedBox(width: 8),
            Text('Required Permissions'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Focus Mode requires the following permissions to work properly:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.admin_panel_settings, color: Colors.orange, size: 20),
                SizedBox(width: 8),
                Expanded(child: Text('Device Administrator Access')),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.orange, size: 20),
                SizedBox(width: 8),
                Expanded(child: Text('Usage Access Permission')),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.layers, color: Colors.orange, size: 20),
                SizedBox(width: 8),
                Expanded(child: Text('Display Over Other Apps')),
              ],
            ),
            SizedBox(height: 16),
            Text(
              'These permissions allow the app to monitor and restrict app usage during study sessions.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Opening device settings for permissions...'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Grant Permissions'),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockedAppsList() {
    final blockedApps = [
      {'name': 'Instagram', 'icon': Icons.camera_alt},
      {'name': 'TikTok', 'icon': Icons.music_video},
      {'name': 'Twitter', 'icon': Icons.message},
      {'name': 'Netflix', 'icon': Icons.movie},
      {'name': 'Games', 'icon': Icons.sports_esports},
    ];

    if (blockedApps.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.apps,
              size: 48,
              color: AppColors.neutral400,
            ),
            const SizedBox(height: 12),
            Text(
              'No apps blocked yet',
              style: TextStyle(
                color: AppColors.neutral600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap "Manage Apps" to start blocking distracting apps',
              style: TextStyle(
                color: AppColors.neutral500,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: blockedApps.take(3).map((app) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  app['icon'] as IconData,
                  color: AppColors.error,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  app['name'] as String,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              Icon(
                Icons.block,
                color: AppColors.error,
                size: 16,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNavigationCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required String route,
  }) {
    return GestureDetector(
      onTap: () => context.go(route),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.neutral200,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.neutral900,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
