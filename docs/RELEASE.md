# Ezze Break - Production Release & Build Guide

## 1. Release Architecture

Ezze Break is configured for Android release builds targeting Android API level 34+ (Android 14) with a minimum SDK of 26 (Android 8.0 Oreo).

- **Application ID:** `com.ezze.break`
- **Internal Namespace:** `com.ezze.appbreak`
- **Version Name:** `1.0.0`
- **Version Code:** `1`

---

## 2. Generating Android Builds

### 2.1 Debug APK
To build a debug APK for direct testing and sideloading:
```bash
flutter build apk --debug
```
- **Output Artifact:** `build/app/outputs/flutter-apk/app-debug.apk`

### 2.2 Unsigned Release APK
To build an optimized release APK:
```bash
flutter build apk --release
```
- **Output Artifact:** `build/app/outputs/flutter-apk/app-release.apk`

### 2.3 Android App Bundle (AAB)
For Google Play distribution:
```bash
flutter build appbundle --release
```
- **Output Artifact:** `build/app/outputs/bundle/release/app-release.aab`

---

## 3. Signing Configuration

To sign the release APK for production distribution:

1. Generate a Java Keystore:
```bash
keytool -genkey -v -keystore ezze_release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias ezze_break_key
```

2. Create `android/key.properties`:
```properties
storePassword=<your-store-password>
keyPassword=<your-key-password>
keyAlias=ezze_break_key
storeFile=../ezze_release.jks
```

3. Update `android/app/build.gradle.kts`:
```kotlin
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}
```

---

## 4. Google Play Policy & Sideloading Notes

1. **Accessibility Service Policy:**
   - Ezze Break's `EzzeAccessibilityService` is used strictly for digital wellbeing foreground detection and user-requested app restriction.
   - For Google Play submission, a prominent disclosure video and written declaration must demonstrate how the Accessibility API is used for the user's explicit self-control purpose.
2. **Usage Access:**
   - Special App Access for `PACKAGE_USAGE_STATS` must declare the digital wellbeing core functionality.
3. **QUERY_ALL_PACKAGES:**
   - Required for launcher app discovery so users can monitor any installed app on their device. For Play Store distribution, declare the "Device Management / Digital Wellbeing" core exception.
