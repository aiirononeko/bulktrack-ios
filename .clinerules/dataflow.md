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
| **iPhone Repository**       | REST呼び出し・CoreDataキャッシュ | `CachedExerciseRepository` + Core Data |
| **Cloud**                   | 本番 API              | —                                    |

---

### 2. iPhone CoreData キャッシュ戦略

| データ種別     | キャッシュ期間 | 戦略                                   | エンティティ                           |
| ------------- | ------------ | ------------------------------------ | ---------------------------------- |
| **全種目**     | 24時間       | Cache-First + API Fallback + Stale Cache | ExerciseCacheEntity                |
| **最近種目**   | 24時間       | Cache-First + API Fallback + 順序保持  | RecentExerciseCacheEntity          |
| **メタデータ** | ―            | キャッシュ有効性管理                      | CacheMetadata                      |

### 2.1 キャッシュフロー（iPhone）

```
searchExercises() ─▶ CachedExerciseRepository
                 │
                 ├─▶ 1. キャッシュ有効性チェック (CacheMetadata)
                 │   └─▶ Valid → ExerciseCacheRepository.getAllExercises()
                 │
                 ├─▶ 2. キャッシュ無効 → APIService.searchExercises()
                 │   └─▶ Success → ExerciseCacheRepository.saveAllExercises()
                 │
                 └─▶ 3. API失敗 → Stale Cache Fallback
```

**効果:**
- 種目選択画面の初回以降は即座に表示
- 1日1回のAPIリクエストに削減
- オフライン時の継続利用可能

---

### 3. WCSession で使い分ける転送メソッド

| 転送メソッド                         | 適材適所                    | 特徴                                   |
| ------------------------------ | ----------------------- | ------------------------------------ |
| **`sendMessage`**              | *即時* に欲しいデータ（最近種目）      | 双方向・即レスポンス・前提：双方フォアグラウンド & Reachable |
| **`updateApplicationContext`** | "全種目リスト" など**スナップショット** | 最新状態 1 件のみ保持。重い JSON 可。              |
| **`transferUserInfo`**         | Workout Set の **キュー送信** | 到達保証あり。大量でもバックグラウンド送信                |
| **`transferFile`**             | 画像／CSV など               | 今回は不要                                |

---

### 4. フロー別タイムライン

#### 4-1 最近行った種目 (高頻度) - キャッシュ対応

```
WatchView.onAppear ─▶ ViewModel.fetchRecentExercises() ─▶ RequestRecentExercisesUseCase.execute()
                │                                      └─▶ SessionSyncRepo.requestRecentExercises("recentExercises")
                │
                └─▶ Show cached list (SwiftData / ViewModel.State.success)
                                                                   ▲
iPhone (WCSessionRelay.didReceiveMessage) ─────────────────────────┤
    └─▶ HandleRecentExercisesRequestUseCase.execute() ────────────┤
        └─▶ CachedExerciseRepository.recentExercises() ───────────┤
            ├─▶ キャッシュ有効 → 即座にレスポンス ──────────────────────┤
            └─▶ キャッシュ無効 → API呼び出し → キャッシュ更新 ──────────┤
                                                                   │
Watch (SessionSyncRepo.recentExercisesPublisher) ◀─────────────────┘
    └─▶ ViewModel.recentExercisesState = .success(data)
        └─▶ save to SwiftData (if needed for caching)
```

*失敗時* は `WCSessionReachabilityDidChange` で再試行。

#### 4-2 全種目リスト (低頻度 + イベント駆動) - キャッシュ対応

| トリガ                       | アクション                                                                        |
| ------------------------- | ---------------------------------------------------------------------------- |
| **① Watch 初回起動**          | `applicationContext` にリストがあれば即ロード。なければ `sendMessage("allExercisesIfStale")`. |
| **② iPhone 側でカスタム種目追加完了** | iPhone: キャッシュ無効化 → API呼び出し → キャッシュ更新 → `updateApplicationContext` 送信      |
| **③ 24h 経過など**            | `BGAppRefreshTask` on iPhone でキャッシュ期限切れ → API リフレッシュ → `applicationContext` 再送 |

> Watch は `applicationContext` を `didReceiveApplicationContext` で拾い、SwiftData に置き換えるだけ。

#### 4-3 ワークアウト記録

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

### 5. ローカルキャッシュ設計

#### 5-1 iPhone (CoreData)

| エンティティ                     | 主キー      | 保存ポリシー                    | 用途               |
| ------------------------------ | ---------- | ----------------------------- | ----------------- |
| `ExerciseCacheEntity`          | exerciseId | 24時間TTL・全種目              | searchExercises() |
| `RecentExerciseCacheEntity`    | exerciseId | 24時間TTL・順序保持・最近100件   | recentExercises() |
| `CacheMetadata`                | key        | TTL管理・有効性フラグ           | キャッシュ制御      |

#### 5-2 Watch (SwiftData)

| テーブル              | 主キー                     | 保存ポリシー                       |
| ----------------- | ----------------------- | ---------------------------- |
| `Exercise`        | exerciseId              | 全種目 (applicationContext)     |
| `RecentExercise`  | exerciseId + accessedAt | 最近 100 件・LRU                 |
| `WorkoutSetEvent` | tempId / setId          | **未送信 or ACK 待ち** が残るようフラグ持ち |

*Migration* は SwiftData なら自動、Core Data なら momd 版管理。

---

### 6. キャッシュ無効化トリガー

| イベント                   | 無効化対象          | トリガー                                    |
| ------------------------ | ------------------ | ----------------------------------------- |
| **カスタム種目作成**        | 全種目キャッシュ      | `CacheInvalidationService.invalidateAllExercises()` |
| **種目情報更新**           | 全種目・最近種目     | `CacheInvalidationService.invalidateAllCaches()` |
| **24時間経過**            | 自動無効化          | `CacheMetadata.isCacheValid` チェック        |

---

### 7. ベストプラクティス Tips

| シーン            | 推奨                                                                       |
| -------------- | ------------------------------------------------------------------------ |
| **起動直後**       | `onAppear` で即キャッシュ表示 → 非同期に `sendMessage` で最新化                           |
| **バックグラウンド転送** | iOS 側は **`BGAppRefreshTask`** で /dashboard 他を取得し `applicationContext` 更新 |
| **到達確認**       | `WCSession.defaultOutstandingUserInfoTransfers` を監視して再送 or エラー表示         |
| **パフォーマンス**    | applicationContext は 65 KB 制限。全種目が超える場合は分割で `transferUserInfo`           |
| **オフライン衝突**    | Set 更新競合は **iPhone を正** とし `updatedAt` で勝敗を決定                            |
| **電池**         | 長時間タイマーは `WKExtendedRuntimeSession` を活用。セット編集画面閉じたら `invalidate()`       |
| **キャッシュ**      | Cache-First戦略でAPI呼び出しを1日1回に削減。フォールバック機能でオフライン対応。              |

---

### 8. 今後スタンドアロン化するときの差分

| 現在 (Relay)    | 後で (REST on watch)                        |                                           |
| ------------- | ----------------------------------------- | ----------------------------------------- |
| Repository 実装 | `WCSessionRelayRepository`                | `APIService` (watch build‐flag)           |
| DI 変更         | `#if os(watchOS) && !STANDALONE_DISABLED` | toggled by build configuration            |
| キャッシュ         | iPhone CoreData → WCSession共有            | watchOS独自CoreData + 同期機能               |
| 同期            | 必要                                        | オフライン用に `CloudKit/Persistence` で二層 commit |

---

## まとめ

1. **最新が欲しいデータ**＝`sendMessage`、**スナップショット**＝`applicationContext`、
   **信頼性重視書き込み**＝`transferUserInfo` の三本柱で実装。
2. **iPhone CoreDataキャッシュ**でパフォーマンス向上・データ使用量削減・オフライン対応を実現。
3. Watch 側は **SwiftData にすべて書く → 楽観的 UI**。
4. iPhone がオンライン時に **REST API** と同期し、完了したら ACK。
5. タイマー・メディア操作は watch 側だけで完結（WCSession 無関係）。

このフローなら PoC フェーズでも "体感リアルタイム" の UX を維持しつつ、
**1日1回のAPIリクエスト**でデータ使用量を削減し、
後でスタンドアロン REST に置き換えるときは **Repository の差し替え** だけで済みます。
