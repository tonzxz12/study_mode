import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/providers/theme_provider.dart';
import '../../core/services/shortcut_service.dart';
import '../../core/theme/styles.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/services/app_blocking_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/firestore_service.dart';
import '../../data/services/app_blocking_settings_service.dart';
import '../auth/auth_wrapper.dart';

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
  bool _hasPopupWindowPermission = false;
  bool _hasBackgroundWindowPermission = false;
  bool _hasLockScreenPermission = false;
  bool _hasShortcutPermission = false;
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
    // Load blocked apps and ensure background monitoring continues
    _autoLoadBlockedApps();
    AppBlockingService.ensurePersistentMonitoring();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Auto-load blocked apps from database
  Future<void> _autoLoadBlockedApps() async {
    try {
      await AppBlockingService.loadBlockedApps();
      final blockedApps = AppBlockingService.getBlockedApps();
      
      if (blockedApps.isNotEmpty) {
        // Update UI to reflect loaded blocked apps
        setState(() {
          for (var app in _blockableApps) {
            app['blocked'] = blockedApps.contains(app['package']);
          }
        });
        
        // Auto-start monitoring
        await AppBlockingService.startMonitoring(blockedApps);
        print('🔥 AUTO-LOADED ${blockedApps.length} blocked apps and started monitoring');
      }
    } catch (e) {
      print('⚠️ Error auto-loading blocked apps: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // When user returns to the app, refresh permission status
      print('🔄 App resumed, checking all permissions...');
      _checkPermissions();
      
      // Show success message if usage permission was just granted
      Future.delayed(const Duration(milliseconds: 500), () async {
        final hasPermission = await _checkUsagePermission();
        if (hasPermission && !_hasUsagePermission) {
          _hasUsagePermission = true;
          setState(() {});
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Usage Access permission granted! App blocking is now available.',
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
        }
      });
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
    // Check notification permission properly
    _hasNotificationPermission = await _checkNotificationPermission();
    // Check additional permissions
    _hasPopupWindowPermission = await _checkPopupWindowPermission();
    _hasBackgroundWindowPermission = await _checkBackgroundWindowPermission();
    _hasLockScreenPermission = await _checkLockScreenPermission();
    _hasShortcutPermission = await _checkShortcutPermission();
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

  Future<bool> _checkNotificationPermission() async {
    try {
      final status = await Permission.notification.status;
      return status.isGranted;
    } catch (e) {
      print('Error checking notification permission: $e');
      // On older Android versions, notifications are granted by default
      return true;
    }
  }

  Future<bool> _checkPopupWindowPermission() async {
    try {
      // This is actually the same as system alert window permission
      final status = await Permission.systemAlertWindow.status;
      return status.isGranted;
    } catch (e) {
      print('Error checking popup window permission: $e');
      return false;
    }
  }

  Future<bool> _checkBackgroundWindowPermission() async {
    try {
      // The "Open new windows while running in the background" permission is managed by Android
      // and there's no direct API to check it. It's typically enabled by default but can be
      // disabled per-app in "Other permissions" settings.
      
      // We'll use system alert window as a proxy since they're related,
      // but this is not a perfect check for the specific "background windows" permission
      final alertWindowStatus = await Permission.systemAlertWindow.status;
      print('🔍 System Alert Window status (proxy check): $alertWindowStatus');
      
      // Note: This may show false positives or negatives since we can't directly check
      // the "Open new windows while running in the background" permission via API
      return alertWindowStatus.isGranted;
    } catch (e) {
      print('Error checking background window permission: $e');
      return false;
    }
  }

  Future<bool> _checkLockScreenPermission() async {
    try {
      // Check if notification permission allows lock screen display
      final notificationStatus = await Permission.notification.status;
      final criticalAlertsStatus = await Permission.criticalAlerts.status;
      // Lock screen permission is typically tied to notification permissions
      return notificationStatus.isGranted || criticalAlertsStatus.isGranted;
    } catch (e) {
      print('Error checking lock screen permission: $e');
      // Default to false if we can't check properly
      return false;
    }
  }

  Future<bool> _checkShortcutPermission() async {
    try {
      // Check if shortcuts are supported on this device
      final isSupported = await ShortcutService.areShortcutsSupported();
      print('📱 Shortcut support check: $isSupported');
      return isSupported;
    } catch (e) {
      print('Error checking shortcut permission: $e');
      // Default to false for safety
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        color: context.background,
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
                                color: context.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(AppStyles.radiusMD),
                              ),
                              child: Icon(
                                Icons.settings_rounded,
                                size: 32,
                                color: context.primary,
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
                                      color: context.primary,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  Text(
                                    'App Configuration',
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
                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppStyles.spaceMD,
                          vertical: AppStyles.spaceXS,
                        ),
                        decoration: BoxDecoration(
                          color: _studyModeEnabled 
                              ? context.success.withOpacity(0.1)
                              : context.muted.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(AppStyles.radiusXL),
                          border: Border.all(
                            color: _studyModeEnabled 
                                ? context.success.withOpacity(0.3)
                                : context.border,
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
                                color: _studyModeEnabled ? context.success : context.mutedForeground,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: AppStyles.spaceXS),
                            Text(
                              _studyModeEnabled ? 'Active' : 'Inactive',
                              style: TextStyle(
                                color: _studyModeEnabled ? context.success : context.mutedForeground,
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
                      
                      // Theme Settings Card  
                      _buildThemeCard(),
                      
                      const SizedBox(height: AppStyles.spaceXL),
                      
                      // Data Management Card
                      _buildDataCard(),

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
    return _hasUsagePermission && 
           _hasOverlayPermission && 
           _isDeviceAdmin && 
           _hasNotificationPermission &&
           _hasPopupWindowPermission &&
           _hasBackgroundWindowPermission &&
           _hasLockScreenPermission &&
           _hasShortcutPermission;
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
              color: context.destructive.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppStyles.radiusMD),
              border: Border.all(
                color: context.destructive.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: context.shadowSM,
            ),
            child: Icon(Icons.block_rounded, color: context.destructive, size: 20),
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
                        color: context.foreground,
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
                    color: context.mutedForeground,
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
              activeColor: context.primary,
              activeTrackColor: context.primary.withOpacity(0.3),
              inactiveThumbColor: context.mutedForeground,
              inactiveTrackColor: context.muted.withOpacity(0.5),
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
              color: context.mutedForeground,
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
        _buildDivider(),
        _buildPermissionTile(
          title: 'Display Pop-up Windows',
          subtitle: 'Allow app to show blocking pop-ups over other apps',
          icon: Icons.open_in_new_rounded,
          isGranted: _hasPopupWindowPermission,
          onTap: _requestPopupWindowPermission,
        ),
        _buildDivider(),
        _buildPermissionTile(
          title: 'Open new windows while running in the background',
          subtitle: 'Allow app to start activities and windows from background',
          icon: Icons.launch_rounded,
          isGranted: _hasBackgroundWindowPermission,
          onTap: _requestBackgroundWindowPermission,
        ),
        _buildDivider(),
        _buildPermissionTile(
          title: 'Show on Lock Screen',
          subtitle: 'Display blocking notifications on lock screen',
          icon: Icons.lock_outline_rounded,
          isGranted: _hasLockScreenPermission,
          onTap: _requestLockScreenPermission,
        ),
        _buildDivider(),
        _buildPermissionTile(
          title: 'Home Screen Shortcuts',
          subtitle: 'Create shortcuts for quick study mode access',
          icon: Icons.shortcut_rounded,
          isGranted: _hasShortcutPermission,
          onTap: _requestShortcutPermission,
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
                          color: context.foreground,
                        ),
                      ),
                      const SizedBox(width: AppStyles.spaceXS),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppStyles.spaceXS,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: (isGranted ? context.success : context.warning).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppStyles.radiusSM),
                        ),
                        child: Text(
                          isGranted ? 'Granted' : 'Required',
                          style: TextStyle(
                            color: isGranted ? context.success : context.warning,
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
                      color: context.mutedForeground,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (!isGranted)
              Icon(
                Icons.chevron_right_rounded,
                color: context.mutedForeground,
                size: 20,
              ),
            if (isGranted)
              Icon(
                Icons.check_circle_rounded,
                color: context.success,
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
        color: context.card,
        borderRadius: BorderRadius.circular(AppStyles.radiusLG),
        border: Border.all(
          color: context.border.withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: context.shadowSM,
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
                color: context.foreground,
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
                    color: context.foreground,
                  ),
                ),
                const SizedBox(height: AppStyles.spaceXS),
                Text(
                  subtitle,
                  style: AppStyles.bodySmall.copyWith(
                    color: context.mutedForeground,
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
              activeColor: context.primary,
              activeTrackColor: context.primary.withOpacity(0.3),
              inactiveThumbColor: context.mutedForeground,
              inactiveTrackColor: context.muted.withOpacity(0.5),
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
            context.border.withOpacity(0.5),
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
                      ? context.destructive.withOpacity(0.1)
                      : context.muted.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(AppStyles.radiusSM),
                ),
                child: Text(
                  '$blockedCount/${_blockableApps.length} blocked',
                  style: TextStyle(
                    color: blockedCount > 0 
                        ? context.destructive 
                        : context.mutedForeground,
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
                        color: context.destructive,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: context.card,
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.block,
                        color: context.primaryForeground,
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
                            : context.foreground,
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
              activeColor: context.destructive,
              activeTrackColor: context.destructive.withOpacity(0.3),
              inactiveThumbColor: context.mutedForeground,
              inactiveTrackColor: context.muted.withOpacity(0.5),
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
              style: TextStyle(color: context.primaryForeground),
            ),
            backgroundColor: context.destructive,
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



  Widget _buildThemeCard() {
    final themeNotifier = ref.read(themeProvider.notifier);
    String themeName = themeNotifier.themeName;
    
    return Container(
      padding: const EdgeInsets.all(AppStyles.spaceLG),
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(AppStyles.radiusLG),
        border: Border.all(
          color: context.border.withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: context.shadowSM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppStyles.spaceSM),
                decoration: BoxDecoration(
                  color: context.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppStyles.radiusMD),
                  border: Border.all(
                    color: context.info.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.palette_rounded,
                  color: context.info,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppStyles.spaceMD),
              Text(
                'Appearance',
                style: AppStyles.subsectionHeader.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: context.foreground,
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
                        color: context.foreground,
                      ),
                    ),
                    const SizedBox(height: AppStyles.spaceXS),
                    Text(
                      themeName,
                      style: AppStyles.bodySmall.copyWith(
                        color: context.mutedForeground,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => _showThemeSelector(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.primary,
                  foregroundColor: context.primaryForeground,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppStyles.radiusMD),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppStyles.spaceMD, 
                    vertical: AppStyles.spaceSM
                  ),
                  elevation: 4,
                  shadowColor: context.primary.withOpacity(0.3),
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
      // Call the service method - this should open the Usage Access settings page directly
      await AppBlockingService.requestUsagePermission();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Find "Study Mode" in the list and enable it',
            style: TextStyle(color: AppStyles.white),
          ),
          backgroundColor: AppStyles.info,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppStyles.radiusMD)
          ),
        ),
      );
    } catch (e) {
      print('Error requesting usage permission: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Error opening Usage Access settings',
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
      // Request notification permission properly
      final status = await Permission.notification.request();
      
      _hasNotificationPermission = status.isGranted;
      setState(() {});
      
      if (status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Notification permission granted!',
              style: TextStyle(color: AppStyles.white),
            ),
            backgroundColor: AppStyles.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppStyles.radiusMD)
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Notification permission denied. Please enable in app settings.',
              style: TextStyle(color: AppStyles.white),
            ),
            backgroundColor: AppStyles.warning,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppStyles.radiusMD)
            ),
          ),
        );
      }
    } catch (e) {
      print('Error requesting notification permission: $e');
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

  Future<void> _requestPopupWindowPermission() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Opening Display Pop-up Windows settings...',
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
      // Request system alert window permission which covers popup windows
      final status = await Permission.systemAlertWindow.request();
      
      _hasPopupWindowPermission = status.isGranted;
      _hasOverlayPermission = status.isGranted; // Update overlay permission too
      setState(() {});
      
      if (status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Pop-up window permission granted!',
              style: TextStyle(color: AppStyles.white),
            ),
            backgroundColor: AppStyles.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppStyles.radiusMD)
            ),
          ),
        );
      } else {
        // Fallback to manual permission via system settings
        await AppBlockingService.requestOverlayPermission();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Please enable "Display over other apps" for Study Mode',
              style: TextStyle(color: AppStyles.white),
            ),
            backgroundColor: AppStyles.warning,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppStyles.radiusMD)
            ),
          ),
        );
      }
    } catch (e) {
      print('Error requesting popup window permission: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Error opening display settings',
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

  Future<void> _requestBackgroundWindowPermission() async {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Opening background window settings...',
              style: TextStyle(color: AppStyles.white),
            ),
            backgroundColor: AppStyles.info,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppStyles.radiusMD)
            ),
          ),
        );    try {
      // Show clear manual instructions first
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            '📋 MANUAL PATH: Android Settings → Apps → Study Mode → Other permissions → "Open new windows while running in the background" → Enable',
            style: TextStyle(color: AppStyles.white),
          ),
          backgroundColor: AppStyles.info,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppStyles.radiusMD)
          ),
        ),
      );
      
      // Wait a moment then try to open settings
      await Future.delayed(const Duration(milliseconds: 1500));
      
      print('📱 Opening system settings for background window permission');
      
      // Method 1: Go directly to app settings (most reliable)
      try {
        final AndroidIntent appSettingsIntent = AndroidIntent(
          action: 'android.settings.APPLICATION_DETAILS_SETTINGS',
          data: 'package:com.studymode.app.study_mode_v2',
        );
        await appSettingsIntent.launch();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              '📱 Scroll down → Find "Other permissions" → "Open new windows while running in the background" → Toggle ON',
              style: TextStyle(color: AppStyles.white),
            ),
            backgroundColor: AppStyles.info,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppStyles.radiusMD)
            ),
          ),
        );
        return;
      } catch (e1) {
        print('⚠️ App settings intent failed: $e1');
      }
      
      // Method 2: Fallback to all apps settings
      try {
        final AndroidIntent allAppsIntent = AndroidIntent(
          action: 'android.settings.MANAGE_ALL_APPLICATIONS_SETTINGS',
        );
        await allAppsIntent.launch();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              '📋 Find "Study Mode" → Tap it → Scroll to "Other permissions" → Enable background windows',
              style: TextStyle(color: AppStyles.white),
            ),
            backgroundColor: AppStyles.warning,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppStyles.radiusMD)
            ),
          ),
        );
        return;
      } catch (e2) {
        print('⚠️ All apps intent failed: $e2');
      }
      
      // Method 3: Try manage applications settings  
      try {
        final AndroidIntent manageAppsIntent = AndroidIntent(
          action: 'android.settings.MANAGE_APPLICATIONS_SETTINGS',
        );
        await manageAppsIntent.launch();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              '🔍 Find Study Mode → Permissions → Other permissions → "Open new windows while running in the background"',
              style: TextStyle(color: AppStyles.white),
            ),
            backgroundColor: AppStyles.warning,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppStyles.radiusMD)
            ),
          ),
        );
        return;
      } catch (e3) {
        print('⚠️ Manage apps intent failed: $e3');
      }
      
      // Method 4: Final fallback to standard app settings
      try {
        final AndroidIntent appSettingsIntent = AndroidIntent(
          action: 'android.settings.APPLICATION_DETAILS_SETTINGS',
          data: 'package:com.studymode.app.study_mode_v2',
        );
        await appSettingsIntent.launch();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              '📱 MANUAL STEPS: Scroll down → Other permissions → Open new windows while running in the background → Toggle ON',
              style: TextStyle(color: AppStyles.white),
            ),
            backgroundColor: AppStyles.warning,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppStyles.radiusMD)
            ),
          ),
        );
      } catch (e3) {
        print('⚠️ App settings intent failed: $e3');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              '❌ Unable to open settings. Please manually go to App Settings > Other permissions > Open new windows while running in the background > Allow',
              style: TextStyle(color: AppStyles.white),
            ),
            backgroundColor: AppStyles.destructive,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppStyles.radiusMD)
            ),
          ),
        );
      }
      
    } catch (e) {
      print('❌ Error requesting background window permission: $e');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error: ${e.toString()}',
            style: const TextStyle(color: AppStyles.white),
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

  Future<void> _requestLockScreenPermission() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Enabling lock screen notifications...',
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
      // Request critical alerts permission for lock screen display
      final status = await Permission.criticalAlerts.request();
      
      _hasLockScreenPermission = status.isGranted || _hasNotificationPermission;
      setState(() {});
      
      if (_hasLockScreenPermission) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Lock screen notifications enabled!',
              style: TextStyle(color: AppStyles.white),
            ),
            backgroundColor: AppStyles.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppStyles.radiusMD)
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Please enable notification permissions first',
              style: TextStyle(color: AppStyles.white),
            ),
            backgroundColor: AppStyles.warning,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppStyles.radiusMD)
            ),
          ),
        );
      }
    } catch (e) {
      print('Error requesting lock screen permission: $e');
    }
  }

  Future<void> _requestShortcutPermission() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Creating home screen shortcuts...',
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
      // Initialize shortcuts
      await ShortcutService.initialize();
      
      // Check if shortcut creation was successful
      final isSupported = await ShortcutService.areShortcutsSupported();
      
      _hasShortcutPermission = isSupported;
      setState(() {});
      
      if (isSupported) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              '🚀 Home screen shortcuts created successfully! Long-press the app icon to see them.',
              style: TextStyle(color: AppStyles.white),
            ),
            backgroundColor: AppStyles.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppStyles.radiusMD)
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Shortcut creation may not be supported on this device',
              style: TextStyle(color: AppStyles.white),
            ),
            backgroundColor: AppStyles.warning,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppStyles.radiusMD)
            ),
          ),
        );
      }
    } catch (e) {
      print('Error creating shortcuts: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to create shortcuts: ${e.toString()}',
            style: const TextStyle(color: AppStyles.white),
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
              color: context.foreground,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Select your preferred theme mode',
                  style: AppStyles.bodyMedium.copyWith(
                    color: context.mutedForeground,
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
                foregroundColor: context.mutedForeground,
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
                color: isSelected 
                    ? context.primary.withOpacity(0.1) 
                    : context.muted.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppStyles.radiusMD),
                border: Border.all(
                  color: isSelected 
                      ? context.primary.withOpacity(0.3) 
                      : context.border,
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                color: isSelected ? context.primary : context.mutedForeground,
                size: 20,
              ),
            ),
            const SizedBox(width: AppStyles.spaceMD),
            Expanded(
              child: Text(
                title,
                style: AppStyles.bodyMedium.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? context.foreground : context.mutedForeground,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_rounded,
                color: context.primary,
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