# kmp-multimodule-template
KMPを使ったiOS, Androidのマルチモジュール構成のtemplateアプリを作成する。
## 要件
- iOSプロジェクトの管理はtuistが前提

## インストール方法

```bash
brew tap kk-house-777/tap
brew install kmp-mobile-multimodule-template
```

## 使い方
### クイックスタート
```bash
# テンプレートからプロジェクトを作成
kmp-mobile-multimodule-template create

# 生成されたプロジェクトをテスト
cd <generated-project-name>
mise install
./gradlew android-app:build
mise run ios-gen
```

### create project
```bash
# テストプロジェクトを作成（対話モード）
kmp-mobile-multimodule-template create

# テストプロジェクトを作成（非対話モード）
kmp-mobile-multimodule-template create \
  --project-name TestApp \
  --bundle-id com.test.app \
  --no-input

# ヘルプを表示
kmp-mobile-multimodule-template --help
```

# Development

This is a Cookiecutter-based template repository for generating Kotlin Multiplatform (KMP) + Tuist mobile projects. The repository contains:
- A reference implementation (`sample-project/`)
- A Cookiecutter template (`cookiecutter-kmp-mobile-tuist/`)
- A CLI wrapper script (`kmp-mobile-tuist`)

## 仕組み
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

##  sample-projectの変更をcookiecutter-kmp-mobile-tuistに反映

###  ./scripts/sync-sample-to-template.sh --help 
```
使用方法: sync-sample-to-template.sh [OPTIONS]

sample-projectの変更をCookiecutterテンプレートに同期します。
Jinja2テンプレート変数を保護し、誤って上書きすることを防ぎます。

オプション:
  --dry-run          実際には変更せず、同期内容のみ表示
  --commit HASH      変更検出のコミット範囲を指定 (デフォルト: HEAD~1..HEAD)
  --working-tree     未コミットの変更(working tree)を同期対象にする
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

  # 未コミットの変更を同期
  ./scripts/sync-sample-to-template.sh --working-tree

  # 詳細ログ付きで実行
  ./scripts/sync-sample-to-template.sh --verbose
```

### github action
`.github/sync-sample-to-template.yml`