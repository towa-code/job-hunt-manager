# Offerbound（就活管理）

就活に関わる情報を一元管理する iOS アプリです。企業ごとに選考状況・面接などの予定・ES などの提出書類をまとめて管理し、直近の予定と締切をひと目で把握できます。

## スクリーンショット概要

- **ホーム**: 選考中の企業数・今後7日の予定数・期限間近の提出物数のサマリーカードと、直近の予定／締切一覧
- **企業**: 検索バーとステータスチップで絞り込める企業一覧 → 詳細画面で予定・提出物を管理
- **締切**: 全企業横断の提出物を「期限超過 / 3日以内 / それ以降 / 提出済」に自動分類

## 主な機能

### 企業管理
- 企業名・業界・URL・メモ・志望度（●●○ の3段階）を登録
- 選考ステータス（興味あり → エントリー → ES提出 → 筆記 → 面接中 → 内定 / 見送り）
- 詳細画面のステータスピルをタップしてその場で変更可能
- 企業名・業界での検索、ステータスチップでのフィルタ

### 予定管理
- 説明会・面接・筆記・OB訪問などの予定を企業に紐づけて登録
- ホームに直近の予定を日付順で表示、企業一覧にも「次の予定」を表示

### 提出物管理
- ES・履歴書などを締切・ステータス（未着手 / 作成中 / 提出済）付きで管理
- 本文メモ欄に ES の下書きを保存可能
- 締切は「今日」「明日」「あと◯日」「◯日超過」の相対表示
- **左スワイプで即「提出済」にできるクイック操作**

### プロフィール
- 氏名・フリガナ（姓/名を分けて保持）・生年月日・連絡先・学歴・資格・URL を登録
- **各行をタップするとクリップボードにコピー**。ES や応募フォームへの転記に使う
- 生年月日は西暦・和暦・年齢の3行に展開し、それぞれ単体でコピー可能
- 氏名と住所は結合形（「鈴木 太郎」「東京都〜1-1-1」）も別行で用意し、入力欄が1つのフォームにも対応
- 未入力の項目は行ごと表示しない

### データ
- SwiftData による端末内保存（サーバー・アカウント不要）
- 企業を削除すると紐づく予定・提出物もまとめて削除（カスケード）

## 技術スタック

| 項目 | 内容 |
|---|---|
| 言語 | Swift |
| UI | SwiftUI |
| 永続化 | SwiftData |
| 最小バージョン | iOS 17.0 |
| プロジェクト生成 | [XcodeGen](https://github.com/yonaskolb/XcodeGen)（`project.yml`） |

## プロジェクト構成

```
JobHuntManager/
├── JobHuntManagerApp.swift        # エントリポイント・ModelContainer 設定
├── Models/
│   ├── Company.swift              # 企業 + 選考ステータス
│   ├── JobEvent.swift             # 予定 + 種別
│   ├── Submission.swift           # 提出物 + 種別・ステータス・緊急度
│   └── Profile.swift              # プロフィール + 資格・URL
├── Views/
│   ├── RootTabView.swift          # 3タブのルート
│   ├── Home/                      # ホーム（サマリー + 直近の予定・締切）
│   ├── Company/                   # 企業一覧・詳細・編集フォーム
│   ├── Event/                     # 予定の編集フォーム
│   ├── Submission/                # 提出物の編集フォーム
│   ├── Deadline/                  # 締切一覧
│   └── Profile/                   # プロフィール（表示・編集フォーム）
└── Support/
    ├── Theme.swift                # デザインシステム（色・フォント・共通コンポーネント）
    └── DateFormatter+Ext.swift    # 日付フォーマット・相対締切表示・和暦・満年齢
```

## ビルド方法

XcodeGen と Xcode（15 以降推奨）が必要です。

```sh
# XcodeGen のインストール（未導入の場合）
brew install xcodegen

# .xcodeproj の生成
xcodegen generate

# Xcode で開く
open JobHuntManager.xcodeproj
```

あとは Xcode からシミュレータまたは実機で実行してください。

> **Note**: ファイルを追加・移動した場合は `xcodegen generate` を再実行してください。プロジェクト構成は `project.yml` で管理しています。

### コマンドラインでのビルド・テスト

```sh
# ビルド
xcodebuild -project JobHuntManager.xcodeproj -scheme JobHuntManager \
  -destination 'generic/platform=iOS Simulator' build

# ユニットテスト
xcodebuild -project JobHuntManager.xcodeproj -scheme JobHuntManager \
  -destination 'platform=iOS Simulator,name=iPhone 17' test
```

### デモデータ

デバッグビルドで起動引数 `-seedSampleData` を付けると、ストアが空の場合のみサンプルデータ（企業6社・予定・提出物・プロフィール1件）が投入されます。

```sh
xcrun simctl launch <device> com.towa.offerbound -seedSampleData
```

## デザイン

モダン・ミニマルなライトテーマです。

- オフホワイトの背景に右上のオレンジグロウ、白いカード＋薄い影
- アクセントはシグナルオレンジ1色。選考ステータスは色付きドットのピルで表現
- 見出しは丸ゴシック（rounded）、日付・数値は等幅フォント

カラーパレットや共通コンポーネント（`StatusPillView` / `PriorityDotsView` / `cardStyle()` など）は `Support/Theme.swift` に集約しています。

## 今後の改善・追加機能案

改善バックログと設計メモは [`docs/`](docs/) にまとめています。

- [docs/backlog.md](docs/backlog.md) — 改善バックログ（既知の課題・追加機能案）
- [docs/cloudkit.md](docs/cloudkit.md) — iPhone / iPad 同期に向けた CloudKit 導入の検討
