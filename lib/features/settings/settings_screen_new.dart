import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/theme/styles.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _studyModeEnabled = false;
  bool _notificationsEnabled = true;
  int _defaultBreakDuration = 30;
  
  // App Blocking Settings
  bool _appBlockingEnabled = false;
  List<Map<String, dynamic>> _blockableApps = [
    {'name': 'Facebook', 'package': 'com.facebook.katana', 'blocked': false, 'icon': Icons.facebook, 'color': Color(0xFF1877F2)},
    {'name': 'Instagram', 'package': 'com.instagram.android', 'blocked': false, 'icon': Icons.camera_alt_rounded, 'color': Color(0xFFE4405F)},
    {'name': 'TikTok', 'package': 'com.zhiliaoapp.musically', 'blocked': false, 'icon': Icons.music_video_rounded, 'color': Color(0xFF000000)},
    {'name': 'Twitter/X', 'package': 'com.twitter.android', 'blocked': false, 'icon': Icons.alternate_email_rounded, 'color': Color(0xFF1DA1F2)},
    {'name': 'YouTube', 'package': 'com.google.android.youtube', 'blocked': false, 'icon': Icons.play_circle_rounded, 'color': Color(0xFFFF0000)},
    {'name': 'WhatsApp', 'package': 'com.whatsapp', 'blocked': false, 'icon': Icons.chat_rounded, 'color': Color(0xFF25D366)},
    {'name': 'Snapchat', 'package': 'com.snapchat.android', 'blocked': false, 'icon': Icons.camera_rounded, 'color': Color(0xFFFFFC00)},
    {'name': 'Discord', 'package': 'com.discord', 'blocked': false, 'icon': Icons.chat_bubble_rounded, 'color': Color(0xFF5865F2)},
    {'name': 'Netflix', 'package': 'com.netflix.mediaclient', 'blocked': false, 'icon': Icons.movie_rounded, 'color': Color(0xFFE50914)},
    {'name': 'Spotify', 'package': 'com.spotify.music', 'blocked': false, 'icon': Icons.music_note_rounded, 'color': Color(0xFF1DB954)},
  ];

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppStyles.primary.withOpacity(0.05),
              AppStyles.background,
              AppStyles.primary.withOpacity(0.02),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Enhanced Modern Header
              Container(
                padding: const EdgeInsets.fromLTRB(
                  AppStyles.spaceXL, 
                  AppStyles.spaceLG, 
                  AppStyles.spaceXL, 
                  AppStyles.spaceLG
                ),
                decoration: BoxDecoration(
                  color: AppStyles.card.withOpacity(0.95),
                  border: Border(
                    bottom: BorderSide(
                      color: AppStyles.border.withOpacity(0.6),
                      width: 1,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppStyles.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: AppStyles.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Logo Icon
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppStyles.primary.withOpacity(0.2),
                            AppStyles.primary.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(AppStyles.radiusMD),
                        border: Border.all(
                          color: AppStyles.primary.withOpacity(0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppStyles.primary.withOpacity(0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.settings_rounded,
                        color: AppStyles.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppStyles.spaceMD),
                    // Title Section
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Settings',
                            style: AppStyles.sectionHeader.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 20,
                              color: AppStyles.foreground,
                            ),
                          ),
                          Text(
                            'Customize your study experience',
                            style: AppStyles.bodySmall.copyWith(
                              color: AppStyles.mutedForeground,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Enhanced Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppStyles.spaceMD, 
                        vertical: AppStyles.spaceXS
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _studyModeEnabled 
                                ? AppStyles.success.withOpacity(0.15)
                                : AppStyles.muted.withOpacity(0.4),
                            _studyModeEnabled 
                                ? AppStyles.success.withOpacity(0.05)
                                : AppStyles.muted.withOpacity(0.2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _studyModeEnabled 
                              ? AppStyles.success.withOpacity(0.3)
                              : AppStyles.border,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _studyModeEnabled 
                                ? AppStyles.success.withOpacity(0.1)
                                : AppStyles.black.withOpacity(0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _studyModeEnabled ? AppStyles.success : AppStyles.mutedForeground,
                              shape: BoxShape.circle,
                              boxShadow: _studyModeEnabled ? [
                                BoxShadow(
                                  color: AppStyles.success.withOpacity(0.4),
                                  blurRadius: 4,
                                  offset: const Offset(0, 0),
                                ),
                              ] : null,
                            ),
                          ),
                          const SizedBox(width: AppStyles.spaceXS),
                          Text(
                            _studyModeEnabled ? 'Active' : 'Inactive',
                            style: AppStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: _studyModeEnabled ? AppStyles.success : AppStyles.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Enhanced Main Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppStyles.spaceXL),
                  child: Column(
                    children: [
                      // Study Mode Card
                      _buildModernCard(
                        title: 'Study Mode',
                        children: [
                          _buildModernSwitchTile(
                            title: 'Focus Mode',
                            subtitle: 'Block distracting apps during study sessions',
                            value: _studyModeEnabled,
                            onChanged: (value) => setState(() => _studyModeEnabled = value),
                            icon: Icons.school_rounded,
                            iconColor: AppStyles.primary,
                          ),
                          _buildDivider(),
                          _buildModernSwitchTile(
                            title: 'App Blocking',
                            subtitle: 'Automatically block selected apps',
                            value: _appBlockingEnabled,
                            onChanged: (value) => setState(() => _appBlockingEnabled = value),
                            icon: Icons.block_rounded,
                            iconColor: AppStyles.destructive,
                          ),
                          _buildDivider(),
                          _buildModernSwitchTile(
                            title: 'Notifications',
                            subtitle: 'Get study reminders and break alerts',
                            value: _notificationsEnabled,
                            onChanged: (value) => setState(() => _notificationsEnabled = value),
                            icon: Icons.notifications_rounded,
                            iconColor: AppStyles.warning,
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: AppStyles.spaceXL),
                      
                      // App Restrictions Card
                      if (_appBlockingEnabled) ...[
                        _buildAppRestrictionsCard(),
                        const SizedBox(height: AppStyles.spaceXL),
                      ],
                      
                      // Break Duration Card
                      _buildBreakDurationCard(),
                      
                      const SizedBox(height: AppStyles.spaceXL),
                      
                      // Theme Settings Card  
                      _buildThemeCard(themeMode),
                      
                      const SizedBox(height: AppStyles.spaceXL),
                      
                      // Data Management Card
                      _buildDataCard(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppStyles.card,
            AppStyles.card.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(AppStyles.radiusLG),
        border: Border.all(
          color: AppStyles.border.withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppStyles.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
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
          Padding(
            padding: const EdgeInsets.all(AppStyles.spaceLG),
            child: Text(
              title,
              style: AppStyles.subsectionHeader.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: AppStyles.foreground,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildModernSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
    required Color iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppStyles.spaceLG, 
        vertical: AppStyles.spaceMD
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppStyles.spaceSM),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  iconColor.withOpacity(0.15),
                  iconColor.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(AppStyles.radiusMD),
              border: Border.all(
                color: iconColor.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: iconColor.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: AppStyles.spaceMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppStyles.foreground,
                  ),
                ),
                const SizedBox(height: AppStyles.spaceXS),
                Text(
                  subtitle,
                  style: AppStyles.bodySmall.copyWith(
                    color: AppStyles.mutedForeground,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 1.1,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: AppStyles.primary,
              activeTrackColor: AppStyles.primary.withOpacity(0.3),
              inactiveThumbColor: AppStyles.mutedForeground,
              inactiveTrackColor: AppStyles.muted.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppStyles.spaceLG),
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            AppStyles.border.withOpacity(0.5),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildAppRestrictionsCard() {
    return _buildModernCard(
      title: 'App Restrictions',
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppStyles.spaceLG),
          child: Text(
            'Select which apps to block during study sessions',
            style: AppStyles.bodySmall.copyWith(
              color: AppStyles.mutedForeground,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: AppStyles.spaceMD),
        ...List.generate(_blockableApps.length, (index) {
          final app = _blockableApps[index];
          return Column(
            children: [
              if (index > 0) _buildDivider(),
              _buildAppTile(app, index),
            ],
          );
        }),
        const SizedBox(height: AppStyles.spaceSM),
      ],
    );
  }

  Widget _buildAppTile(Map<String, dynamic> app, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppStyles.spaceLG, 
        vertical: AppStyles.spaceMD
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppStyles.spaceSM),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  (app['color'] as Color).withOpacity(0.15),
                  (app['color'] as Color).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(AppStyles.radiusMD),
              border: Border.all(
                color: (app['color'] as Color).withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Icon(
              app['icon'] as IconData,
              color: app['color'] as Color,
              size: 20,
            ),
          ),
          const SizedBox(width: AppStyles.spaceMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  app['name'] as String,
                  style: AppStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppStyles.foreground,
                  ),
                ),
                const SizedBox(height: AppStyles.spaceXS),
                Text(
                  app['package'] as String,
                  style: AppStyles.bodySmall.copyWith(
                    color: AppStyles.mutedForeground,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 1.1,
            child: Switch(
              value: app['blocked'] as bool,
              onChanged: (value) {
                setState(() {
                  _blockableApps[index]['blocked'] = value;
                });
              },
              activeColor: AppStyles.destructive,
              activeTrackColor: AppStyles.destructive.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakDurationCard() {
    return Container(
      padding: const EdgeInsets.all(AppStyles.spaceLG),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppStyles.card,
            AppStyles.card.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(AppStyles.radiusLG),
        border: Border.all(
          color: AppStyles.border.withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppStyles.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppStyles.spaceSM),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppStyles.warning.withOpacity(0.15),
                      AppStyles.warning.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppStyles.radiusMD),
                  border: Border.all(
                    color: AppStyles.warning.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.timer_rounded,
                  color: AppStyles.warning,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppStyles.spaceMD),
              Text(
                'Break Duration',
                style: AppStyles.subsectionHeader.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: AppStyles.foreground,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppStyles.spaceSM),
          Text(
            'How long breaks should last during study sessions',
            style: AppStyles.bodySmall.copyWith(
              color: AppStyles.mutedForeground,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppStyles.spaceLG),
          
          Row(
            children: [
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppStyles.primary,
                    inactiveTrackColor: AppStyles.muted,
                    thumbColor: AppStyles.primary,
                    overlayColor: AppStyles.primary.withOpacity(0.2),
                    valueIndicatorColor: AppStyles.primary,
                    valueIndicatorTextStyle: const TextStyle(
                      color: AppStyles.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  child: Slider(
                    value: _defaultBreakDuration.toDouble(),
                    min: 5,
                    max: 60,
                    divisions: 11,
                    label: '$_defaultBreakDuration minutes',
                    onChanged: (value) => setState(() => _defaultBreakDuration = value.round()),
                  ),
                ),
              ),
              const SizedBox(width: AppStyles.spaceMD),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppStyles.spaceMD, 
                  vertical: AppStyles.spaceSM
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppStyles.primary.withOpacity(0.15),
                      AppStyles.primary.withOpacity(0.05),
                    ],
                  ),
                  border: Border.all(
                    color: AppStyles.primary.withOpacity(0.3), 
                    width: 1.5
                  ),
                  borderRadius: BorderRadius.circular(AppStyles.radiusMD),
                ),
                child: Text(
                  '$_defaultBreakDuration min',
                  style: AppStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppStyles.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemeCard(ThemeMode themeMode) {
    String themeName = themeMode == ThemeMode.light ? 'Light' : 
                      themeMode == ThemeMode.dark ? 'Dark' : 'System';
    
    return Container(
      padding: const EdgeInsets.all(AppStyles.spaceLG),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppStyles.card,
            AppStyles.card.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(AppStyles.radiusLG),
        border: Border.all(
          color: AppStyles.border.withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppStyles.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppStyles.spaceSM),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppStyles.info.withOpacity(0.15),
                      AppStyles.info.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppStyles.radiusMD),
                  border: Border.all(
                    color: AppStyles.info.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.palette_rounded,
                  color: AppStyles.info,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppStyles.spaceMD),
              Text(
                'Appearance',
                style: AppStyles.subsectionHeader.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: AppStyles.foreground,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppStyles.spaceMD),
          
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Theme Mode',
                      style: AppStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppStyles.foreground,
                      ),
                    ),
                    const SizedBox(height: AppStyles.spaceXS),
                    Text(
                      themeName,
                      style: AppStyles.bodySmall.copyWith(
                        color: AppStyles.mutedForeground,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => _showThemeSelector(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppStyles.primary,
                  foregroundColor: AppStyles.primaryForeground,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppStyles.radiusMD),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppStyles.spaceMD, 
                    vertical: AppStyles.spaceSM
                  ),
                  elevation: 4,
                  shadowColor: AppStyles.primary.withOpacity(0.3),
                ),
                child: Text(
                  'Change',
                  style: AppStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDataCard() {
    return _buildModernCard(
      title: 'Data Management',
      children: [
        _buildDataTile(
          title: 'Clear All Data',
          subtitle: 'Reset app to initial state',
          icon: Icons.delete_outline_rounded,
          iconColor: AppStyles.destructive,
          onTap: _showClearDataDialog,
        ),
        _buildDivider(),
        _buildDataTile(
          title: 'Export Data',
          subtitle: 'Save your study data as JSON',
          icon: Icons.download_rounded,
          iconColor: AppStyles.success,
          onTap: _showExportDialog,
        ),
        const SizedBox(height: AppStyles.spaceSM),
      ],
    );
  }

  Widget _buildDataTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppStyles.radiusMD),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppStyles.spaceLG, 
          vertical: AppStyles.spaceMD
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppStyles.spaceSM),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    iconColor.withOpacity(0.15),
                    iconColor.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppStyles.radiusMD),
                border: Border.all(
                  color: iconColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: AppStyles.spaceMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppStyles.foreground,
                    ),
                  ),
                  const SizedBox(height: AppStyles.spaceXS),
                  Text(
                    subtitle,
                    style: AppStyles.bodySmall.copyWith(
                      color: AppStyles.mutedForeground,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppStyles.mutedForeground,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeSelector() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppStyles.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppStyles.radiusLG),
            side: BorderSide(color: AppStyles.border, width: 1),
          ),
          titlePadding: const EdgeInsets.fromLTRB(
            AppStyles.spaceXL, 
            AppStyles.spaceLG, 
            AppStyles.spaceXL, 
            0
          ),
          contentPadding: const EdgeInsets.fromLTRB(0, AppStyles.spaceMD, 0, 0),
          actionsPadding: const EdgeInsets.fromLTRB(
            AppStyles.spaceXL, 
            0, 
            AppStyles.spaceXL, 
            AppStyles.spaceLG
          ),
          title: Text(
            'Choose Theme',
            style: AppStyles.sectionHeader.copyWith(
              fontWeight: FontWeight.w700,
              color: AppStyles.foreground,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildThemeOption('Light', Icons.light_mode_rounded, ThemeMode.light),
              _buildThemeOption('Dark', Icons.dark_mode_rounded, ThemeMode.dark),
              _buildThemeOption('System', Icons.settings_rounded, ThemeMode.system),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: AppStyles.mutedForeground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppStyles.radiusMD)
                ),
              ),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildThemeOption(String title, IconData icon, ThemeMode value) {
    final isSelected = ref.read(themeProvider) == value;
    return InkWell(
      onTap: () {
        ref.read(themeProvider.notifier).setThemeMode(value);
        Navigator.of(context).pop();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppStyles.spaceXL, 
          vertical: AppStyles.spaceMD
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppStyles.spaceSM),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    isSelected 
                        ? AppStyles.primary.withOpacity(0.15) 
                        : AppStyles.muted.withOpacity(0.3),
                    isSelected 
                        ? AppStyles.primary.withOpacity(0.05) 
                        : AppStyles.muted.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppStyles.radiusMD),
                border: Border.all(
                  color: isSelected 
                      ? AppStyles.primary.withOpacity(0.3) 
                      : AppStyles.border,
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppStyles.primary : AppStyles.mutedForeground,
                size: 20,
              ),
            ),
            const SizedBox(width: AppStyles.spaceMD),
            Expanded(
              child: Text(
                title,
                style: AppStyles.bodyMedium.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? AppStyles.foreground : AppStyles.mutedForeground,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_rounded,
                color: AppStyles.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppStyles.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppStyles.radiusLG),
            side: BorderSide(color: AppStyles.border, width: 1),
          ),
          titlePadding: const EdgeInsets.fromLTRB(
            AppStyles.spaceXL,
            AppStyles.spaceLG,
            AppStyles.spaceXL,
            0
          ),
          contentPadding: const EdgeInsets.fromLTRB(
            AppStyles.spaceXL,
            AppStyles.spaceMD,
            AppStyles.spaceXL,
            0
          ),
          actionsPadding: const EdgeInsets.fromLTRB(
            AppStyles.spaceXL,
            AppStyles.spaceMD,
            AppStyles.spaceXL,
            AppStyles.spaceLG
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppStyles.spaceSM),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppStyles.destructive.withOpacity(0.15),
                      AppStyles.destructive.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppStyles.radiusMD),
                  border: Border.all(
                    color: AppStyles.destructive.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.warning_rounded,
                  color: AppStyles.destructive,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppStyles.spaceMD),
              Text(
                'Clear All Data',
                style: AppStyles.sectionHeader.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppStyles.foreground,
                ),
              ),
            ],
          ),
          content: Text(
            'This will permanently delete all your study data, settings, and progress. This action cannot be undone.',
            style: AppStyles.bodyMedium.copyWith(
              color: AppStyles.mutedForeground,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: AppStyles.mutedForeground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppStyles.radiusMD)
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppStyles.spaceMD,
                  vertical: AppStyles.spaceSM
                ),
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                      'All data cleared successfully',
                      style: TextStyle(color: AppStyles.white),
                    ),
                    backgroundColor: AppStyles.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppStyles.radiusMD)
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppStyles.destructive,
                foregroundColor: AppStyles.destructiveForeground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppStyles.radiusMD)
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppStyles.spaceMD,
                  vertical: AppStyles.spaceSM
                ),
              ),
              child: const Text('Clear Data'),
            ),
          ],
        );
      },
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppStyles.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppStyles.radiusLG),
            side: BorderSide(color: AppStyles.border, width: 1),
          ),
          titlePadding: const EdgeInsets.fromLTRB(
            AppStyles.spaceXL,
            AppStyles.spaceLG,
            AppStyles.spaceXL,
            0
          ),
          contentPadding: const EdgeInsets.fromLTRB(
            AppStyles.spaceXL,
            AppStyles.spaceMD,
            AppStyles.spaceXL,
            0
          ),
          actionsPadding: const EdgeInsets.fromLTRB(
            AppStyles.spaceXL,
            AppStyles.spaceMD,
            AppStyles.spaceXL,
            AppStyles.spaceLG
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppStyles.spaceSM),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppStyles.success.withOpacity(0.15),
                      AppStyles.success.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppStyles.radiusMD),
                  border: Border.all(
                    color: AppStyles.success.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.download_rounded,
                  color: AppStyles.success,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppStyles.spaceMD),
              Text(
                'Export Data',
                style: AppStyles.sectionHeader.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppStyles.foreground,
                ),
              ),
            ],
          ),
          content: Text(
            'Your study data will be exported as a JSON file. This includes your study sessions, blocked apps, and settings.',
            style: AppStyles.bodyMedium.copyWith(
              color: AppStyles.mutedForeground,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: AppStyles.mutedForeground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppStyles.radiusMD)
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppStyles.spaceMD,
                  vertical: AppStyles.spaceSM
                ),
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                      'Data exported successfully',
                      style: TextStyle(color: AppStyles.white),
                    ),
                    backgroundColor: AppStyles.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppStyles.radiusMD)
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppStyles.success,
                foregroundColor: AppStyles.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppStyles.radiusMD)
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppStyles.spaceMD,
                  vertical: AppStyles.spaceSM
                ),
              ),
              child: const Text('Export'),
            ),
          ],
        );
      },
    );
  }
}