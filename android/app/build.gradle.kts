plugins {
    id("com.android.application")
    id("kotlin-android")
    // Flutter 插件必须应用
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    // ⚠️ 注意：如果你修改过包名，请确认这里是否正确
    namespace = "com.example.animeone_tv" 
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    defaultConfig {
        // ⚠️ 注意：确认 applicationId 是否与你的 AndroidManifest.xml 一致
        applicationId = "com.example.animeone_tv"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // --- NDK 配置：只编译 armeabi-v7a 以获得最小体积和最大兼容性 ---
        // v7 (32位) APK 可以在所有 ARM 设备上运行（包括 v7 和 v8）
        ndk {
            abiFilters.add("armeabi-v7a")  // 32位 ARM 设备（兼容所有 ARM 设备）
        }
    }

    buildTypes {
        release {
            // release 模式下的签名配置
            signingConfig = signingConfigs.getByName("debug")
            
            // ✅ 启用 R8 代码压缩和混淆 - 可减少 30-50% APK 体积
            isMinifyEnabled = true
            
            // ✅ 启用资源压缩 - 移除未使用的资源文件
            isShrinkResources = true
            
            // ProGuard 规则文件
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}