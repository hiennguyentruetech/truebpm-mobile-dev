# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Flutter embedding and Play Core
-keep class io.flutter.embedding.** { *; }
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# Better Auth Flutter
-keep class better_auth_flutter.** { *; }
-keep class com.betterauth.** { *; }

# HTTP and networking
-keepattributes *Annotation*
-keepclassmembers class * {
    @retrofit2.http.* <methods>;
}
-keep class retrofit2.** { *; }
-keep class okhttp3.** { *; }
-keep class okio.** { *; }

# Google Sign In
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# uCrop library for image cropping
-keep class com.yalantis.ucrop.** { *; }
-keep interface com.yalantis.ucrop.** { *; }
-dontwarn com.yalantis.ucrop.**

# Image picker and cropper
-keep class image_picker.** { *; }
-keep class image_cropper.** { *; }
-keep class io.flutter.plugins.imagepicker.** { *; }

# Gson (if used)
-keepattributes Signature
-keepattributes *Annotation*
-keep class sun.misc.Unsafe { *; }
-keep class com.google.gson.** { *; }

# Permission handler
-keep class com.baseflow.permissionhandler.** { *; }

# Shared preferences
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# URL launcher
-keep class io.flutter.plugins.urllauncher.** { *; }

# Path provider
-keep class io.flutter.plugins.pathprovider.** { *; }

# Logger
-dontwarn java.lang.invoke.**

# Keep model classes if you have any
-keep class com.ken.yohor.models.** { *; }

# WebView
-keep class com.pichillilorenzo.flutter_inappwebview.** { *; }

# Motion sensors
-keep class com.dchs.motion_sensors.** { *; }

# YouTube player
-keep class com.sarbagyastha.youtube_player_flutter.** { *; }

# General rules
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Disable obfuscation for better debugging
-dontobfuscate

# Additional rules for missing classes
-dontwarn kotlin.**
-dontwarn kotlinx.**
-keep class kotlin.** { *; }
-keep class kotlinx.** { *; }
