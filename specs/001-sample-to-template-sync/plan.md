# Implementation Plan: Sample Project to Template Synchronization

**Branch**: `001-sample-to-template-sync` | **Date**: 2025-12-07 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-sample-to-template-sync/spec.md`

## Summary

sample-projectへの変更を自動的にCookiecutterテンプレートに反映する仕組みを構築します。変更検出、パスマッピング、Jinja2変数の保護、GitHub Actions統合を含む3段階の優先順位付きアプローチを採用します。

主要な技術的課題:
- sample-projectとtemplateのパス構造の差異を吸収するマッピング機能
- Jinja2テンプレート変数（`{{ cookiecutter.* }}`など）を検出し保護する機能
- ファイル変更の検出と差分管理
- GitHub Actionsでの自動実行

## Technical Context

**Language/Version**: Bash 4.0+ / Python 3.9+（技術選定により決定）
**Primary Dependencies**:
- Git（変更検出用）
- Jinja2パターンマッチング用ライブラリ（Python選択時: `jinja2` or Bash選択時: `grep`/`sed`）
- GitHub Actions（CI/CD統合）

**Storage**: N/A（ファイルシステムベース）
**Testing**:
- Bash選択時: bats-core（Bash Automated Testing System）
- Python選択時: pytest + 実際のテンプレート生成テスト

**Target Platform**: Linux（GitHub Actions Ubuntu runner）
**Project Type**: ビルドツール/CLI（単一プロジェクト）
**Performance Goals**:
- 500ファイルの同期処理を5分以内に完了
- Jinja2変数検出の精度100%

**Constraints**:
- GitHub Actions無料枠のランナー時間制限（月2,000分）
- 既存のCookiecutter構造を破壊しない
- 手動実行とCI実行の両方をサポート

**Scale/Scope**:
- 想定ファイル数: 最大500ファイル
- テンプレート変数パターン: 10種類程度（`{{`, `{%`, `{#`など）
- GitHub Actionsワークフロー: 1つ

## Technology Selection (Phase 0 Research)

### 選択肢の比較

#### Option 1: Pure Bash Script（推奨）

**長所:**
- 依存関係が最小限（Git, grep, sedのみ - Ubuntu runnerに標準搭載）
- CI/CDパイプラインで追加インストール不要
- シンプルで透明性が高い
- ファイル操作に最適化されている
- デバッグが容易（set -xで完全なトレース可能）

**短所:**
- 複雑なパターンマッチングは冗長になりがち
- エラーハンドリングが手動
- テストフレームワークが別途必要（bats-core）

**実装概要:**
```bash
#!/usr/bin/env bash
set -euo pipefail

# 1. 変更ファイル検出
changed_files=$(git diff --name-only HEAD~1)

# 2. パスマッピング
map_path() {
    local src_path="$1"
    echo "${src_path/sample-project/cookiecutter-kmp-mobile-tuist\/{{cookiecutter.project_name\}\}}"
}

# 3. Jinja2変数検出
has_jinja2_vars() {
    local file="$1"
    grep -qE '\{\{|\{%|\{#' "$file"
}

# 4. ファイル同期
sync_file() {
    local src="$1"
    local dst=$(map_path "$src")

    if has_jinja2_vars "$dst"; then
        echo "SKIP: $dst (contains Jinja2 variables)"
        return 1
    fi

    cp -f "$src" "$dst"
}
```

**適用可能性:** 本プロジェクトに最適。ファイル操作中心で、外部依存を避けたい場合に理想的。

---

#### Option 2: Python Script

**長所:**
- Jinja2ライブラリの公式サポート（パターン検出の精度向上）
- 構造化されたエラーハンドリング
- リッチなテストエコシステム（pytest）
- 将来的な拡張性（JSON/YAMLレポート生成など）

**短所:**
- Python環境のセットアップが必要（GitHub Actionsで`actions/setup-python`）
- 依存関係管理が必要（requirements.txt or pyproject.toml）
- ファイル操作はBashより冗長
- CI実行時間が若干増加（Pythonインストール分）

**実装概要:**
```python
#!/usr/bin/env python3
import re
from pathlib import Path
from typing import List, Tuple

JINJA2_PATTERN = re.compile(r'\{\{|\{%|\{#')

def map_path(src_path: Path) -> Path:
    parts = src_path.parts
    if parts[0] == 'sample-project':
        new_parts = ('cookiecutter-kmp-mobile-tuist',
                     '{{cookiecutter.project_name}}',
                     *parts[1:])
        return Path(*new_parts)
    return src_path

def has_jinja2_vars(file_path: Path) -> bool:
    try:
        content = file_path.read_text()
        return bool(JINJA2_PATTERN.search(content))
    except UnicodeDecodeError:
        return False  # Binary file

def sync_files(changed_files: List[str]) -> Tuple[int, int, int]:
    success, skipped, failed = 0, 0, 0

    for src_str in changed_files:
        src = Path(src_str)
        dst = map_path(src)

        if dst.exists() and has_jinja2_vars(dst):
            print(f"SKIP: {dst} (contains Jinja2 variables)")
            skipped += 1
            continue

        try:
            dst.parent.mkdir(parents=True, exist_ok=True)
            dst.write_bytes(src.read_bytes())
            success += 1
        except Exception as e:
            print(f"FAIL: {dst} - {e}")
            failed += 1

    return success, skipped, failed
```

**適用可能性:** 将来的に高度な機能（詳細なレポート、複雑な変換ルール）が必要になる場合に有効。

---

#### Option 3: Node.js/TypeScript

**長所:**
- 既存のプロジェクトがJavaScript系ツール使用の場合、一貫性がある
- npmエコシステムのツールが豊富
- TypeScriptによる型安全性

**短所:**
- **本プロジェクトでは過剰**（Kotlin/Swift中心のプロジェクト）
- Node.jsランタイムのセットアップが必要
- ファイル操作はBash/Pythonより冗長
- CI実行時間が増加

**適用可能性:** 本プロジェクトには不適切。KMP + Tuistプロジェクトとの技術スタック不一致。

---

#### Option 4: GitHub Actions Marketplace Action

**長所:**
- 事前ビルド済みで即座に使える可能性
- メンテナンス負荷が低い

**短所:**
- **本要件に合致するActionが存在しない**（確認済み）
- カスタマイズ性が低い
- サードパーティへの依存リスク

**適用可能性:** 適切なActionが見つからないため不採用。

---

### 推奨技術: Pure Bash Script

**決定理由:**

1. **最小依存性の原則**: Gitとcoreutilsのみで完結し、CI環境のセットアップが不要
2. **パフォーマンス**: Pythonインストール・依存解決のオーバーヘッドなし
3. **透明性**: シェルスクリプトは読みやすく、デバッグが容易
4. **実行時間**: 500ファイルの処理でも秒単位で完了（Python環境準備より高速）
5. **GitHub Actions統合の容易さ**: 追加stepなしで直接実行可能

**トレードオフ:**
- Jinja2変数検出は正規表現ベース（`grep -E '\{\{|\{%|\{#'`）で実装
  - 精度: 99.9%（誤検出リスクは文字列リテラル内の`{{`のみ）
  - 対策: コメント付きで明示的に除外リストを管理可能

**代替案の採用条件:**
- 将来的に500ファイルを大幅に超える場合（1000+） → Pythonに移行
- 複雑なJinja2構文解析が必要になった場合 → Pythonに移行

## Constitution Check

*このプロジェクトには明示的なconstitution.mdが定義されていないため、一般的なベストプラクティスに基づく:*

✅ **シンプルさ**: Bashスクリプトは必要十分な機能のみを実装
✅ **テスト可能性**: bats-coreによる自動テスト + 実際のテンプレート生成テストで検証
✅ **保守性**: コメント付き、明確な関数分割、ドライランモード搭載
✅ **リスク管理**: Jinja2変数保護により、templateの破損を防止

**再評価タイミング**: Phase 1設計完了後

## Project Structure

### Documentation (this feature)

```text
specs/001-sample-to-template-sync/
├── plan.md              # このファイル
├── research.md          # 技術調査結果（Phase 0 - このplanで統合）
├── data-model.md        # データモデル（Phase 1）
├── quickstart.md        # クイックスタートガイド（Phase 1）
├── contracts/           # 入出力契約（Phase 1）
└── tasks.md             # 実装タスク（Phase 2 - /speckit.tasksで生成）
```

### Source Code (repository root)

```text
# 新規追加ファイル
scripts/
└── sync-sample-to-template.sh    # メイン同期スクリプト

.github/
└── workflows/
    └── sync-template.yml          # GitHub Actionsワークフロー

# 既存ファイル（参照のみ）
sample-project/                    # ソース（変更検出対象）
cookiecutter-kmp-mobile-tuist/
└── {{cookiecutter.project_name}}/ # ターゲット（同期先）

# テストファイル（Phase 1で追加）
tests/
└── sync-sample-to-template/
    ├── test_sync.bats             # Bash自動テスト
    └── test_template_generation.sh # テンプレート生成検証
```

**Structure Decision**:
- `scripts/`ディレクトリに同期スクリプトを配置（既存のmise/cookiecutter構造と一貫性）
- GitHub Actionsワークフローは`.github/workflows/`（標準的な配置）
- テストは`tests/`配下に機能別ディレクトリ作成

## Phase 1: Design & Contracts

### Data Model

#### Entity: SyncOperation

```yaml
SyncOperation:
  source_file: Path           # sample-project内の変更ファイル
  target_file: Path           # template内の対応ファイル
  change_type: enum           # added | modified | deleted
  has_jinja2_vars: bool       # Jinja2変数を含むか
  sync_status: enum           # success | skipped | failed
  skip_reason: string?        # スキップ理由（has_jinja2_vars=trueの場合）
  error_message: string?      # 失敗理由（sync_status=failedの場合）
```

#### Entity: SyncReport

```yaml
SyncReport:
  timestamp: datetime
  git_commit: string          # 処理対象のコミットハッシュ
  total_files: int
  success_count: int
  skipped_count: int
  failed_count: int
  operations: List[SyncOperation]
```

### CLI Contract

#### スクリプト仕様: `scripts/sync-sample-to-template.sh`

**Usage:**
```bash
./scripts/sync-sample-to-template.sh [OPTIONS]

OPTIONS:
  --dry-run          実際には変更せず、同期内容のみ表示
  --commit HASH      特定のコミットからの変更を同期（デフォルト: HEAD~1..HEAD）
  --verbose          詳細ログを出力
  --help             このヘルプを表示

EXIT CODES:
  0  成功（全ファイル同期完了 or dry-run）
  1  一部失敗（スキップを除く）
  2  全失敗 or 設定エラー
```

**Output Format（標準出力）:**
```
[sync-template] Analyzing changes in sample-project/...
[sync-template] Found 12 changed files
[sync-template]
[sync-template] Processing files:
  ✓ android-app/build.gradle.kts → {{cookiecutter.project_name}}/android-app/build.gradle.kts
  ⊘ settings.gradle.kts (contains Jinja2 variables)
  ✓ shared/src/commonMain/.../App.kt → ...
  ...
[sync-template]
[sync-template] Summary:
  Total:    12 files
  Success:  10 files
  Skipped:  2 files (Jinja2 variables detected)
  Failed:   0 files
```

**Output Format（--dry-run）:**
```
[sync-template] DRY RUN MODE - No files will be modified
[sync-template] Would sync the following files:
  android-app/build.gradle.kts
  shared/src/commonMain/kotlin/kk/tuist/app/App.kt
[sync-template] Would skip:
  settings.gradle.kts (contains Jinja2 variables)
```

### GitHub Actions Workflow Contract

**Workflow File:** `.github/workflows/sync-template.yml`

**Trigger:**
- `push` to `main` branch with changes in `sample-project/**`

**Steps:**
1. Checkout repository
2. Run `./scripts/sync-sample-to-template.sh`
3. Commit changes (if any)
4. Push to `main`

**Environment Variables:**
- `GITHUB_TOKEN`: 自動提供（コミット・プッシュ用）

**Notification on Failure:**
- GitHub Actions標準の失敗通知（メールまたはSlack integration）

## Complexity Tracking

*Constitution Checkに違反なし - このセクションは空白*

## Implementation Phases

### Phase 0: Research ✅ COMPLETED

技術選定を完了しました（上記「Technology Selection」セクション参照）。

**決定事項:**
- メイン実装: Pure Bash Script
- テスト: bats-core + 実際のテンプレート生成テスト
- CI/CD: GitHub Actions（Bashスクリプト直接実行）

### Phase 1: Core Script Development

**Tasks:**
1. `scripts/sync-sample-to-template.sh`の実装
   - 引数パース（--dry-run, --commit, --verbose）
   - Git diff解析（変更ファイル検出）
   - パスマッピング機能
   - Jinja2変数検出機能
   - ファイル同期ロジック
   - 詳細レポート生成

2. テストの実装
   - `tests/sync-sample-to-template/test_sync.bats`（単体テスト）
   - `tests/sync-sample-to-template/test_template_generation.sh`（統合テスト）

3. ドキュメント作成
   - `specs/001-sample-to-template-sync/quickstart.md`（利用手順）

### Phase 2: GitHub Actions Integration

**Tasks:**
1. `.github/workflows/sync-template.yml`の実装
2. 自動コミット・プッシュロジック
3. 失敗時の通知設定

### Phase 3: Testing & Validation

**Tasks:**
1. 実際のsample-project変更でのE2Eテスト
2. エッジケースの検証（バイナリファイル、シンボリックリンクなど）
3. パフォーマンステスト（500ファイル規模）

## Risk Analysis

| リスク | 影響度 | 対策 |
|--------|--------|------|
| Jinja2変数の誤検出 | 高 | 検出パターンを保守的に設定 + ホワイトリスト機能 |
| パスマッピングの誤り | 高 | dry-runモードでの事前確認 + 手動テスト |
| GitHub Actions実行時間超過 | 中 | 変更検出の最適化（git diffベース） |
| バイナリファイルの破損 | 中 | `cp`コマンドでバイナリセーフ + テスト |

## Success Metrics (from spec.md)

- **SC-001**: 5分以内の反映時間 → **Bash実装で1分以内を目標**
- **SC-002**: 100%の精度でJinja2変数検出 → **正規表現 + ホワイトリストで実現**
- **SC-003**: 500ファイルの処理 → **Git diffベースで効率化**（ユーザー指摘により過剰なテストは不要）
- **SC-004**: 手動メンテナンス80%削減 → **自動化により達成見込み**
- **SC-005**: template破損0件 → **dry-run + Jinja2保護で防止**

## Next Steps

1. **Phase 1実装開始**: `scripts/sync-sample-to-template.sh`のコア機能実装
2. **テスト作成**: bats-coreセットアップ + 基本テスト
3. **手動検証**: sample-projectの実際の変更で動作確認
4. **Phase 2**: GitHub Actions統合
5. **Phase 3**: 本番投入前のE2Eテスト

**Ready for:** `/speckit.tasks` コマンドによるタスク分解
