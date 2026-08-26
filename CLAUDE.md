# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

**Offerbound** — 就活（新卒採用）の選考状況を管理する iOS アプリ。SwiftUI + SwiftData、端末内保存のみ。UI 文言・コメントはすべて日本語。

## コマンド

プロジェクトは XcodeGen 管理（`project.yml` が正）。

```sh
# ファイルを追加・移動・削除したら必須
xcodegen generate

# ビルド
xcodebuild -project JobHuntManager.xcodeproj -scheme JobHuntManager \
  -destination 'generic/platform=iOS Simulator' build

# 全テスト（<name> は `xcrun simctl list devices available` で確認）
# ※ `xcode-select -p` が CommandLineTools を指している環境では
#    DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer を前置する
xcodebuild -project JobHuntManager.xcodeproj -scheme JobHuntManager \
  -destination 'platform=iOS Simulator,name=iPhone 17' test

# 単一クラス / 単一テスト
xcodebuild ... test -only-testing:JobHuntManagerTests/SubmissionTests
xcodebuild ... test -only-testing:JobHuntManagerTests/SubmissionTests/testUrgencyBoundaryAtThreeDays

# デモデータ付き起動（DEBUG かつストアが空のときだけ投入される）
xcrun simctl launch <device> com.towa.offerbound -seedSampleData
```

`.xcodeproj` は生成物だが Git 追跡されている。`xcodegen generate` は `xcshareddata/xcschemes/` も上書きするので、生成後の差分は `git diff` で確認してからコミットする。

## アーキテクチャ

ViewModel 層はない。View が `@Query` で SwiftData を直接読み、ロジックはモデルの computed property か `Date` 拡張に置く。

- **Models/** — `Company` ⇄ `JobEvent` / `Submission` の1対多。`Company` 側に `@Relationship(deleteRule: .cascade, inverse:)` を張っているのでカスケード削除は SwiftData 任せ。
- **Views/** — タブ3枚（`RootTabView`）。Home はサマリー＋直近、Company は一覧→詳細、Deadline は全企業横断の締切一覧。
- **Support/Theme.swift** — 色・フォント・共通コンポーネント（`StatusPillView` / `PriorityDotsView` / `cardStyle()` / `AppBackground`）の集約先。新しい色やカード装飾をここ以外に書かない。
- **Support/DateFormatter+Ext.swift** — 表示用フォーマットと `relativeDeadlineLabel`（「今日」「あと3日」「2日超過」）。

### 落とし穴（テストで固定済み。壊すと退行する）

- **逆関係を手で append しない。** `JobEvent(... , company: c)` / `Submission(... , company: c)` をイニシャライザで渡して `context.insert` するだけで関係が張られる。追加で `c.events.append(...)` すると二重登録になる（`RelationshipTests`）。
- **固定フォーマットの `DateFormatter` には `en_US_POSIX` を指定する。** 端末が和暦設定だと `0008/06/15` になる（`DateFormattingTests`）。
- **日付の比較は `Calendar.startOfDay` 起点で行う。** ホームの「今後7日」も `Submission.urgency` の3日判定も 0:00 基準。時刻起点にすると当日分が消える。
- **enum の `rawValue` が表示ラベル兼永続化値。** `SelectionStatus` などの `rawValue` を変えると既存データが読めなくなるので、表示だけ変えたいときは `label` 側で吸収する。
- **ライトテーマ固定。** `.preferredColorScheme(.light)` は `RootTabView` と各シート（`NavigationStack` を自前で持つ Edit 系 View）にそれぞれ必要。シートは別の presentation context なので継承されない。

### 編集フォームの規約

`*EditView` は `let model: Model?`（nil = 新規、値あり = 編集）を受け取り、`@State` にミラーして `.onAppear` で `loadExistingValues()`、`save()` で書き戻して `dismiss()`。新規/編集の分岐はこの1パターンに揃える。

## ドキュメント

- `docs/backlog.md` — 既知の課題と改善バックログ（P1: マイグレーション設計、企業削除導線、`urgency` の `Date()` 直参照 など）。作業前に該当項目がないか確認する。
- `docs/cloudkit.md` — CloudKit 同期の検討メモ。

## Git 規約

**ブランチ名**は `種別-機能名`。種別は次の4つのみ。

| 種別 | 用途 | 例 |
|---|---|---|
| `feature` | 機能追加 | `feature-company-delete` |
| `fix` | バグ修正 | `fix-deadline-jp-calendar` |
| `doc` | ドキュメントのみ | `doc-cloudkit-note` |
| `refactor` | 挙動を変えない整理 | `refactor-extract-summary-logic` |

**コミットメッセージ**は `種別: 内容` の1行形式（ブランチと同じ4種別。ただし機能追加は `feat:`）。

```
feat: 企業一覧にスワイプ削除を追加
fix: 提出済みの提出物が「◯日超過」と表示される問題を修正
doc: バックログに P1 の項目を追記
refactor: ホームの集計ロジックをテスト可能な型に切り出し
```

`main` に直接コミットせず、必ず上記の命名でブランチを切ってから作業する。
