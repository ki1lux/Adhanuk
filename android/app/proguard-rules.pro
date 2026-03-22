# Flutter-specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep just_audio native classes
-keep class com.google.android.exoplayer2.** { *; }
-keep class com.jcraft.** { *; }

# Keep geolocator
-keep class com.baseflow.geolocator.** { *; }

# Keep flutter_local_notifications
-keep class com.dexterous.** { *; }

# Suppress warnings for common third-party libraries
-dontwarn com.google.android.play.core.**
-dontwarn com.google.errorprone.annotations.**
