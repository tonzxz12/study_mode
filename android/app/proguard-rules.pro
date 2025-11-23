# Flutter & Dart
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Gson (used by Firebase)
-keepattributes Signature
-keepattributes *Annotation*
-keep class sun.misc.Unsafe { *; }
-keep class com.google.gson.stream.** { *; }

# Notification and Permission plugins
-keep class com.dexterous.** { *; }
-keep class com.baseflow.** { *; }

# App Blocking Service
-keep class com.studymode.app.study_mode_v2.** { *; }

# Usage Stats
-keep class android.app.usage.** { *; }

# Device Admin
-keep class android.app.admin.** { *; }

# System Alert Window
-keep class android.view.WindowManager { *; }

# Shared Preferences
-keep class android.content.SharedPreferences { *; }

# Path Provider
-keep class io.flutter.plugins.pathprovider.** { *; }

# Device Info
-keep class io.flutter.plugins.deviceinfo.** { *; }

# Keep annotation default values (needed for Firebase)
-keepattributes AnnotationDefault

# Keep generic signature of Call, Response (R8 full mode strips signatures from non-kept items).
-keep,allowshrinking,allowoptimization class okhttp3.** { *; }
-keep,allowshrinking,allowoptimization class retrofit2.** { *; }

# With R8 full mode generic signatures are stripped for classes that are not
# kept. Suspend functions are wrapped in continuations where the type argument
# is used.
-keep,allowshrinking,allowoptimization class kotlin.coroutines.Continuation