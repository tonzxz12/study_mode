import 'dart:async';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:usage_stats/usage_stats.dart';  // Temporarily disabled
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
      DateTime now = DateTime.now();
      DateTime start = now.subtract(const Duration(minutes: 5));
      
      List<UsageInfo> stats = await UsageStats.queryUsageStats(start, now);
      return stats.isNotEmpty;
    } catch (e) {
      print('Usage stats error (likely no permission): $e');
      return false;
    }
  }

  // Request usage access permission
  static Future<void> requestUsagePermission() async {
    await UsageStats.grantUsagePermission();
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

  // CONTINUOUS Start monitoring blocked apps (public interface)
  static Future<void> startMonitoring(List<String> blockedApps) async {
    try {
      print('🔒 Starting CONTINUOUS app blocking for ${blockedApps.length} apps');
      _blockedPackages = blockedApps;
      _isMonitoring = true;
      
      // Use CONTINUOUS monitoring for persistent blocking
      _startContinuousMonitoring(blockedApps);
      
      // Ensure background service is running for persistence
      await _ensureBackgroundServiceRunning();
      
      // Save state
      await _saveBlockedApps();
      
      print('✅ CONTINUOUS app blocking started - monitoring every 300ms');
      print('📱 Background service enabled for persistent blocking');
    } catch (e) {
      print('❌ Error starting continuous monitoring: $e');
    }
  }

  // CONTINUOUS monitoring implementation 
  static void _startContinuousMonitoring(List<String> blockedApps) {
    try {
      // Start CONTINUOUS foreground monitoring for instant blocking
      _monitoringTimer?.cancel();
      _monitoringTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
        _checkBlockedAppsContinuously();
      });
      
      print('🔒 CONTINUOUS monitoring timer started');
      print('  ⏱️  Interval: 300ms (continuous protection)');
      print('  🚫 INSTANT blocking - always active');
      print('  📱 Persistent Study Mode focus');
    } catch (e) {
      print('❌ Error in continuous monitoring startup: $e');
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

  // CONTINUOUS app detection and blocking - ALWAYS block without interference
  static Future<void> _checkBlockedAppsContinuously() async {
    if (!_isMonitoring || _blockedPackages.isEmpty) return;
    
    try {
      DateTime now = DateTime.now();
      
      // Check very recent usage (last 2 seconds) for immediate detection
      DateTime startTime = now.subtract(const Duration(seconds: 2));
      List<UsageInfo> usageInfos = await UsageStats.queryUsageStats(startTime, now);
      
      for (UsageInfo usage in usageInfos) {
        if (_blockedPackages.contains(usage.packageName) && 
            usage.lastTimeUsed != null) {
          
          int lastUsedMillis = int.tryParse(usage.lastTimeUsed!) ?? 0;
          DateTime lastUsedTime = DateTime.fromMillisecondsSinceEpoch(lastUsedMillis);
          
          // CONTINUOUS BLOCKING - ALWAYS block, very short cooldown to prevent spam only
          if (now.difference(lastUsedTime).inSeconds < 2) {
            DateTime? lastBlocked = _lastBlockedTime[usage.packageName!];
            // Ultra-short 30ms cooldown to allow continuous re-blocking but prevent excessive calls
            if (lastBlocked == null || now.difference(lastBlocked).inMilliseconds >= 30) {
              String appName = _getAppNameFromPackage(usage.packageName!);
              print('🚫🚫🚫 CONTINUOUS BLOCKING: $appName - ALWAYS BLOCKED!');
              _lastBlockedTime[usage.packageName!] = now;
              
              // Perform continuous blocking with persistent focus
              await _performContinuousBlocking(usage.packageName!);
              print('⚡ $appName continuously blocked - Study Mode enforced');
            }
          }
        }
      }
    } catch (e) {
      print('❌ Error in continuous monitoring: $e');
      // Don't stop monitoring even if there's an error - keep protecting!
    }
  }

  // CONTINUOUS persistent blocking - close app and FORCE Study Mode to stay
  static Future<void> _performContinuousBlocking(String packageName) async {
    try {
      String appName = _getAppNameFromPackage(packageName);
      
      // Step 1: IMMEDIATELY close blocked app multiple times
      for (int i = 0; i < 2; i++) {
        try {
          await _channel.invokeMethod('killApp', {'packageName': packageName});
        } catch (e) {
          // Continue even if native method fails
        }
        if (i == 0) await Future.delayed(const Duration(milliseconds: 50));
      }
      
      // Step 2: Force Study Mode to foreground
      try {
        await _channel.invokeMethod('bringAppToForeground');
      } catch (e) {
        // Fallback to Android Intent
        try {
          const studyModeIntent = AndroidIntent(
            action: 'android.intent.action.MAIN',
            package: 'com.studymode.app.study_mode_v2',
            flags: <int>[
              0x10000000, // FLAG_ACTIVITY_NEW_TASK
              0x20000000, // FLAG_ACTIVITY_SINGLE_TOP
            ],
          );
          await studyModeIntent.launch();
        } catch (intentError) {
          // Continue monitoring even if intents fail
        }
      }
      
      print('✅ $appName continuously blocked - Study Mode maintained');
    } catch (e) {
      print('❌ Continuous blocking error: $e');
      // Continue monitoring regardless of errors
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
    const Map<String, String> appNames = {
      'com.instagram.android': 'Instagram',
      'com.facebook.katana': 'Facebook', 
      'com.twitter.android': 'Twitter',
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

  // Background service entry point
  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) {
    print('Background app blocking service started - CONTINUOUS protection');
    
    // Listen for stop commands
    service.on('stop').listen((event) {
      print('Stopping background app blocking service');
      service.stopSelf();
    });
    
    // CONTINUOUS background monitoring - backup protection layer
    Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      if (!_isMonitoring || _blockedPackages.isEmpty) {
        return;
      }
      
      try {
        DateTime now = DateTime.now();
        DateTime startTime = now.subtract(const Duration(seconds: 2));
        
        List<UsageInfo> usageInfos = await UsageStats.queryUsageStats(startTime, now);
        
        for (UsageInfo usage in usageInfos) {
          if (_blockedPackages.contains(usage.packageName) && 
              usage.lastTimeUsed != null) {
            
            int lastUsedMillis = int.tryParse(usage.lastTimeUsed!) ?? 0;
            DateTime lastUsedTime = DateTime.fromMillisecondsSinceEpoch(lastUsedMillis);
            
            // CONTINUOUS BACKGROUND BLOCKING - Always block, backup protection
            if (now.difference(lastUsedTime).inSeconds < 2) {
              String appName = _getAppNameFromPackage(usage.packageName!);
              print('🔒 BACKGROUND CONTINUOUS: $appName - BACKUP PROTECTION!');
              
              // Simple background blocking - always effective
              try {
                await _channel.invokeMethod('killApp', {'packageName': usage.packageName!});
                await _channel.invokeMethod('bringAppToForeground');
                print('🛡️ Background: $appName blocked, Study Mode active');
              } catch (blockError) {
                print('⚠️ Background blocking error: $blockError');
              }
            }
          }
        }
      } catch (e) {
        print('Background monitoring error: $e');
        // Continue monitoring - NEVER STOP PROTECTING
      }
    });
    
    // Send periodic status updates
    Timer.periodic(const Duration(minutes: 1), (timer) {
      if (_isMonitoring && _blockedPackages.isNotEmpty) {
        print('CONTINUOUS blocking active - Monitoring ${_blockedPackages.length} apps');
        service.invoke('update_notification', {
          'title': 'Study Mode ACTIVE 🔒',
          'body': 'Continuous blocking of ${_blockedPackages.length} apps - Always protected'
        });
      }
    });
  }
}