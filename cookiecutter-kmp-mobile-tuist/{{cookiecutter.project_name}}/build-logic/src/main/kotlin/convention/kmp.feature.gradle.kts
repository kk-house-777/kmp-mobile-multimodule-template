package convention

plugins {
    id("primitive.kmp")
    id("primitive.kmp.ios")
    id("primitive.kmp.compose")
    id("primitive.compose.resources")
    id("primitive.metro")
}

kotlin {
    sourceSets {
        commonMain.dependencies {

        }

        commonTest.dependencies {
        }
    }
}
