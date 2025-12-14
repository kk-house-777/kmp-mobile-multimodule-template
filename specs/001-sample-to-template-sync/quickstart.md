# クイックスタート: Sample Project to Template 同期ツール

**Feature**: #001-sample-to-template-sync
**作成日**: 2025-12-07
**対象**: 開発者・メンテナー

## 概要

このツールは、`sample-project/`ディレクトリへの変更を自動的にCookiecutterテンプレート(`cookiecutter-kmp-mobile-tuist/{{cookiecutter.project_name}}/`)に反映します。

**主な機能:**
- Git履歴ベースの変更検出
- Jinja2テンプレート変数の自動保護
- ドライランモードでの事前確認
- GitHub Actionsによる自動同期

## インストール

ツールは標準のBashスクリプトとして実装されており、追加のインストールは不要です。

**必要な環境:**
- Bash 4.0+
- Git
- coreutils (grep, cp, rm など - 標準で利用可能)

## 基本的な使い方

### 1. 手動で同期を実行

```bash
# リポジトリのルートディレクトリで実行
./scripts/sync-sample-to-template.sh
```

これにより、`HEAD~1..HEAD` の変更が同期されます。

**出力例:**
```
[sync-template] Synchronizing sample-project changes to template...
[sync-template] Analyzing changes in sample-project/...
[sync-template] Found 3 changed file(s)

[sync-template] Processing files:
  ✓ UPDATED: sample-project/android-app/build.gradle.kts → cookiecutter-kmp-mobile-tuist/{{cookiecutter.project_name}}/android-app/build.gradle.kts
  ⊘ SKIP: sample-project/settings.gradle.kts (destination contains Jinja2 variables)
  ✓ UPDATED: sample-project/shared/src/commonMain/kotlin/App.kt → ...

[sync-template] Summary:
  Total:    3 files
  Success:  2 files
  Skipped:  1 files (Jinja2 variables detected)
  Failed:   0 files

[sync-template] Synchronization completed successfully!
```

### 2. ドライランモード(事前確認)

実際に変更を適用せず、何が同期されるかを確認できます。

```bash
./scripts/sync-sample-to-template.sh --dry-run
```

**出力例:**
```
[sync-template] DRY RUN MODE - No files will be modified
[sync-template] Found 2 changed file(s)

[sync-template] Processing files:
  ✓ WOULD UPDATE: sample-project/README.md → cookiecutter-kmp-mobile-tuist/{{cookiecutter.project_name}}/README.md
  + WOULD ADD: sample-project/docs/new-feature.md → cookiecutter-kmp-mobile-tuist/{{cookiecutter.project_name}}/docs/new-feature.md
```

### 3. 特定のコミット範囲を指定

```bash
# 特定のブランチとの差分を同期
./scripts/sync-sample-to-template.sh --commit main..feature-branch

# 特定のコミット間を同期
./scripts/sync-sample-to-template.sh --commit abc123..def456

# 過去N個のコミットを同期
./scripts/sync-sample-to-template.sh --commit HEAD~5..HEAD
```

### 4. 詳細ログを有効化

```bash
./scripts/sync-sample-to-template.sh --verbose
```

**詳細ログの出力例:**
```
[sync-template:verbose] Repository root: /path/to/repo
[sync-template:verbose] Sample project: sample-project
[sync-template:verbose] Template directory: cookiecutter-kmp-mobile-tuist/{{cookiecutter.project_name}}
[sync-template:verbose] Commit range: HEAD~1..HEAD
[sync-template:verbose] Processing: sample-project/build.gradle.kts (M)
[sync-template:verbose]   Source: sample-project/build.gradle.kts
[sync-template:verbose]   Destination: cookiecutter-kmp-mobile-tuist/{{cookiecutter.project_name}}/build.gradle.kts
[sync-template:verbose]   Creating directory: cookiecutter-kmp-mobile-tuist/{{cookiecutter.project_name}}
```

## オプション一覧

| オプション | 説明 | デフォルト |
|-----------|------|-----------|
| `--dry-run` | 実際には変更せず、同期内容のみ表示 | なし |
| `--commit HASH` | 変更検出のコミット範囲を指定 | `HEAD~1..HEAD` |
| `--verbose` | 詳細ログを出力 | なし |
| `--help` | ヘルプメッセージを表示 | なし |

## GitHub Actionsによる自動同期

mainブランチへの`sample-project/**`の変更がpushまたはマージされると、自動的に同期が実行されます。

**ワークフロー:** `.github/workflows/sync-template.yml`

**トリガー条件:**
- `main`ブランチへのpush
- `sample-project/`配下のファイル変更

**動作:**
1. 変更を検出
2. 同期スクリプトを実行
3. 変更があればコミット・プッシュ
4. 失敗時は通知

### 手動でワークフローを起動

GitHub ActionsのUIから手動で起動することもできます:

1. リポジトリの"Actions"タブを開く
2. "Sync Sample Project to Template"ワークフローを選択
3. "Run workflow"ボタンをクリック

## Jinja2変数の保護について

### 保護される理由

Cookiecutterテンプレートには、プロジェクト生成時に置き換えられるJinja2変数(`{{ cookiecutter.* }}`)が含まれています。これらの変数をsample-projectの内容で上書きすると、テンプレートが破損します。

### 検出パターン

以下のパターンが検出されます:
- `{{ ... }}` - 変数展開
- `{% ... %}` - 制御構文
- `{# ... #}` - コメント

### 動作

ファイルの**宛先**(template側)にJinja2変数が含まれている場合、そのファイルはスキップされ、元の内容が保持されます。

**例:**

```bash
# sample-project/settings.gradle.kts (source)
rootProject.name = "sample-project"

# cookiecutter-kmp-mobile-tuist/{{cookiecutter.project_name}}/settings.gradle.kts (destination)
rootProject.name = "{{ cookiecutter.project_name }}"
```

この場合、`settings.gradle.kts`は同期から**除外**され、template側の`{{ cookiecutter.project_name }}`が保持されます。

### 行単位の保護（Cookiecutterマーカー）

**v1.1.0以降**では、ファイル全体をスキップするのではなく、**特定の行やセクションだけ**を保護できるマーカー機能が追加されました。

#### 1. インラインマーカー（1行の保護）

特定の行だけを保護したい場合、行末に`// COOKIECUTTER_KEEP`コメントを追加します。

**例: パッケージ宣言の保護**

```kotlin
// Template側ファイル
package {{ cookiecutter.bundle_id_prefix }} // COOKIECUTTER_KEEP

fun myFunction() {
    println("Hello")
}
```

この場合、同期実行時：
- **1行目**: 保護される（Jinja2変数が保持される）
- **3行目以降**: sample-projectから同期される

#### 2. セクションマーカー（複数行の保護）

複数行をまとめて保護したい場合、`COOKIECUTTER_PROTECTED_START`と`COOKIECUTTER_PROTECTED_END`で囲みます。

**例: importセクションの保護**

```kotlin
// Template側ファイル
// COOKIECUTTER_PROTECTED_START
package {{ cookiecutter.bundle_id_prefix }}
import {{ cookiecutter.project_name|lower }}.generated.resources.Res
// COOKIECUTTER_PROTECTED_END

fun myFunction() {
    println("Hello")
}
```

この場合、同期実行時：
- **2-4行目**: 保護される（Jinja2変数が保持される）
- **6行目以降**: sample-projectから同期される

#### マーカー使用時の動作

| ファイルの状態 | 動作 |
|--------------|------|
| マーカーあり + Jinja2変数あり | 行単位マージ（⚡マーク表示） |
| マーカーなし + Jinja2変数あり | ファイル全体をスキップ（⊘マーク表示） |
| Jinja2変数なし | ファイル全体を同期（✓マーク表示） |

**出力例（マーカー使用時）:**
```
  ⚡ MERGED (line-level): sample-project/App.kt → cookiecutter-.../App.kt
```

#### 使用上の注意

1. **マーカーはTemplate側にのみ配置**: sample-projectには不要
2. **コメント形式を適切に選択**:
   - Kotlin/Java: `// COOKIECUTTER_KEEP`
   - Python: `# COOKIECUTTER_KEEP`
   - XML: `<!-- COOKIECUTTER_KEEP -->`
3. **セクションは正しく閉じる**: `START`と`END`のペアが必要
4. **ネストは避ける**: セクション内に別のセクションを作らない

## よくあるワークフロー

### ワークフロー1: 新機能の追加

1. `sample-project/`で新機能を開発・テスト
2. ドライランで同期内容を確認
   ```bash
   ./scripts/sync-sample-to-template.sh --dry-run
   ```
3. 問題がなければ実際に同期
   ```bash
   ./scripts/sync-sample-to-template.sh
   ```
4. 変更をコミット
   ```bash
   git add .
   git commit -m "feat: add new feature to template"
   git push origin main
   ```
5. GitHub Actionsが自動的に再度同期を実行(冪等性あり)

### ワークフロー2: 複数コミットをまとめて同期

```bash
# 過去5コミット分の変更を一括で同期
./scripts/sync-sample-to-template.sh --commit HEAD~5..HEAD --verbose
```

### ワークフロー3: ブランチ間の差分を同期

```bash
# feature ブランチで開発後、mainとの差分を同期
git checkout feature-branch
./scripts/sync-sample-to-template.sh --commit main..HEAD
```

## トラブルシューティング

### 問題: "No changes detected"と表示される

**原因**: 指定されたコミット範囲に`sample-project/`配下の変更がない

**解決方法**:
- `git log --oneline -- sample-project/`で変更履歴を確認
- `--commit`オプションで正しいコミット範囲を指定

### 問題: 期待したファイルがスキップされる

**原因**: template側のファイルにJinja2変数が含まれている

**解決方法**:
1. `--verbose`で詳細を確認
2. template側のファイルを確認し、Jinja2変数が本当に必要かチェック
3. 必要なら手動で編集

### 問題: GitHub Actionsワークフローが起動しない

**原因考察**:
- `sample-project/`配下のファイル変更ではない
- ブランチが`main`ではない
- ワークフローファイルに構文エラーがある

**解決方法**:
1. GitHub ActionsのUIから手動起動を試す
2. ワークフローログを確認

### 問題: 同期後にテンプレート生成が失敗する

**原因**: Jinja2変数が誤って上書きされた可能性

**解決方法**:
1. template側のファイルでJinja2変数をGrepで検索
   ```bash
   grep -rn "{{ cookiecutter" cookiecutter-kmp-mobile-tuist/
   ```
2. 失われた変数を手動で復元
3. Issueを作成してツールの改善を提案

## パフォーマンス

**処理時間の目安:**
- 10ファイル: < 1秒
- 100ファイル: < 5秒
- 500ファイル: < 30秒

**最適化のヒント:**
- 不要なファイル(build artifacts, IDE files)はコミットしない
- `--commit`オプションで必要な範囲のみ指定

## 次のステップ

- [Feature仕様書](./spec.md) - 詳細な要件とユーザーストーリー
- [実装計画](./plan.md) - 技術選定と設計
- [タスク一覧](./tasks.md) - 実装タスクの詳細

## サポート

問題が発生した場合は、以下の情報を含めてIssueを作成してください:
- 実行したコマンド
- エラーメッセージ
- `--verbose`オプション付きの実行結果
- Git履歴の関連部分
