plugins {
    alias(libs.plugins.kotlinMultiplatform)
    id("primitive.kmp.skie")
}

kotlin {
    listOf(
        iosArm64(),
        iosSimulatorArm64()
    ).forEach { iosTarget ->
        iosTarget.binaries.framework {
            baseName = "Shared"
            isStatic = true
            export(projects.kmpLibraries.feature)
        }
    }

    sourceSets {
        commonMain.dependencies {
            api(projects.kmpLibraries.feature)
        }
    }
}