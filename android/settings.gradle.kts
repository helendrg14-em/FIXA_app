pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        val localPropertiesFile = file("local.properties")
        if (localPropertiesFile.exists()) {
            localPropertiesFile.inputStream().use { properties.load(it) }
        }
        var path = properties.getProperty("flutter.sdk")
        if (path.isNullOrBlank()) {
            path = System.getenv("FLUTTER_ROOT") ?: System.getenv("FLUTTER_HOME")
        }
        require(path != null && file("$path/packages/flutter_tools/gradle").isDirectory) {
            "Ejecuta flutter pub get o configura flutter.sdk en android/local.properties."
        }
        path
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "9.1.1" apply false
    id("org.jetbrains.kotlin.android") version "2.4.0" apply false
}

include(":app")

