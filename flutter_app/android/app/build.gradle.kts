plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Base64
import java.util.Properties

val localProperties = Properties().apply {
    val localPropertiesFile = rootProject.file("local.properties")
    if (localPropertiesFile.exists()) {
        localPropertiesFile.inputStream().use { load(it) }
    }
}

fun encodeDartDefine(entry: String): String =
    Base64.getEncoder().encodeToString(entry.toByteArray(Charsets.UTF_8))

val mapsApiKeyForManifest = localProperties.getProperty("MAPS_API_KEY") ?: ""
val geminiApiKeyForDart = localProperties.getProperty("GEMINI_API_KEY") ?: ""
val groqApiKeyForDart = localProperties.getProperty("GROQ_API_KEY") ?: ""

val localDartDefineEncodings = listOfNotNull(
    mapsApiKeyForManifest.takeIf { it.isNotBlank() }
        ?.let { encodeDartDefine("MAPS_API_KEY=$it") },
    geminiApiKeyForDart.takeIf { it.isNotBlank() }
        ?.let { encodeDartDefine("GEMINI_API_KEY=$it") },
    groqApiKeyForDart.takeIf { it.isNotBlank() }
        ?.let { encodeDartDefine("GROQ_API_KEY=$it") },
)

val flutterDartDefines = project.findProperty("dart-defines")?.toString()?.trim().orEmpty()
val mergedDartDefines = when {
    localDartDefineEncodings.isEmpty() -> flutterDartDefines
    flutterDartDefines.isEmpty() -> localDartDefineEncodings.joinToString(",")
    else -> "$flutterDartDefines,${localDartDefineEncodings.joinToString(",")}"
}
if (mergedDartDefines.isNotEmpty()) {
    extra["dart-defines"] = mergedDartDefines
    // Some Gradle / IDE flows do not propagate `extra` to Flutter tasks; mirror here:
    extensions.extraProperties.set("dart-defines", mergedDartDefines)
}

fun String.escapeForBuildConfigString(): String =
    '"' + replace("\\", "\\\\").replace("\"", "\\\"") + '"'

android {
    namespace = "com.example.frontend"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    buildFeatures {
        buildConfig = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.frontend"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        manifestPlaceholders["MAPS_API_KEY"] = mapsApiKeyForManifest

        // Gemini API key for Dart (MethodChannel); matches dart-defines merge.
        buildConfigField(
            "String",
            "GEMINI_API_KEY",
            geminiApiKeyForDart.escapeForBuildConfigString(),
        )
        buildConfigField(
            "String",
            "GROQ_API_KEY",
            groqApiKeyForDart.escapeForBuildConfigString(),
        )
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
