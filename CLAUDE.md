# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
# Open the project (auto-resolves Swift packages)
open BulkTrack.xcodeproj

# Build and run iOS app
# Use Xcode: ⌘-R with BulkTrack scheme selected

# Build and run watchOS app  
# Use Xcode: ⌘-R with BulkTrackWatchApp scheme selected

# Clean build folder
# Xcode: Product → Clean Build Folder (⌘-Shift-K)
```

## Architecture Overview

**BulkTrack** is a strength-training app with iOS, watchOS, and widget targets using Clean Architecture with Swift Package Manager for modularity.

### Package Structure
- **Domain Package** (`Packages/Domain/`) - Pure Swift business logic, entities, use cases, repository protocols
- **Data Package** (`Packages/Data/`) - API client, CoreData caching, DTOs, mappers, background services

### Key Architectural Patterns
- **Clean Architecture**: View → ViewModel → UseCase → Repository → API/Cache
- **Dependency Injection**: Centralized `DIContainer` with factory methods
- **Cache-First Strategy**: 24-hour TTL CoreData cache with API fallback
- **Anonymous Auth**: Device ID → API activation → Bearer tokens in Keychain

### Multi-Target Communication
- **iOS ↔ watchOS**: Watch Connectivity with `WCSessionRelay` on both platforms
- **Widgets**: Live Activity support via `LiveActivityService` and `TimerWidgetExtension`

## Domain Layer (`Packages/Domain/`)

### Core Entities
- `ExerciseEntity` - Exercise definitions and metadata
- `WorkoutSetEntity` - Individual workout sets with reps/weight
- `AuthToken` - Authentication state management
- `TimerState` - Workout timer state and activities

### Use Cases by Feature
- **Auth**: `ActivateDeviceUseCase`, `LogoutUseCase` 
- **Exercise**: `FetchAllExercisesUseCase`, `FetchRecentExercisesUseCase`
- **Workout**: `SaveWorkoutSetUseCase`, `CreateSetUseCase`, `UpdateSetUseCase`
- **Timer**: `IntervalTimerUseCase`, `TimerNotificationUseCase`
- **WatchSync**: `RequestRecentExercisesUseCase`, `HandleRecentExercisesRequestUseCase`

## Data Layer (`Packages/Data/`)

### Networking
- Custom `NetworkClient` with `Endpoint` protocol (no third-party dependencies)
- Environment-specific API URLs via xcconfig files
- DTOs with dedicated mappers (`ExerciseMapper`, `TokenMapper`, `WorkoutSetMapper`)

### Caching Strategy
- **Cache Repository Pattern**: `ExerciseCacheRepository`, `RecentExerciseCacheRepository`
- **Cache-first**: Return valid cache immediately, fallback to API on miss
- **Stale fallback**: Use expired cache when API fails
- **24-hour TTL**: Automatic invalidation via `CacheInvalidationService`

### Background Services
- `GlobalTimerService` - Workout timer with background execution
- `BackgroundTimerService` - iOS background processing
- `LiveActivityService` - Dynamic Island integration
- `TimerPersistenceService` - Timer state persistence

## Authentication Flow

1. **Device Registration**: Generate device ID → `ActivateDeviceUseCase`
2. **Token Management**: Bearer tokens stored in Keychain via `KeychainService`
3. **Auto-refresh**: Automatic token refresh with silent re-activation fallback
4. **Background-aware**: Handles app lifecycle transitions

## Error Handling

- `ResultState<T>` enum for loading/success/error states in ViewModels
- `AppError` with user-facing messages and technical details
- Graceful degradation: Use stale cache when API unavailable

## Development Notes

- **Swift 6.1** with iOS 18.0+ / watchOS 11.0+ deployment targets
- **No external dependencies** - Custom implementations for networking and utilities
- **CoreData stack** managed by `PersistentContainer` with background context support
- **Watch Connectivity** requires both iOS and watchOS apps running for bidirectional communication