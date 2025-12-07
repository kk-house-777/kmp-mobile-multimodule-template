package primitive

import com.android.build.gradle.BaseExtension
import util.getDefaultPackageName
import util.libs
import util.version

plugins {
    id("org.jetbrains.kotlin.multiplatform")
    /**
     *  replace with "com.android.kotlin.multiplatform.library"
     *  after https://youtrack.jetbrains.com/issue/CMP-8202/Preview-not-work-in-commonMain-with-multi-module is resolved
     */
    id("com.android.library")
}

kotlin {
    androidTarget()
}

configure<BaseExtension> {
    defaultConfig {
        minSdk = libs.version("android.minSdk").toInt()
        targetSdk = libs.version("android.targetSdk").toInt()
    }
    compileSdkVersion(libs.version("android.compileSdk").toInt())
    namespace = getDefaultPackageName(project.name)
}
