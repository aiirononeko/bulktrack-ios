# BulkTrack iOS Client

> **Mission Statement:** Build the **fastest, most friction-less strength-training log** that *understands* progressive overload and uses data-driven volume management to fuel muscle growth.
>
> This client is written in **Swift 5.9+ and SwiftUI**, and communicates with the [BulkTrack API](https://github.com/aiirononeko/bulktrack-api) over HTTP. It is being refactored towards a Clean Architecture.

---

## What We Make (Pillars)

| Pillar                         | Why it Matters                                                                              | How it Shows Up in the App (Current & Planned)                                                                                                                               |
| ------------------------------ | ------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **1 Frustration-free Logging** | A set should be captured in <800 ms, even offline.                                         | Device-ID onboarding (no account needed initially). Future: Offline caching, single-tap set duplication, auto-prefill, display of previous session's sets.                     |
| **2 Volume-Centric Insights**  | Hypertrophy hinges on *effective volume*. Users need a gut-level view of "did I do enough?" | Future: Daily/weekly muscle‐volume aggregation, highlight under-stimulated areas, deload warnings.                                                                         |
| **3 AI-Ready Data Rails**      | Tomorrow's coach learns from your history + recovery. Clean data > fancy models.            | Clear separation of concerns (Domain, Data, Presentation layers), well-defined DTOs and Entities. Future: Normalised local schema, explicit tempo/rest, deterministic IDs. |
| **4 Edge-native Speed**        | Millisecond APIs worldwide without DevOps drag.                                             | Communication with Cloudflare-Workers based API. Future: Aggressive caching, background refresh.                                                                             |

---

## Requirements

* Xcode 15.3 or later (swift-tools-version 5.9)
* iOS 17.0+ / watchOS 10.0+
* SwiftLint 0.54+ (optional, for linting)
* Homebrew + Make (optional, for helper scripts if any)

---

## Getting Started

```bash
# 1. Clone
$ git clone https://github.com/aiirononeko/bulktrack-ios.git
$ cd bulktrack-ios

# 2. Resolve Swift packages
$ open BulkTrack.xcodeproj  # Xcode will fetch dependencies (Domain, Data, SharedUI packages) automatically

# 3. Create local config (if applicable for API base URL overrides)
# $ cp Config/Secrets.sample.xcconfig Config/Secrets.xcconfig
# # ↳ edit API_BASE_URL if needed
```

> **Tip:** The `API_BASE_URL` in `Packages/Data/Sources/Data/Networking/NetworkClient.swift` defaults to `http://localhost:8787/v1` for DEBUG and `https://api.bulk-track.com/v1` for RELEASE. Adjust as needed.

### Running on Simulator / Device

1.  Select the **BulkTrack** (iOS) or **BulkTrackWatchApp** (watchOS) scheme.
2.  Choose a simulator or a physical device.
3.  Press ⌘-R.

The first cold-start of the iOS app triggers a device activation (`POST /v1/auth/device`); a `deviceId` UUID is generated (currently v4, stored in UserDefaults) and used to obtain API tokens, which are stored in the Keychain. Subsequent launches use cached tokens and implement a refresh mechanism.

---

## Project Layout (Clean Architecture)

The project follows a Clean Architecture approach, separating concerns into distinct layers and modules. This promotes testability, maintainability, and scalability.

```text
BulkTrack/
├── Docs/
│   └── ARCHITECTURE.md         # Detailed architecture guide (canonical source)
│
├── Packages/                   # Swift Package Manager modules for core logic
│   ├── Domain/                 # Pure Swift: Entities, Use Cases, Repository Protocols
│   │   ├── Sources/Domain/
│   │   │   ├── Entities/       # Business model objects (e.g., AuthToken, ExerciseEntity)
│   │   │   ├── UseCases/       # Application-specific business rules
│   │   │   └── RepositoryProtocols.swift # Interfaces for data access
│   │   └── Tests/DomainTests/
│   │
│   ├── Data/                   # Data sources: API client, persistence, mappers
│   │   ├── Sources/Data/
│   │   │   ├── DTO/            # Data Transfer Objects (mirroring API schema)
│   │   │   ├── Mapper/         # DTO <-> Entity mappers
│   │   │   ├── Networking/     # API client (NetworkClient, APIService, Endpoints)
│   │   │   └── Storage/        # Secure storage (e.g., KeychainService)
│   │   └── Tests/DataTests/
│   │
│   └── SharedUI/ (Optional)    # Reusable SwiftUI components across targets
│       ├── Sources/SharedUI/
│       └── Tests/SharedUITests/
│
├── Apps/                       # Application targets (iOS, watchOS)
│   ├── iOS/
│   │   ├── App/                # iOS App entry point & bootstrap
│   │   │   ├── BulkTrackApp.swift  # @main struct
│   │   │   └── Bootstrap/      # DIContainer, AppInitializer
│   │   ├── Features/           # Feature-sliced UI modules (View, ViewModel)
│   │   │   └── (e.g., Home, RecentExercises, Settings)
│   │   └── Services/           # iOS-specific services (e.g., WCSessionRelay)
│   │
│   └── watchOS/
│       ├── App/                # watchOS App entry point & bootstrap (single target)
│       │   ├── BulkTrackApp.swift # @main struct for watchOS
│       │   └── Bootstrap/      # DIContainer, WatchAppInitializer
│       ├── Features/           # watchOS specific UI features
│       │   └── RecentExercises/# Example feature
│       │       ├── View/
│       │       └── ViewModel/
│       ├── Services/           # watchOS-specific services (WCSessionRelay, HealthKit)
│       └── Resources/          # watchOS assets, localization
│
├── Shared/ (Project-level)     # Shared resources for app targets (e.g., xcconfig)
│   └── Configuration/
│
└── Tools/                      # Build tools, linters configuration (e.g., SwiftLint)
    └── swiftlint.yml
```

### Layer Responsibilities:

*   **Domain Package:** Contains the core business logic and entities of the application. It is independent of UI and data source implementations. Defines repository protocols (interfaces) for data access.
*   **Data Package:** Implements the repository protocols defined in the Domain layer. Handles data retrieval from APIs (via `NetworkClient` and `APIService`), local storage (e.g., `KeychainService` for tokens, UserDefaults for device ID), and mapping between Data Transfer Objects (DTOs) and Domain Entities.
*   **SharedUI Package (Optional):** Contains common SwiftUI views, components, or design system elements reusable across different app targets or features.
*   **Apps (iOS & watchOS):**
    *   **Presentation Layer:** Resides within each app target's `Features/` directory. Consists of SwiftUI Views and ViewModels. ViewModels orchestrate data flow to and from Views, interact with Domain UseCases (or Repositories directly for simpler cases), and manage UI state.
    *   **Bootstrap:** Handles app initialization, dependency injection (via `DIContainer`), and setup of app-level services.
    *   **App-Specific Services:** Platform-specific services like Watch Connectivity (`WCSessionRelay`) or HealthKit integration.

### Data Flow (Conceptual)

```mermaid
graph TD
    subgraph "Presentation Layer (iOS/watchOS App)"
        View["View (SwiftUI)"]
        ViewModel["ViewModel"]
    end

    subgraph "Domain Layer (Package)"
        UseCase["UseCase (Optional)"]
        RepositoryProtocol["Repository Protocol"]
        Entity["Domain Entity"]
    end

    subgraph "Data Layer (Package)"
        RepositoryImpl["Repository Implementation (e.g., APIService, KeychainService)"]
        DTO["Data Transfer Object (DTO)"]
        NetworkClient["NetworkClient / Local Storage"]
    end

    View -->|User Actions, .task, .onAppear| ViewModel
    ViewModel -->|Calls| UseCase
    UseCase -->|Uses| RepositoryProtocol
    ViewModel -->|Observes State / Publishes Data| View

    RepositoryProtocol -- Implemented by --> RepositoryImpl
    RepositoryImpl -->|Fetches/Sends| NetworkClient
    NetworkClient -->|Raw Data/API DTOs| RepositoryImpl
    RepositoryImpl -->|Maps DTO to Entity| Entity
    Entity -- Returned to/Used by --> UseCase
    UseCase -- Returns Entity/Processed Data to --> ViewModel
    
    %% For Watch Connectivity (Example: Recent Exercises)
    subgraph "watchOS App"
        Watch_View["RecentExercisesView"]
        Watch_VM["RecentExercisesViewModel"]
        Watch_WCSessionRelay["WCSessionRelay (watchOS)"]
    end
    subgraph "iOS App"
        iOS_WCSessionRelay["WCSessionRelay (iOS)"]
        iOS_APIService["APIService (iOS)"]
    end
    Watch_View --> Watch_VM
    Watch_VM -->|requestRecentExercises| Watch_WCSessionRelay
    Watch_WCSessionRelay -->|sendMessage| iOS_WCSessionRelay
    iOS_WCSessionRelay -->|Calls| iOS_APIService
    iOS_APIService -->|Fetches from API| ExternalAPI["External API"]
    ExternalAPI -->|DTOs| iOS_APIService
    iOS_APIService -->|Entities| iOS_WCSessionRelay
    iOS_WCSessionRelay -->|Reply with DTOs| Watch_WCSessionRelay
    Watch_WCSessionRelay -->|Entities (after mapping)| Watch_VM
    Watch_VM -->|Updates| Watch_View
```

*   **Swift Concurrency (`async/await`)** is used for asynchronous operations.
*   **Combine** is used for reactive state management in ViewModels and services (e.g., `CurrentValueSubject` for `isAuthenticated` status).
*   **Dependency Injection** is managed via a simple `DIContainer` in each app's Bootstrap layer.

---

## API Client

The application interacts with the BulkTrack API using a custom-built networking layer:
*   **`NetworkClient.swift`** (`Packages/Data/Sources/Data/Networking/`): A generic client responsible for executing URLRequests and handling basic response/error processing. It uses `async/await` with `URLSession`.
*   **`Endpoint.swift`** (typically defined alongside `NetworkClient` or per API): A protocol to define individual API endpoints (URL, path, method, headers, parameters).
*   **`APIService.swift`** (`Packages/Data/Sources/Data/Networking/`): Implements repository protocols (e.g., `ExerciseRepository`, `AuthRepository`). It uses `NetworkClient` to make specific API calls (e.g., fetching recent exercises, activating device).
*   **DTOs (Data Transfer Objects)** (`Packages/Data/Sources/Data/DTO/`): Swift `struct`s conforming to `Codable`, mirroring the JSON schemas defined in the API's OpenAPI specification.
*   **Mappers** (`Packages/Data/Sources/Data/Mapper/`): Responsible for converting between DTOs and Domain Entities (e.g., `ExerciseMapper`, `TokenMapper`).

This setup avoids reliance on external code generation tools for the API client, providing more control, though it requires manual DTO and Endpoint definition based on the OpenAPI spec.

---

## Authentication Flow

The app uses a Bearer token-based authentication system.

1.  **Device Activation (Anonymous Onboarding):**
    *   On first launch, the iOS app generates a unique Device ID (UUID v4, stored in UserDefaults via `DeviceIdentifierService`).
    *   It calls `POST /v1/auth/device` with the `X-Device-Id` header.
    *   The API responds with an `AuthToken` (containing `accessToken`, `refreshToken`, `expiresIn`).
    *   This `AuthToken` and its retrieval time are stored securely in the Keychain via `KeychainService`.
2.  **Authenticated Requests:**
    *   For API endpoints requiring authentication, `APIService` (via `AuthManager` and `NetworkClient`) automatically attaches an `Authorization: Bearer <accessToken>` header to requests.
3.  **Token Refresh:**
    *   `AuthManager` is responsible for managing token lifecycle.
    *   It calculates the `accessToken`'s expiry time based on `expiresIn` and the time it was retrieved.
    *   Before the `accessToken` expires (e.g., 60 seconds prior), `AuthManager` attempts to use the `refreshToken` to call `POST /v1/auth/refresh`.
    *   **Automatic Recovery on Refresh Failure:**
        *   If the refresh attempt fails due to a temporary network issue, `AuthManager` will automatically retry the refresh operation a few times with exponential backoff.
        *   If retries also fail, or if the refresh token is deemed invalid (e.g., an "invalid_grant" error from the server), `AuthManager` will attempt a "silent device activation." This involves trying to re-activate the device in the background using the stored Device ID, provided a cooldown period (e.g., 24 hours) since the last silent activation attempt has passed.
        *   If silent activation is successful, a new set of tokens is obtained, and the user's session continues seamlessly.
        *   If all automatic recovery attempts (retries and silent activation) fail, the user will eventually need to be prompted to log in again (e.g., by clearing local tokens, leading to the activation flow on next protected resource access).
    *   If the initial refresh or subsequent recovery is successful, a new `AuthToken` is received and stored, updating the session.
4.  **Logout:**
    *   User-initiated logout calls `POST /v1/auth/logout` with the current `refreshToken` in the body (and `accessToken` in header).
    *   If successful, local tokens are deleted from Keychain.

---

## Local Development Scripts

(Review and update if `make` commands are still relevant or used)

| Task                    | Command                                  |
| ----------------------- | ---------------------------------------- |
| Unit tests              | `⌘-U` in Xcode *or* `make test` (if configured) |
| SwiftFormat + SwiftLint | `make format` (if configured)            |
| ...                     | ...                                      |

---

## Roadmap / TODO (Excerpt)

*   **Robust Token Refresh & Error Handling:**
    *   The token refresh mechanism in `AuthManager` now includes retries for temporary network errors and a silent re-activation attempt for unrecoverable refresh token errors.
    *   Further enhancement: Implement automatic retry of the original API request (that might have triggered a 401) *after* a successful token refresh.
*   **UI for Errors:** Display user-facing errors from `AuthManager` and `AppInitializer` (e.g., via alerts), especially for scenarios where automatic token recovery fails and user action is required.
*   **watchOS App:** Continue development of features beyond recent exercises.
*   **Core Data / SwiftData:** Implement local database caching for offline support and performance.
*   Workout timer & rest-push notifications
*   Live Activity for session timer

---

## Acknowledgements

*   [BulkTrack API](https://github.com/aiirononeko/bulktrack-api) for the backend.
*   SwiftUI and Combine frameworks by Apple.
*   `.clinerules/` for project-specific architectural guidelines.
