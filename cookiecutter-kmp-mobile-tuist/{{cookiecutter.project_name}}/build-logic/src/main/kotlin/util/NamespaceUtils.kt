package util

internal fun getDefaultPackageName(moduleName: String): String {
    return "{{ cookiecutter.bundle_id_prefix }}.${moduleName.replace("-", "_")}"
}
