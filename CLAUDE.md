# CLAUDE.md
当資料は英語で記載しますが、特別事情がなければ出力は日本語にしてください。
@README.md

# 諸注意
- sample-projectを編集する場合、明確な指示がなければ cookiecutter-kmp-mobile-tuist 配下への変更は不要。

# テストの実行

## 事前準備
```bash
# mise と cookiecutter をセットアップ
mise trust
mise run python-install
```

## CLI ツールのテスト

### 1. ヘルプメッセージの確認
```bash
./kmp-mobile-tuist --help
```

### 2. プロジェクト作成テスト（cookiecutter 直接実行）
```bash
# テンポラリディレクトリにテストプロジェクトを作成
mise exec -- cookiecutter \
  "https://github.com/kk-house-777/kmp-mobile-tuist-template.git" \
  --directory "cookiecutter-kmp-mobile-tuist" \
  --no-input \
  --output-dir /tmp/kmp-test \
  project_name=TestKMPApp \
  bundle_id_prefix=com.test.kmpapp
```

**期待結果**: プロジェクトが `/tmp/kmp-test/TestKMPApp` に生成される

### 3. 生成されたプロジェクトのビルド確認
```bash
# Android アプリのビルド
cd /tmp/kmp-test/TestKMPApp
./gradlew android-app:assembleDebug --no-daemon
```

**期待結果**: ビルドが成功し、APK が生成される

### 4. クリーンアップ
```bash
rm -rf /tmp/kmp-test
```

## テスト項目チェックリスト
- [ ] ヘルプメッセージが正しく表示される
- [ ] プロジェクトが正常に生成される
- [ ] パッケージ名が正しく置換される（`com.test.kmpapp`）
- [ ] Android アプリがビルドできる
- [ ] 生成されたプロジェクト構造が正しい

## 既知の問題
- `kmp-mobile-tuist` スクリプトは mise 環境で cookiecutter コマンドが PATH に通っている必要がある
- cookiecutter 2.6.0 では `--extra-context` オプションではなく、位置引数として `key=value` 形式で渡す必要がある