# kmp-multimodule-template

[日本語版README](./doc/README.ja.md)

Create a multimodule template application for iOS and Android using KMP (Kotlin Multiplatform).

## Requirements
- iOS project management is based on [Tuist](https://tuist.dev/)

## Installation

```bash
brew tap kk-house-777/tap
brew install kmp-mobile-multimodule-template
```

## Usage
### Quick Start
```bash
# Create a test project from template (interactive)
kmp-mobile-multimodule-template create

# Create a test project (non-interactive)
kmp-mobile-multimodule-template create \
  --project-name TestApp \
  --bundle-id com.test.app \
  --no-input

# Test the generated project
cd <generated-project-name>
mise install
./gradlew android-app:build
mise run ios-gen
```

### Show Help
```bash
kmp-mobile-multimodule-template --help
```

# Development

This is a Cookiecutter-based template repository for generating Kotlin Multiplatform (KMP) + Tuist mobile projects. The repository contains:
- A reference implementation (`sample-project/`)
- A Cookiecutter template (`cookiecutter-kmp-mobile-tuist/`)
- A CLI wrapper script (`kmp-mobile-tuist`)

## How It Works
```
% kmp-mobile-multimodule-template --help
kmp-mobile-multimodule-template - CLI tool for creating KMP + Tuist mobile projects

Usage:
  kmp-mobile-multimodule-template create [OPTIONS]

Commands:
  create              Create a new KMP + Tuist project from template
  --help, -h          Show this help message

Options for 'create':
  --project-name NAME         Project name (default: App)
  --bundle-id ID              Bundle ID prefix (default: com.example.app)
  --android-app-name NAME     Android app name (default: same as project-name)
  --ios-app-name NAME         iOS app name (default: same as project-name)
  --output-dir DIR            Output directory (default: current directory)
  --no-input                  Use default values without prompting

Examples:
  # Interactive mode
  kmp-mobile-multimodule-template create

  # With arguments
  kmp-mobile-multimodule-template create --project-name MyApp --bundle-id com.mycompany.myapp

  # Non-interactive mode
  kmp-mobile-multimodule-template create --project-name MyApp --bundle-id com.mycompany.myapp --no-input
```

## Syncing Changes from sample-project to cookiecutter-kmp-mobile-tuist

### ./scripts/sync-sample-to-template.sh --help
```
Usage: sync-sample-to-template.sh [OPTIONS]

Sync changes from sample-project to Cookiecutter template.
Protects Jinja2 template variables to prevent accidental overwrites.

Options:
  --dry-run          Display sync contents without making changes
  --commit HASH      Specify commit range for change detection (default: HEAD~1..HEAD)
  --working-tree     Sync uncommitted changes (working tree)
  --verbose          Output detailed logs
  --help             Display this help

Exit codes:
  0  Success (all files synced or dry-run)
  1  Partial failure (excluding skips)
  2  Complete failure or configuration error

Examples:
  # Sync changes from the latest commit
  ./scripts/sync-sample-to-template.sh

  # Dry run mode
  ./scripts/sync-sample-to-template.sh --dry-run

  # Specify a commit range
  ./scripts/sync-sample-to-template.sh --commit main..HEAD

  # Sync uncommitted changes
  ./scripts/sync-sample-to-template.sh --working-tree

  # Run with verbose logging
  ./scripts/sync-sample-to-template.sh --verbose
```

### GitHub Action
`.github/sync-sample-to-template.yml`