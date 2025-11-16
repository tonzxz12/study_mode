import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/providers/theme_provider.dart';
import '../../core/theme/styles.dart';
import '../../core/services/app_blocking_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/firestore_service.dart';
import '../../data/services/app_blocking_settings_service.dart';
import '../auth/auth_wrapper.dart';
import '../debug/firestore_debug_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> with WidgetsBindingObserver {
  bool _studyModeEnabled = false;
  bool _notificationsEnabled = true;
  int _defaultBreakDuration = 30;
  
  // User Profile Data
  String _userDisplayName = 'Student';
  String _userEmail = '';
  
  // App Blocking Settings
  bool _appBlockingEnabled = false;
  bool _hasUsagePermission = false;
  bool _hasOverlayPermission = false;
  bool _isDeviceAdmin = false;
  bool _hasNotificationPermission = true; // Default to true for older Android
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSavedSettings();
    _checkPermissions();
    // Ensure background monitoring continues when app is opened
    AppBlockingService.ensurePersistentMonitoring();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // When user returns to the app, refresh permission status
      _checkPermissions();
    }
  }

  // Load saved settings from storage
  Future<void> _loadSavedSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load app blocking enabled state
      _appBlockingEnabled = await AppBlockingService.loadAppBlockingEnabled();
      
      // Load study mode enabled state
      _studyModeEnabled = prefs.getBool('study_mode_enabled') ?? false;
      
      // Load notifications enabled state
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      
      // Load default break duration
      _defaultBreakDuration = prefs.getInt('default_break_duration') ?? 30;
      
      // Load individual app blocking states from Firebase
      await _loadBlockedAppsFromFirebase();
      
      // Load user profile data from Firebase
      await _loadUserProfileData();
      
      setState(() {});
      print('Loaded saved settings from storage');
    } catch (e) {
      print('Error loading saved settings: $e');
    }
  }

  // Save settings to storage
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save basic settings
      await prefs.setBool('study_mode_enabled', _studyModeEnabled);
      await prefs.setBool('notifications_enabled', _notificationsEnabled);
      await prefs.setInt('default_break_duration', _defaultBreakDuration);
      
      // Save app blocking enabled state
      await AppBlockingService.saveAppBlockingEnabled(_appBlockingEnabled);
      
      print('Saved settings to storage');
    } catch (e) {
      print('Error saving settings: $e');
    }
  }

  // Clear all saved data
  Future<void> _clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Clear all settings
      await prefs.clear();
      
      // Clear app blocking data
      await AppBlockingService.clearSavedData();
      await AppBlockingService.stopMonitoring();
      
      // Reset local state
      setState(() {
        _studyModeEnabled = false;
        _notificationsEnabled = true;
        _defaultBreakDuration = 30;
        _appBlockingEnabled = false;
        
        // Reset all blocked apps
        for (int i = 0; i < _blockableApps.length; i++) {
          _blockableApps[i]['blocked'] = false;
        }
      });
      
      print('Cleared all data successfully');
    } catch (e) {
      print('Error clearing all data: $e');
    }
  }

  // Export all data to JSON file
  Future<void> _exportData() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      
      // Gather all data
      final exportData = {
        'export_date': DateTime.now().toIso8601String(),
        'app_version': '1.0.0',
        'settings': {
          'study_mode_enabled': _studyModeEnabled,
          'notifications_enabled': _notificationsEnabled,
          'default_break_duration': _defaultBreakDuration,
          'app_blocking_enabled': _appBlockingEnabled,
        },
        'blocked_apps': _blockableApps.where((app) => app['blocked'] as bool)
            .map((app) => {
              'name': app['name'],
              'package': app['package'],
              'blocked_date': DateTime.now().toIso8601String(),
            }).toList(),
        'permissions': {
          'usage_permission': _hasUsagePermission,
          'overlay_permission': _hasOverlayPermission,
          'device_admin': _isDeviceAdmin,
        },
        'app_blocking_service': {
          'monitoring_active': AppBlockingService.isMonitoringActive,
          'blocked_packages': AppBlockingService.getBlockedApps(),
        }
      };
      
      // Create JSON file
      final fileName = 'study_mode_data_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(jsonEncode(exportData));
      
      print('Data exported to: ${file.path}');
      return;
    } catch (e) {
      print('Error exporting data: $e');
      throw e;
    }
  }

  Future<void> _checkPermissions() async {
    // Check if we have usage access permission
    _hasUsagePermission = await _checkUsagePermission();
    // Check if we have overlay permission
    _hasOverlayPermission = await _checkOverlayPermission();
    // Check if we're device admin
    _isDeviceAdmin = await _checkDeviceAdmin();
    setState(() {});
  }

  Future<bool> _checkUsagePermission() async {
    try {
      return await AppBlockingService.hasUsagePermission();
    } catch (e) {
      print('Error checking usage permission: $e');
      return false;
    }
  }

  Future<bool> _checkOverlayPermission() async {
    try {
      return await AppBlockingService.hasOverlayPermission();
    } catch (e) {
      print('Error checking overlay permission: $e');
      return false;
    }
  }

  Future<bool> _checkDeviceAdmin() async {
    try {
      return await AppBlockingService.isDeviceAdmin();
    } catch (e) {
      print('Error checking device admin: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
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
          bottom: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section with Settings Title and Status Badge
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
                      // Settings Title with Icon
                      Expanded(
                        child: Row(
                          children: [
                            // Settings Icon
                            Container(
                              padding: const EdgeInsets.all(AppStyles.spaceXS),
                              decoration: BoxDecoration(
                                color: AppStyles.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(AppStyles.radiusMD),
                              ),
                              child: Icon(
                                Icons.settings_rounded,
                                size: 32,
                                color: AppStyles.primary,
                              ),
                            ),
                            const SizedBox(width: AppStyles.spaceMD),
                            // Settings Text
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Settings',
                                    style: AppStyles.screenTitle.copyWith(
                                      height: 1.1,
                                      letterSpacing: -0.5,
                                      color: AppStyles.primary,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  Text(
                                    'App Configuration',
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
                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppStyles.spaceMD,
                          vertical: AppStyles.spaceXS,
                        ),
                        decoration: BoxDecoration(
                          color: _studyModeEnabled 
                              ? AppStyles.success.withOpacity(0.1)
                              : AppStyles.muted.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(AppStyles.radiusXL),
                          border: Border.all(
                            color: _studyModeEnabled 
                                ? AppStyles.success.withOpacity(0.3)
                                : AppStyles.border,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: _studyModeEnabled ? AppStyles.success : AppStyles.mutedForeground,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: AppStyles.spaceXS),
                            Text(
                              _studyModeEnabled ? 'Active' : 'Inactive',
                              style: TextStyle(
                                color: _studyModeEnabled ? AppStyles.success : AppStyles.mutedForeground,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppStyles.spaceXL),

                // Settings Content
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppStyles.spaceXL),
                  child: Column(
                    children: [
                      // User Profile Card
                      _buildUserProfileCard(),
                      
                      const SizedBox(height: AppStyles.spaceLG),
                      
                      // Study Mode Card
                      _buildModernCard(
                        title: 'Study Mode',
                        children: [
                          _buildModernSwitchTile(
                            title: 'Focus Mode',
                            subtitle: 'Block distracting apps during study sessions',
                            value: _studyModeEnabled,
                            onChanged: (value) {
                              setState(() => _studyModeEnabled = value);
                              _saveSettings();
                            },
                            icon: Icons.school_rounded,
                            iconColor: AppStyles.primary,
                          ),
                          _buildDivider(),
                          _buildAppBlockingTile(),
                          _buildDivider(),
                          _buildModernSwitchTile(
                            title: 'Notifications',
                            subtitle: 'Get study reminders and break alerts',
                            value: _notificationsEnabled,
                            onChanged: (value) {
                              setState(() => _notificationsEnabled = value);
                              _saveSettings();
                            },
                            icon: Icons.notifications_rounded,
                            iconColor: AppStyles.warning,
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: AppStyles.spaceXL),
                      
                      // App Blocking Setup Card
                      if (_appBlockingEnabled && !_allPermissionsGranted()) ...[
                        _buildAppBlockingSetupCard(),
                        const SizedBox(height: AppStyles.spaceXL),
                      ],
                      
                      // App Restrictions Card
                      if (_appBlockingEnabled && _allPermissionsGranted()) ...[
                        _buildAppRestrictionsCard(),
                        const SizedBox(height: AppStyles.spaceXL),
                      ],
                      
                      // Break Duration Card
                      _buildBreakDurationCard(),
                      
                      const SizedBox(height: AppStyles.spaceXL),
                      
                      // Theme Settings Card  
                      _buildThemeCard(),
                      
                      const SizedBox(height: AppStyles.spaceXL),
                      
                      // Data Management Card
                      _buildDataCard(),

                      const SizedBox(height: AppStyles.spaceXL),

                      // Debug Card (for testing Firestore)
                      _buildDebugCard(),

                      const SizedBox(height: AppStyles.spaceXL),

                      // Logout Section
                      _buildLogoutCard(),
                    ],
                  ),
                ),

                const SizedBox(height: AppStyles.spaceXXL * 2), // Extra space for navbar
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _allPermissionsGranted() {
    return _hasUsagePermission && _hasOverlayPermission && _isDeviceAdmin;
  }

  Widget _buildAppBlockingTile() {
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
                  AppStyles.destructive.withOpacity(0.15),
                  AppStyles.destructive.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(AppStyles.radiusMD),
              border: Border.all(
                color: AppStyles.destructive.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppStyles.destructive.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Icon(Icons.block_rounded, color: AppStyles.destructive, size: 20),
          ),
          const SizedBox(width: AppStyles.spaceMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'App Blocking',
                      style: AppStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppStyles.foreground,
                      ),
                    ),
                    const SizedBox(width: AppStyles.spaceXS),
                    if (!_allPermissionsGranted() && _appBlockingEnabled)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppStyles.spaceXS,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppStyles.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppStyles.radiusSM),
                        ),
                        child: Text(
                          'Setup Required',
                          style: TextStyle(
                            color: AppStyles.warning,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppStyles.spaceXS),
                Text(
                  _allPermissionsGranted() && _appBlockingEnabled 
                      ? 'Ready to block selected apps during study sessions'
                      : 'Requires device permissions for full functionality',
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
              value: _appBlockingEnabled,
              onChanged: (value) async {
                if (value && !_allPermissionsGranted()) {
                  _showPermissionDialog();
                } else {
                  setState(() => _appBlockingEnabled = value);
                  _saveSettings();
                }
              },
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

  Widget _buildAppBlockingSetupCard() {
    return _buildModernCard(
      title: 'App Blocking Setup',
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppStyles.spaceLG),
          child: Text(
            'Grant the following permissions to enable app blocking during study sessions:',
            style: AppStyles.bodySmall.copyWith(
              color: AppStyles.mutedForeground,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: AppStyles.spaceMD),
        
        _buildPermissionTile(
          title: 'Usage Access',
          subtitle: 'Monitor app usage to detect when blocked apps are opened',
          icon: Icons.analytics_rounded,
          isGranted: _hasUsagePermission,
          onTap: _requestUsagePermission,
        ),
        _buildDivider(),
        _buildPermissionTile(
          title: 'Display Over Apps',
          subtitle: 'Show blocking overlay when restricted apps are accessed',
          icon: Icons.layers_rounded,
          isGranted: _hasOverlayPermission,
          onTap: _requestOverlayPermission,
        ),
        _buildDivider(),
        _buildPermissionTile(
          title: 'Notifications',
          subtitle: 'Send reminders and study session notifications',
          icon: Icons.notifications_rounded,
          isGranted: _hasNotificationPermission,
          onTap: _requestNotificationPermission,
        ),
        _buildDivider(),
        _buildPermissionTile(
          title: 'Device Administrator',
          subtitle: 'Enhanced app control and blocking capabilities',
          icon: Icons.admin_panel_settings_rounded,
          isGranted: _isDeviceAdmin,
          onTap: _requestDeviceAdmin,
        ),
        
        const SizedBox(height: AppStyles.spaceLG),
        if (!_allPermissionsGranted())
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppStyles.spaceLG),
            child: Container(
              padding: const EdgeInsets.all(AppStyles.spaceMD),
              decoration: BoxDecoration(
                color: AppStyles.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppStyles.radiusMD),
                border: Border.all(
                  color: AppStyles.warning.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_rounded,
                    color: AppStyles.warning,
                    size: 20,
                  ),
                  const SizedBox(width: AppStyles.spaceSM),
                  Expanded(
                    child: Text(
                      'App blocking requires special permissions. Tap each item above to grant access.',
                      style: AppStyles.bodySmall.copyWith(
                        color: AppStyles.warning,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: AppStyles.spaceSM),
      ],
    );
  }

  Widget _buildPermissionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isGranted,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: isGranted ? null : onTap,
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
                    (isGranted ? AppStyles.success : AppStyles.warning).withOpacity(0.15),
                    (isGranted ? AppStyles.success : AppStyles.warning).withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppStyles.radiusMD),
                border: Border.all(
                  color: (isGranted ? AppStyles.success : AppStyles.warning).withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                icon, 
                color: isGranted ? AppStyles.success : AppStyles.warning, 
                size: 20
              ),
            ),
            const SizedBox(width: AppStyles.spaceMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: AppStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppStyles.foreground,
                        ),
                      ),
                      const SizedBox(width: AppStyles.spaceXS),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppStyles.spaceXS,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: (isGranted ? AppStyles.success : AppStyles.warning).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppStyles.radiusSM),
                        ),
                        child: Text(
                          isGranted ? 'Granted' : 'Required',
                          style: TextStyle(
                            color: isGranted ? AppStyles.success : AppStyles.warning,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
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
            if (!isGranted)
              Icon(
                Icons.chevron_right_rounded,
                color: AppStyles.mutedForeground,
                size: 20,
              ),
            if (isGranted)
              Icon(
                Icons.check_circle_rounded,
                color: AppStyles.success,
                size: 20,
              ),
          ],
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
    final blockedCount = _blockableApps.where((app) => app['blocked'] as bool).length;
    
    return _buildModernCard(
      title: 'App Restrictions',
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppStyles.spaceLG),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Select which apps to block during study sessions',
                  style: AppStyles.bodySmall.copyWith(
                    color: AppStyles.mutedForeground,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppStyles.spaceSM,
                  vertical: AppStyles.spaceXS,
                ),
                decoration: BoxDecoration(
                  color: blockedCount > 0 
                      ? AppStyles.destructive.withOpacity(0.1)
                      : AppStyles.muted.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(AppStyles.radiusSM),
                ),
                child: Text(
                  '$blockedCount/${_blockableApps.length} blocked',
                  style: TextStyle(
                    color: blockedCount > 0 
                        ? AppStyles.destructive 
                        : AppStyles.mutedForeground,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
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
    final isBlocked = app['blocked'] as bool;
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
            child: Stack(
              children: [
                Icon(
                  app['icon'] as IconData,
                  color: isBlocked 
                      ? AppStyles.mutedForeground 
                      : app['color'] as Color,
                  size: 20,
                ),
                if (isBlocked)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppStyles.destructive,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppStyles.card,
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.block,
                        color: AppStyles.white,
                        size: 8,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppStyles.spaceMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      app['name'] as String,
                      style: AppStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isBlocked 
                            ? AppStyles.mutedForeground 
                            : AppStyles.foreground,
                        decoration: isBlocked 
                            ? TextDecoration.lineThrough 
                            : TextDecoration.none,
                      ),
                    ),
                    const SizedBox(width: AppStyles.spaceXS),
                    if (isBlocked)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppStyles.spaceXS,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppStyles.destructive.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppStyles.radiusSM),
                        ),
                        child: Text(
                          'BLOCKED',
                          style: TextStyle(
                            color: AppStyles.destructive,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppStyles.spaceXS),
                Text(
                  app['package'] as String,
                  style: AppStyles.bodySmall.copyWith(
                    color: AppStyles.mutedForeground,
                    fontFamily: 'monospace',
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 1.1,
            child: Switch(
              value: isBlocked,
              onChanged: (value) {
                setState(() {
                  _blockableApps[index]['blocked'] = value;
                });
                _updateAppBlocking(app['package'] as String, value);
              },
              activeColor: AppStyles.destructive,
              activeTrackColor: AppStyles.destructive.withOpacity(0.3),
              inactiveThumbColor: AppStyles.mutedForeground,
              inactiveTrackColor: AppStyles.muted.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  void _updateAppBlocking(String packageName, bool shouldBlock) async {
    try {
      final userId = FirestoreService.currentUserId;
      if (userId == null) {
        print('❌ No user logged in for app blocking settings');
        return;
      }

      if (shouldBlock) {
        // Add app to blocking list
        AppBlockingService.addBlockedApp(packageName);
        
        // Start monitoring if this is the first blocked app
        final blockedApps = _blockableApps.where((app) => app['blocked'] as bool).map((app) => app['package'] as String).toList();
        if (blockedApps.length == 1) {
          await AppBlockingService.startMonitoring(blockedApps);
        }
        
        // Save to Firebase settings table
        await AppBlockingSettingsService.updateBlockedApps(userId, blockedApps);
        print('✅ Saved blocked app $packageName to Firebase settings for user: $userId');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Now blocking ${_blockableApps.firstWhere((app) => app['package'] == packageName)['name']}',
              style: const TextStyle(color: AppStyles.white),
            ),
            backgroundColor: AppStyles.destructive,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppStyles.radiusMD)
            ),
          ),
        );
      } else {
        // Remove app from blocking list
        AppBlockingService.removeBlockedApp(packageName);
        
        // Update monitoring with remaining blocked apps
        final blockedApps = _blockableApps.where((app) => app['blocked'] as bool).map((app) => app['package'] as String).toList();
        if (blockedApps.isEmpty) {
          await AppBlockingService.stopMonitoring();
        } else {
          await AppBlockingService.startMonitoring(blockedApps);
        }
        
        // Save to Firebase settings table
        await AppBlockingSettingsService.updateBlockedApps(userId, blockedApps);
        print('✅ Removed blocked app $packageName from Firebase settings for user: $userId');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Stopped blocking ${_blockableApps.firstWhere((app) => app['package'] == packageName)['name']}',
              style: const TextStyle(color: AppStyles.white),
            ),
            backgroundColor: AppStyles.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppStyles.radiusMD)
            ),
          ),
        );
      }
    } catch (e) {
      print('Error updating app blocking: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Error updating app blocking settings',
            style: TextStyle(color: AppStyles.white),
          ),
          backgroundColor: AppStyles.destructive,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppStyles.radiusMD)
          ),
        ),
      );
    }
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
                    onChanged: (value) {
                      setState(() => _defaultBreakDuration = value.round());
                      _saveSettings();
                    },
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

  Widget _buildThemeCard() {
    final themeNotifier = ref.read(themeProvider.notifier);
    String themeName = themeNotifier.themeName;
    
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
        _buildDivider(),
        _buildDataTile(
          title: 'Data Collection Status',
          subtitle: 'View student data sync & collection status',
          icon: Icons.analytics_rounded,
          iconColor: AppStyles.info,
          onTap: _showDataCollectionStatus,
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

  Widget _buildLogoutCard() {
    return _buildModernCard(
      title: 'Account',
      children: [
        _buildDataTile(
          title: 'Sign Out',
          subtitle: 'Sign out of your account',
          icon: Icons.logout_rounded,
          iconColor: AppStyles.destructive,
          onTap: _showLogoutDialog,
        ),
        const SizedBox(height: AppStyles.spaceSM),
      ],
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppStyles.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppStyles.radiusLG),
          ),
          title: Text(
            'Sign Out',
            style: AppStyles.subsectionHeader.copyWith(
              color: AppStyles.foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Are you sure you want to sign out? You will need to sign in again to access your account.',
            style: AppStyles.bodyMedium.copyWith(
              color: AppStyles.mutedForeground,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: AppStyles.mutedForeground,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppStyles.spaceLG,
                  vertical: AppStyles.spaceSM,
                ),
              ),
              child: Text(
                'Cancel',
                style: AppStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await AuthService().signOut();
                  if (mounted) {
                    // Navigate to auth wrapper which will show login screen
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const AuthWrapper(),
                      ),
                      (route) => false,
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to sign out: $e'),
                        backgroundColor: AppStyles.destructive,
                      ),
                    );
                  }
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: AppStyles.destructive,
                backgroundColor: AppStyles.destructive.withOpacity(0.1),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppStyles.spaceLG,
                  vertical: AppStyles.spaceSM,
                ),
              ),
              child: Text(
                'Sign Out',
                style: AppStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showPermissionDialog() {
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
                  Icons.security_rounded,
                  color: AppStyles.warning,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppStyles.spaceMD),
              Text(
                'Permissions Required',
                style: AppStyles.sectionHeader.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppStyles.foreground,
                ),
              ),
            ],
          ),
          content: Text(
            'App blocking requires special Android permissions to function properly. You\'ll need to grant Usage Access, Display Over Apps, and Device Administrator permissions.',
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
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() => _appBlockingEnabled = true);
                _saveSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppStyles.primary,
                foregroundColor: AppStyles.primaryForeground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppStyles.radiusMD)
                ),
              ),
              child: const Text('Enable & Setup'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _requestUsagePermission() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Opening Usage Access settings...',
          style: TextStyle(color: AppStyles.white),
        ),
        backgroundColor: AppStyles.info,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppStyles.radiusMD)
        ),
      ),
    );
    
    try {
      await AppBlockingService.requestUsagePermission();
      await Future.delayed(const Duration(seconds: 1));
      _hasUsagePermission = await _checkUsagePermission();
      setState(() {});
      
      if (_hasUsagePermission) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Usage Access permission granted!',
              style: TextStyle(color: AppStyles.white),
            ),
            backgroundColor: AppStyles.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppStyles.radiusMD)
            ),
          ),
        );
      }
    } catch (e) {
      print('Error requesting usage permission: $e');
    }
  }

  Future<void> _requestOverlayPermission() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Requesting Display Over Apps permission...',
          style: TextStyle(color: AppStyles.white),
        ),
        backgroundColor: AppStyles.info,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppStyles.radiusMD)
        ),
      ),
    );
    
    try {
      final granted = await AppBlockingService.requestOverlayPermission();
      _hasOverlayPermission = granted;
      setState(() {});
      
      if (granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Display Over Apps permission granted!',
              style: TextStyle(color: AppStyles.white),
            ),
            backgroundColor: AppStyles.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppStyles.radiusMD)
            ),
          ),
        );
      }
    } catch (e) {
      print('Error requesting overlay permission: $e');
    }
  }

  Future<void> _requestNotificationPermission() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Checking notification permission...',
          style: TextStyle(color: AppStyles.white),
        ),
        backgroundColor: AppStyles.info,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppStyles.radiusMD)
        ),
      ),
    );
    
    try {
      // On Android 13+, we need to request notification permission
      // For older versions, it's granted by default
      _hasNotificationPermission = true;
      setState(() {});
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Notification permission is enabled',
            style: TextStyle(color: AppStyles.white),
          ),
          backgroundColor: AppStyles.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppStyles.radiusMD)
          ),
        ),
      );
    } catch (e) {
      print('Error checking notification permission: $e');
    }
  }

  Future<void> _requestDeviceAdmin() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Opening Device Administrator settings...',
          style: TextStyle(color: AppStyles.white),
        ),
        backgroundColor: AppStyles.info,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppStyles.radiusMD)
        ),
      ),
    );
    
    try {
      await AppBlockingService.requestDeviceAdmin();
      
      // Check permission status after a delay and when user returns to app
      await Future.delayed(const Duration(seconds: 3));
      _isDeviceAdmin = await _checkDeviceAdmin();
      setState(() {});
      
      if (_isDeviceAdmin) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Device Administrator access granted!',
              style: TextStyle(color: AppStyles.white),
            ),
            backgroundColor: AppStyles.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppStyles.radiusMD)
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Please enable Device Administrator to use app blocking features',
              style: TextStyle(color: AppStyles.white),
            ),
            backgroundColor: AppStyles.warning,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppStyles.radiusMD)
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      print('Error requesting device admin permission: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Error opening Device Administrator settings',
            style: TextStyle(color: AppStyles.white),
          ),
          backgroundColor: AppStyles.destructive,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppStyles.radiusMD)
          ),
        ),
      );
    }
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
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Select your preferred theme mode',
                  style: AppStyles.bodyMedium.copyWith(
                    color: AppStyles.mutedForeground,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                _buildThemeOption('Light Mode', Icons.light_mode_rounded, ThemeMode.light),
                const SizedBox(height: 8),
                _buildThemeOption('Dark Mode', Icons.dark_mode_rounded, ThemeMode.dark),
                const SizedBox(height: 8),
                _buildThemeOption('System Default', Icons.settings_rounded, ThemeMode.system),
                const SizedBox(height: 16),
              ],
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
              ),
              child: const Text('Done'),
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
              onPressed: () async {
                Navigator.of(context).pop();
                await _clearAllData();
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
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await _exportData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                        'Data exported successfully to Documents folder',
                        style: TextStyle(color: AppStyles.white),
                      ),
                      backgroundColor: AppStyles.success,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppStyles.radiusMD)
                      ),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                        'Error exporting data',
                        style: TextStyle(color: AppStyles.white),
                      ),
                      backgroundColor: AppStyles.destructive,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppStyles.radiusMD)
                      ),
                    ),
                  );
                }
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

  void _showDataCollectionStatus() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppStyles.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppStyles.radiusLG),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppStyles.spaceSM),
                decoration: BoxDecoration(
                  color: AppStyles.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppStyles.radiusSM),
                ),
                child: Icon(
                  Icons.analytics_rounded,
                  color: AppStyles.info,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppStyles.spaceMD),
              Text(
                'Student Data Collection',
                style: AppStyles.subsectionHeader.copyWith(
                  color: AppStyles.foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'This app collects study session data for research purposes. Your data helps improve educational technology.',
                  style: AppStyles.bodyMedium.copyWith(
                    color: AppStyles.mutedForeground,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: AppStyles.spaceMD),
                Container(
                  padding: const EdgeInsets.all(AppStyles.spaceMD),
                  decoration: BoxDecoration(
                    color: AppStyles.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppStyles.radiusMD),
                    border: Border.all(
                      color: AppStyles.info.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📊 Data Collected:',
                        style: AppStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppStyles.info,
                        ),
                      ),
                      const SizedBox(height: AppStyles.spaceXS),
                      Text(
                        '• Study session duration\n'
                        '• Subject progress\n'
                        '• Focus scores\n'
                        '• App usage patterns\n'
                        '• Study habits & analytics',
                        style: AppStyles.bodySmall.copyWith(
                          color: AppStyles.mutedForeground,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppStyles.spaceMD),
                Container(
                  padding: const EdgeInsets.all(AppStyles.spaceMD),
                  decoration: BoxDecoration(
                    color: AppStyles.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppStyles.radiusMD),
                    border: Border.all(
                      color: AppStyles.success.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🔒 Privacy Protection:',
                        style: AppStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppStyles.success,
                        ),
                      ),
                      const SizedBox(height: AppStyles.spaceXS),
                      Text(
                        '• Data is anonymized\n'
                        '• No personal identifiers stored\n'
                        '• Secure cloud storage\n'
                        '• You can export/delete anytime',
                        style: AppStyles.bodySmall.copyWith(
                          color: AppStyles.mutedForeground,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: AppStyles.mutedForeground,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppStyles.spaceLG,
                  vertical: AppStyles.spaceSM,
                ),
              ),
              child: Text(
                'Close',
                style: AppStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDebugCard() {
    return _buildModernCard(
      title: 'Developer Tools',
      children: [
        _buildDataTile(
          title: 'Firestore Debug',
          subtitle: 'Test database connection and data saving',
          icon: Icons.bug_report_rounded,
          iconColor: AppStyles.warning,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const FirestoreDebugScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: AppStyles.spaceSM),
      ],
    );
  }

  // Load blocked apps from Firebase
  Future<void> _loadBlockedAppsFromFirebase() async {
    try {
      final userId = FirestoreService.currentUserId;
      if (userId != null) {
        final settings = await AppBlockingSettingsService.getUserSettings(userId);
        
        // Update local blocked apps state
        for (int i = 0; i < _blockableApps.length; i++) {
          final packageName = _blockableApps[i]['package'] as String;
          _blockableApps[i]['blocked'] = settings.blockedApps.contains(packageName);
        }
        
        print('✅ Loaded ${settings.blockedApps.length} blocked apps from Firebase for user: $userId');
      } else {
        print('❌ No user logged in to load blocked apps');
      }
    } catch (e) {
      print('❌ Error loading blocked apps from Firebase: $e');
    }
  }

  // Load user profile data from Firebase
  Future<void> _loadUserProfileData() async {
    try {
      final userId = FirestoreService.currentUserId;
      if (userId != null) {
        final userData = await FirestoreService.getUserData();
        
        if (userData != null) {
          _userDisplayName = userData['displayName'] ?? 'Student';
          _userEmail = userData['email'] ?? '';
          print('✅ Loaded user profile: $_userDisplayName ($_userEmail)');
        } else {
          print('❌ No user data found in Firebase');
        }
      } else {
        print('❌ No user logged in to load profile data');
      }
    } catch (e) {
      print('❌ Error loading user profile data: $e');
    }
  }

  // Build user profile card
  Widget _buildUserProfileCard() {
    final user = FirestoreService.currentUserId;
    
    return _buildModernCard(
      title: 'Profile',
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppStyles.spaceLG, vertical: AppStyles.spaceMD),
          child: Row(
            children: [
              // User Avatar
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppStyles.primary,
                      AppStyles.primary.withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: AppStyles.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              
              const SizedBox(width: AppStyles.spaceMD),
              
              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userDisplayName,
                      style: AppStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppStyles.foreground,
                      ),
                    ),
                    const SizedBox(height: AppStyles.spaceXS),
                    Text(
                      _userEmail.isNotEmpty ? _userEmail : (user != null ? 'ID: ${user.substring(0, 8)}...' : 'Not logged in'),
                      style: AppStyles.bodySmall.copyWith(
                        color: AppStyles.mutedForeground,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppStyles.spaceXS),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppStyles.spaceXS,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppStyles.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppStyles.radiusSM),
                      ),
                      child: Text(
                        'Active',
                        style: TextStyle(
                          color: AppStyles.success,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Settings sync status
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Icon(
                    Icons.cloud_done_rounded,
                    color: AppStyles.success,
                    size: 20,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Synced',
                    style: TextStyle(
                      color: AppStyles.success,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}