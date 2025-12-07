# Feature Specification: Sample Project to Template Synchronization

**Feature Branch**: `001-sample-to-template-sync`
**Created**: 2025-12-07
**Status**: Draft
**Input**: User description: "sample-projectに対する変更をtemplateに反映する仕組みの構築

sample-projectへの変更をtemplateに反映する仕組みが欲しい。
templateの置換部分に影響を及ぼさない前提の変更を対象にしましょう。その前提で良い。
さらに,sample-project の変更を含む main へのpush や マージで github actionが動いて自動で反映されるまでを目指したい。"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Manual Change Reflection (Priority: P1)

A developer makes a change to the sample-project (e.g., updates a Gradle dependency, modifies build configuration, or improves code structure) that should also apply to the template. The system automatically detects and syncs these changes to the appropriate template files, ensuring both the sample and generated projects stay consistent.

**Why this priority**: This is the core value proposition. Without automated synchronization, maintaining consistency between sample-project and template requires manual, error-prone copying.

**Independent Test**: Can be fully tested by making a non-templated change to sample-project, triggering the sync mechanism, and verifying the change appears in the corresponding template file(s).

**Acceptance Scenarios**:

1. **Given** a developer updates a Gradle dependency version in sample-project/build.gradle.kts, **When** the change is committed and pushed to main, **Then** the template's build.gradle.kts file is automatically updated with the same dependency version
2. **Given** a developer modifies a Kotlin source file in sample-project that doesn't contain template variables, **When** the change is merged to main, **Then** the corresponding template file is updated to reflect the changes
3. **Given** a developer adds a new utility file to sample-project that has no template-specific content, **When** the change is pushed to main, **Then** the new file is copied to the template structure

---

### User Story 2 - Change Validation and Safety (Priority: P2)

Before syncing changes from sample-project to template, the system validates that changes don't affect template substitution variables (Jinja2 placeholders like `{{ cookiecutter.project_name }}`). Changes that would overwrite or conflict with template variables are flagged and reported but not automatically applied.

**Why this priority**: This prevents breaking the template generation mechanism, which is critical but secondary to having basic sync functionality.

**Independent Test**: Can be tested by attempting to sync a file containing template variables and verifying the system correctly rejects or flags the change.

**Acceptance Scenarios**:

1. **Given** a change to sample-project includes a file with template variables, **When** the sync process runs, **Then** the system detects the template variables and skips automatic synchronization for that file
2. **Given** the sync process encounters template-conflicting changes, **When** synchronization completes, **Then** a report is generated listing which files were skipped and why
3. **Given** a file in sample-project contains no template variables, **When** the sync validation runs, **Then** the file is marked as safe to sync

---

### User Story 3 - GitHub Actions Integration (Priority: P3)

When changes to sample-project are pushed or merged to the main branch, a GitHub Actions workflow automatically triggers the synchronization process, applies approved changes to the template, and creates a commit with the synchronized changes.

**Why this priority**: Automation is valuable for reducing manual work, but the sync mechanism itself must work first.

**Independent Test**: Can be tested by pushing a change to sample-project on main and verifying the GitHub Actions workflow runs, detects the changes, and commits the synchronized template updates.

**Acceptance Scenarios**:

1. **Given** changes to sample-project are merged to main, **When** the merge completes, **Then** a GitHub Actions workflow triggers automatically
2. **Given** the GitHub Actions workflow runs, **When** it detects syncable changes, **Then** it commits the synchronized template updates with a descriptive commit message
3. **Given** the synchronization workflow encounters errors, **When** the workflow fails, **Then** developers are notified via workflow failure notifications with detailed error information

---

### Edge Cases

- What happens when a file exists in sample-project but should not be in the template (e.g., local development files)?
- How does the system handle partial file changes where some sections have template variables and others don't?
- What happens when the same file is changed in both sample-project and template simultaneously?
- How are file deletions in sample-project handled - should they propagate to template?
- What happens when sample-project directory structure changes (files moved/renamed)?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST identify files in sample-project that have changed since the last synchronization
- **FR-002**: System MUST detect template variables (Jinja2 syntax) in files before attempting synchronization
- **FR-003**: System MUST only synchronize files that do not contain template variables or template-specific logic
- **FR-004**: System MUST maintain a mapping between sample-project file paths and their corresponding template file paths
- **FR-005**: System MUST generate a synchronization report showing which files were synced, skipped, and why
- **FR-006**: System MUST create commits with descriptive messages indicating which files were synchronized from sample-project
- **FR-007**: System MUST be triggered automatically when changes are pushed or merged to the main branch
- **FR-008**: System MUST handle file additions, modifications, and deletions in sample-project
- **FR-009**: System MUST skip synchronization for files explicitly marked as sample-only (e.g., via configuration file)
- **FR-010**: System MUST validate that synchronized content does not break template generation [NEEDS CLARIFICATION: Should we run a test template generation after sync to verify?]

### Key Entities

- **SyncableFile**: Represents a file in sample-project eligible for synchronization, with attributes: source path, target template path, contains template variables (boolean), last sync timestamp
- **SyncMapping**: Defines the relationship between sample-project directories/files and template directories/files, accounting for path transformations (e.g., `sample-project/android-app` → `{{cookiecutter.project_name}}/android-app`)
- **SyncReport**: Documents synchronization results, including synced files list, skipped files with reasons, errors encountered, and timestamp
- **TemplateVariable**: Represents Jinja2 placeholders detected in files (e.g., `{{ cookiecutter.bundle_id_prefix }}`), used for validation

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Developers can make non-templated changes to sample-project and see them reflected in the template within 5 minutes of pushing to main
- **SC-002**: The synchronization process correctly identifies and skips 100% of files containing template variables
- **SC-003**: Synchronization process completes successfully for projects with up to 500 files without timeout
- **SC-004**: The system reduces manual template maintenance time by at least 80% (measured by time spent manually copying changes)
- **SC-005**: Template generation succeeds for 100% of synchronized changes (no broken templates introduced by sync)

## Assumptions

- The directory structure mapping between sample-project and template is well-defined and relatively stable
- Template variables follow standard Jinja2 syntax (`{{ ... }}`) making them detectable via regex or parsing
- GitHub Actions has appropriate permissions to commit changes to the repository
- The synchronization process will run on every push/merge to main, not on feature branches
- Files in `.gitignore` or build artifacts are excluded from synchronization
- The sync process will use file content comparison (not just timestamps) to detect meaningful changes
