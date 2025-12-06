plugins {
    alias(libs.plugins.kotlinMultiplatform)
}

kotlin {
    listOf(
        iosArm64(),
        iosSimulatorArm64()
    ).forEach { iosTarget ->
        iosTarget.binaries.framework {
            baseName = "Shared"
            isStatic = true
            export(projects.kmpLibraries.dataA)
        }
    }

    sourceSets {
        commonMain.dependencies {
            api(projects.kmpLibraries.dataA)
        }
    }
}