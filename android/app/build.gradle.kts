plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.studyflow.studyflow"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.studyflow.studyflow"
        minSdk = 24
        targetSdk = 36
        versionCode = 1
        versionName = "1.0.0"
        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = true
            isShrinkResources = true
        }
    }
}

// Gradle DSL-safe: 组装完成后把 release APK 重命名为 StudyFlow.apk
afterEvaluate {
    tasks.matching { it.name == "assembleRelease" }.configureEach {
        doLast {
            val outDir = File(project.buildDir, "outputs/apk/release")
            if (outDir.exists()) {
                val src = outDir.listFiles()?.firstOrNull {
                    it.name.endsWith(".apk") && it.name.contains("-release")
                }
                if (src != null && src.exists()) {
                    val target = File(outDir, "StudyFlow.apk")
                    src.copyTo(target, overwrite = true)
                    println("APK renamed -> ${target.name}")
                }
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.multidex:multidex:2.0.1")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
