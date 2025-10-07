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
        autoStart: true, // AUTO-START for persistent monitoring
        isForegroundMode: true,
        autoStartOnBoot: true, // Start on device boot
        notificationChannelId: 'study_mode_blocking',
        initialNotificationTitle: 'Study Mode Active',
        initialNotificationContent: 'App blocking is running in background',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true, // AUTO-START for iOS too
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
      
      // SAFE auto-start: Always start monitoring when blocked apps exist
      if (_blockedPackages.isNotEmpty) {
        print('🔒 STARTING safe app monitoring for ${_blockedPackages.length} apps');
        print('📱 Apps to block: ${_blockedPackages.join(", ")}');
        
        // Force enable monitoring and start it
        _isMonitoring = true;
        
        // Use a delayed start to avoid initialization conflicts
        Timer(const Duration(seconds: 2), () async {
          try {
            await startMonitoring(_blockedPackages);
            print('✅ Safe app monitoring started successfully');
          } catch (e) {
            print('❌ Error starting app monitoring: $e');
          }
        });
      } else {
        print('📴 No blocked apps configured - monitoring inactive');
        _isMonitoring = false;
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

  // SAFE Start monitoring blocked apps (public interface)
  static Future<void> startMonitoring(List<String> blockedApps) async {
    try {
      print('🔒 Starting SAFE app blocking for ${blockedApps.length} apps');
      _blockedPackages = blockedApps;
      _isMonitoring = true;
      
      // Use SAFE monitoring (no aggressive background services)
      _startSafeMonitoring(blockedApps);
      
      // Ensure background service is running for persistence
      await _ensureBackgroundServiceRunning();
      
      // Save state
      await _saveBlockedApps();
      
      print('✅ Safe app blocking started - monitoring every 5 seconds');
      print('📱 Background service enabled for persistence');
    } catch (e) {
      print('❌ Error starting safe monitoring: $e');
    }
  }

  // SAFE monitoring implementation 
  static void _startSafeMonitoring(List<String> blockedApps) {
    try {
      // Start AGGRESSIVE foreground monitoring for continuous blocking
      _monitoringTimer?.cancel();
      _monitoringTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
        _checkBlockedAppsSafely();
      });
      
      print('🔒 CONTINUOUS monitoring timer started');
      print('  ⏱️  Interval: 2 seconds (aggressive)');
      print('  � CONTINUOUS blocking - no cooldown');
      print('  📱 Always-active implementation');
    } catch (e) {
      print('❌ Error in safe monitoring startup: $e');
    }
  }
  
  // Ensure background service stays running
  static Future<void> _ensureBackgroundServiceRunning() async {
    try {
      final service = FlutterBackgroundService();
      if (!await service.isRunning()) {
        await service.startService();
        print('🔄 Started background monitoring service');
      } else {
        print('✅ Background monitoring service already running');
      }
    } catch (e) {
      print('❌ Error ensuring background service: $e');
    }
  }

  // SAFE app detection and blocking
  static Future<void> _checkBlockedAppsSafely() async {
    if (!_isMonitoring || _blockedPackages.isEmpty) return;
    
    try {
      DateTime now = DateTime.now();
      
      // Check only recent usage (last 3 seconds)
      DateTime startTime = now.subtract(const Duration(seconds: 3));
      List<UsageInfo> usageInfos = await UsageStats.queryUsageStats(startTime, now);
      
      for (UsageInfo usage in usageInfos) {
        if (_blockedPackages.contains(usage.packageName) && 
            usage.lastTimeUsed != null) {
          
          int lastUsedMillis = int.tryParse(usage.lastTimeUsed!) ?? 0;
          DateTime lastUsedTime = DateTime.fromMillisecondsSinceEpoch(lastUsedMillis);
          
          // IMMEDIATE BLOCKING - Always block when detected (minimal cooldown)
          if (now.difference(lastUsedTime).inSeconds < 2) {
            DateTime? lastBlocked = _lastBlockedTime[usage.packageName!];
            if (lastBlocked == null || now.difference(lastBlocked).inSeconds >= 1) {
              String appName = _getAppNameFromPackage(usage.packageName!);
              print('🚫🚫🚫 FOREGROUND BLOCKING: $appName - IMMEDIATE ACTION!');
              _lastBlockedTime[usage.packageName!] = now;
              
              // Perform aggressive blocking - ALWAYS
              await _performSafeBlocking(usage.packageName!);
              print('⚡ $appName blocked by foreground monitor');
            }
          }
        }
      }
    } catch (e) {
      print('❌ Error in safe monitoring: $e');
    }
  }

  // ENHANCED blocking - close app and open Study Mode
  static Future<void> _performSafeBlocking(String packageName) async {
    try {
      String appName = _getAppNameFromPackage(packageName);
      print('🚫 BLOCKING $appName - Closing and opening Study Mode');
      
      // Step 1: Close the blocked app using native method first
      try {
        await _channel.invokeMethod('closeApp', {'packageName': packageName});
        print('🔧 Native close attempted for $appName');
      } catch (e) {
        print('⚠️ Native close failed: $e');
      }
      
      // Step 2: Show blocking alert notification
      try {
        await _channel.invokeMethod('showBlockingToast', {
          'message': '$appName is BLOCKED! Study Mode is active. Go focus! 🎯'
        });
        print('📢 Alert shown for blocked $appName');
      } catch (alertError) {
        print('⚠️ Alert failed: $alertError');
      }
      
      // Step 3: Wait a moment for app to close and alert to show
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Step 4: ENSURE Study Mode opens - try multiple methods for guaranteed success
      bool studyModeOpened = false;
      print('🔄 Starting Study Mode opening attempts...');
      
      // Method 1: Try native openStudyModeApp first
      try {
        print('🔄 Attempt 1: Native openStudyModeApp');
        await _channel.invokeMethod('openStudyModeApp');
        print('✅ SUCCESS: Study Mode opened via native method');
        studyModeOpened = true;
      } catch (e) {
        print('❌ Native method failed: $e');
      }
      
      // Method 2: If native failed, try Android Intent
      if (!studyModeOpened) {
        try {
          print('🔄 Attempt 2: Android Intent launch');
          const studyModeIntent = AndroidIntent(
            action: 'android.intent.action.MAIN',
            package: 'com.studymode.app.study_mode_v2',
            flags: <int>[
              0x10000000, // FLAG_ACTIVITY_NEW_TASK
              0x00200000, // FLAG_ACTIVITY_CLEAR_TOP
            ],
          );
          await studyModeIntent.launch();
          print('✅ SUCCESS: Study Mode opened via Android Intent');
          studyModeOpened = true;
        } catch (intentError) {
          print('❌ Android Intent failed: $intentError');
        }
      }
      
      // Method 3: Last resort - simple package launch
      if (!studyModeOpened) {
        try {
          print('🔄 Attempt 3: Simple package launch');
          const simpleIntent = AndroidIntent(
            action: 'android.intent.action.MAIN',
            package: 'com.studymode.app.study_mode_v2',
            flags: <int>[0x10000000],
          );
          await simpleIntent.launch();
          print('✅ SUCCESS: Study Mode opened via simple launch');
          studyModeOpened = true;
        } catch (simpleError) {
          print('❌ Simple launch failed: $simpleError');
        }
      }
      
      // Final status report
      if (studyModeOpened) {
        print('🎯 MISSION ACCOMPLISHED: Study Mode is now open!');
      } else {
        print('💥 CRITICAL: ALL Study Mode opening methods failed!');
      }
      
      print('✅ $appName blocked - Study Mode should be active');
    } catch (e) {
      print('❌ Enhanced blocking error: $e');
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
            
            // IMMEDIATE BLOCKING - Always block when detected (minimal cooldown)
            if (now.difference(lastUsedTime).inSeconds < 2) {
              DateTime? lastBlocked = _lastBlockedTime[usage.packageName!];
              if (lastBlocked == null || now.difference(lastBlocked).inSeconds >= 1) {
                String appName = _getAppNameFromPackage(usage.packageName!);
                print('�🚫🚫 IMMEDIATE BLOCKING: $appName - NO ESCAPE!');
                _lastBlockedTime[usage.packageName!] = now;
                
                // Use aggressive blocking from background service - ALWAYS
                await _performSafeBlocking(usage.packageName!);
                print('⚡ $appName blocking completed by background service');
                
                // Minimal delay to prevent rapid-fire
                await Future.delayed(const Duration(milliseconds: 500));
              } else {
                print('🔄 ${usage.packageName} still in cooldown - ${now.difference(lastBlocked).inSeconds}s ago');
              }
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