# Feature Specification: Sample Project to Template Synchronization

**Feature Branch**: `001-sample-to-template-sync`
**Created**: 2025-12-07
**Status**: Draft
**Input**: User description: "sample-projectへの変更をtemplateに反映する仕組みが欲しい。templateの置換部分に影響を及ぼさない前提の変更を対象にしましょう。その前提で良い。さらに,sample-project の変更を含む main へのpush や マージで github actionが動いて自動で反映されるまでを目指したい。"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - 手動での変更反映 (Priority: P1)

開発者がsample-projectに変更を加えた後、その変更をtemplateに手動で反映させたい。ただし、templateの置換部分（Jinja2変数など）は保護される必要がある。

**Why this priority**: 最も基本的な機能であり、これがないと自動化も実現できない。手動実行可能な同期メカニズムがMVPとして必要。

**Independent Test**: sample-projectの任意のファイル（例：build.gradleの依存関係）を変更し、同期コマンドを実行することで、templateの対応するファイルが更新され、Jinja2変数が保持されていることを確認できる。

**Acceptance Scenarios**:

1. **Given** sample-project内のKotlinファイルを更新、**When** 同期コマンドを実行、**Then** template内の対応ファイルが更新され、`{{ cookiecutter.* }}`プレースホルダーは維持される
2. **Given** sample-project内の新規ファイルを追加、**When** 同期コマンドを実行、**Then** template内に同じパス構造で新規ファイルが作成される
3. **Given** sample-project内のファイルを削除、**When** 同期コマンドを実行、**Then** template内の対応ファイルも削除される

---

### User Story 2 - 変更の検証と安全性確保 (Priority: P2)

開発者が同期を実行する際、templateの置換部分に影響を与える変更がある場合は警告を受け、同期をスキップできる。

**Why this priority**: データの整合性とtemplateの破損防止のため重要だが、P1の基本同期機能があれば後から追加可能。

**Independent Test**: Jinja2変数を含むファイルをsample-projectで変更し、同期を実行すると警告が表示され、そのファイルがスキップされることを確認できる。

**Acceptance Scenarios**:

1. **Given** sample-projectで`bundle_id_prefix`などのハードコード値を変更、**When** 同期コマンドを実行、**Then** 警告が表示され、該当ファイルは同期対象から除外される
2. **Given** 同期対象ファイルリストの確認、**When** ドライランモードで実行、**Then** 実際に変更せずに同期される内容のレポートが表示される

---

### User Story 3 - GitHub Actions による自動同期 (Priority: P3)

mainブランチへのpushまたはマージ時に、sample-projectの変更が自動的にtemplateに反映される。

**Why this priority**: 開発者の手間を大幅に削減するが、手動同期（P1）と検証機能（P2）が確立された後に実装すべき。

**Independent Test**: sample-projectの変更を含むPRをmainにマージし、GitHub Actionsワークフローが起動して、自動的にtemplateが更新され、コミットが作成されることを確認できる。

**Acceptance Scenarios**:

1. **Given** sample-projectの変更がmainにマージされた、**When** GitHub Actions ワークフローが実行、**Then** templateへの変更が自動コミット・プッシュされる
2. **Given** 自動同期が失敗（template変数の競合など）、**When** ワークフロー完了、**Then** 失敗通知が送信され、手動介入が求められる

---

### Edge Cases

- sample-projectとtemplateのディレクトリ構造が異なる場合の対応は？（例：sample-projectは`kk.tuist.app`だがtemplateは`{{cookiecutter.bundle_id_prefix}}`）
- バイナリファイル（画像、JARなど）の同期はどう扱う？
- Jinja2変数を含む行と含まない行が混在するファイルの扱いは？
- 同期中にファイルパーミッションやシンボリックリンクはどう処理する？
- gradleラッパーやその他の生成ファイルは同期対象か？

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: システムはsample-project内の変更ファイルを検出できなければならない
- **FR-002**: システムはsample-projectのファイルパスをtemplateの対応パスにマッピングできなければならない
- **FR-003**: システムはファイル内にJinja2テンプレート変数（`{{ cookiecutter.* }}`など）が含まれているかを検出できなければならない
- **FR-004**: システムはJinja2変数を含むファイルを同期対象から除外、または警告を表示しなければならない
- **FR-005**: システムはsample-projectのファイル追加・変更・削除をtemplateに反映できなければならない
- **FR-006**: システムは同期結果のレポート（成功・スキップ・失敗ファイル一覧）を生成しなければならない
- **FR-007**: システムはドライランモード（実際には変更せずに同期内容を確認）を提供しなければならない
- **FR-008**: GitHub Actionsワークフローはmainブランチへのpush/マージをトリガーとして起動しなければならない
- **FR-009**: ワークフローはsample-projectに変更がある場合のみ同期処理を実行しなければならない
- **FR-010**: ワークフローは同期後、自動的にコミット・プッシュを実行しなければならない [NEEDS CLARIFICATION: 同期後にtest template generationを実行して検証すべきか？]

### Key Entities

- **Changed File**: sample-project内で追加・変更・削除されたファイル（パス、変更タイプ、内容）
- **Template Mapping**: sample-projectのパスとtemplateパスの対応関係（例：`sample-project/android-app/build.gradle.kts` → `cookiecutter-kmp-mobile-tuist/{{cookiecutter.project_name}}/android-app/build.gradle.kts`）
- **Jinja2 Variable Pattern**: テンプレート変数の検出パターン（例：`{{`, `{%`, `{#`）
- **Sync Report**: 同期結果の記録（成功ファイル数、スキップファイル数、失敗ファイル、警告メッセージ）

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: sample-projectの変更がtemplateに反映されるまでの時間が5分以内（GitHub Actions実行時）
- **SC-002**: Jinja2変数を含むファイルを100%の精度で検出し、誤って上書きしない
- **SC-003**: 最大500ファイルを持つプロジェクトで同期処理が正常に完了する
- **SC-004**: 手動メンテナンス時間が80%削減される（現状の手動コピー作業と比較）
- **SC-005**: 同期によるtemplateの破損が0件（全ての自動同期後にtemplate生成テストが成功）
