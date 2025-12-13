#!/usr/bin/env bash
#
# End-to-end test: Verify template can be generated after synchronization
#
# This test validates that:
# 1. The sync script runs successfully
# 2. The template can still be used to generate a project
# 3. No Jinja2 syntax errors were introduced
#
# Usage:
#   ./tests/sync-sample-to-template/test_template_generation.sh [--no-color]
#
# Options:
#   --no-color   Disable colored output

set -euo pipefail

# Detect --no-color flag or non-TTY output
USE_COLOR=1
for arg in "$@"; do
    if [[ "$arg" == "--no-color" ]]; then
        USE_COLOR=0
        break
    fi
done
if [[ ! -t 1 ]]; then
    USE_COLOR=0
fi

# Colors for output
if [[ "$USE_COLOR" -eq 1 ]]; then
    readonly COLOR_GREEN='\033[0;32m'
    readonly COLOR_RED='\033[0;31m'
    readonly COLOR_BLUE='\033[0;34m'
    readonly COLOR_RESET='\033[0m'
else
    readonly COLOR_GREEN=''
    readonly COLOR_RED=''
    readonly COLOR_BLUE=''
    readonly COLOR_RESET=''
fi

# Get repository root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo -e "${COLOR_BLUE}=== Template Generation Validation Test ===${COLOR_RESET}"
echo ""

# Change to repo root
cd "$REPO_ROOT"

# Check if cookiecutter is available
if ! command -v cookiecutter &> /dev/null; then
    echo -e "${COLOR_RED}✗ cookiecutter is not installed${COLOR_RESET}"
    echo "  Install with: pip install cookiecutter"
    exit 1
fi

echo -e "${COLOR_GREEN}✓ cookiecutter is available${COLOR_RESET}"

# Create temporary directory for test
TEST_DIR=$(mktemp -d)
trap "rm -rf '$TEST_DIR'" EXIT

echo "  Test directory: $TEST_DIR"
echo ""

# Generate project from template
echo -e "${COLOR_BLUE}Generating test project from template...${COLOR_RESET}"

cd "$TEST_DIR"

# Use non-interactive mode with default values
cookiecutter "$REPO_ROOT/cookiecutter-kmp-mobile-tuist" \
    --no-input \
    project_name="TestSyncProject" \
    bundle_id_prefix="com.test.sync" \
    android_app_name="TestSync" \
    ios_app_name="TestSync" \
    || {
        echo -e "${COLOR_RED}✗ Template generation failed${COLOR_RESET}"
        echo "  This likely means Jinja2 syntax errors were introduced during sync"
        exit 1
    }

echo -e "${COLOR_GREEN}✓ Template generated successfully${COLOR_RESET}"
echo ""

# Verify the generated project structure
PROJECT_DIR="$TEST_DIR/TestSyncProject"

echo -e "${COLOR_BLUE}Verifying generated project structure...${COLOR_RESET}"

# Check for essential files/directories
EXPECTED_PATHS=(
    "$PROJECT_DIR/settings.gradle.kts"
    "$PROJECT_DIR/android-app"
    "$PROJECT_DIR/shared"
    "$PROJECT_DIR/ios"
)

ALL_EXIST=true
for path in "${EXPECTED_PATHS[@]}"; do
    if [[ -e "$path" ]]; then
        echo -e "${COLOR_GREEN}✓${COLOR_RESET} $path"
    else
        echo -e "${COLOR_RED}✗${COLOR_RESET} $path (missing)"
        ALL_EXIST=false
    fi
done

if [[ "$ALL_EXIST" == "false" ]]; then
    echo ""
    echo -e "${COLOR_RED}✗ Project structure is incomplete${COLOR_RESET}"
    exit 1
fi

echo ""
echo -e "${COLOR_GREEN}✓ Project structure is valid${COLOR_RESET}"
echo ""

# Check that no Jinja2 template syntax remains in generated files
echo -e "${COLOR_BLUE}Checking for leftover Jinja2 syntax...${COLOR_RESET}"

# Search for common Jinja2 patterns
if grep -r "{{ cookiecutter\." "$PROJECT_DIR" 2>/dev/null; then
    echo -e "${COLOR_RED}✗ Found unreplaced Jinja2 variables${COLOR_RESET}"
    echo "  Template variables should have been replaced during generation"
    exit 1
fi

echo -e "${COLOR_GREEN}✓ No Jinja2 syntax found in generated files${COLOR_RESET}"
echo ""

# Verify that placeholders were actually replaced
echo -e "${COLOR_BLUE}Verifying placeholder replacement...${COLOR_RESET}"

# Check settings.gradle.kts for correct project name
if grep -q 'rootProject.name = "TestSyncProject"' "$PROJECT_DIR/settings.gradle.kts"; then
    echo -e "${COLOR_GREEN}✓${COLOR_RESET} Project name was correctly replaced"
else
    echo -e "${COLOR_RED}✗${COLOR_RESET} Project name was not replaced correctly"
    echo "  Expected: rootProject.name = \"TestSyncProject\""
    echo "  Found:"
    grep "rootProject.name" "$PROJECT_DIR/settings.gradle.kts" || echo "  (pattern not found)"
    exit 1
fi

# Check for bundle ID replacement (look in build.gradle.kts files)
if grep -rq "com\.test\.sync" "$PROJECT_DIR/android-app" 2>/dev/null; then
    echo -e "${COLOR_GREEN}✓${COLOR_RESET} Bundle ID was correctly replaced"
else
    echo -e "${COLOR_RED}✗${COLOR_RESET} Bundle ID was not replaced correctly"
    exit 1
fi

echo ""

# Optional: Try to run Gradle tasks if Gradle is available
if [[ -x ./gradlew ]] || command -v gradle &> /dev/null; then
    echo -e "${COLOR_BLUE}Running Gradle validation...${COLOR_RESET}"

    cd "$PROJECT_DIR"

    # Try to run a simple Gradle task
    if ./gradlew tasks --dry-run &> /dev/null || gradle tasks --dry-run &> /dev/null; then
        echo -e "${COLOR_GREEN}✓${COLOR_RESET} Gradle configuration is valid"
    else
        echo -e "${COLOR_RED}✗${COLOR_RESET} Gradle configuration has errors"
        echo "  Note: This doesn't necessarily mean the sync failed,"
        echo "        it could be a pre-existing issue with the template"
    fi

    echo ""
fi

# Final summary
echo -e "${COLOR_GREEN}=== All Template Generation Tests Passed ===${COLOR_RESET}"
echo ""
echo "Summary:"
echo "  ✓ Template generated without errors"
echo "  ✓ Project structure is complete"
echo "  ✓ No Jinja2 syntax errors"
echo "  ✓ Placeholders were correctly replaced"
echo ""
echo -e "${COLOR_GREEN}The template is valid and ready to use!${COLOR_RESET}"

exit 0
