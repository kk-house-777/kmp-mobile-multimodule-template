#!/usr/bin/env bash
#
# sync-sample-to-template.sh
#
# Synchronizes changes from sample-project to the Cookiecutter template.
# Protects Jinja2 template variables from being overwritten.
#
# Usage:
#   ./scripts/sync-sample-to-template.sh [OPTIONS]
#
# Options:
#   --dry-run          Show what would be synced without making changes
#   --commit HASH      Specify commit range for change detection (default: HEAD~1..HEAD)
#   --verbose          Enable detailed logging
#   --help             Display this help message
#
# Exit Codes:
#   0  Success (all files synced or dry-run)
#   1  Partial failure (some files failed, excluding skips)
#   2  Complete failure or configuration error

set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
readonly SAMPLE_PROJECT_DIR="sample-project"
readonly TEMPLATE_DIR="cookiecutter-kmp-mobile-tuist/{{cookiecutter.project_name}}"

# ANSI color codes for output
readonly COLOR_RESET='\033[0m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[0;33m'
readonly COLOR_RED='\033[0;31m'
readonly COLOR_BLUE='\033[0;34m'

# ============================================================================
# Global Variables
# ============================================================================

DRY_RUN=false
VERBOSE=false
COMMIT_RANGE="HEAD~1..HEAD"

# Counters for reporting
declare -i TOTAL_FILES=0
declare -i SUCCESS_COUNT=0
declare -i SKIPPED_COUNT=0
declare -i FAILED_COUNT=0

declare -a SKIPPED_FILES=()
declare -a FAILED_FILES=()

# ============================================================================
# Functions
# ============================================================================

#
# Print usage information
#
usage() {
    cat <<EOF
使用方法: $(basename "$0") [OPTIONS]

sample-projectの変更をCookiecutterテンプレートに同期します。
Jinja2テンプレート変数を保護し、誤って上書きすることを防ぎます。

オプション:
  --dry-run          実際には変更せず、同期内容のみ表示
  --commit HASH      変更検出のコミット範囲を指定 (デフォルト: HEAD~1..HEAD)
  --verbose          詳細ログを出力
  --help             このヘルプを表示

終了コード:
  0  成功 (全ファイル同期完了 or dry-run)
  1  一部失敗 (スキップを除く)
  2  全失敗 or 設定エラー

例:
  # 最新のコミットからの変更を同期
  ./scripts/sync-sample-to-template.sh

  # ドライランモード
  ./scripts/sync-sample-to-template.sh --dry-run

  # 特定のコミット範囲を指定
  ./scripts/sync-sample-to-template.sh --commit main..HEAD

  # 詳細ログ付きで実行
  ./scripts/sync-sample-to-template.sh --verbose
EOF
}

#
# Log message with prefix
# Args: message
#
log() {
    echo -e "${COLOR_BLUE}[sync-template]${COLOR_RESET} $*"
}

#
# Log verbose message (only if VERBOSE=true)
# Args: message
#
log_verbose() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "${COLOR_BLUE}[sync-template:verbose]${COLOR_RESET} $*"
    fi
}

#
# Log error message
# Args: message
#
log_error() {
    echo -e "${COLOR_RED}[sync-template:ERROR]${COLOR_RESET} $*" >&2
}

#
# Map sample-project path to template path
# Args: source_path
# Returns: mapped template path
#
map_path() {
    local src_path="$1"

    # Remove sample-project/ prefix and prepend template path
    local relative_path="${src_path#$SAMPLE_PROJECT_DIR/}"
    echo "$TEMPLATE_DIR/$relative_path"
}

#
# Check if file contains Jinja2 template variables
# Args: file_path
# Returns: 0 if Jinja2 vars found, 1 otherwise
#
has_jinja2_vars() {
    local file="$1"

    # Return false if file doesn't exist
    [[ -f "$file" ]] || return 1

    # Check for Jinja2 patterns: {{, {%, {#
    # Use grep -q for quiet mode (only exit code matters)
    # Ignore binary files (grep will skip them automatically with -I)
    grep -qE '\{\{|\{%|\{#' "$file" 2>/dev/null
}

#
# Sync a single file from sample-project to template
# Args: source_file change_type
# Returns: 0 on success, 1 on skip, 2 on failure
#
sync_file() {
    local src="$1"
    local change_type="$2"
    local dst

    dst=$(map_path "$src")

    log_verbose "Processing: $src ($change_type)"
    log_verbose "  Source: $src"
    log_verbose "  Destination: $dst"

    # Check if destination contains Jinja2 variables
    if [[ -f "$dst" ]] && has_jinja2_vars "$dst"; then
        log_verbose "  Jinja2 variables detected in destination"
        echo -e "  ${COLOR_YELLOW}⊘${COLOR_RESET} SKIP: $src (destination contains Jinja2 variables)"
        SKIPPED_FILES+=("$src: destination contains Jinja2 variables")
        ((SKIPPED_COUNT++))
        return 1
    fi

    # Dry-run mode: just report what would happen
    if [[ "$DRY_RUN" == "true" ]]; then
        case "$change_type" in
            A) echo -e "  ${COLOR_GREEN}+${COLOR_RESET} WOULD ADD: $src → $dst" ;;
            M) echo -e "  ${COLOR_GREEN}✓${COLOR_RESET} WOULD UPDATE: $src → $dst" ;;
            D) echo -e "  ${COLOR_RED}−${COLOR_RESET} WOULD DELETE: $dst" ;;
        esac
        ((SUCCESS_COUNT++))
        return 0
    fi

    # Actual sync operations
    case "$change_type" in
        A|M)
            # Create parent directory if needed
            local dst_dir
            dst_dir=$(dirname "$dst")
            if [[ ! -d "$dst_dir" ]]; then
                log_verbose "  Creating directory: $dst_dir"
                mkdir -p "$dst_dir" || {
                    log_error "Failed to create directory: $dst_dir"
                    FAILED_FILES+=("$src: failed to create destination directory")
                    ((FAILED_COUNT++))
                    return 2
                }
            fi

            # Copy file (preserving permissions)
            if cp -p "$src" "$dst"; then
                if [[ "$change_type" == "A" ]]; then
                    echo -e "  ${COLOR_GREEN}+${COLOR_RESET} ADDED: $src → $dst"
                else
                    echo -e "  ${COLOR_GREEN}✓${COLOR_RESET} UPDATED: $src → $dst"
                fi
                ((SUCCESS_COUNT++))
                return 0
            else
                log_error "Failed to copy: $src → $dst"
                FAILED_FILES+=("$src: copy operation failed")
                ((FAILED_COUNT++))
                return 2
            fi
            ;;

        D)
            if [[ -f "$dst" ]]; then
                if rm -f "$dst"; then
                    echo -e "  ${COLOR_RED}−${COLOR_RESET} DELETED: $dst"
                    ((SUCCESS_COUNT++))
                    return 0
                else
                    log_error "Failed to delete: $dst"
                    FAILED_FILES+=("$dst: delete operation failed")
                    ((FAILED_COUNT++))
                    return 2
                fi
            else
                log_verbose "  File already deleted: $dst"
                ((SUCCESS_COUNT++))
                return 0
            fi
            ;;

        *)
            log_error "Unknown change type: $change_type for file $src"
            FAILED_FILES+=("$src: unknown change type $change_type")
            ((FAILED_COUNT++))
            return 2
            ;;
    esac
}

#
# Print summary report
#
print_summary() {
    log ""
    log "Summary:"
    log "  Total:    $TOTAL_FILES files"
    log "  Success:  ${COLOR_GREEN}$SUCCESS_COUNT${COLOR_RESET} files"

    if [[ $SKIPPED_COUNT -gt 0 ]]; then
        log "  Skipped:  ${COLOR_YELLOW}$SKIPPED_COUNT${COLOR_RESET} files (Jinja2 variables detected)"
    fi

    if [[ $FAILED_COUNT -gt 0 ]]; then
        log "  Failed:   ${COLOR_RED}$FAILED_COUNT${COLOR_RESET} files"
    fi

    # Print detailed skip/failure info if verbose or if there are failures
    if [[ "$VERBOSE" == "true" ]] && [[ ${#SKIPPED_FILES[@]} -gt 0 ]]; then
        log ""
        log "Skipped files:"
        for file in "${SKIPPED_FILES[@]}"; do
            echo "    - $file"
        done
    fi

    if [[ ${#FAILED_FILES[@]} -gt 0 ]]; then
        log ""
        log_error "Failed files:"
        for file in "${FAILED_FILES[@]}"; do
            echo "    - $file"
        done
    fi
}

# ============================================================================
# Main Script
# ============================================================================

main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --commit)
                COMMIT_RANGE="$2"
                shift 2
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            --help|-h)
                usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                exit 2
                ;;
        esac
    done

    # Change to repository root
    cd "$REPO_ROOT"

    log "Synchronizing sample-project changes to template..."

    if [[ "$DRY_RUN" == "true" ]]; then
        log "${COLOR_YELLOW}DRY RUN MODE${COLOR_RESET} - No files will be modified"
    fi

    log_verbose "Repository root: $REPO_ROOT"
    log_verbose "Sample project: $SAMPLE_PROJECT_DIR"
    log_verbose "Template directory: $TEMPLATE_DIR"
    log_verbose "Commit range: $COMMIT_RANGE"

    # Get changed files from git diff
    log "Analyzing changes in $SAMPLE_PROJECT_DIR/..."

    local changed_files
    changed_files=$(git diff --name-status "$COMMIT_RANGE" -- "$SAMPLE_PROJECT_DIR/" 2>/dev/null) || {
        log_error "Failed to get git diff. Make sure you're in a git repository and the commit range is valid."
        exit 2
    }

    # Count total files
    TOTAL_FILES=$(echo "$changed_files" | grep -c "^[AMD]" || true)

    if [[ $TOTAL_FILES -eq 0 ]]; then
        log "No changes detected in $SAMPLE_PROJECT_DIR/"
        exit 0
    fi

    log "Found $TOTAL_FILES changed file(s)"
    log ""
    log "Processing files:"

    # Process each changed file
    while IFS=$'\t' read -r status file; do
        # Extract change type (A=added, M=modified, D=deleted)
        local change_type="${status:0:1}"

        # Skip if not in sample-project (should not happen due to git diff filter)
        [[ "$file" == "$SAMPLE_PROJECT_DIR/"* ]] || continue

        # Sync the file
        sync_file "$file" "$change_type" || true  # Continue even if one file fails

    done <<< "$changed_files"

    # Print summary
    print_summary

    # Determine exit code
    if [[ $FAILED_COUNT -gt 0 ]]; then
        if [[ $SUCCESS_COUNT -eq 0 ]]; then
            log_error "All files failed to sync"
            exit 2
        else
            log_error "Some files failed to sync"
            exit 1
        fi
    else
        log "${COLOR_GREEN}Synchronization completed successfully!${COLOR_RESET}"
        exit 0
    fi
}

# Trap errors and provide helpful message
trap 'log_error "Script failed at line $LINENO. Exit code: $?"' ERR

# Run main function
main "$@"
