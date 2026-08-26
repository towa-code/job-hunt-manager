# モデル変更とマイグレーション

`VersionedSchema` / `SchemaMigrationPlan` を導入するまでの間、モデルを変えるときに踏んではいけない罠と、変更が安全かを確かめる手順。

背景と着手の期限は [backlog.md](backlog.md) の「モデル変更の扱い」を参照。

---

## 罠1: 非 Optional の enum プロパティを追加すると既存インストールが落ちる

2026-08-26、インターン選考対応（`SelectionKind` の追加）を実装する際に実機検証で判明した。

```swift
// これをやると、既存データを持つ端末で起動直後にクラッシュする
var kind: SelectionKind = SelectionKind.fullTime
```

Swift 側の `= .fullTime` は**オブジェクトの初期化時にしか効かない**。自動軽量マイグレーションでカラム（`ZKIND`）は追加されるが、**既存行の値は NULL のまま**で、デフォルト値は書き込まれない。その NULL を非 Optional の enum として読んだ瞬間に落ちる。

```
swift_dynamicCastFailure
  → SwiftData
  → Company.kind.getter
```

### 対処: Optional で保存し、非 Optional のアクセサで既定値を与える

```swift
/// 保存用。移行済みの既存行は NULL で読まれるため Optional にする。
/// 直接触るのは `kind` のアクセサだけ。
var kindRaw: SelectionKind?

/// 未設定（移行済みの既存行）は本選考として扱う
var kind: SelectionKind {
    get { kindRaw ?? .fullTime }
    set { kindRaw = newValue }
}
```

`Date?` や `String?` のような **もともと Optional な型の追加は問題ない**（NULL が正当な値なので）。危ないのは「非 Optional で宣言された、NULL を表現できない型」。

## 罠2: `rawValue` を変えると既存データが読めなくなる

`SelectionStatus` などの `rawValue` は永続化値そのもの。`case writtenTest = "筆記"` を `case test = "テスト"` に変えると、`"筆記"` を保存済みの端末は次の起動で落ちる。

```
Fatal error: Failed to decode a composite attribute:
  CompositeAttribute - name: status, valueType: SelectionStatus
```

表示だけ変えたいときは `label` 側で吸収する。選考区分ごとに表示を変える例:

```swift
func label(for kind: SelectionKind) -> String {
    switch (self, kind) {
    case (.applied, .internship): return "応募"
    case (.offer, .internship): return "参加確定"
    default: return rawValue
    }
}
```

---

## 変更が安全かを確かめる手順

自動テストでは検出できない（テストは毎回まっさらなインメモリストアを使うため）。**変更前のモデルで作ったストアを、変更後のアプリで開けるか**を実機で確かめる。

開発中のシミュレータとは**別のデバイス**を使うこと。同じ bundle ID なので、作業中のシミュレータを使うと Xcode からの実行と衝突する。

```sh
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
DEV=<検証用デバイスのUDID>   # xcrun simctl list devices available で確認
```

### 1. 変更前のモデルでストアを作る

モデル変更を当てる前のコードで:

```sh
xcodebuild -project JobHuntManager.xcodeproj -scheme JobHuntManager \
  -configuration Debug -destination "id=$DEV" -derivedDataPath /tmp/dd build

xcrun simctl uninstall $DEV com.towa.offerbound
xcrun simctl install $DEV /tmp/dd/Build/Products/Debug-iphonesimulator/JobHuntManager.app
xcrun simctl launch $DEV com.towa.offerbound -seedSampleData
```

保存されたことを確認:

```sh
CONT=$(xcrun simctl get_app_container $DEV com.towa.offerbound data)
sqlite3 "$CONT/Library/Application Support/default.store" "select count(*) from ZCOMPANY;"
```

### 2. モデルを変更して、上書きインストールする

`uninstall` してはいけない（データが消えて検証にならない）。`install` は上書きしてもデータコンテナを保持する。

```sh
xcodebuild ... build
xcrun simctl install $DEV .../JobHuntManager.app   # 上書き
xcrun simctl launch $DEV com.towa.offerbound
```

### 3. クラッシュしていないか確認する

`launch` は成功した扱いで PID を返すため、戻り値では判定できない。プロセスの生存とクラッシュログの増加を見る。

```sh
xcrun simctl spawn $DEV launchctl list | grep offerbound   # 生きているか
ls ~/Library/Logs/DiagnosticReports/JobHuntManager*.ips | wc -l   # 前後で増えていないか
```

新カラムと既存データの状態も確認する:

```sh
sqlite3 "$CONT/Library/Application Support/default.store" "pragma table_info(ZCOMPANY);"
sqlite3 "$CONT/Library/Application Support/default.store" "select count(*) from ZCOMPANY;"
```

### 4. 追加したプロパティを実際に読ませる

ここが要点。**カラムが増えただけでは落ちない。** NULL の値を読んで初めて落ちる。起動時に必ず通る場所（ホームの集計など）から新プロパティを参照させた状態で 3 を再実行する。これをやらないと罠1 を見逃す。
