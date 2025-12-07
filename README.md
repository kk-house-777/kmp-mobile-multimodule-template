# kmp-mobile-tuist-template

iOSとAndroidのプロジェクト構成に対して、CompositeBuildを設定し、iOSのプロジェクト管理をTuistに移行後miseから実行できる様にしたtemplateのprojectです。

- `./sample-project/`: サンプルプロジェクト
- `./cookiecutter-kmp-mobile-tuist/`: Cookiecutterテンプレート
- `./kmp-mobile-tuist`: CLIスクリプト

## プロジェクト構成

```
.
├── sample-project/              # サンプルプロジェクト
├── cookiecutter-kmp-mobile-tuist/  # Cookiecutterテンプレート
│   ├── cookiecutter.json        # テンプレート変数定義
│   ├── hooks/                   # 生成時のフック処理
│   │   ├── pre_gen_project.py   # バリデーション
│   │   └── post_gen_project.py  # ディレクトリ移動処理
│   └── {{cookiecutter.project_name}}/  # テンプレート本体
└── kmp-mobile-tuist             # CLIスクリプト
```

## 使い方

### 1. 前提条件

#### オプション A: mise を使う（推奨）

このプロジェクトではmiseでPython環境とcookiecutterのバージョンを管理しています：

```bash
# miseをインストール（まだの場合）
curl https://mise.run | sh

# Python環境とcookiecutterをインストール
mise install
mise run install
```

#### オプション B: pipx を使う

```bash
pipx install cookiecutter
```

### 2. 新しいプロジェクトを作成

#### 対話形式で作成

```bash
# miseを使っている場合
mise run create

# または直接実行
./kmp-mobile-tuist create
```

以下の情報を入力してください：
- **project_name**: プロジェクト名 (例: `MyApp`)
- **android_app_name**: Androidアプリ名 (デフォルト: project_nameと同じ)
- **ios_app_name**: iOSアプリ名 (デフォルト: project_nameと同じ)
- **bundle_id_prefix**: Bundle ID / Application ID のプレフィクス (例: `com.mycompany.myapp`)

#### 引数を指定して作成

```bash
./kmp-mobile-tuist create \
  --project-name MyApp \
  --bundle-id com.mycompany.myapp
```

#### ノンインタラクティブモード

```bash
./kmp-mobile-tuist create \
  --project-name MyApp \
  --bundle-id com.mycompany.myapp \
  --no-input
```

### 3. 生成されたプロジェクトのセットアップ

```bash
# プロジェクトディレクトリに移動
cd MyApp

# Tuistなどのツールをインストール
mise install

# Androidアプリをビルド
./gradlew android-app:build

# iOSプロジェクトを生成
mise run ios-gen
```

## テンプレート変数

生成時に以下の変数が置換されます：

| 変数 | 置換される箇所 | 例 |
|------|---------------|-----|
| `project_name` | rootProject.name, app_name | `MyApp` |
| `bundle_id_prefix` | パッケージ名、applicationId、Bundle ID | `com.mycompany.myapp` |
| `android_app_name` | Androidアプリ名 | `MyApp` |
| `ios_app_name` | iOSアプリ名、PRODUCT_NAME | `MyApp` |

### 主な置換箇所

- **settings.gradle.kts**: `rootProject.name = "{{ project_name }}"`
- **android-app/build.gradle.kts**: `namespace`, `applicationId`
- **build-logic/src/main/kotlin/util/NamespaceUtils.kt**: パッケージ名のプレフィクス
- **ios/xcconfigs/ios-app.xcconfig**: `PRODUCT_NAME`, `PRODUCT_BUNDLE_IDENTIFIER`
- **Kotlinソースファイル**: `package` 宣言とディレクトリ構造
- **strings.xml**: アプリ名

## 技術スタック

- **Android**: Kotlin Multiplatform, Jetpack Compose
- **iOS**: Tuist, SwiftUI
- **ビルドシステム**: Gradle (Composite Build), Tuist
- **テンプレートエンジン**: Cookiecutter

## テンプレートのカスタマイズ

テンプレートをカスタマイズする場合は、以下のファイルを編集してください：

- `cookiecutter-kmp-mobile-tuist/cookiecutter.json`: 変数定義とデフォルト値
- `cookiecutter-kmp-mobile-tuist/hooks/pre_gen_project.py`: 生成前のバリデーション
- `cookiecutter-kmp-mobile-tuist/hooks/post_gen_project.py`: 生成後の処理
- `cookiecutter-kmp-mobile-tuist/{{cookiecutter.project_name}}/`: テンプレートファイル本体
