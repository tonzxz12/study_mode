package com.studymode.app.study_mode_v2

import android.app.ActivityManager
import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "app_blocking_service"
    private lateinit var devicePolicyManager: DevicePolicyManager
    private lateinit var componentName: ComponentName

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        devicePolicyManager = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        componentName = ComponentName(this, StudyModeDeviceAdminReceiver::class.java)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isDeviceAdmin" -> {
                    try {
                        val isAdmin = devicePolicyManager.isAdminActive(componentName)
                        result.success(isAdmin)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to check device admin status", e.message)
                    }
                }
                "requestDeviceAdmin" -> {
                    try {
                        val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN).apply {
                            putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, componentName)
                            putExtra(DevicePolicyManager.EXTRA_ADD_EXPLANATION, 
                                "Enable device admin to block apps during study sessions")
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to request device admin", e.message)
                    }
                }
                "closeApp" -> {
                    try {
                        val packageName = call.argument<String>("packageName")
                        if (packageName != null) {
                            closeBlockedApp(packageName)
                            result.success(true)
                        } else {
                            result.error("ERROR", "Package name is required", null)
                        }
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to close app", e.message)
                    }
                }
                "openStudyModeApp" -> {
                    try {
                        bringAppToForeground()
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to open Study Mode app", e.message)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun closeBlockedApp(packageName: String) {
        try {
            val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
            
            // Method 1: Use ActivityManager to kill background processes
            try {
                activityManager.killBackgroundProcesses(packageName)
            } catch (e: Exception) {
                // This method requires KILL_BACKGROUND_PROCESSES permission
            }
            
            // Method 2: If we have device admin rights, try to force close
            if (devicePolicyManager.isAdminActive(componentName)) {
                try {
                    // Force stop the application
                    val runningApps = activityManager.runningAppProcesses
                    runningApps?.forEach { processInfo ->
                        if (processInfo.processName == packageName) {
                            android.os.Process.killProcess(processInfo.pid)
                        }
                    }
                } catch (e: Exception) {
                    // Process killing might fail on newer Android versions
                }
            }
            
            // Method 3: Send the app to background/home screen first
            val homeIntent = Intent(Intent.ACTION_MAIN).apply {
                addCategory(Intent.CATEGORY_HOME)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            startActivity(homeIntent)
            
            // Small delay to let the home screen appear
            Thread.sleep(100)
            
            // Method 4: Now bring our app to foreground
            bringAppToForeground()
            
        } catch (e: Exception) {
            // If all closing methods fail, at least bring our app to foreground
            bringAppToForeground()
        }
    }

    private fun bringAppToForeground() {
        try {
            val intent = Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
            }
            startActivity(intent)
        } catch (e: Exception) {
            // Fallback: try to bring to front using activity manager
            val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
            activityManager.moveTaskToFront(taskId, ActivityManager.MOVE_TASK_WITH_HOME)
        }
    }
}
