# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**

# RevenueCat
-keep class com.revenuecat.purchases.** { *; }
-dontwarn com.revenuecat.purchases.**

# Gson (used by some SDKs)
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**

# Flutter deferred components (optional Play Core — not used in this app)
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# Health Connect (required for release/minified builds — permission UI crashes without these)
-keep public class androidx.health.** { public protected *; }
-keep public class androidx.health.connect.** { public protected *; }
-dontwarn androidx.health.**

# Protobuf (Health Connect client dependency)
-keep class * extends com.google.protobuf.GeneratedMessageLite { *; }
