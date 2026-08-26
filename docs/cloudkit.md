# CloudKit 導入検討（iPhone / iPad 同期）

**ステータス: 検討中（未着手）**
目的は「同じ Apple ID の iPhone と iPad で同じデータを見られること」。SwiftData は `ModelConfiguration` に `cloudKitDatabase` を指定するだけでプライベートデータベースへのミラーリングが有効になるため、実装量そのものは小さい。ハードルはコードよりも **前提条件とスキーマの不可逆性** にある。

## 1. 現状のモデルは CloudKit 互換か

CloudKit ミラーリング（NSPersistentCloudKitContainer）には、Core Data / SwiftData のスキーマに対する制約がある。現状のモデルを照合した結果:

| 要件 | 現状 | 判定 |
|---|---|---|
| すべてのプロパティが optional かデフォルト値を持つ | `Company` / `JobEvent` / `Submission` の全プロパティにデフォルト値あり | ✅ |
| `@Attribute(.unique)` を使っていない | 未使用 | ✅ |
| すべてのリレーションが optional | `JobEvent.company` / `Submission.company` はいずれも `Company?` | ✅ |
| すべてのリレーションに inverse がある | `Company.events` / `Company.submissions` に `inverse:` 指定あり | ✅ |
| `deleteRule` に `.deny` を使っていない | `.cascade` のみ | ✅ |

**結論: モデル側の変更なしで導入できる見込み。** これは偶然ではなく、SwiftData の `@Model` にデフォルト値を全部書く書き方をしていたおかげ。

要検証:

- `SelectionStatus` / `EventType` / `SubmissionType` / `SubmissionStatus` は `Codable` enum として保存されている。CloudKit 上ではバイナリ属性として同期される想定だが、実機で往復を確認すること。
- `Company.id: UUID` は現在どこからも参照されていない。CloudKit では一意制約が使えないため、重複マージの手がかりとして使うか、いっそ削除するかを決める。

## 2. 必要な前提条件

- [ ] **有料の Apple Developer Program** — CloudKit は無料アカウントでは使えない。`project.yml` の `DEVELOPMENT_TEAM` は現在空なので設定が必要
- [ ] iCloud コンテナ（例: `iCloud.com.towa.offerbound`）の作成
- [ ] entitlements ファイルの追加（現在このプロジェクトには存在しない）
- [ ] Background Modes に `remote-notification` を追加（他端末の変更をプッシュで受け取るため）
- [ ] 動作確認には iCloud にサインイン済みのシミュレータ / 実機が2台分必要

## 3. 実装手順（想定）

1. `JobHuntManager/JobHuntManager.entitlements` を追加し、`project.yml` の `JobHuntManager` ターゲットから参照する

   ```yaml
   entitlements:
     path: JobHuntManager/JobHuntManager.entitlements
     properties:
       com.apple.developer.icloud-container-identifiers:
         - iCloud.com.towa.offerbound
       com.apple.developer.icloud-services: [CloudKit]
   ```

2. `Info.plist` に `UIBackgroundModes: [remote-notification]` を追加
3. `JobHuntManagerApp.swift` の `ModelConfiguration` に `cloudKitDatabase:` を渡す

   ```swift
   let modelConfiguration = ModelConfiguration(
       schema: schema,
       isStoredInMemoryOnly: false,
       cloudKitDatabase: .private("iCloud.com.towa.offerbound")
   )
   ```

4. デバッグ実行の引数に `-com.apple.CoreData.CloudKitDebug 1` を足して同期ログを確認
5. CloudKit Console でスキーマを確認し、**リリース前に Development → Production へデプロイ**

## 4. リスク・注意点

- **スキーマは実質的に不可逆** — Production へデプロイした後は、フィールドの削除・型変更ができない（追加は可）。したがって **モデル設計を固めてから入れる** べきで、[backlog.md](backlog.md) の「選考の履歴・結果の記録」のようにモデルを触る変更は CloudKit 導入より先に済ませたい。
- **マイグレーション設計が前提** — 現状 `ModelContainer` 生成失敗は `fatalError` で、`VersionedSchema` も無い。同期を入れると「片方の端末だけ古いアプリ」という状況が常態化するため、先に P1 のマイグレーション対応を済ませること。
- **一意制約が使えない** — 2台で同じ企業を別々に登録すると重複行として同期される。手動マージ UI か、`id` ベースの重複検出を別途考える必要がある。
- **競合解決はフィールド単位の後勝ち** — カスタムのマージロジックは書けない。同じ提出物を2台で同時に編集すると、後から書いた側の値が残る。
- **既存のローカルデータ** — 同じストアファイルがミラーリング対象になるため、初回同期で全件がアップロードされる。バックアップを取ってから検証すること。
- **同期は即時ではない** — 数秒〜数分のラグがある。UI 側で「同期中」を示す必要があるかは要検討。

## 5. 代替案

CloudKit を入れない / まだ入れられない場合:

- **JSON エクスポート / インポート** — 手動同期にはなるが、Developer Program 不要で、端末紛失時のバックアップ手段にもなる。実装コストも小さい。バックログに独立した項目として入れてある。

## 6. 判断のポイント

先に決めたいこと:

1. 有料の Developer Program に入るか（入らないなら JSON エクスポート一択）
2. モデル変更を伴う機能（選考履歴など）を CloudKit の前に入れるか、後に回すか
3. 重複データを許容するか、マージ UI を作るか
