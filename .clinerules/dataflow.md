## iPhone ⇆ Apple Watch ― データフローデザイン（PoC 版）

> **前提**
>
> * **スタンドアロン通信（直接 REST ↔︎ watch）** は後回し。
> * 今は **iPhone をゲートウェイ** にしてクラウドと同期する。
> * Swift / SwiftUI / `WCSession` が使える環境（watchOS 10 以上）を想定。

---

### 1. 役者と責務

| レイヤ                         | 主な責務                | 主要 API                               |
| --------------------------- | ------------------- | ------------------------------------ |
| **Watch UI (Presentation)** | 最近種目・全種目・ワークアウト記録画面 | SwiftUI Scene / `ObservableObject`   |
| **Watch Data Cache**        | オフライン保持・キューイング      | *SwiftData*（watchOS 10〜）or Core Data |
| **Watch ↔︎ iPhone Relay**   | 双方向転送・再送制御          | `WCSession`                          |
| **iPhone Repository**       | REST 呼び出し・永続キャッシュ   | `APIService` + Core Data             |
| **Cloud**                   | 本番 API              | —                                    |

---

### 2. WCSession で使い分ける転送メソッド

| 転送メソッド                         | 適材適所                    | 特徴                                   |
| ------------------------------ | ----------------------- | ------------------------------------ |
| **`sendMessage`**              | *即時* に欲しいデータ（最近種目）      | 双方向・即レスポンス・前提：双方フォアグラウンド & Reachable |
| **`updateApplicationContext`** | “全種目リスト” など**スナップショット** | 最新状態 1 件のみ保持。重い JSON 可。              |
| **`transferUserInfo`**         | Workout Set の **キュー送信** | 到達保証あり。大量でもバックグラウンド送信                |
| **`transferFile`**             | 画像／CSV など               | 今回は不要                                |

---

### 3. フロー別タイムライン

#### 3-1 最近行った種目 (高頻度)

```
WatchView.onAppear ─▶ sendMessage("recentExercises")
                └─▶ Show cached list (SwiftData)
                              ▲
iPhone didReceiveMessage ──┐  │
    fetchRecentExercises() │  │
    reply(recents DTO) ────┘  │
                              │
         save to SwiftData ◀──┘  (watch side)
```

*失敗時* は `WCSessionReachabilityDidChange` で再試行。

#### 3-2 全種目リスト (低頻度 + イベント駆動)

| トリガ                       | アクション                                                                        |
| ------------------------- | ---------------------------------------------------------------------------- |
| **① Watch 初回起動**          | `applicationContext` にリストがあれば即ロード。なければ `sendMessage("allExercisesIfStale")`. |
| **② iPhone 側でカスタム種目追加完了** | iPhone 更新後 → `updateApplicationContext` で全リスト送信（サーバ書き込み後で OK）                |
| **③ 24h 経過など**            | `BGAppRefreshTask` on iPhone で API リフレッシュ → `applicationContext` 再送          |

> Watch は `applicationContext` を `didReceiveApplicationContext` で拾い、SwiftData に置き換えるだけ。

#### 3-3 ワークアウト記録

1. **Watch で Set 作成 / 更新 / 削除**

   ```swift
   queue.append(SetEvent.create(payload))
   try? wcSession.transferUserInfo(payload)
   SwiftData.save(event)   // 楽観的 UI
   ```
2. **iPhone 受信 (`didReceiveUserInfo`)** → Core Data に反映 → `APIService` でクラウド POST。
   *成功時* → `reply` で **正式 ID** を送信。
3. **Watch 返信受信** → 楽観保存した `tempId` を正式 ID に置き換え。

> ⚠️ *到達保証付き* なので **地下鉄圏外でもローカル保存 → 後で送信** が成立。

---

### 4. ローカルキャッシュ設計（Watch）

| テーブル              | 主キー                     | 保存ポリシー                       |
| ----------------- | ----------------------- | ---------------------------- |
| `Exercise`        | exerciseId              | 全種目 (applicationContext)     |
| `RecentExercise`  | exerciseId + accessedAt | 最近 100 件・LRU                 |
| `WorkoutSetEvent` | tempId / setId          | **未送信 or ACK 待ち** が残るようフラグ持ち |

*Migration* は SwiftData なら自動、Core Data なら momd 版管理。

---

### 5. ベストプラクティス Tips

| シーン            | 推奨                                                                       |
| -------------- | ------------------------------------------------------------------------ |
| **起動直後**       | `onAppear` で即キャッシュ表示 → 非同期に `sendMessage` で最新化                           |
| **バックグラウンド転送** | iOS 側は **`BGAppRefreshTask`** で /dashboard 他を取得し `applicationContext` 更新 |
| **到達確認**       | `WCSession.defaultOutstandingUserInfoTransfers` を監視して再送 or エラー表示         |
| **パフォーマンス**    | applicationContext は 65 KB 制限。全種目が超える場合は分割で `transferUserInfo`           |
| **オフライン衝突**    | Set 更新競合は **iPhone を正** とし `updatedAt` で勝敗を決定                            |
| **電池**         | 長時間タイマーは `WKExtendedRuntimeSession` を活用。セット編集画面閉じたら `invalidate()`       |

---

### 6. 今後スタンドアロン化するときの差分

| 現在 (Relay)    | 後で (REST on watch)                        |                                           |
| ------------- | ----------------------------------------- | ----------------------------------------- |
| Repository 実装 | `WCSessionRelayRepository`                | `APIService` (watch build‐flag)           |
| DI 変更         | `#if os(watchOS) && !STANDALONE_DISABLED` | toggled by build configuration            |
| キャッシュ         | そのまま流用                                    | そのまま流用                                    |
| 同期            | 必要                                        | オフライン用に `CloudKit/Persistence` で二層 commit |

---

## まとめ

1. **最新が欲しいデータ**＝`sendMessage`、**スナップショット**＝`applicationContext`、
   **信頼性重視書き込み**＝`transferUserInfo` の三本柱で実装。
2. Watch 側は **SwiftData にすべて書く → 楽観的 UI**。
3. iPhone がオンライン時に **REST API** と同期し、完了したら ACK。
4. タイマー・メディア操作は watch 側だけで完結（WCSession 無関係）。

このフローなら PoC フェーズでも “体感リアルタイム” の UX を維持しつつ、
後でスタンドアロン REST に置き換えるときは **Repository の差し替え** だけで済みます。
