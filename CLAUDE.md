# CLAUDE.md

当資料は英語で記載しますが、特別事情がなければ出力は日本語にしてください。
This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a Cookiecutter-based template repository for generating Kotlin Multiplatform (KMP) + Tuist mobile projects. The repository contains:
- A reference implementation (`sample-project/`)
- A Cookiecutter template (`cookiecutter-kmp-mobile-tuist/`)
- A CLI wrapper script (`kmp-mobile-tuist`)

## Development Setup

```bash
# Install dependencies
mise install
mise run install

# Create a test project from template
mise run create

# Test the generated project
cd <generated-project-name>
mise install
./gradlew android-app:build
mise run ios-gen
```

## Architecture

### Template Generation Flow

1. **User Input** → Cookiecutter variables in `cookiecutter.json`
2. **Validation** → `hooks/pre_gen_project.py` validates project_name and bundle_id_prefix
3. **Template Rendering** → Jinja2 processes all files in `{{cookiecutter.project_name}}/`
4. **Post-Processing** → `hooks/post_gen_project.py` moves Kotlin package directories from placeholder (`kk/tuist/app`) to user-specified package path

### Key Template Variables

- `project_name`: Used for rootProject.name and derives resource package name
- `bundle_id_prefix`: Used for Android applicationId, iOS Bundle ID, and Kotlin package names
- `android_app_name` / `ios_app_name`: App display names (default to project_name)

**Important transformations:**
- `project_name` → lowercase with hyphens/spaces replaced by underscores for resource packages
  - Example: `"MyApp"` → `myapp.android_app.generated.resources`
- `bundle_id_prefix` → Used as-is for package declarations
  - Example: `"com.example.app"` → `package com.example.app`

### Build Logic Architecture (Gradle Convention Plugins)

The template uses Gradle Composite Build with convention plugins in `build-logic/`:

**Key Concept: Dynamic Package Naming**
- `NamespaceUtils.kt` provides `getDefaultPackageName(moduleName)`
- Returns `"${bundle_id_prefix}.${moduleName.replace("-", "_")}"`
- Used by primitive plugins to set `namespace` and Compose Resources `packageOfResClass`

**Primitive Plugins** (in `build-logic/src/main/kotlin/primitive/`):
- `kmp.gradle.kts`: Base KMP setup, sets Android namespace dynamically
- `kmp.compose.gradle.kts`: Compose Multiplatform setup
- `compose.resources.gradle.kts`: Configures Compose Resources with dynamic package naming
- `kmp.ios.gradle.kts`: iOS framework configuration
- `kmp.skie.gradle.kts`: SKIE (Swift-Kotlin Interface Enhancer)
- `metro.gradle.kts`: Metro bundler for React Native (if applicable)

**Convention Plugins** (in `build-logic/src/main/kotlin/convention/`):
- Compose primitive plugins to provide higher-level configurations

### Template File Modifications

When modifying template files, remember:

1. **Hard-coded values must be templated:**
   - Package declarations: `package {{ cookiecutter.bundle_id_prefix }}`
   - Import statements for generated resources use project name:
     ```kotlin
     import {{ cookiecutter.project_name|lower|replace('-', '_')|replace(' ', '_') }}.android_app.generated.resources.Res
     ```
   - iOS Bundle IDs: `{{ cookiecutter.bundle_id_prefix }}.{{ cookiecutter.ios_app_name }}`

2. **Keep sample-project in sync:** Changes to template structure should be reflected in `sample-project/` as the reference implementation

3. **Files that should NOT be rendered:** Listed in `_copy_without_render` (binary files, gradle wrapper)

## Common Commands

### Template Development

```bash
# Create test project (interactive)
./kmp-mobile-tuist create

# Create test project (non-interactive)
./kmp-mobile-tuist create \
  --project-name TestApp \
  --bundle-id com.test.app \
  --no-input
```

### Testing Generated Projects

```bash
# Build Android
./gradlew android-app:build

# Generate iOS project with Tuist
cd ios && tuist generate

# Clean all builds
./gradlew clean
```

### Maintaining sample-project

The `sample-project/` should remain buildable as a reference. When updating template:
1. Test changes in `sample-project/` first
2. Apply working changes to `cookiecutter-kmp-mobile-tuist/{{cookiecutter.project_name}}/`
3. Add appropriate Jinja2 template syntax

## Critical Template Rules

### Project Name Validation (pre_gen_project.py)
- Must start with a letter (a-z or A-Z)
- Can contain letters, numbers, hyphens (-), and underscores (_)
- Cannot start or end with hyphen/underscore
- Valid: `MyApp`, `my-app`, `kk_app`

### Bundle ID Validation
- Reverse domain format (e.g., `com.example.app`)
- Each segment starts with lowercase letter
- Only lowercase letters, numbers, underscores allowed

### Package Directory Migration (post_gen_project.py)

The hook automatically:
1. Moves `kk/tuist/app` → `{bundle_id_prefix_as_path}`
2. Cleans up empty parent directories hierarchically
3. Processes all Kotlin source sets: commonMain, androidMain, iosMain, *Test

## .gitignore Considerations

Template excludes build artifacts and generated files:
- `.gradle/`, `build/`, `.kotlin/`
- `local.properties`, `.idea/`
- Xcode: `*.xcodeproj`, `*.xcworkspace`, `Derived/`
- Tuist generates these, so they should never be committed in the template

## Troubleshooting

### "Unresolved reference" for Compose Resources
- Ensure import uses project name (lowercase, underscore-separated):
  ```kotlin
  import {{ cookiecutter.project_name|lower|replace('-', '_') }}.android_app.generated.resources.Res
  ```
- NOT the bundle_id_prefix

### Empty kk/tuist/app directories remain after generation
- Check `post_gen_project.py` cleanup logic
- Verify the hierarchical directory removal works from deepest to shallowest

### Template rendering errors with Jinja2 extensions
- Avoid using external Jinja2 extensions (like `jinja2_time`)
- Use only built-in filters: `lower`, `replace`, `upper`, etc.
