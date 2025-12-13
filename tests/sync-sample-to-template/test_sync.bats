#!/usr/bin/env bats
#
# Basic tests for sync-sample-to-template.sh
#
# Requirements: bats-core (https://github.com/bats-core/bats-core)
# Run with: bats tests/sync-sample-to-template/test_sync.bats

setup() {
    # Get repository root
    export REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    export SCRIPT="$REPO_ROOT/scripts/sync-sample-to-template.sh"

    # Create temporary test directory
    export TEST_DIR="$(mktemp -d)"
    export TEST_SAMPLE="$TEST_DIR/sample-project"
    export TEST_TEMPLATE="$TEST_DIR/cookiecutter-kmp-mobile-tuist/{{cookiecutter.project_name}}"

    # Initialize git repo in test directory
    cd "$TEST_DIR"
    git init
    git config user.name "Test User" || { echo "ERROR: git config user.name failed" >&2; exit 1; }
    git config user.email "test@example.com" || { echo "ERROR: git config user.email failed" >&2; exit 1; }

    # Create sample structure
    mkdir -p "$TEST_SAMPLE"
    mkdir -p "$TEST_TEMPLATE"
}

teardown() {
    # Clean up test directory
    if [[ -n "$TEST_DIR" ]] && [[ -d "$TEST_DIR" ]]; then
        rm -rf "$TEST_DIR"
    fi
}

@test "Script exists and is executable" {
    [ -x "$SCRIPT" ]
}

@test "Script shows help with --help" {
    run "$SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "使用方法" ]]
}

@test "Script exits cleanly with no changes" {
    cd "$TEST_DIR"

    # Create initial commit
    echo "test" > "$TEST_SAMPLE/README.md"
    git add .
    git commit -m "Initial commit"

    # Run sync script (should find no changes)
    run "$SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "No changes detected" ]]
}

@test "Path mapping works correctly" {
    # This test verifies the map_path function logic
    # We'll do this by checking actual sync behavior

    cd "$TEST_DIR"

    # Create initial commit
    echo "initial" > "$TEST_SAMPLE/test.txt"
    git add .
    git commit -m "Initial commit"

    # Create a change
    echo "modified" > "$TEST_SAMPLE/test.txt"
    git add .
    git commit -m "Modify test file"

    # Run sync
    run "$SCRIPT"
    [ "$status" -eq 0 ]

    # Check that file was synced to correct location
    [ -f "$TEST_TEMPLATE/test.txt" ]
    [ "$(cat "$TEST_TEMPLATE/test.txt")" = "modified" ]
}

@test "Jinja2 variable detection protects template files" {
    cd "$TEST_DIR"

    # Create destination file with Jinja2 variables
    mkdir -p "$(dirname "$TEST_TEMPLATE/protected.txt")"
    echo "Value: {{ cookiecutter.project_name }}" > "$TEST_TEMPLATE/protected.txt"

    # Create source file
    echo "initial" > "$TEST_SAMPLE/protected.txt"
    git add .
    git commit -m "Initial commit"

    # Modify source file
    echo "This should not overwrite template" > "$TEST_SAMPLE/protected.txt"
    git add .
    git commit -m "Modify protected file"

    # Run sync
    run "$SCRIPT"
    [ "$status" -eq 0 ]

    # Template file should still contain Jinja2 variable
    [[ "$(cat "$TEST_TEMPLATE/protected.txt")" =~ "cookiecutter.project_name" ]]

    # Output should mention skip
    [[ "$output" =~ "SKIP" ]]
    [[ "$output" =~ "Jinja2" ]]
}

@test "Dry-run mode does not modify files" {
    cd "$TEST_DIR"

    # Create initial commit
    echo "initial" > "$TEST_SAMPLE/dryrun.txt"
    git add .
    git commit -m "Initial commit"

    # Create a change
    echo "modified" > "$TEST_SAMPLE/dryrun.txt"
    git add .
    git commit -m "Modify file"

    # Run sync in dry-run mode
    run "$SCRIPT" --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" =~ "DRY RUN" ]]
    [[ "$output" =~ "WOULD" ]]

    # File should NOT exist in template
    [ ! -f "$TEST_TEMPLATE/dryrun.txt" ]
}

@test "Binary files are copied correctly" {
    cd "$TEST_DIR"

    # Create a binary file (small PNG-like structure)
    printf '\x89PNG\r\n\x1a\n' > "$TEST_SAMPLE/image.png"
    git add .
    git commit -m "Initial commit"

    # Modify binary file
    printf '\x89PNG\r\n\x1a\n\x00\x00\x00\x01' > "$TEST_SAMPLE/image.png"
    git add .
    git commit -m "Modify binary"

    # Run sync
    run "$SCRIPT"
    [ "$status" -eq 0 ]

    # File should exist and be identical
    [ -f "$TEST_TEMPLATE/image.png" ]
    cmp -s "$TEST_SAMPLE/image.png" "$TEST_TEMPLATE/image.png"
}

@test "File deletion is synced" {
    cd "$TEST_DIR"

    # Create file and commit
    echo "content" > "$TEST_SAMPLE/delete-me.txt"
    git add .
    git commit -m "Initial commit"

    # Sync it once
    "$SCRIPT" > /dev/null

    # Verify it exists in template
    [ -f "$TEST_TEMPLATE/delete-me.txt" ]

    # Delete the file
    git rm "$TEST_SAMPLE/delete-me.txt"
    git commit -m "Delete file"

    # Run sync again
    run "$SCRIPT"
    [ "$status" -eq 0 ]

    # File should be deleted from template
    [ ! -f "$TEST_TEMPLATE/delete-me.txt" ]
    [[ "$output" =~ "DELETED" ]]
}

@test "Multiple files are processed" {
    cd "$TEST_DIR"

    # Create multiple files
    echo "file1" > "$TEST_SAMPLE/file1.txt"
    echo "file2" > "$TEST_SAMPLE/file2.txt"
    echo "file3" > "$TEST_SAMPLE/file3.txt"
    git add .
    git commit -m "Initial commit"

    # Modify all
    echo "modified1" > "$TEST_SAMPLE/file1.txt"
    echo "modified2" > "$TEST_SAMPLE/file2.txt"
    echo "modified3" > "$TEST_SAMPLE/file3.txt"
    git add .
    git commit -m "Modify all files"

    # Run sync
    run "$SCRIPT"
    [ "$status" -eq 0 ]

    # All files should be synced
    [ -f "$TEST_TEMPLATE/file1.txt" ]
    [ -f "$TEST_TEMPLATE/file2.txt" ]
    [ -f "$TEST_TEMPLATE/file3.txt" ]

    # Output should show correct count
    [[ "$output" =~ "3 files" ]]
    [[ "$output" =~ "Success:.*3" ]]
}

@test "Verbose mode produces detailed output" {
    cd "$TEST_DIR"

    # Create and modify a file
    echo "initial" > "$TEST_SAMPLE/verbose.txt"
    git add .
    git commit -m "Initial commit"

    echo "modified" > "$TEST_SAMPLE/verbose.txt"
    git add .
    git commit -m "Modify file"

    # Run with --verbose
    run "$SCRIPT" --verbose
    [ "$status" -eq 0 ]

    # Should contain verbose markers
    [[ "$output" =~ "verbose" ]]
    [[ "$output" =~ "Processing:" ]]
}

@test "Custom commit range works" {
    cd "$TEST_DIR"

    # Create initial commit
    echo "v1" > "$TEST_SAMPLE/range.txt"
    git add .
    git commit -m "Commit 1"

    # Create second commit
    echo "v2" > "$TEST_SAMPLE/range.txt"
    git add .
    git commit -m "Commit 2"

    # Create third commit
    echo "v3" > "$TEST_SAMPLE/range.txt"
    git add .
    COMMIT3=$(git commit -m "Commit 3" && git rev-parse HEAD)

    # Sync only from commit 1 to commit 2 (not commit 3)
    run "$SCRIPT" --commit HEAD~2..HEAD~1
    [ "$status" -eq 0 ]

    # Template should have v2, not v3
    [ "$(cat "$TEST_TEMPLATE/range.txt")" = "v2" ]
}

@test "Inline marker (COOKIECUTTER_KEEP) protects single line" {
    cd "$TEST_DIR"

    # Create destination file with inline marker
    mkdir -p "$(dirname "$TEST_TEMPLATE/inline.txt")"
    cat > "$TEST_TEMPLATE/inline.txt" <<'EOF'
package {{ cookiecutter.bundle_id_prefix }} // COOKIECUTTER_KEEP
fun normalFunction() {
    println("Hello")
}
EOF

    # Create source file
    cat > "$TEST_SAMPLE/inline.txt" <<'EOF'
package com.example.app
fun normalFunction() {
    println("World")
}
EOF
    git add .
    git commit -m "Initial commit"

    # Modify source file
    cat > "$TEST_SAMPLE/inline.txt" <<'EOF'
package com.example.app
fun normalFunction() {
    println("Modified!")
}
EOF
    git add .
    git commit -m "Modify file"

    # Run sync
    run "$SCRIPT"
    [ "$status" -eq 0 ]

    # First line should still have Jinja2 variable (protected)
    head -n 1 "$TEST_TEMPLATE/inline.txt" | grep -q "cookiecutter.bundle_id_prefix"

    # Second line should be updated from source
    sed -n '2p' "$TEST_TEMPLATE/inline.txt" | grep -q "normalFunction"

    # Third line should be updated
    grep -q "Modified!" "$TEST_TEMPLATE/inline.txt"

    # Output should mention merge
    [[ "$output" =~ "MERGE" ]]
}

@test "Section markers (COOKIECUTTER_PROTECTED_START/END) protect multiple lines" {
    cd "$TEST_DIR"

    # Create destination file with section markers
    mkdir -p "$(dirname "$TEST_TEMPLATE/section.kt")"
    cat > "$TEST_TEMPLATE/section.kt" <<'EOF'
// COOKIECUTTER_PROTECTED_START
package {{ cookiecutter.bundle_id_prefix }}
import {{ cookiecutter.project_name|lower }}.generated.resources.Res
// COOKIECUTTER_PROTECTED_END

fun myFunction() {
    println("Original")
}
EOF

    # Create source file
    cat > "$TEST_SAMPLE/section.kt" <<'EOF'
package com.example.app
import com.example.app.generated.resources.Res

fun myFunction() {
    println("Modified")
}
EOF
    git add .
    git commit -m "Initial commit"

    # Modify source file
    cat > "$TEST_SAMPLE/section.kt" <<'EOF'
package com.example.app
import com.example.app.generated.resources.Res

fun myFunction() {
    println("Updated!")
}
EOF
    git add .
    git commit -m "Modify file"

    # Run sync
    run "$SCRIPT"
    [ "$status" -eq 0 ]

    # Protected section should still have Jinja2 variables
    grep -q "cookiecutter.bundle_id_prefix" "$TEST_TEMPLATE/section.kt"
    grep -q "cookiecutter.project_name" "$TEST_TEMPLATE/section.kt"

    # Function should be updated from source
    grep -q "Updated!" "$TEST_TEMPLATE/section.kt"

    # Output should mention merge
    [[ "$output" =~ "MERGE" ]]
}

@test "Markers work in dry-run mode" {
    cd "$TEST_DIR"

    # Create destination file with markers
    mkdir -p "$(dirname "$TEST_TEMPLATE/marker-dry.txt")"
    echo "package {{ cookiecutter.bundle_id_prefix }} // COOKIECUTTER_KEEP" > "$TEST_TEMPLATE/marker-dry.txt"

    # Create and modify source
    echo "package com.example.app" > "$TEST_SAMPLE/marker-dry.txt"
    git add .
    git commit -m "Initial commit"

    echo "package com.example.updated" > "$TEST_SAMPLE/marker-dry.txt"
    git add .
    git commit -m "Modify file"

    # Run in dry-run mode
    run "$SCRIPT" --dry-run
    [ "$status" -eq 0 ]

    # Output should show would merge
    [[ "$output" =~ "WOULD MERGE" ]]

    # Template should be unchanged
    grep -q "cookiecutter.bundle_id_prefix" "$TEST_TEMPLATE/marker-dry.txt"
}

@test "Mixed markers and regular Jinja2 - markers take precedence" {
    cd "$TEST_DIR"

    # Create file with both markers and regular Jinja2
    mkdir -p "$(dirname "$TEST_TEMPLATE/mixed.txt")"
    cat > "$TEST_TEMPLATE/mixed.txt" <<'EOF'
package {{ cookiecutter.bundle_id_prefix }} // COOKIECUTTER_KEEP
fun test() {
    val name = "{{ cookiecutter.project_name }}"
}
EOF

    # Create source
    cat > "$TEST_SAMPLE/mixed.txt" <<'EOF'
package com.example.app
fun test() {
    val name = "MyProject"
}
EOF
    git add .
    git commit -m "Initial commit"

    # Modify source
    cat > "$TEST_SAMPLE/mixed.txt" <<'EOF'
package com.example.app
fun test() {
    val name = "UpdatedProject"
}
EOF
    git add .
    git commit -m "Modify file"

    # Run sync
    run "$SCRIPT"
    [ "$status" -eq 0 ]

    # First line protected by marker
    head -n 1 "$TEST_TEMPLATE/mixed.txt" | grep -q "cookiecutter.bundle_id_prefix"

    # Lines without markers should be updated
    grep -q "UpdatedProject" "$TEST_TEMPLATE/mixed.txt"

    # Should use merge, not skip
    [[ "$output" =~ "MERGE" ]]
}

@test "Nested protected sections are handled correctly" {
    cd "$TEST_DIR"

    # Create file with nested markers (should not be nested, but test handling)
    mkdir -p "$(dirname "$TEST_TEMPLATE/nested.txt")"
    cat > "$TEST_TEMPLATE/nested.txt" <<'EOF'
// COOKIECUTTER_PROTECTED_START
line1: {{ cookiecutter.var1 }}
// COOKIECUTTER_PROTECTED_START
line2: {{ cookiecutter.var2 }}
// COOKIECUTTER_PROTECTED_END
line3: {{ cookiecutter.var3 }}
// COOKIECUTTER_PROTECTED_END
line4: normal
EOF

    # Create source
    cat > "$TEST_SAMPLE/nested.txt" <<'EOF'
line1: updated1
line2: updated2
line3: updated3
line4: updated4
EOF
    git add .
    git commit -m "Initial commit"

    echo "modified" > "$TEST_SAMPLE/nested.txt"
    git add .
    git commit -m "Modify file"

    # Run sync - should not crash
    run "$SCRIPT"
    [ "$status" -eq 0 ]

    # All protected lines should remain
    grep -q "cookiecutter.var1" "$TEST_TEMPLATE/nested.txt"
}

@test "Source longer than destination with markers" {
    cd "$TEST_DIR"

    # Create short destination with marker
    mkdir -p "$(dirname "$TEST_TEMPLATE/longer.txt")"
    cat > "$TEST_TEMPLATE/longer.txt" <<'EOF'
line1: {{ cookiecutter.var }} // COOKIECUTTER_KEEP
line2: original
EOF

    # Create longer source
    cat > "$TEST_SAMPLE/longer.txt" <<'EOF'
line1: source
line2: updated
line3: new
line4: more
EOF
    git add .
    git commit -m "Initial commit"

    # Modify to make it even longer
    cat > "$TEST_SAMPLE/longer.txt" <<'EOF'
line1: source
line2: updated
line3: new
line4: more
line5: extra
EOF
    git add .
    git commit -m "Modify file"

    # Run sync
    run "$SCRIPT"
    [ "$status" -eq 0 ]

    # First line should be protected
    head -n 1 "$TEST_TEMPLATE/longer.txt" | grep -q "cookiecutter.var"

    # Additional lines should be appended
    grep -q "line5: extra" "$TEST_TEMPLATE/longer.txt"
}
