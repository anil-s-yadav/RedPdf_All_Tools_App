# Flutter & Dart
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Keep annotations
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses,EnclosingMethod

# Keep Kotlin metadata
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**

# PDFium (used by pdfrx)
-keep class com.pdfium.** { *; }
-dontwarn com.pdfium.**

# Syncfusion
-keep class com.syncfusion.** { *; }
-dontwarn com.syncfusion.**

# In-App Update
-keep class com.google.android.play.** { *; }
-dontwarn com.google.android.play.**

# uCrop (Image Cropper) & OkHttp
-keep class com.yalantis.ucrop.** { *; }
-dontwarn com.yalantis.ucrop.**
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**
