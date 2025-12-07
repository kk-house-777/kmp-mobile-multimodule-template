package primitive

import util.commonMainImplementation

plugins {
    id("org.jetbrains.compose")
    id("org.jetbrains.kotlin.plugin.compose")
}

dependencies {
    commonMainImplementation(compose.ui)
    commonMainImplementation(compose.components.uiToolingPreview)
    commonMainImplementation(compose.materialIconsExtended)
}

dependencies {
    add("debugImplementation", compose.uiTooling)
}
