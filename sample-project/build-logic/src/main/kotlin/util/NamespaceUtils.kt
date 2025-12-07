package util

internal fun getDefaultPackageName(moduleName: String): String {
    return "kk.tuist.app.${moduleName.replace("-", "_")}"
}
