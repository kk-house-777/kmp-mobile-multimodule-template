# KMP Mobile Tuist Template

Cookiecutterベースのテンプレートで、Kotlin Multiplatform (KMP) + Tuist を使ったモバイルプロジェクトを生成します。

## 必要な環境

- Python 3.x
- cookiecutter (`pip install cookiecutter`)

## 使い方

### 対話形式で作成

```bash
cookiecutter path/to/cookiecutter-kmp-mobile-tuist
```

または、プロジェクトルートから：

```bash
./kmp-mobile-tuist create
```

### 引数を指定して作成

```bash
./kmp-mobile-tuist create \
  --project-name MyApp \
  --bundle-id com.mycompany.myapp \
  --android-app-name MyApp \
  --ios-app-name MyApp
```

### ノンインタラクティブモード

```bash
./kmp-mobile-tuist create \
  --project-name MyApp \
  --bundle-id com.mycompany.myapp \
  --no-input
```

## テンプレート変数

| 変数名 | 説明 | デフォルト値 | 例 |
|--------|------|-------------|-----|
| `project_name` | プロジェクト名 | `App` | `MyApp`, `TodoApp` |
| `android_app_name` | Androidアプリ名 | `{{ project_name }}` | `MyApp` |
| `ios_app_name` | iOSアプリ名 | `{{ project_name }}` | `MyApp` |
| `bundle_id_prefix` | Bundle ID / Application ID のプレフィクス | `com.example.app` | `com.mycompany.myapp` |

## 生成されるプロジェクト構造

```
{{ project_name }}/
├── android-app/                     # Androidアプリケーション
│   ├── src/
│   │   ├── androidMain/kotlin/{{ bundle_id_path }}/
│   │   └── androidUnitTest/kotlin/{{ bundle_id_path }}/
│   └── build.gradle.kts
├── kmp-libraries/                   # KMPライブラリ群
│   └── feature/
│       ├── src/
│       │   ├── commonMain/kotlin/{{ bundle_id_path }}/feature/
│       │   ├── commonTest/kotlin/{{ bundle_id_path }}/feature/
│       │   ├── androidMain/kotlin/{{ bundle_id_path }}/feature/
│       │   └── iosMain/kotlin/{{ bundle_id_path }}/feature/
│       └── build.gradle.kts
├── ios/                             # iOSプロジェクト (Tuist)
│   ├── Project.swift
│   ├── Tuist/Package.swift
│   └── xcconfigs/ios-app.xcconfig
├── build-logic/                     # Gradle Convention Plugins
└── settings.gradle.kts
```

## 生成後の手順

```bash
# 1. プロジェクトディレクトリに移動
cd {{ project_name }}

# 2. Tuistなどのツールをインストール
mise install

# 3. Androidアプリをビルド
./gradlew build

# 4. iOSプロジェクトを生成
cd ios && tuist generate
```

## テンプレートのカスタマイズ

テンプレートをカスタマイズする場合は、以下のファイルを編集してください：

- `cookiecutter.json`: 変数定義とデフォルト値
- `hooks/pre_gen_project.py`: 生成前のバリデーション
- `hooks/post_gen_project.py`: 生成後の処理
- `{{cookiecutter.project_name}}/`: テンプレートファイル本体

## ライセンス

このテンプレートは自由に使用・改変できます。
