# BulkTrack Architecture Guide

## 0. TL;DR

| レイヤ                      | Swift Package       | iOS Target            | watchOS Target (single)   |
| ------------------------ | ------------------- | --------------------- | ------------------------- |
| **Domain**               | `Packages/Domain`   | import                | import                    |
| **Data**                 | `Packages/Data`     | import                | import                    |
| **Shared UI (optional)** | `Packages/SharedUI` | import                | import                    |
| **Presentation**         | –                   | `Apps/iOS/Features/*` | `Apps/watchOS/Features/*` |
| **App Bootstrap**        | –                   | `Apps/iOS/App/`       | `Apps/watchOS/App/`       |

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
│   │   │   ├── Entities.swift          # Week, Dashboard, ExerciseEntity …
│   │   │   ├── RepositoryProtocols.swift
│   │   │   └── UseCases/
│   │   │       └── FetchDashboardUseCase.swift
│   │   └── Tests/DomainTests/
│   │       └── DashboardEntityTests.swift
│   │
│   ├── Data/                           ← External data tech
│   │   ├── Sources/Data/
│   │   │   ├── Networking/
│   │   │   │   ├── APIService.swift    # Conforms to *Repository* protocols
│   │   │   │   ├── NetworkClient.swift
│   │   │   │   └── APIError.swift
│   │   │   ├── Mapper/
│   │   │   │   ├── DashboardMapper.swift
│   │   │   │   └── ExerciseMapper.swift
│   │   │   ├── DTO/
│   │   │   │   ├── DashboardResponse.swift
│   │   │   │   ├── ExerciseDTO.swift
│   │   │   │   └── WorkoutSetDTO.swift
│   │   │   └── Models/
│   │   │       └── TokenResponse.swift
│   │   └── Tests/DataTests/
│   │       └── APIServiceMockTests.swift
│   │
│   └── SharedUI/                       ← Design-system level components
│       ├── Sources/SharedUI/
│       │   └── Charts/
│       │       ├── VolumeTrendGraph.swift
│       │       └── AverageRMTrendGraph.swift
│       └── Tests/SharedUITests/
│
├── Shared/                             ← Build & infra
│   └── Configuration/
│       ├── Debug.xcconfig
│       └── Release.xcconfig
│
├── Apps/
│   ├── iOS/
│   │   ├── App/
│   │   │   ├── BulkTrackApp.swift      # @main
│   │   │   └── Bootstrap/
│   │   │       ├── DIContainer.swift
│   │   │       └── AppInitializer.swift
│   │   │
│   │   └── Features/
│   │       ├── Home/
│   │       │   ├── View/
│   │       │   │   ├── HomeView.swift
│   │       │   │   └── Components/
│   │       │   │       └── BodyPartVolumeCard.swift
│   │       │   └── ViewModels/
│   │       │       └── HomeViewModel.swift
│   │       ├── Menu/ …                 # future features
│   │       └── Settings/ …
│   │
│   └── watchOS/
│       ├── App/                        ← Single-target WatchApp
│       │   ├── BulkTrackWatchApp.swift # @main (SwiftUI)
│       │   └── Bootstrap/
│       │       ├── DIContainer.swift   # same code, re-import
│       │       └── WatchAppInitializer.swift
│       │
│       ├── Features/
│       │   ├── Dashboard/
│       │   │   ├── DashboardView.swift
│       │   │   └── DashboardViewModel.swift
│       │   ├── QuickLog/
│       │   │   └── QuickLogView.swift
│       │   └── Settings/
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

| Folder                      | 内容                                                                                        |
| --------------------------- | ----------------------------------------------------------------------------------------- |
| `Entities.swift`            | **純粋モデル**: `Week`, `Dashboard`, `BodyPartVolume`, `ExerciseEntity`, `WorkoutSetEntity` …  |
| `RepositoryProtocols.swift` | `DashboardRepository`, `ExerciseRepository`, `WorkoutSetRepository`, `HealthRepository` … |
| `UseCases/`                 | 1 UseCase = 1 file (`FetchDashboardUseCase`, `CreateWorkoutSetUseCase` …)                 |
| **依存禁止**                    | UIKit / SwiftUI / CoreData / URLSession など一切 import しない                                   |

### 2.2 Data (Packages/Data)

| Sub-folder                   | 記述内容                                                                                  |
| ---------------------------- | ------------------------------------------------------------------------------------- |
| `Networking/`                | `APIService.swift` (facade + Repository実装) / `NetworkClient.swift` / `APIError.swift` |
| `DTO/`                       | Codable structs mirroring OpenAPI schema (`DashboardResponse`, `ExerciseDTO`)         |
| `Mapper/`                    | `DashboardMapper`: DTO → Domain.Entity / `ExerciseMapper` など                          |
| `Models/TokenResponse.swift` | refresh-token用 model                                                                  |
| **依存**                       | `import Domain`, `import Foundation`, **UI framework禁止**                              |

### 2.3 SharedUI (Packages/SharedUI) ≪任意≫

Reusable View components (Charts, Buttons, Modifiers)
Fully SwiftUI, no business logic.

### 2.4 Presentation (iOS / watchOS Features)

* **View** – SwiftUI only.
* **ViewModel** – `@MainActor`, depends on **Domain Repository protocols** *only* (`DashboardRepository`).
  Conversion Domain → UI happens here (e.g. `BodyPartVolumeViewModel`).

### 2.5 Bootstrap (App layer)

| ファイル                                             | 役割                                                                                  |
| ------------------------------------------------ | ----------------------------------------------------------------------------------- |
| `BulkTrackApp.swift` / `BulkTrackWatchApp.swift` | `@main`, owns `WindowGroup` / `.task` startup                                       |
| `DIContainer.swift`                              | `Resolver`-like singleton.<br>`register(DashboardRepository.self) { APIService() }` |
| `AppInitializer.swift`                           | activation check, token refresh pre-flight                                          |

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
