# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# If your project uses WebView with JS, uncomment the following
# and specify the fully qualified class name to the JavaScript interface
# class:
#-keepclassmembers class fqcn.of.javascript.interface.for.webview {
#   public *;
#}

# Uncomment this to preserve the line number information for
# debugging stack traces.
#-keepattributes SourceFile,LineNumberTable

# If you keep the line number information, uncomment this to
# hide the original source file name.
#-renamesourcefileattribute SourceFile

# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# New modular Play libraries (only add what you actually use)
# -keep class com.google.android.play.appupdate.** { *; }
# -keep class com.google.android.play.review.** { *; }
# -dontwarn com.google.android.play.appupdate.**
# -dontwarn com.google.android.play.review.**

# Hive database rules
-keep class * extends androidx.room.RoomDatabase
-keep @androidx.room.Entity class *
-dontwarn androidx.room.paging.**

# Google Mobile Ads rules
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.android.gms.common.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep enum classes
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep Parcelable classes
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Keep Serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep R classes
-keep class **.R$* {
    public static <fields>;
}

# Keep custom application classes
-keep class com.harshm.subtrackr.** { *; }

# Remove logging in release
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}

# --- Allow R8 to remove Flutter's Play-Store split path completely ---

# If these classes are present, they are safe to shrink/obfuscate away.
# This overrides broader keep rules coming from flutter_proguard_rules.pro.
-if class io.flutter.embedding.android.FlutterPlayStoreSplitApplication
-keep,allowshrinking,allowobfuscation class io.flutter.embedding.android.FlutterPlayStoreSplitApplication { *; }

-if class io.flutter.embedding.engine.deferredcomponents.PlayStoreDeferredComponentManager
-keep,allowshrinking,allowobfuscation class io.flutter.embedding.engine.deferredcomponents.PlayStoreDeferredComponentManager { *; }

# (Optional but helpful) other DC helpers may appear; allow them to shrink too.
-if class io.flutter.embedding.engine.deferredcomponents.**
-keep,allowshrinking,allowobfuscation class io.flutter.embedding.engine.deferredcomponents.** { *; }

# We are NOT using Play Core; don't fail on its missing symbols referenced by those classes.
-dontwarn com.google.android.play.core.**
