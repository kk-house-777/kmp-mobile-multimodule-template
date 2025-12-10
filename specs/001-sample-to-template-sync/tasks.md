# Tasks: Sample Project to Template Synchronization

**Input**: Design documents from `/specs/001-sample-to-template-sync/`
**Prerequisites**: plan.md (required), spec.md (required for user stories)

**Tests**: テストはオプションであり、spec.mdでの明示的な要求がない限り含まれません。

**Organization**: タスクはユーザーストーリー別に整理され、各ストーリーの独立した実装とテストを可能にします。

## Format: `[ID] [P?] [Story] Description`

- **[P]**: 並列実行可能（異なるファイル、依存関係なし）
- **[Story]**: このタスクが属するユーザーストーリー（例: US1, US2, US3）
- 説明には正確なファイルパスを含む

## Path Conventions

このプロジェクトは以下の構造を使用します:
- **スクリプト**: `scripts/` (リポジトリルート)
- **GitHub Actions**: `.github/workflows/`
- **テスト**: `tests/sync-sample-to-template/`
- **ドキュメント**: `specs/001-sample-to-template-sync/`

---

## Phase 1: Setup (共通インフラ)

**目的**: プロジェクト初期化と基本構造

- [ ] T001 スクリプトディレクトリを作成 `scripts/`
- [ ] T002 テストディレクトリを作成 `tests/sync-sample-to-template/`
- [ ] T003 [P] bats-coreのセットアップ方法をREADMEに追記（オプション）

---

## Phase 2: Foundational (全ストーリーの前提条件)

**目的**: 全てのユーザーストーリーが依存するコアインフラ

**⚠️ 重要**: このフェーズが完了するまで、ユーザーストーリーの作業を開始できません

- [ ] T004 パスマッピング機能の実装 in `scripts/sync-sample-to-template.sh`
- [ ] T005 [P] Jinja2変数検出機能の実装 in `scripts/sync-sample-to-template.sh`
- [ ] T006 基本的なCLI引数パース（--help）の実装 in `scripts/sync-sample-to-template.sh`

**Checkpoint**: 基盤完成 - ユーザーストーリーの実装を並列で開始可能

---

## Phase 3: User Story 1 - 手動での変更反映 (Priority: P1) 🎯 MVP

**Goal**: 開発者がsample-projectに変更を加えた後、その変更をtemplateに手動で反映させる。Jinja2変数は保護される。

**Independent Test**: sample-projectの任意のファイル（例：build.gradleの依存関係）を変更し、同期コマンドを実行することで、templateの対応するファイルが更新され、Jinja2変数が保持されていることを確認できる。

### Implementation for User Story 1

- [ ] T007 [P] [US1] Git diff解析機能の実装（変更ファイル検出） in `scripts/sync-sample-to-template.sh`
- [ ] T008 [US1] ファイル同期ロジックの実装（追加・変更・削除対応） in `scripts/sync-sample-to-template.sh`
- [ ] T009 [US1] Jinja2変数保護機能の統合 in `scripts/sync-sample-to-template.sh`
- [ ] T010 [US1] 同期レポート生成機能の実装（標準出力） in `scripts/sync-sample-to-template.sh`
- [ ] T011 [US1] スクリプトに実行権限を付与し、基本動作確認

**Checkpoint**: この時点でUser Story 1は完全に機能し、独立してテスト可能です

---

## Phase 4: User Story 2 - 変更の検証と安全性確保 (Priority: P2)

**Goal**: 開発者が同期を実行する際、templateの置換部分に影響を与える変更がある場合は警告を受け、同期をスキップできる。

**Independent Test**: Jinja2変数を含むファイルをsample-projectで変更し、同期を実行すると警告が表示され、そのファイルがスキップされることを確認できる。

### Implementation for User Story 2

- [ ] T012 [P] [US2] ドライランモード（--dry-run）の実装 in `scripts/sync-sample-to-template.sh`
- [ ] T013 [P] [US2] 詳細ログモード（--verbose）の実装 in `scripts/sync-sample-to-template.sh`
- [ ] T014 [US2] スキップファイルの詳細レポート機能の実装 in `scripts/sync-sample-to-template.sh`
- [ ] T015 [US2] エラーハンドリングと適切な終了コードの実装 in `scripts/sync-sample-to-template.sh`

**Checkpoint**: User Stories 1と2の両方が独立して動作することを確認

---

## Phase 5: User Story 3 - GitHub Actions による自動同期 (Priority: P3)

**Goal**: mainブランチへのpushまたはマージ時に、sample-projectの変更が自動的にtemplateに反映される。

**Independent Test**: sample-projectの変更を含むPRをmainにマージし、GitHub Actionsワークフローが起動して、自動的にtemplateが更新され、コミットが作成されることを確認できる。

### Implementation for User Story 3

- [ ] T016 [P] [US3] GitHub Actionsワークフローファイルの作成 `.github/workflows/sync-template.yml`
- [ ] T017 [US3] ワークフロートリガー設定（mainブランチ、sample-project/**パス） in `.github/workflows/sync-template.yml`
- [ ] T018 [US3] 同期スクリプト実行ステップの追加 in `.github/workflows/sync-template.yml`
- [ ] T019 [US3] 自動コミット・プッシュロジックの追加 in `.github/workflows/sync-template.yml`
- [ ] T020 [US3] 失敗時の通知設定（GitHub Actions標準） in `.github/workflows/sync-template.yml`

**Checkpoint**: 全てのユーザーストーリーが独立して機能することを確認

---

## Phase 6: Polish & Cross-Cutting Concerns

**目的**: 複数のユーザーストーリーに影響する改善

- [ ] T021 [P] クイックスタートガイドの作成 `specs/001-sample-to-template-sync/quickstart.md`
- [ ] T022 [P] エッジケースのドキュメント化（バイナリファイル、シンボリックリンクなど） in `quickstart.md`
- [ ] T023 実際のsample-project変更でのE2Eテスト実施
- [ ] T024 [P] bats-coreテストの作成（オプション） in `tests/sync-sample-to-template/test_sync.bats`
- [ ] T025 コードクリーンアップとコメント追加 in `scripts/sync-sample-to-template.sh`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: 依存関係なし - 即座に開始可能
- **Foundational (Phase 2)**: Setupの完了に依存 - 全てのユーザーストーリーをブロック
- **User Stories (Phase 3+)**: 全てFoundational phaseの完了に依存
  - ユーザーストーリーは並列で進行可能（リソースがある場合）
  - または優先順位順に順次実行（P1 → P2 → P3）
- **Polish (Final Phase)**: 全ての希望するユーザーストーリーの完了に依存

### User Story Dependencies

- **User Story 1 (P1)**: Foundational (Phase 2)の後に開始可能 - 他のストーリーに依存なし
- **User Story 2 (P2)**: Foundational (Phase 2)の後に開始可能 - US1と統合するがUS1に依存する（US1の機能を拡張）
- **User Story 3 (P3)**: Foundational (Phase 2)の後に開始可能 - US1とUS2に依存する（既存の同期機能を自動化）

### Within Each User Story

- コア実装が統合前に完了
- ストーリー完了後、次の優先順位に移動

### Parallel Opportunities

- 全てのSetupタスクは並列実行可能
- Foundationalフェーズ内で[P]マークのタスクは並列実行可能
- User Story 1とUser Story 2の一部実装は並列可能（異なるファイル）
- Polishフェーズの[P]マークタスクは並列実行可能

---

## Parallel Example: User Story 1

```bash
# User Story 1内の並列可能なタスクをまとめて実行:
Task: "Git diff解析機能の実装（変更ファイル検出）"  # T007 [P] - 異なる関数
# 注: US1のタスクは相互依存が高いため、並列化の機会は限定的
```

---

## Implementation Strategy

### MVP First (User Story 1のみ)

1. Phase 1: Setupを完了
2. Phase 2: Foundationalを完了（重要 - 全ストーリーをブロック）
3. Phase 3: User Story 1を完了
4. **停止して検証**: User Story 1を独立してテスト
5. 準備ができたらデプロイ/デモ

### Incremental Delivery

1. Setup + Foundationalを完了 → 基盤完成
2. User Story 1を追加 → 独立テスト → デプロイ/デモ (MVP!)
3. User Story 2を追加 → 独立テスト → デプロイ/デモ
4. User Story 3を追加 → 独立テスト → デプロイ/デモ
5. 各ストーリーは前のストーリーを壊さずに価値を追加

### Parallel Team Strategy

複数の開発者がいる場合:

1. チーム全体でSetup + Foundationalを完了
2. Foundational完了後:
   - 開発者A: User Story 1（T007-T011）
   - 開発者B: User Story 2の一部準備（T012-T013の設計）
3. User Story 1完了後:
   - 開発者A: User Story 3（T016-T020）
   - 開発者B: User Story 2（T012-T015）

---

## Task Summary

- **合計タスク数**: 25タスク
- **User Story 1タスク数**: 5タスク（T007-T011）
- **User Story 2タスク数**: 4タスク（T012-T015）
- **User Story 3タスク数**: 5タスク（T016-T020）
- **並列実行機会**: SetupとFoundationalフェーズで最大3タスク、Polishフェーズで最大3タスク
- **推奨MVPスコープ**: Phase 1 + Phase 2 + Phase 3（User Story 1のみ）

---

## Notes

- [P]タスク = 異なるファイル、依存関係なし
- [Story]ラベルはタスクを特定のユーザーストーリーにマッピング（トレーサビリティのため）
- 各ユーザーストーリーは独立して完了・テスト可能
- 各タスクまたは論理的なグループの後にコミット
- 任意のチェックポイントで停止してストーリーを独立して検証
- 避けるべき: 曖昧なタスク、同じファイルの競合、独立性を壊すストーリー間依存
