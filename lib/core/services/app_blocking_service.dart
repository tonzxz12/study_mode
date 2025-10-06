import 'dart:async';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:usage_stats/usage_stats.dart';
import 'package:system_alert_window/system_alert_window.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:android_intent_plus/android_intent.dart';

@pragma('vm:entry-point')
class AppBlockingService {
  static const MethodChannel _channel = MethodChannel('app_blocking_service');
  static Timer? _monitoringTimer;
  static List<String> _blockedPackages = [];
  static bool _isMonitoring = false;
  static bool _isInitialized = false;
  static final Map<String, DateTime> _lastBlockedTime = {};

  // Initialize the app blocking service
  static Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
    
    await _initializeBackgroundService();
    // Load saved blocked apps and restore monitoring if needed
    await loadBlockedApps();
  }

  static Future<void> _initializeBackgroundService() async {
    await FlutterBackgroundService().configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
      ),
    );
  }

  // Check if device has usage access permission
  static Future<bool> hasUsagePermission() async {
    try {
      // Try to query usage stats to check permission
      DateTime endTime = DateTime.now();
      DateTime startTime = DateTime.now().subtract(const Duration(days: 1));
      List<UsageInfo> usageInfos = await UsageStats.queryUsageStats(startTime, endTime);
      return usageInfos.isNotEmpty;
    } catch (e) {
      print('Error checking usage permission: $e');
      return false;
    }
  }

  // Request usage access permission
  static Future<void> requestUsagePermission() async {
    try {
      await UsageStats.grantUsagePermission();
    } catch (e) {
      print('Error requesting usage permission: $e');
    }
  }

  // Check if device has overlay permission
  static Future<bool> hasOverlayPermission() async {
    try {
      final result = await SystemAlertWindow.checkPermissions();
      return result ?? false;
    } catch (e) {
      print('Error checking overlay permission: $e');
      return false;
    }
  }

  // Request overlay permission
  static Future<bool> requestOverlayPermission() async {
    try {
      final result = await SystemAlertWindow.requestPermissions();
      return result ?? false;
    } catch (e) {
      print('Error requesting overlay permission: $e');
      return false;
    }
  }

  // Check if device admin is enabled
  static Future<bool> isDeviceAdmin() async {
    try {
      final result = await _channel.invokeMethod('isDeviceAdmin');
      return result ?? false;
    } catch (e) {
      print('Error checking device admin: $e');
      return false;
    }
  }

  // Request device admin permission
  static Future<bool> requestDeviceAdmin() async {
    try {
      await _channel.invokeMethod('requestDeviceAdmin');
      
      // Wait a bit for user to complete the process and then check status
      await Future.delayed(const Duration(seconds: 2));
      return await isDeviceAdmin();
    } catch (e) {
      print('Error requesting device admin: $e');
      return false;
    }
  }

  // Add app to blocked list
  static void addBlockedApp(String packageName) {
    if (!_blockedPackages.contains(packageName)) {
      _blockedPackages.add(packageName);
      _saveBlockedApps(); // Save to storage
    }
  }

  // Remove app from blocked list
  static void removeBlockedApp(String packageName) {
    _blockedPackages.remove(packageName);
    _saveBlockedApps(); // Save to storage
  }

  // Get blocked apps list
  static List<String> getBlockedApps() {
    return List.from(_blockedPackages);
  }

  // Ensure background service continues running
  static Future<void> ensurePersistentMonitoring() async {
    if (_isMonitoring && _blockedPackages.isNotEmpty) {
      try {
        final service = FlutterBackgroundService();
        if (!await service.isRunning()) {
          await service.startService();
          print('Restarted background app blocking service');
        }
      } catch (e) {
        print('Error ensuring persistent monitoring: $e');
      }
    }
  }

  // Check if monitoring is active
  static bool get isMonitoringActive => _isMonitoring && _blockedPackages.isNotEmpty;

  // Storage keys
  static const String _keyBlockedApps = 'blocked_apps';
  static const String _keyAppBlockingEnabled = 'app_blocking_enabled';
  static const String _keyMonitoringActive = 'monitoring_active';

  // Save blocked apps to local storage
  static Future<void> _saveBlockedApps() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_keyBlockedApps, _blockedPackages);
      await prefs.setBool(_keyMonitoringActive, _isMonitoring);
      print('Saved ${_blockedPackages.length} blocked apps to storage');
    } catch (e) {
      print('Error saving blocked apps: $e');
    }
  }

  // Load blocked apps from local storage
  static Future<void> loadBlockedApps() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _blockedPackages = prefs.getStringList(_keyBlockedApps) ?? [];
      _isMonitoring = prefs.getBool(_keyMonitoringActive) ?? false;
      
      print('Loaded ${_blockedPackages.length} blocked apps from storage');
      if (_blockedPackages.isNotEmpty) {
        print('Blocked apps: ${_blockedPackages.join(", ")}');
      }
      
      // Restore monitoring if it was active (with proper safeguards)
      if (_isMonitoring && _blockedPackages.isNotEmpty) {
        print('Restoring app monitoring on startup...');
        // Use a delayed start to avoid initialization conflicts
        Timer(const Duration(seconds: 2), () async {
          try {
            await _startMonitoringInternal(_blockedPackages);
            print('App monitoring restored successfully');
          } catch (e) {
            print('Error restoring app monitoring: $e');
          }
        });
      } else {
        print('Note: No active app blocking to restore');
      }
    } catch (e) {
      print('Error loading blocked apps: $e');
    }
  }

  // Save app blocking enabled state
  static Future<void> saveAppBlockingEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyAppBlockingEnabled, enabled);
      print('Saved app blocking enabled state: $enabled');
    } catch (e) {
      print('Error saving app blocking enabled state: $e');
    }
  }

  // Load app blocking enabled state
  static Future<bool> loadAppBlockingEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyAppBlockingEnabled) ?? false;
    } catch (e) {
      print('Error loading app blocking enabled state: $e');
      return false;
    }
  }

  // Clear all saved data
  static Future<void> clearSavedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyBlockedApps);
      await prefs.remove(_keyAppBlockingEnabled);
      await prefs.remove(_keyMonitoringActive);
      print('Cleared all app blocking data from storage');
    } catch (e) {
      print('Error clearing saved data: $e');
    }
  }

  // Start monitoring blocked apps (public interface)
  static Future<void> startMonitoring(List<String> blockedApps) async {
    try {
      _blockedPackages = blockedApps;
      _isMonitoring = true;
      
      // Initialize background service if not already done (but don't reload apps)
      if (!_isInitialized) {
        await _initializeBackgroundService();
        _isInitialized = true;
      }
      
      await _startMonitoringInternal(blockedApps);
    } catch (e) {
      print('Error starting monitoring: $e');
    }
  }

  // Internal monitoring startup (avoids initialization loops)
  static Future<void> _startMonitoringInternal(List<String> blockedApps) async {
    try {
      final service = FlutterBackgroundService();
      
      // Ensure service is running
      if (!await service.isRunning()) {
        await service.startService();
        print('Started persistent background app blocking service');
      } else {
        print('Background app blocking service already running');
      }
      
      // Start aggressive foreground monitoring
      _monitoringTimer?.cancel();
      _monitoringTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
        _checkBlockedApps();
      });
      
      // Save current state to storage
      await _saveBlockedApps();
      
      print('Enhanced app monitoring started for ${blockedApps.length} apps');
      print('Background monitoring: ACTIVE');
      print('Foreground monitoring: ACTIVE');
      print('Redirect target: Study Mode App');
      print('Settings saved to local storage');
    } catch (e) {
      print('Error in internal monitoring startup: $e');
    }
  }

  // Stop monitoring
  static Future<void> stopMonitoring() async {
    try {
      final service = FlutterBackgroundService();
      if (await service.isRunning()) {
        service.invoke('stopService');
      }
      _isMonitoring = false;
      _monitoringTimer?.cancel();
      
      // Save stopped state to storage
      await _saveBlockedApps();
      
      print('App monitoring stopped');
      print('Settings saved to local storage');
    } catch (e) {
      print('Error stopping monitoring: $e');
    }
  }

  // Check if any blocked apps are currently running (foreground monitoring)
  static Future<void> _checkBlockedApps() async {
    if (!_isMonitoring || _blockedPackages.isEmpty) return;
    
    try {
      DateTime now = DateTime.now();
      DateTime startTime = now.subtract(const Duration(seconds: 3));
      
      List<UsageInfo> usageInfos = await UsageStats.queryUsageStats(startTime, now);
      
      for (UsageInfo usage in usageInfos) {
        if (_blockedPackages.contains(usage.packageName) && 
            usage.lastTimeUsed != null) {
          
          // Convert lastTimeUsed from string milliseconds to DateTime
          int lastUsedMillis = int.tryParse(usage.lastTimeUsed!) ?? 0;
          DateTime lastUsedTime = DateTime.fromMillisecondsSinceEpoch(lastUsedMillis);
          
          // Immediate blocking for recent app usage (with cooldown)
          if (now.difference(lastUsedTime).inSeconds < 2) {
            // Check cooldown to prevent rapid retriggering
            DateTime? lastBlocked = _lastBlockedTime[usage.packageName!];
            if (lastBlocked == null || now.difference(lastBlocked).inSeconds > 5) {
              print('Foreground detected blocked app: ${usage.packageName}');
              _lastBlockedTime[usage.packageName!] = now;
              await _blockApp(usage.packageName!);
            }
          }
        }
      }
    } catch (e) {
      print('Error checking blocked apps: $e');
    }
  }

  // Block a specific app
  static Future<void> _blockApp(String packageName) async {
    try {
      // Show blocking overlay first
      await _showBlockingOverlay(packageName);
      
      // Wait a moment for overlay to be visible
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Try to close the app using device admin (if available)
      if (await isDeviceAdmin()) {
        await _channel.invokeMethod('closeApp', {'packageName': packageName});
      }
      
      // Wait a moment for app to close
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Redirect to Study Mode app instead of home screen
      await _openStudyModeApp();
      
      print('Blocked app: $packageName - Redirected to Study Mode');
    } catch (e) {
      print('Error blocking app $packageName: $e');
    }
  }

  // Show blocking overlay
  static Future<void> _showBlockingOverlay(String packageName) async {
    try {
      // Get app name for better user experience
      String appName = _getAppNameFromPackage(packageName);
      
      await SystemAlertWindow.showSystemWindow(
        height: 200,
        width: 300,
        gravity: SystemWindowGravity.CENTER,
        notificationTitle: "🔒 Study Mode Active",
        notificationBody: "$appName is blocked!\nRedirecting to Study Mode...",
        prefMode: SystemWindowPrefMode.OVERLAY,
      );
      
      // Auto-dismiss the overlay after 3 seconds (gives time for app closure)
      Timer(const Duration(seconds: 3), () {
        SystemAlertWindow.closeSystemWindow();
      });
      
      print('Blocking overlay shown for $appName ($packageName)');
    } catch (e) {
      print('Error showing blocking overlay: $e');
    }
  }

  // Helper method to get friendly app names
  static String _getAppNameFromPackage(String packageName) {
    const appNames = {
      'com.facebook.katana': 'Facebook',
      'com.instagram.android': 'Instagram',
      'com.zhiliaoapp.musically': 'TikTok',
      'com.twitter.android': 'Twitter/X',
      'com.google.android.youtube': 'YouTube',
      'com.whatsapp': 'WhatsApp',
      'com.snapchat.android': 'Snapchat',
      'com.discord': 'Discord',
      'com.netflix.mediaclient': 'Netflix',
      'com.spotify.music': 'Spotify',
    };
    
    return appNames[packageName] ?? 'This app';
  }

  // Open Study Mode app
  static Future<void> _openStudyModeApp() async {
    try {
      // Use method channel to bring Study Mode app to foreground
      await _channel.invokeMethod('openStudyModeApp');
      print('Redirected to Study Mode app');
    } catch (e) {
      print('Error opening Study Mode app via method channel: $e');
      // Fallback: Use AndroidIntent
      try {
        const studyModeIntent = AndroidIntent(
          action: 'android.intent.action.MAIN',
          package: 'com.studymode.app.study_mode_v2',
          componentName: 'com.studymode.app.study_mode_v2/.MainActivity',
          flags: <int>[
            0x10000000, // FLAG_ACTIVITY_NEW_TASK
            0x00200000, // FLAG_ACTIVITY_CLEAR_TOP
            0x20000000, // FLAG_ACTIVITY_SINGLE_TOP
          ],
        );
        await studyModeIntent.launch();
        print('Redirected to Study Mode app via fallback');
      } catch (fallbackError) {
        print('Error with fallback intent: $fallbackError');
        // Final fallback: Open home screen
        try {
          const homeIntent = AndroidIntent(
            action: 'android.intent.action.MAIN',
            category: 'android.intent.category.HOME',
          );
          await homeIntent.launch();
        } catch (homeError) {
          print('Error opening home screen: $homeError');
        }
      }
    }
  }

  // Background service entry point
  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) {
    print('Background app blocking service started - Running persistently');
    
    // Listen for stop commands
    service.on('stop').listen((event) {
      print('Stopping background app blocking service');
      service.stopSelf();
    });
    
    // Enhanced periodic monitoring with faster checks
    Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!_isMonitoring || _blockedPackages.isEmpty) {
        // Keep service running but skip monitoring if not enabled
        return;
      }
      
      try {
        DateTime now = DateTime.now();
        DateTime startTime = now.subtract(const Duration(seconds: 3));
        
        List<UsageInfo> usageInfos = await UsageStats.queryUsageStats(startTime, now);
        
        for (UsageInfo usage in usageInfos) {
          if (_blockedPackages.contains(usage.packageName) && 
              usage.lastTimeUsed != null) {
            
            // Convert lastTimeUsed from string milliseconds to DateTime
            int lastUsedMillis = int.tryParse(usage.lastTimeUsed!) ?? 0;
            DateTime lastUsedTime = DateTime.fromMillisecondsSinceEpoch(lastUsedMillis);
            
            // More aggressive blocking - check within last 2 seconds
            if (now.difference(lastUsedTime).inSeconds < 2) {
              print('Detected blocked app: ${usage.packageName} - Blocking immediately');
              await _blockApp(usage.packageName!);
              
              // Add small delay to prevent rapid-fire blocking
              await Future.delayed(const Duration(milliseconds: 500));
            }
          }
        }
      } catch (e) {
        print('Background monitoring error: $e');
        // Continue monitoring even if there's an error
      }
    });
    
    // Send periodic status updates
    Timer.periodic(const Duration(minutes: 1), (timer) {
      if (_isMonitoring && _blockedPackages.isNotEmpty) {
        print('App blocking service active - Monitoring ${_blockedPackages.length} apps');
        service.invoke('update_notification', {
          'title': 'Study Mode Active',
          'body': 'Blocking ${_blockedPackages.length} apps in background'
        });
      }
    });
  }
}