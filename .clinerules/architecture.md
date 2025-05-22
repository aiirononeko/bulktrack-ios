# BulkTrack Architecture Guide

## 0. TL;DR

| レイヤ                      | Swift Package       | iOS Target            | watchOS Target (single)   |
| ------------------------ | ------------------- | --------------------- | ------------------------- |
| **Domain**               | `Packages/Domain`   | import                | import                    |
| **Data**                 | `Packages/Data`     | import                | import                    |
| **Shared UI (optional)** | `Packages/SharedUI` | import                | import                    |
| **Presentation**         | –                   | `Apps/iOS/Features/*` | `Apps/watchOS/Features/*` |
| **App Bootstrap**        | –                   | `Apps/iOS/App/`       | `Apps/watchOS/App/`       |
| **Shared (Error Handling)** | `Packages/Domain`  | import                | import                    |

`Apps/watchOS` は **single target**（WatchApp）方式。Extension フォルダは不要で、SwiftUI の `@main` が直接 WatchApp に入ります。

---

## 1. Directory Tree (Complete)

```text
BulkTrack/
├── Docs/
│   └── ARCHITECTURE.md                 ← ★ このファイル
│
├── Packages/
│   ├── Domain/                         ← 100 % Pure Swift
│   │   ├── Sources/Domain/
│   │   │   ├── Entities/               # Business model objects
│   │   │   │   ├── AuthToken.swift
│   │   │   │   └── ExerciseEntity.swift # (e.g., Week, Dashboard ... are future additions)
│   │   │   ├── RepositoryProtocols.swift
│   │   │   ├── UseCases/               # Application-specific business rules
│   │   │   │   ├── Auth/
│   │   │   │   │   ├── ActivateDeviceUseCase.swift
│   │   │   │   │   └── LogoutUseCase.swift
│   │   │   │   └── WatchSync/
│   │   │   │       ├── RequestRecentExercisesUseCase.swift
│   │   │   │       └── HandleRecentExercisesRequestUseCase.swift
│   │   │   └── Shared/                 # Shared Domain Models (e.g. AppError, ResultState)
│   │   │       ├── AppError.swift
│   │   │       └── ResultState.swift
│   │   └── Tests/DomainTests/
│   │       └── DashboardEntityTests.swift # (Example test, actual tests may vary)
│   │
│   ├── Data/                           ← External data tech
│   │   ├── Sources/Data/
│   │   │   ├── Networking/
│   │   │   │   ├── APIService.swift    # Conforms to *Repository* protocols (e.g., AuthRepository, ExerciseRepository)
│   │   │   │   ├── NetworkClient.swift
│   │   │   │   └── APIError.swift      # (Now potentially wrapped by Domain/Shared/AppError.swift)
│   │   │   ├── Mapper/
│   │   │   │   ├── ExerciseMapper.swift
│   │   │   │   └── TokenMapper.swift   # (DashboardMapper etc. are future additions)
│   │   │   ├── DTO/                    # Data Transfer Objects mirroring API schema
│   │   │   │   ├── DashboardResponse.swift # (Actual DTOs based on API)
│   │   │   │   ├── ExerciseDTO.swift
│   │   │   │   └── WorkoutSetDTO.swift # (And others like TokenResponseDTO etc.)
│   │   │   ├── Storage/                # Secure storage (e.g. KeychainService)
│   │   │   │   └── KeychainService.swift
│   │   └── Tests/DataTests/
│   │       └── DataTests.swift         # (Formerly APIServiceMockTests.swift)
│   │
│   └── SharedUI/                       ← Design-system level components
│       ├── Sources/SharedUI/           # (Currently not extensively used or may not exist)
│       │   └── Charts/                 # (Example, actual components may vary)
│       │       ├── VolumeTrendGraph.swift
│       │       └── AverageRMTrendGraph.swift
│       └── Tests/SharedUITests/
│
├── Config/                             ← Build & infra configurations (formerly Shared/Configuration)
│   ├── Prod.xcconfig
│   ├── Secrets.xcconfig
│   └── Secrets.sample.xcconfig
│
├── Apps/
│   ├── iOS/
│   │   ├── App/
│   │   │   ├── BulkTrackApp.swift      # @main
│   │   │   └── Bootstrap/
│   │   │       ├── DIContainer.swift
│   │   │       └── AppInitializer.swift
│   │   │
│   │   └── Features/                   # Feature-sliced UI modules
│   │       ├── Home/                   # (Example, actual features may vary, current code might be in BulkTrack/Presentation/)
│   │       │   ├── View/HomeView.swift
│   │       │   └── ViewModels/HomeViewModel.swift
│   │       ├── Menu/ …                 # future features
│   │       └── Settings/ …
│   │
│   └── watchOS/
│       ├── App/                        ← Single-target WatchApp
│       │   ├── BulkTrackWatchApp.swift # @main (SwiftUI)
│       │   └── Bootstrap/
│       │       ├── DIContainer.swift   # Manages dependencies for watchOS
│       │       └── WatchAppInitializer.swift
│       │
│       ├── Features/
│       │   ├── RecentExercises/        # Example feature (PoC scope)
│       │   │   ├── View/RecentExercisesView.swift
│       │   │   └── ViewModel/RecentExercisesViewModel.swift
│       │   ├── Dashboard/              # (Future feature)
│       │   │   ├── DashboardView.swift
│       │   │   └── DashboardViewModel.swift
│       │   ├── QuickLog/               # (Future feature)
│       │   │   └── QuickLogView.swift
│       │   └── Settings/               # (Future feature)
│       │       └── WatchSettingsView.swift
│       │
│       ├── Services/
│       │   ├── Connectivity/
│       │   │   ├── WCSessionRelay.swift
│       │   │   └── PayloadMapper.swift
│       │   └── HealthKitRepository.swift  # implements HealthRepository
│       │
│       └── Resources/
│           ├── Assets.xcassets
│           └── Localizable.strings
│
└── Tools/
    ├── swiftgen.yml
    └── swiftlint.yml
```

---

## 2. Layer-by-Layer Details

### 2.1 Domain (Packages/Domain)

| Folder                      | 内容                                                                                                                               |
| --------------------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| `Entities/`                 | **純粋モデル**: `AuthToken.swift`, `ExerciseEntity.swift`。 (例: `Week`, `Dashboard` は将来追加)                                       |
| `RepositoryProtocols.swift` | `AuthRepository`, `ExerciseRepository`, `SessionSyncRepository`, `SecureStorageServiceProtocol` など。 (例: `DashboardRepository` は将来追加) |
| `UseCases/`                 | 各UseCaseは機能単位でサブディレクトリに配置 (例: `Auth/ActivateDeviceUseCase.swift`, `WatchSync/RequestRecentExercisesUseCase.swift`) |
| `Shared/`                   | `AppError.swift`, `ResultState.swift` など、Domainレイヤ内で共有されるモデルやユーティリティ。                                                |
| **依存禁止**                    | UIKit / SwiftUI / CoreData / URLSession など一切 import しない                                                                        |

### 2.2 Data (Packages/Data)

| Sub-folder    | 記述内容                                                                                                   |
| ------------- | ---------------------------------------------------------------------------------------------------------- |
| `Networking/` | `APIService.swift` (Repository実装), `NetworkClient.swift`, `APIError.swift` (Domainの`AppError`にラップされる想定) |
| `DTO/`        | APIスキーマに対応するCodable struct (例: `ExerciseDTO.swift`, `TokenResponseDTO.swift`)                         |
| `Mapper/`     | DTO ⇔ Domain Entity変換 (例: `ExerciseMapper.swift`, `TokenMapper.swift`)                                     |
| `Storage/`    | `KeychainService.swift` (SecureStorageServiceProtocolの実装)                                               |
| **依存**        | `import Domain`, `import Foundation`。**UIフレームワーク禁止**                                                      |

### 2.3 SharedUI (Packages/SharedUI) ≪任意≫

再利用可能なViewコンポーネント (Charts, Buttons, Modifiersなど)。
SwiftUIのみで構成され、ビジネスロジックは含まない。現状は積極的には利用されていない可能性あり。

### 2.4 Presentation (iOS / watchOS Features)

* **View** – SwiftUI のみ。
* **ViewModel** – `@MainActor`。**Domain UseCaseプロトコル**に依存 (推奨)。シンプルなケースではRepositoryプロトコルに直接依存することもある。UI表示のためのデータ変換や状態管理を行う。

### 2.5 Bootstrap (App layer)

| ファイル                                             | 役割                                                                                                |
| ------------------------------------------------ | ------------------------------------------------------------------------------------------------- |
| `BulkTrackApp.swift` / `BulkTrackWatchApp.swift` | `@main` struct。`WindowGroup`のオーナーであり、アプリ起動時の処理 (`.task` modifierなど) を持つ。                 |
| `DIContainer.swift`                              | シングルトンとして依存性を管理・提供。各プラットフォームで必要なインスタンスを生成・保持。                                  |
| `AppInitializer.swift` / `WatchAppInitializer.swift` | アプリ起動時の初期化処理（デバイス認証、WCSessionアクティベートなど）を実行。`DIContainer`から必要な依存を取得。 |

---

## 3. watchOS (single-target) 特記事項

| 項目                         | 実装指針                                                                                                             |
| -------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| **Watch Connectivity**     | `WCSessionRelay` placed in `Apps/watchOS/Services/Connectivity/`. Implements `SessionSyncRepository` for Domain. |
| **HealthKit / WorkoutKit** | Device-only data; make `HealthKitRepository` conform to `HealthRepository` (Domain).                             |
| **Assets & Localizable**   | 直接 `WatchApp/Resources/` に含める。ターゲット Membership は WatchApp のみ。                                                    |
| **BackgroundTasks**        | If needed, add `BGProcessing` entitlement directly to WatchApp target.                                           |

---

## 4. Build Dependencies

```text
Domain        (no deps)
  ▲
  │
Data -------- SharedUI
  ▲              ▲
  │              │
Apps/iOS      Apps/watchOS (single-target)
```

Add the frameworks in **Xcode ▸ General ▸ Frameworks, Libraries & Embedded Content**:

| Target                | Must Link                                            |
| --------------------- | ---------------------------------------------------- |
| **BulkTrack (iOS)**   | Domain.framework, Data.framework, SharedUI.framework |
| **BulkTrackWatchApp** | Domain.framework, Data.framework, SharedUI.framework |

---

## 5. Testing Strategy

| Package / Target | Test Target              | What to test                            |
| ---------------- | ------------------------ | --------------------------------------- |
| Domain           | `DomainTests`            | Entity equality, UseCase pure logic     |
| Data             | `DataTests`              | NetworkClient stubs, Mapper correctness |
| iOS App          | `PresentationTests`      | ViewModel with **mock repositories**    |
| watchOS App      | `WatchPresentationTests` | QuickLogViewModel, WCSession stubs      |

---

> **Principle Recap**
>
> 1. Domain is framework-free and platform-agnostic.
> 2. Data converts the outside world (REST, HK, WCSession) into Domain.
> 3. Presentation converts Domain into pixels.
> 4. DIContainer wires everything together at the very edge (App layer).
