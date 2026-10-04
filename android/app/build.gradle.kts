import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.hypnoloop.app"
    compileSdk = 36
    buildToolsVersion = "35.0.0"
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.hypnoloop.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 24
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Private local builds use the same debug identity; no publishing key.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

// Flutter 3.41 regenerates Windows SDK paths without escaping the drive colon.
// Normalize after Dart compilation and before lint reads this generated file.
val normalizeLocalPropertiesForLint = tasks.register("normalizeLocalPropertiesForLint") {
    mustRunAfter(tasks.matching { it.name.startsWith("compileFlutterBuild") })
    doLast {
        val propertiesFile = rootProject.file("local.properties")
        if (propertiesFile.exists()) {
            val original = propertiesFile.readText()
            val escaped = original.replace(Regex("(?m)^([^=\\r\\n]+=[A-Za-z]):")) {
                "${it.groupValues[1]}\\:"
            }
            if (escaped != original) propertiesFile.writeText(escaped)
        }
    }
}
tasks.matching { it.name.contains("Lint", ignoreCase = true) &&
    it.name != "normalizeLocalPropertiesForLint" }.configureEach {
    dependsOn(normalizeLocalPropertiesForLint)
}
