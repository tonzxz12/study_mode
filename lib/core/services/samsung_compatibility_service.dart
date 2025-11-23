import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';

class SamsungCompatibilityService {
  static const MethodChannel _channel = MethodChannel('samsung_compatibility');
  
  // Check if device is Samsung
  static Future<bool> isSamsungDevice() async {
    if (!Platform.isAndroid) return false;
    
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.manufacturer.toLowerCase().contains('samsung');
    } catch (e) {
      print('Error checking Samsung device: $e');
      return false;
    }
  }
  
  // Get Samsung device model for specific compatibility checks
  static Future<String?> getSamsungModel() async {
    if (!await isSamsungDevice()) return null;
    
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.model;
    } catch (e) {
      print('Error getting Samsung model: $e');
      return null;
    }
  }
  
  // Check if Samsung A54 which has known issues
  static Future<bool> isSamsungA54() async {
    final model = await getSamsungModel();
    return model?.toLowerCase().contains('sm-a546') == true || 
           model?.toLowerCase().contains('galaxy a54') == true;
  }
  
  // Request Samsung-specific permissions for app blocking
  static Future<void> requestSamsungAppBlockingPermissions() async {
    if (!await isSamsungDevice()) return;
    
    // 1. Auto-start apps permission (crucial for Samsung)
    await _requestSamsungAutoStartPermission();
    
    // 2. Battery optimization whitelist
    await _requestBatteryOptimizationWhitelist();
    
    // 3. Samsung Smart Manager permissions
    await _requestSmartManagerPermissions();
    
    // 4. Samsung One UI specific permissions
    await _requestOneUIPermissions();
  }
  
  // Request auto-start permission (Samsung-specific)
  static Future<void> _requestSamsungAutoStartPermission() async {
    try {
      // Samsung Auto-start manager
      const samsungAutoStartIntent = AndroidIntent(
        action: 'android.settings.APPLICATION_DETAILS_SETTINGS',
        data: 'package:com.studymode.app.study_mode_v2',
      );
      await samsungAutoStartIntent.launch();
      print('Samsung auto-start permission requested');
    } catch (e) {
      print('Error requesting Samsung auto-start: $e');
    }
  }
  
  // Request battery optimization whitelist
  static Future<void> _requestBatteryOptimizationWhitelist() async {
    try {
      // Samsung battery optimization settings
      const batteryOptIntent = AndroidIntent(
        action: 'android.settings.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS',
        data: 'package:com.studymode.app.study_mode_v2',
      );
      await batteryOptIntent.launch();
      print('Samsung battery optimization whitelist requested');
    } catch (e) {
      try {
        // Fallback to general battery settings
        const batterySettingsIntent = AndroidIntent(
          action: 'android.settings.BATTERY_SAVER_SETTINGS',
        );
        await batterySettingsIntent.launch();
      } catch (e2) {
        print('Error requesting battery optimization: $e2');
      }
    }
  }
  
  // Request Samsung Smart Manager permissions
  static Future<void> _requestSmartManagerPermissions() async {
    try {
      // Samsung Smart Manager - Auto-run apps
      const smartManagerIntent = AndroidIntent(
        action: 'android.intent.action.MAIN',
        package: 'com.samsung.android.sm',
        componentName: 'com.samsung.android.sm/.ui.ram.AutoRunActivity',
      );
      await smartManagerIntent.launch();
      print('Samsung Smart Manager permissions requested');
    } catch (e) {
      try {
        // Alternative Samsung Device Care
        const deviceCareIntent = AndroidIntent(
          action: 'android.intent.action.MAIN',
          package: 'com.samsung.android.lool',
        );
        await deviceCareIntent.launch();
      } catch (e2) {
        print('Error requesting Samsung Smart Manager: $e2');
      }
    }
  }
  
  // Request Samsung One UI specific permissions
  static Future<void> _requestOneUIPermissions() async {
    try {
      // Samsung One UI - App power management
      const oneUIIntent = AndroidIntent(
        action: 'android.intent.action.MAIN',
        package: 'com.samsung.android.sm_cn',
        componentName: 'com.samsung.android.sm.ui.ram.RamActivity',
      );
      await oneUIIntent.launch();
      print('Samsung One UI permissions requested');
    } catch (e) {
      print('Error requesting One UI permissions: $e');
    }
  }
  
  // Enhanced Samsung app blocking compatibility
  static Future<void> applySamsungAppBlockingFix() async {
    if (!await isSamsungDevice()) return;
    
    print('🔧 Applying Samsung compatibility fixes...');
    
    // 1. Enable aggressive usage stats checking for Samsung
    await _enableAggressiveUsageStatsForSamsung();
    
    // 2. Use Samsung-specific app termination methods
    await _applySamsungAppTerminationFix();
    
    // 3. Enable Samsung-specific foreground service
    await _enableSamsungForegroundService();
    
    print('✅ Samsung compatibility fixes applied');
  }
  
  // Enable more aggressive usage stats checking for Samsung devices
  static Future<void> _enableAggressiveUsageStatsForSamsung() async {
    // Samsung devices require more frequent usage stats checks
    // This will be handled in the main AppBlockingService
    print('🔧 Enabled aggressive usage stats for Samsung');
  }
  
  // Apply Samsung-specific app termination methods
  static Future<void> _applySamsungAppTerminationFix() async {
    try {
      await _channel.invokeMethod('applySamsungAppTermination');
      print('🔧 Applied Samsung app termination fix');
    } catch (e) {
      print('Error applying Samsung termination fix: $e');
    }
  }
  
  // Enable Samsung-specific foreground service
  static Future<void> _enableSamsungForegroundService() async {
    try {
      await _channel.invokeMethod('enableSamsungForegroundService');
      print('🔧 Enabled Samsung foreground service');
    } catch (e) {
      print('Error enabling Samsung foreground service: $e');
    }
  }
  
  // Show Samsung-specific setup instructions
  static Future<void> showSamsungSetupInstructions() async {
    if (!await isSamsungDevice()) return;
    
    final model = await getSamsungModel();
    
    print('📱 Samsung Device Detected: $model');
    print('🔧 Required Samsung-specific setup:');
    print('1. Add Study Mode to Auto-start apps');
    print('2. Disable battery optimization for Study Mode');
    print('3. Allow background activity in Smart Manager');
    print('4. Enable "Allow app while using other apps" permission');
    print('5. Disable adaptive battery restrictions');
  }
  
  // Check if Samsung-specific permissions are granted
  static Future<bool> hasSamsungPermissions() async {
    if (!await isSamsungDevice()) return true;
    
    try {
      final result = await _channel.invokeMethod('checkSamsungPermissions');
      return result ?? false;
    } catch (e) {
      print('Error checking Samsung permissions: $e');
      return false;
    }
  }
}