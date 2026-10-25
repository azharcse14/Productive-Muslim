# R8 keep rules for release builds.
#
# Flutter's Gradle plugin adds the engine/plugin-registrant rules, and our
# plugins ship their own consumer rules (jni, androidx). flutter_local_notifications
# ≥19 relies on Gson's bundled rules for its scheduled-notification cache;
# these are kept explicitly anyway, because a stripped field there silently
# breaks every scheduled reminder after a reboot or reschedule.
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}
-keep,allowobfuscation,allowshrinking class com.google.gson.reflect.TypeToken
-keep,allowobfuscation,allowshrinking class * extends com.google.gson.reflect.TypeToken
