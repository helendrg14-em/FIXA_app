import groovy.json.JsonSlurper
plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val idFixa = "com.fixa.fixa"
val configuracionFirebase = file("google-services.json")
val firebase = if (configuracionFirebase.isFile) {
    val datos = JsonSlurper().parse(configuracionFirebase) as Map<*, *>
    val proyecto = datos["project_info"] as Map<*, *>
    val clientes = datos["client"] as List<*>
    val cliente = clientes.map { it as Map<*, *> }.firstOrNull {
        val info = it["client_info"] as Map<*, *>
        val android = info["android_client_info"] as Map<*, *>
        android["package_name"] == idFixa
    } ?: error("google-services.json debe incluir la app Android $idFixa.")
    val cuenta = cliente["client_info"] as Map<*, *>
    val clave = (cliente["api_key"] as List<*>).first() as Map<*, *>
    mapOf(
        "google_app_id" to cuenta["mobilesdk_app_id"],
        "google_api_key" to clave["current_key"],
        "gcm_defaultSenderId" to proyecto["project_number"],
        "project_id" to proyecto["project_id"]
    ).mapValues { (nombre, valor) ->
        (valor as? String)?.takeIf { it.isNotBlank() }
            ?: error("Falta $nombre en google-services.json.")
    }
} else {
    emptyMap()
}
android {
    namespace = idFixa

    buildFeatures {
        resValues = firebase.isNotEmpty()
    }

    sourceSets.getByName("main").java.srcDir(
        if (firebase.isEmpty()) "src/sinFcm/kotlin" else "src/fcm/kotlin"
    )
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = idFixa
        manifestPlaceholders["servicioFcmHabilitado"] = firebase.isNotEmpty()
        firebase.forEach { (nombre, valor) -> resValue("string", nombre, valor) }
        // Android 7.0+: cubre casi todos los celulares en uso.
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    if (firebase.isNotEmpty()) {
        implementation("com.google.firebase:firebase-messaging:25.0.1")
    }
}
