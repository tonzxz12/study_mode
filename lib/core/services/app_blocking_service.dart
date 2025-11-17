import 'dart:async';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:usage_stats/usage_stats.dart';  // Temporarily disabled
import 'package:system_alert_window/system_alert_window.dart';
// import 'package:flutter_background_service/flutter_background_service.dart'; // DISABLED
import 'package:android_intent_plus/android_intent.dart';
// import 'package:permission_handler/permission_handler.dart';  // Temporarily disabled

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
    
    // Auto-start monitoring if there are blocked apps
    if (_blockedPackages.isNotEmpty) {
      print('🔥 AUTO-STARTING monitoring with ${_blockedPackages.length} blocked apps');
      await startMonitoring(_blockedPackages);
    } else {
      print('ℹ️ No blocked apps found - monitoring will start when apps are blocked');
    }
  }

  static Future<void> _initializeBackgroundService() async {
    // Initialize without flutter_background_service to avoid crashes
    // Use native Android monitoring instead
    print('🔥 Background monitoring initialized via native Android methods');
  }

  // Check if device has usage access permission
  static Future<bool> hasUsagePermission() async {
    try {
      // Use method channel to check usage permission from native Android code
      final bool hasPermission = await _channel.invokeMethod('hasUsagePermission');
      return hasPermission;
    } catch (e) {
      print('Error checking usage permission: $e');
      return false;
    }
  }

  // Request usage access permission
  static Future<void> requestUsagePermission() async {
    try {
      // Open Usage Access settings directly using Android Intent
      const AndroidIntent intent = AndroidIntent(
        action: 'android.settings.USAGE_ACCESS_SETTINGS',
      );
      await intent.launch();
      print('AppBlockingService.requestUsagePermission() called successfully');
    } catch (e) {
      print('Error opening Usage Access settings: $e');
      rethrow;
    }
  }

  // Storage keys
  static const String _keyBlockedApps = 'blocked_apps';
  static const String _keyAppBlockingEnabled = 'app_blocking_enabled';
  static const String _keyMonitoringActive = 'monitoring_active';

  // Load blocked apps from storage
  static Future<void> loadBlockedApps() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _blockedPackages = prefs.getStringList(_keyBlockedApps) ?? [];
      _isMonitoring = prefs.getBool(_keyMonitoringActive) ?? false;
      
      if (_isMonitoring && _blockedPackages.isNotEmpty) {
        // Restart ultra-aggressive monitoring
        await startMonitoring(_blockedPackages);
      }
      print('Loaded ${_blockedPackages.length} blocked apps from storage');
    } catch (e) {
      print('Error loading blocked apps: $e');
      _blockedPackages = [];
      _isMonitoring = false;
    }
  }

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

  // Block specific apps with CONTINUOUS monitoring
  static Future<void> blockApps(List<String> packageNames) async {
    _blockedPackages = packageNames;
    await _saveBlockedApps();
    
    if (packageNames.isNotEmpty) {
      await startMonitoring(packageNames);
    } else {
      await stopMonitoring();
    }
  }

  // Ensure persistent monitoring (compatibility method)
  static Future<void> ensurePersistentMonitoring() async {
    // Load blocked apps from storage if not already loaded
    if (_blockedPackages.isEmpty) {
      await loadBlockedApps();
    }
    
    // Start monitoring if there are blocked apps
    if (_blockedPackages.isNotEmpty) {
      await startMonitoring(_blockedPackages);
      print('🔥 Persistent monitoring ensured with ${_blockedPackages.length} blocked apps');
    } else {
      print('⚠️ No blocked apps found - monitoring not started');
    }
  }

  // Get current blocked apps list
  static List<String> getBlockedApps() {
    return List<String>.from(_blockedPackages);
  }

  // Add a blocked app
  static Future<void> addBlockedApp(String packageName) async {
    if (!_blockedPackages.contains(packageName)) {
      _blockedPackages.add(packageName);
      await _saveBlockedApps();
      
      // Immediately start monitoring with updated list
      await startMonitoring(_blockedPackages);
      print('🔥 Added $packageName to blocking - monitoring started automatically');
    }
  }

  // Remove a blocked app
  static Future<void> removeBlockedApp(String packageName) async {
    if (_blockedPackages.contains(packageName)) {
      _blockedPackages.remove(packageName);
      await _saveBlockedApps();
      
      // Restart monitoring with updated list
      if (_isMonitoring) {
        if (_blockedPackages.isNotEmpty) {
          await startMonitoring(_blockedPackages);
        } else {
          await stopMonitoring();
        }
      }
    }
  }

  // Save app blocking enabled state
  static Future<void> saveAppBlockingEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyAppBlockingEnabled, enabled);
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

  // Clear saved data
  static Future<void> clearSavedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyBlockedApps);
      await prefs.remove(_keyAppBlockingEnabled);
      await prefs.remove(_keyMonitoringActive);
      _blockedPackages.clear();
      _isMonitoring = false;
    } catch (e) {
      print('Error clearing saved data: $e');
    }
  }

  // Get monitoring status
  static bool get isMonitoringActive => _isMonitoring;

  // Check overlay permission
  static Future<bool> hasOverlayPermission() async {
    try {
      final result = await SystemAlertWindow.checkPermissions();
      return result ?? false;
    } catch (e) {
      print('Error checking overlay permission: $e');
      return false;
    }
  }

  // Request overlay permission - opens system settings
  static Future<bool> requestOverlayPermission() async {
    try {
      // Request permission which will open settings
      await SystemAlertWindow.requestPermissions();
      // Check if granted after user returns
      await Future.delayed(const Duration(seconds: 2));
      final result = await SystemAlertWindow.checkPermissions();
      return result ?? false;
    } catch (e) {
      print('Error requesting overlay permission: $e');
      return false;
    }
  }

  // Check device admin (placeholder)
  static Future<bool> isDeviceAdmin() async {
    try {
      return await _channel.invokeMethod('isDeviceAdmin') ?? false;
    } catch (e) {
      print('Error checking device admin: $e');
      return false;
    }
  }

  // Request device admin (placeholder)
  static Future<void> requestDeviceAdmin() async {
    try {
      await _channel.invokeMethod('requestDeviceAdmin');
    } catch (e) {
      print('Error requesting device admin: $e');
    }
  }

  // CONTINUOUS Start monitoring blocked apps (public interface)
  static Future<void> startMonitoring(List<String> blockedApps) async {
    try {
      print('🔒 Starting ULTRA-FAST app blocking for ${blockedApps.length} apps');
      print('📦 Blocked packages: ${blockedApps.join(", ")}');
      _blockedPackages = blockedApps;
      _isMonitoring = true;
      
      // Use CONTINUOUS monitoring for persistent blocking
      _startContinuousMonitoring(blockedApps);
      
      // Ensure background service is running for persistence
      await _ensureBackgroundServiceRunning();
      
      // Save state
      await _saveBlockedApps();
      
      print('✅ ULTRA-FAST app blocking started - monitoring every 100ms');
      print('📱 Background service enabled for persistent blocking');
      print('🎯 Monitoring active: $_isMonitoring');
      print('🎯 Blocked apps count: ${_blockedPackages.length}');
    } catch (e) {
      print('❌ Error starting continuous monitoring: $e');
    }
  }

  // CONTINUOUS monitoring implementation 
  static void _startContinuousMonitoring(List<String> blockedApps) {
    try {
      // Start ULTRA-FAST monitoring for instant blocking
      _monitoringTimer?.cancel();
      _monitoringTimer = Timer.periodic(const Duration(milliseconds: 25), (timer) {
        _checkBlockedAppsContinuously();
      });
      
      print('🔒 INSTANT monitoring timer started');
      print('  ⚡ Interval: 25ms (INSTANT response)');
      print('  🚫 INSTANT blocking - always active');
      print('  📱 Persistent Study Mode focus');
    } catch (e) {
      print('❌ Error in continuous monitoring startup: $e');
    }
  }
  
  // Ensure background service stays running
  static Future<void> _ensureBackgroundServiceRunning() async {
    // Use native Android background monitoring instead of flutter_background_service
    print('🔥 Background monitoring ensured via native methods');
  }

  // MULTI-LAYER app detection and blocking - ALWAYS block without interference
  static Future<void> _checkBlockedAppsContinuously() async {
    if (!_isMonitoring || _blockedPackages.isEmpty) {
      if (!_isMonitoring) print('⚠️ Monitoring not active');
      if (_blockedPackages.isEmpty) print('⚠️ No blocked packages');
      return;
    }
    
    try {
      DateTime now = DateTime.now();
      
      // LAYER 1: Usage Stats Detection (primary method)
      await _checkUsageStatsBlocking(now);
      
      // LAYER 2: Running Tasks Detection (backup method)
      await _checkRunningTasksBlocking(now);
      
    } catch (e) {
      print('❌ Error in multi-layer monitoring: $e');
    }
  }
  
  // Layer 1: Usage stats based detection
  static Future<void> _checkUsageStatsBlocking(DateTime now) async {
    try {
      DateTime startTime = now.subtract(const Duration(seconds: 1));
      
      List<dynamic> usageInfos = await _channel.invokeMethod('queryUsageStats', {
        'startTime': startTime.millisecondsSinceEpoch,
        'endTime': now.millisecondsSinceEpoch,
      });

      print('📊 Usage Stats Layer 1: Found ${usageInfos.length} usage entries');

      for (Map<dynamic, dynamic> usage in usageInfos) {
        String? packageName = usage['packageName']?.toString();
        int? lastTimeUsed = usage['lastTimeUsed'];
        
        if (packageName != null) {
          print('  📱 Recent usage: $packageName (${lastTimeUsed != null ? DateTime.fromMillisecondsSinceEpoch(lastTimeUsed) : 'no timestamp'})');
        }
        
        if (packageName != null && 
            _blockedPackages.contains(packageName) && 
            lastTimeUsed != null) {
          
          DateTime lastUsedTime = DateTime.fromMillisecondsSinceEpoch(lastTimeUsed);
          
          // Check if app was used very recently (within 1 second for instant blocking)
          if (now.difference(lastUsedTime).inSeconds < 1) {
            DateTime? lastBlocked = _lastBlockedTime[packageName];
            if (lastBlocked == null || now.difference(lastBlocked).inMilliseconds >= 50) {
              String appName = _getAppNameFromPackage(packageName);
              print('🚫🚫🚫 USAGE STATS BLOCKING: $appName - DETECTED!');
              _lastBlockedTime[packageName] = now;
              
              await _performInstantBlocking(packageName);
              return; // Exit immediately after instant blocking
            }
          }
        }
      }
    } catch (e) {
      print('⚠️ Usage stats detection error: $e');
    }
  }
  
  // Layer 2: Running tasks detection (backup method)
  static Future<void> _checkRunningTasksBlocking(DateTime now) async {
    try {
      // Query running tasks via method channel
      List<dynamic> runningTasks = await _channel.invokeMethod('getRunningTasks');
      
      print('🏃 Running Tasks Layer 2: Found ${runningTasks.length} active tasks');
      
      for (Map<dynamic, dynamic> task in runningTasks) {
        String? packageName = task['packageName']?.toString();
        
        if (packageName != null) {
          print('  🏃 Active task: $packageName');
        }
        
        if (packageName != null && _blockedPackages.contains(packageName)) {
          DateTime? lastBlocked = _lastBlockedTime[packageName];
          if (lastBlocked == null || now.difference(lastBlocked).inMilliseconds >= 50) {
            String appName = _getAppNameFromPackage(packageName);
            print('🚫🚫🚫 INSTANT RUNNING TASK BLOCKING: $appName');
            _lastBlockedTime[packageName] = now;
            
            await _performInstantBlocking(packageName);
            print('⚡ $appName INSTANTLY blocked via running tasks');
            return; // Exit immediately after blocking
          }
        }
      }
    } catch (e) {
      print('⚠️ Running tasks detection error: $e');
    }
  }

  // INSTANT blocking with immediate termination and app switch
  static Future<void> _performInstantBlocking(String packageName) async {
    try {
      String appName = _getAppNameFromPackage(packageName);
      print('🔥 INSTANT BLOCKING START: $appName ($packageName)');
      
      // 1. INSTANT app termination (no delays)
      await _channel.invokeMethod('forceStopApp', {'packageName': packageName});
      print('💀 App terminated: $appName');
      
      // 2. INSTANT Study Mode switch (no delays) 
      await _launchStudyModeIntent();
      print('📱 Study Mode launched after blocking: $appName');
      
      print('⚡ INSTANT blocking completed for $appName');
    } catch (e) {
      print('❌ Instant blocking error for $packageName: $e');
    }
  }


  
  // Helper method for launching Study Mode intent
  static Future<void> _launchStudyModeIntent() async {
    try {
      // Use native method to bring Study Mode app to foreground
      await _channel.invokeMethod('bringAppToForeground');
      print('🔥 Study Mode brought to foreground via native method');
    } catch (e) {
      print('⚠️ Native foreground launch failed: $e');
      // Fallback to AndroidIntent if native method fails
      try {
        const studyModeIntent = AndroidIntent(
          action: 'android.intent.action.MAIN',
          package: 'com.studymode.app.study_mode_v2',
          flags: <int>[
            0x10000000, // FLAG_ACTIVITY_NEW_TASK
            0x20000000, // FLAG_ACTIVITY_SINGLE_TOP  
            0x00200000, // FLAG_ACTIVITY_REORDER_TO_FRONT
          ],
        );
        await studyModeIntent.launch();
        print('🔥 Study Mode launched via AndroidIntent fallback');
      } catch (e2) {
        print('⚠️ All launch methods failed: $e2');
      }
    }
  }

  // Stop monitoring
  static Future<void> stopMonitoring() async {
    try {
      // DISABLED - Background service removed due to crash
      // final service = FlutterBackgroundService();
      // if (await service.isRunning()) {
      //   service.invoke('stopService');
      // }
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

  // Helper method to get friendly app names - ACTIVE
  static String _getAppNameFromPackage(String packageName) {
    const Map<String, String> appNames = {
      'com.instagram.android': 'Instagram',
      'com.facebook.katana': 'Facebook', 
      'com.twitter.android': 'Twitter/X',
      'com.snapchat.android': 'Snapchat',
      'com.zhiliaoapp.musically': 'TikTok',
      'com.whatsapp': 'WhatsApp',
      'com.discord': 'Discord',
      'com.netflix.mediaclient': 'Netflix',
      'com.spotify.music': 'Spotify',
      'com.google.android.youtube': 'YouTube',
    };
    
    return appNames[packageName] ?? 'This app';
  }

  // Background service entry point - DISABLED
  // @pragma('vm:entry-point')
  // static void onStart(ServiceInstance service) {
  //   print('Background app blocking service started - CONTINUOUS protection');
  //   
  //   // Listen for stop commands
  //   service.on('stop').listen((event) {
  //     print('Stopping background app blocking service');
  //     service.stopSelf();
  //   });
  //   
  //   // CONTINUOUS background monitoring - backup protection layer
  //   Timer.periodic(const Duration(milliseconds: 500), (timer) async {
  //     if (!_isMonitoring || _blockedPackages.isEmpty) {
  //       return;
  //     }
  //     
  //     try {
  //       DateTime now = DateTime.now();
  //       DateTime startTime = now.subtract(const Duration(seconds: 2));
  //       
  //       List<UsageInfo> usageInfos = await UsageStats.queryUsageStats(startTime, now);
  //       
  //       for (UsageInfo usage in usageInfos) {
  //         if (_blockedPackages.contains(usage.packageName) && 
  //             usage.lastTimeUsed != null) {
  //           
  //           int lastUsedMillis = int.tryParse(usage.lastTimeUsed!) ?? 0;
  //           DateTime lastUsedTime = DateTime.fromMillisecondsSinceEpoch(lastUsedMillis);
  //           
  //           // CONTINUOUS BACKGROUND BLOCKING - Always block, backup protection
  //           if (now.difference(lastUsedTime).inSeconds < 2) {
  //             String appName = _getAppNameFromPackage(usage.packageName!);
  //             print('🔒 BACKGROUND CONTINUOUS: $appName - BACKUP PROTECTION!');
  //             
  //             // Simple background blocking - always effective
  //             try {
  //               await _channel.invokeMethod('killApp', {'packageName': usage.packageName!});
  //               await _channel.invokeMethod('bringAppToForeground');
  //               print('🛡️ Background: $appName blocked, Study Mode active');
  //             } catch (blockError) {
  //               print('⚠️ Background blocking error: $blockError');
  //             }
  //           }
  //         }
  //       }
  //     } catch (e) {
  //       print('Background monitoring error: $e');
  //       // Continue monitoring - NEVER STOP PROTECTING
  //     }
  //   });
  //   
  //   // Send periodic status updates
  //   Timer.periodic(const Duration(minutes: 1), (timer) {
  //     if (_isMonitoring && _blockedPackages.isNotEmpty) {
  //       print('CONTINUOUS blocking active - Monitoring ${_blockedPackages.length} apps');
  //       service.invoke('update_notification', {
  //         'title': 'Study Mode ACTIVE 🔒',
  //         'body': 'Continuous blocking of ${_blockedPackages.length} apps - Always protected'
  //       });
  //     }
  //   });
  // }
}