//
//  AppInitializer.swift
//  BulkTrack
//
//  Created by Ryota Katada on 2025/05/21.
//

import Foundation
import SwiftUI
import Domain
import Data

@MainActor
final class AppInitializer: ObservableObject {

    @Published var initializationState: ResultState<Void, AppError> = .idle

    private let activateDeviceUseCase: ActivateDeviceUseCaseProtocol
    private let deviceIdentifierService: DeviceIdentifierServiceProtocol
    private let authManager: AuthManagerProtocol
    private let globalTimerService: GlobalTimerServiceProtocol
    private let timerNotificationUseCase: TimerNotificationUseCaseProtocol
    private let backgroundTimerService: BackgroundTimerServiceProtocol

    init(
        activateDeviceUseCase: ActivateDeviceUseCaseProtocol,
        deviceIdentifierService: DeviceIdentifierServiceProtocol,
        authManager: AuthManagerProtocol,
        globalTimerService: GlobalTimerServiceProtocol,
        timerNotificationUseCase: TimerNotificationUseCaseProtocol,
        backgroundTimerService: BackgroundTimerServiceProtocol
    ) {
        self.activateDeviceUseCase = activateDeviceUseCase
        self.deviceIdentifierService = deviceIdentifierService
        self.authManager = authManager
        self.globalTimerService = globalTimerService
        self.timerNotificationUseCase = timerNotificationUseCase
        self.backgroundTimerService = backgroundTimerService
    }

    /// アプリ起動時の初期化
    func initializeApp() {
        // TabBarの外観をシステム標準に設定
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }

        guard initializationState.isIdle || initializationState.failureError != nil else {
            // Already loading or successfully initialized
            return
        }
        initializationState = .loading
        
        Task {
            do {                
                let deviceId = deviceIdentifierService.getDeviceIdentifier()

                // 1. デバイス認証の処理
                if !authManager.isAuthenticated.value {
                    print("[AppInitializer] User not authenticated, attempting activation via UseCase.")
                    try await activateDeviceUseCase.execute(deviceId: deviceId)
                    print("[AppInitializer] activateDeviceUseCase.execute completed.")
                } else {
                    print("[AppInitializer] User already authenticated.")
                }
                
                // 2. プッシュ通知権限の要求
                await requestNotificationPermissions()
                
                // 3. バックグラウンドアプリ更新の状態チェック
                checkBackgroundAppRefreshStatus()
                
                // 4. タイマー状態の復元（認証成功後）
                if authManager.isAuthenticated.value {
                    restoreTimerStateIfNeeded()
                }
                                
                if authManager.isAuthenticated.value { 
                    print("[AppInitializer] App initialized successfully. User is authenticated.")
                    self.initializationState = .success(())
                } else {
                    print("[AppInitializer] App initialized but user is NOT authenticated.")
                    self.initializationState = .failure(.authenticationError(.activationFailed("認証状態になりませんでした。")))
                }
            } catch let error as AppError {
                print("[AppInitializer] Initialization failed with AppError: \(error.localizedDescription)")
                self.initializationState = .failure(error)
            } catch let error as UserFacingAuthError {
                print("[AppInitializer] Initialization failed with UserFacingAuthError: \(error.localizedDescription)")
                switch error {
                case .activationFailed(let underlying):
                    self.initializationState = .failure(.authenticationError(.activationFailed(underlying.localizedDescription)))
                case .refreshTokenFailed(let underlying):
                    self.initializationState = .failure(.authenticationError(.refreshTokenFailed(underlying.localizedDescription)))
                default:
                    self.initializationState = .failure(.unknownError(error.localizedDescription))
                }
            }
            catch {
                print("[AppInitializer] Initialization failed with an unexpected error: \(error.localizedDescription)")
                self.initializationState = .failure(.unknownError(error.localizedDescription))
            }
        }
    }
}

// MARK: - Private Methods
private extension AppInitializer {
    /// プッシュ通知権限の要求
    func requestNotificationPermissions() async {
        do {
            let granted = try await timerNotificationUseCase.requestNotificationPermission()
            if granted {
                print("[AppInitializer] Notification permission granted")
            } else {
                print("[AppInitializer] Notification permission denied")
                // 権限が拒否されても初期化は継続する
            }
        } catch {
            print("[AppInitializer] Failed to request notification permission: \(error)")
            // エラーが発生しても初期化は継続する
        }
    }
    
    /// バックグラウンドアプリ更新の状態チェック
    func checkBackgroundAppRefreshStatus() {
        let status = globalTimerService.backgroundAppRefreshStatus
        
        switch status {
        case .available:
            print("[AppInitializer] Background app refresh is available")
        case .denied:
            print("[AppInitializer] Background app refresh is denied")
        case .restricted:
            print("[AppInitializer] Background app refresh is restricted")
        }
        
        // バックグラウンド更新が無効でも初期化は継続する
        // 必要に応じてユーザーに通知を表示する処理を追加可能
    }
    
    /// タイマー状態の復元
    func restoreTimerStateIfNeeded() {
        // GlobalTimerServiceが内部で永続化されたタイマー状態を復元する
        // 明示的な復元処理は必要ないが、ログ出力のため呼び出し
        print("[AppInitializer] Timer state restoration handled by GlobalTimerService")
        
        // 必要に応じて追加の復元処理をここに記述
    }
}

// MARK: - Background App Refresh Support
extension AppInitializer {
    /// バックグラウンドアプリ更新の設定画面を開く
    func requestBackgroundProcessingPermission() {
        globalTimerService.requestBackgroundProcessingPermission()
    }
    
    /// 現在のバックグラウンドアプリ更新状態を取得
    var backgroundAppRefreshStatus: BackgroundAppRefreshStatus {
        globalTimerService.backgroundAppRefreshStatus
    }
}
