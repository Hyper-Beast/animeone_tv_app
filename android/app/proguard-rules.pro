# Flutter 相关 - 保护 Flutter 框架核心类
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Dart 相关
-keep class io.flutter.embedding.** { *; }

# Video Player 插件
-keep class io.flutter.plugins.videoplayer.** { *; }

# Cached Network Image
-keep class io.flutter.plugins.cachednetworkimage.** { *; }

# Shared Preferences
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# HTTP 网络请求
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }

# 保留泛型信息
-keepattributes Signature

# 保留异常信息
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception

# 保留 native 方法
-keepclasseswithmembernames class * {
    native <methods>;
}

# 忽略 Google Play Core 相关警告（这些是可选依赖，不影响应用运行）
-dontwarn com.google.android.play.core.**
-dontwarn com.google.android.play.**

# 如果使用了 Play Core，但不需要动态功能模块，可以忽略这些类
-keep class com.google.android.play.core.** { *; }

