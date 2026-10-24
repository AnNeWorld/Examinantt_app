# Jitsi Meet SDK
-keep class org.jitsi.meet.** { *; }
-keep class org.jitsi.meet.sdk.** { *; }
-keep class org.jitsi.jitsi_meet_flutter_sdk.** { *; }
-keep class com.facebook.react.** { *; }
-dontwarn org.jitsi.meet.**
-dontwarn com.facebook.react.**

# WebRTC
-keep class org.webrtc.** { *; }
-dontwarn org.webrtc.**

# AWS IVS & Cronet optional references
-dontwarn org.chromium.net.**
-dontwarn com.amazonaws.ivs.**
-keep class com.amazonaws.ivs.** { *; }
