# Implementation Tasks: Sample Project to Template Synchronization

**Feature**: #001-sample-to-template-sync
**Created**: 2025-12-07
**Dependencies**: [spec.md](./spec.md), [plan.md](./plan.md)

## Task Organization

Tasks are organized by phase and user story priority. Tasks marked with `[P]` can be executed in parallel with other `[P]` tasks in the same phase.

---

## Phase 1: Setup & Foundation

### TASK-001: [P] Project structure initialization
**Story**: Setup | **Priority**: P0 | **Estimated Effort**: 15min
**Files**: `scripts/`, `tests/sync-sample-to-template/`

Create the base directory structure for the synchronization system.

**Acceptance Criteria**:
- [ ] `scripts/` directory exists
- [ ] `tests/sync-sample-to-template/` directory exists
- [ ] Directories are committed to git

---

### TASK-002: Path mapping logic
**Story**: US1 | **Priority**: P1 | **Estimated Effort**: 30min
**Files**: `scripts/sync-sample-to-template.sh`
**Dependencies**: TASK-001

Implement the path mapping function that converts sample-project paths to template paths.

**Implementation Details**:
```bash
map_path() {
    local src_path="$1"
    # sample-project/foo/bar.kt → cookiecutter-kmp-mobile-tuist/{{cookiecutter.project_name}}/foo/bar.kt
    echo "${src_path/sample-project/cookiecutter-kmp-mobile-tuist\/{{cookiecutter.project_name\}\}}"
}
```

**Acceptance Criteria**:
- [ ] Function correctly maps sample-project root to template root
- [ ] Preserves subdirectory structure
- [ ] Handles edge cases (paths with spaces, special characters)

---

### TASK-003: Jinja2 variable detection
**Story**: US1, US2 | **Priority**: P1 | **Estimated Effort**: 30min
**Files**: `scripts/sync-sample-to-template.sh`
**Dependencies**: TASK-001

Implement detection of Jinja2 template variables in files.

**Implementation Details**:
```bash
has_jinja2_vars() {
    local file="$1"
    grep -qE '\{\{|\{%|\{#' "$file" 2>/dev/null
}
```

**Acceptance Criteria**:
- [ ] Detects `{{ cookiecutter.* }}` patterns
- [ ] Detects `{% ... %}` patterns
- [ ] Detects `{# ... #}` comment patterns
- [ ] Returns false for binary files
- [ ] Returns false for files without Jinja2 syntax

---

## Phase 2: Core Synchronization (US1 - P1)

### TASK-004: Git diff analysis
**Story**: US1 | **Priority**: P1 | **Estimated Effort**: 45min
**Files**: `scripts/sync-sample-to-template.sh`
**Dependencies**: TASK-001

Implement Git-based change detection for sample-project files.

**Implementation Details**:
- Use `git diff --name-status` to detect added/modified/deleted files
- Filter for files under `sample-project/` directory
- Support `--commit` option to specify commit range

**Acceptance Criteria**:
- [ ] Detects added files (status: A)
- [ ] Detects modified files (status: M)
- [ ] Detects deleted files (status: D)
- [ ] Filters to `sample-project/**` only
- [ ] Supports custom commit range via `--commit` option

---

### TASK-005: File synchronization logic
**Story**: US1 | **Priority**: P1 | **Estimated Effort**: 1h
**Files**: `scripts/sync-sample-to-template.sh`
**Dependencies**: TASK-002, TASK-003, TASK-004

Implement the core file synchronization logic with Jinja2 protection.

**Implementation Details**:
```bash
sync_file() {
    local src="$1"
    local change_type="$2"
    local dst=$(map_path "$src")

    # Check if destination has Jinja2 vars
    if [[ -f "$dst" ]] && has_jinja2_vars "$dst"; then
        echo "⊘ SKIP: $src (destination contains Jinja2 variables)"
        return 1
    fi

    case "$change_type" in
        A|M) cp -f "$src" "$dst" ;;
        D) rm -f "$dst" ;;
    esac
}
```

**Acceptance Criteria**:
- [ ] Copies added files (A) to template
- [ ] Copies modified files (M) to template
- [ ] Deletes removed files (D) from template
- [ ] Skips files where destination contains Jinja2 variables
- [ ] Creates parent directories as needed
- [ ] Preserves binary files correctly

---

### TASK-006: Sync report generation
**Story**: US1 | **Priority**: P1 | **Estimated Effort**: 30min
**Files**: `scripts/sync-sample-to-template.sh`
**Dependencies**: TASK-005

Generate a summary report of synchronization results.

**Output Format**:
```
[sync-template] Summary:
  Total:    12 files
  Success:  10 files
  Skipped:  2 files (Jinja2 variables detected)
  Failed:   0 files
```

**Acceptance Criteria**:
- [ ] Counts total changed files
- [ ] Counts successfully synced files
- [ ] Counts skipped files with reasons
- [ ] Counts failed files with error messages
- [ ] Outputs human-readable summary

---

### TASK-007: CLI argument parsing
**Story**: US1 | **Priority**: P1 | **Estimated Effort**: 30min
**Files**: `scripts/sync-sample-to-template.sh`
**Dependencies**: TASK-001

Implement CLI argument parsing for script options.

**Supported Options**:
- `--dry-run`: Show what would be synced without making changes
- `--commit HASH`: Specify commit range for change detection
- `--verbose`: Enable detailed logging
- `--help`: Display usage information

**Acceptance Criteria**:
- [ ] Parses all supported options correctly
- [ ] Displays help text with `--help`
- [ ] Validates option values
- [ ] Sets appropriate flags for each option

---

### TASK-008: Script header and error handling
**Story**: US1 | **Priority**: P1 | **Estimated Effort**: 20min
**Files**: `scripts/sync-sample-to-template.sh`
**Dependencies**: TASK-001

Add robust error handling and script setup.

**Implementation**:
```bash
#!/usr/bin/env bash
set -euo pipefail

# Trap errors
trap 'echo "[ERROR] Script failed at line $LINENO"' ERR
```

**Acceptance Criteria**:
- [ ] Script has proper shebang
- [ ] Enables strict mode (`set -euo pipefail`)
- [ ] Traps and reports errors with line numbers
- [ ] Exits with appropriate exit codes (0=success, 1=partial failure, 2=error)

---

## Phase 3: Validation & Safety (US2 - P2)

### TASK-009: Dry-run mode implementation
**Story**: US2 | **Priority**: P2 | **Estimated Effort**: 30min
**Files**: `scripts/sync-sample-to-template.sh`
**Dependencies**: TASK-007, TASK-005

Implement dry-run mode that shows changes without applying them.

**Output Example**:
```
[sync-template] DRY RUN MODE - No files will be modified
[sync-template] Would sync:
  ✓ android-app/build.gradle.kts
[sync-template] Would skip:
  ⊘ settings.gradle.kts (contains Jinja2 variables)
```

**Acceptance Criteria**:
- [ ] `--dry-run` flag prevents all file modifications
- [ ] Shows list of files that would be synced
- [ ] Shows list of files that would be skipped with reasons
- [ ] Exit code reflects what would happen (0=success, 1=would have failures)

---

### TASK-010: Verbose logging
**Story**: US2 | **Priority**: P2 | **Estimated Effort**: 20min
**Files**: `scripts/sync-sample-to-template.sh`
**Dependencies**: TASK-007

Add detailed logging when `--verbose` flag is used.

**Acceptance Criteria**:
- [ ] Logs each file being processed
- [ ] Logs path mapping results
- [ ] Logs Jinja2 detection results
- [ ] Logs file operation success/failure
- [ ] Only enabled when `--verbose` is set

---

### TASK-011: Detailed skip reporting
**Story**: US2 | **Priority**: P2 | **Estimated Effort**: 30min
**Files**: `scripts/sync-sample-to-template.sh`
**Dependencies**: TASK-006

Enhance skip reporting with detailed reasons and affected lines.

**Example Output**:
```
⊘ SKIP: sample-project/settings.gradle.kts
  Reason: Contains Jinja2 variables
  Lines: 5, 12, 23 ({{ cookiecutter.project_name }})
```

**Acceptance Criteria**:
- [ ] Shows file path being skipped
- [ ] Shows reason for skip
- [ ] Optionally shows line numbers with Jinja2 patterns (in verbose mode)

---

## Phase 4: GitHub Actions Integration (US3 - P3)

### TASK-012: [P] GitHub Actions workflow file
**Story**: US3 | **Priority**: P3 | **Estimated Effort**: 45min
**Files**: `.github/workflows/sync-template.yml`
**Dependencies**: TASK-008 (script must be functional)

Create GitHub Actions workflow for automatic synchronization.

**Workflow Specification**:
```yaml
name: Sync Sample to Template
on:
  push:
    branches: [main]
    paths: ['sample-project/**']
jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: ./scripts/sync-sample-to-template.sh
      - run: git add .
      - run: git commit -m "chore: sync sample-project changes to template"
      - run: git push
```

**Acceptance Criteria**:
- [ ] Triggers on push to main branch
- [ ] Only runs when `sample-project/**` files change
- [ ] Checks out repository
- [ ] Runs sync script
- [ ] Commits changes if any
- [ ] Pushes to main branch

---

### TASK-013: Auto-commit logic
**Story**: US3 | **Priority**: P3 | **Estimated Effort**: 30min
**Files**: `.github/workflows/sync-template.yml`
**Dependencies**: TASK-012

Implement automatic commit and push of synchronized changes.

**Implementation**:
- Configure git user for automated commits
- Check if there are changes to commit (`git diff --quiet`)
- Create commit with descriptive message
- Push to main branch using `GITHUB_TOKEN`

**Acceptance Criteria**:
- [ ] Configures git user.name and user.email
- [ ] Only commits when changes exist
- [ ] Commit message includes sync context
- [ ] Uses `GITHUB_TOKEN` for authentication
- [ ] Handles push failures gracefully

---

### TASK-014: Workflow failure notifications
**Story**: US3 | **Priority**: P3 | **Estimated Effort**: 20min
**Files**: `.github/workflows/sync-template.yml`
**Dependencies**: TASK-012

Configure failure notifications for the workflow.

**Acceptance Criteria**:
- [ ] Workflow fails if sync script exits with error
- [ ] Failure triggers GitHub's default notification
- [ ] Workflow summary shows failure reason
- [ ] Failed runs are easily identifiable in Actions tab

---

## Phase 5: Testing & Documentation

### TASK-015: [P] Basic sync test (bats)
**Story**: Testing | **Priority**: P1 | **Estimated Effort**: 1h
**Files**: `tests/sync-sample-to-template/test_sync.bats`
**Dependencies**: TASK-008

Create bats tests for core synchronization functionality.

**Test Cases**:
- File addition sync
- File modification sync
- File deletion sync
- Jinja2 variable detection
- Path mapping
- Dry-run mode

**Acceptance Criteria**:
- [ ] Tests run with `bats tests/sync-sample-to-template/test_sync.bats`
- [ ] All test cases pass
- [ ] Tests are reproducible and isolated

---

### TASK-016: [P] Template generation validation test
**Story**: Testing | **Priority**: P2 | **Estimated Effort**: 45min
**Files**: `tests/sync-sample-to-template/test_template_generation.sh`
**Dependencies**: TASK-008

Create end-to-end test that validates template can still be generated.

**Test Flow**:
1. Run sync script
2. Generate a test project from template using cookiecutter
3. Verify generated project builds successfully

**Acceptance Criteria**:
- [ ] Test generates project from template
- [ ] Verifies no Jinja2 syntax errors
- [ ] Can be run manually for validation
- [ ] Exits with non-zero on failure

---

### TASK-017: [P] Quickstart documentation
**Story**: Documentation | **Priority**: P2 | **Estimated Effort**: 30min
**Files**: `specs/001-sample-to-template-sync/quickstart.md`
**Dependencies**: TASK-008

Write user-facing documentation for the sync tool.

**Content**:
- Installation (if any)
- Basic usage examples
- Option descriptions
- Common workflows
- Troubleshooting

**Acceptance Criteria**:
- [ ] Document covers all CLI options
- [ ] Includes practical examples
- [ ] Explains Jinja2 protection behavior
- [ ] Written in Japanese (per CLAUDE.md)

---

### TASK-018: [P] Update main README
**Story**: Documentation | **Priority**: P3 | **Estimated Effort**: 15min
**Files**: `README.md` (if exists at repository root)
**Dependencies**: TASK-017

Add a section to the main README about the sync tool.

**Acceptance Criteria**:
- [ ] Mentions sync tool existence
- [ ] Links to quickstart documentation
- [ ] Briefly explains its purpose

---

## Phase 6: Edge Cases & Polish

### TASK-019: Binary file handling
**Story**: Edge Cases | **Priority**: P2 | **Estimated Effort**: 30min
**Files**: `scripts/sync-sample-to-template.sh`
**Dependencies**: TASK-005

Ensure binary files (images, JARs) are handled correctly.

**Implementation**:
- Use `cp` which is binary-safe
- Skip Jinja2 detection for binary files (grep will fail gracefully)

**Acceptance Criteria**:
- [ ] Binary files are copied correctly
- [ ] No corruption occurs
- [ ] Jinja2 detection doesn't error on binary files

---

### TASK-020: Symbolic link handling
**Story**: Edge Cases | **Priority**: P3 | **Estimated Effort**: 20min
**Files**: `scripts/sync-sample-to-template.sh`
**Dependencies**: TASK-005

Handle symbolic links appropriately.

**Decision**: Document that symlinks are dereferenced (copied as files) or preserved.

**Acceptance Criteria**:
- [ ] Behavior with symlinks is documented
- [ ] No errors when encountering symlinks

---

### TASK-021: File permission preservation
**Story**: Edge Cases | **Priority**: P3 | **Estimated Effort**: 15min
**Files**: `scripts/sync-sample-to-template.sh`
**Dependencies**: TASK-005

Preserve executable permissions when syncing files.

**Implementation**:
- Use `cp -p` to preserve permissions

**Acceptance Criteria**:
- [ ] Executable files remain executable after sync
- [ ] Permissions are preserved

---

### TASK-022: .gitignore and excluded files
**Story**: Edge Cases | **Priority**: P2 | **Estimated Effort**: 30min
**Files**: `scripts/sync-sample-to-template.sh`
**Dependencies**: TASK-004

Respect .gitignore patterns and exclude certain files from sync.

**Excluded Patterns**:
- `build/`, `.gradle/`, `.idea/`
- `*.iml`, `local.properties`
- Generated Xcode projects

**Acceptance Criteria**:
- [ ] Build artifacts are not synced
- [ ] IDE-specific files are not synced
- [ ] Only source files are synchronized

---

### TASK-023: Performance optimization
**Story**: Performance | **Priority**: P3 | **Estimated Effort**: 30min
**Files**: `scripts/sync-sample-to-template.sh`
**Dependencies**: TASK-008

Optimize for performance with large file sets.

**Optimizations**:
- Batch file operations where possible
- Avoid redundant checks
- Use efficient git commands

**Acceptance Criteria**:
- [ ] Sync completes in under 1 minute for typical changes
- [ ] Scales to 500 files (meets SC-003)

---

### TASK-024: Error recovery
**Story**: Robustness | **Priority**: P2 | **Estimated Effort**: 30min
**Files**: `scripts/sync-sample-to-template.sh`
**Dependencies**: TASK-008

Handle partial failures gracefully.

**Implementation**:
- Continue syncing other files even if one fails
- Report all failures at the end
- Exit with appropriate code (1 for partial failure)

**Acceptance Criteria**:
- [ ] Script continues after individual file failure
- [ ] All failures are reported in summary
- [ ] Exit code reflects partial vs complete failure

---

### TASK-025: Code cleanup and comments
**Story**: Code Quality | **Priority**: P3 | **Estimated Effort**: 30min
**Files**: `scripts/sync-sample-to-template.sh`
**Dependencies**: All implementation tasks

Add comprehensive comments and clean up code.

**Acceptance Criteria**:
- [ ] All functions have comment headers
- [ ] Complex logic has inline comments
- [ ] Script follows consistent style
- [ ] No redundant or dead code

---

## Summary

**Total Tasks**: 25
**Phases**: 6
**Estimated Total Effort**: ~12-15 hours

**Critical Path** (MVP):
1. TASK-001 (Setup)
2. TASK-002, TASK-003 (Path mapping, Jinja2 detection) - Can be parallel
3. TASK-004 (Git diff)
4. TASK-005 (Sync logic)
5. TASK-006, TASK-007, TASK-008 (Reporting, CLI, Error handling) - Can be parallel
6. TASK-015 (Testing)

**Priority Execution Order**:
- Phase 1 (Setup) → Phase 2 (US1-P1) → Phase 3 (US2-P2) → Phase 4 (US3-P3)
- Testing and documentation can be done in parallel with implementation

**Parallel Execution Groups**:
- TASK-001, TASK-015, TASK-016, TASK-017, TASK-018 (different concerns, no shared files)
- TASK-002, TASK-003 (different functions in same file, but independent logic)
- TASK-006, TASK-007 (different parts of same script)
