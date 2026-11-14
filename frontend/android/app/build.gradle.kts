import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Necesita android/app/google-services.json (ver CONTEXTO_PARA_IA.md) para
    // que "Continuar con Google" funcione nativo en Android — sin ese archivo
    // el build falla.
    id("com.google.gms.google-services")
    // Registro de errores (Crashlytics): ver main.dart, _activarRegistroDeErrores.
    id("com.google.firebase.crashlytics")
}

// Firma de release: se lee de android/key.properties, que NO está en Git (ver
// android/key.properties.example y PLAY_STORE.md). Si el archivo no existe, el
// build de release se firma con la clave de depuración para poder probarlo,
// pero ESE APK/AAB NO SIRVE para subir a Play Store.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.soundcheckpro.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // OJO: el ID de la app NO se puede cambiar una vez publicada, y tiene que
        // coincidir con la app Android registrada en Firebase (google-services.json).
        // Ver PLAY_STORE.md §2 antes de tocarlo.
        applicationId = "com.soundcheckpro.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Reduce y ofusca el código Java/Kotlin (R8) y quita recursos sin
            // usar. El código Dart se ofusca al compilar con --obfuscate (ver
            // PLAY_STORE.md). Reglas en proguard-rules.pro.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
