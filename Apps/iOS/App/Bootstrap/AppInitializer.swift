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

    @Published var userFacingError: UserFacingAuthError?

    private let activateDeviceUseCase: ActivateDeviceUseCaseProtocol
    private let deviceIdentifierService: DeviceIdentifierServiceProtocol
    private let authManager: AuthManagerProtocol // isAuthenticated を参照するために保持

    init(container: DIContainer = .shared) {
        self.activateDeviceUseCase = container.activateDeviceUseCase
        self.deviceIdentifierService = container.deviceIdentifierService
        self.authManager = container.authManager // isAuthenticated を参照するために保持
    }

    /// アプリ起動時の初期化
    func initializeApp() {
        Task {
            do {
                // AuthManagerのisAuthenticatedを最初に確認し、既に認証済みなら何もしないか、
                // あるいはactivateDeviceIfNeededのロジックをUseCaseが持つべきか。
                // activateDeviceIfNeededは「必要ならアクティベート」なので、UseCaseがその判断をしても良い。
                // ここでは、AuthManagerのisAuthenticatedをチェックし、未認証の場合のみUseCaseを実行する。
                // ただし、activateDeviceIfNeededの元々の実装は「トークンがなければアクティベート」なので、
                // UseCaseもその前提でdeviceIdを渡して実行すれば良い。
                // AuthManagerのisAuthenticatedは結果確認に使う。
                
                let deviceId = deviceIdentifierService.getDeviceIdentifier()
                // activateDeviceIfNeededのロジック（トークンがなければアクティベート）は
                // AuthManagerに残っているため、AppInitializerはAuthManagerのメソッドを呼ぶのが自然。
                // UseCase化するなら、activateDeviceIfNeededに相当するUseCaseが必要。
                // ActivateDeviceUseCaseは単純なactivateDeviceのラップなので、
                // 「必要なら」のロジックはAppInitializerが持つか、新しいUseCaseを作るか。

                // PoCの範囲では、AuthManagerのactivateDeviceIfNeededをそのまま呼び、
                // UseCaseの導入はViewModelからの具体的なアクション（例：ログインボタン押下時の明示的なログアウト）
                // に限定する方が影響範囲が少ないかもしれない。
                // しかし、指示は「認証関連」なので、ここもUseCase経由にすべき。

                // ActivateDeviceUseCaseは「デバイスをアクティベートする」という単一責務。
                // 「必要なら」という判断は呼び出し側（この場合はAppInitializer）が行うか、
                // ActivateDeviceIfNeededUseCaseのような別のUseCaseを作る。
                // ここでは、AppInitializerがAuthManagerのisAuthenticatedを見て判断する。
                if !authManager.isAuthenticated.value {
                    print("[AppInitializer] User not authenticated, attempting activation.")
                    _ = try await activateDeviceUseCase.execute(deviceId: deviceId)
                    // ActivateDeviceUseCaseが成功すれば、AuthManagerのisAuthenticatedも更新されるはず
                    // (APIService -> AuthRepository -> AuthManagerのトークン保存フロー経由で)
                } else {
                    print("[AppInitializer] User already authenticated.")
                }
                                
                if authManager.isAuthenticated.value { // 再度確認
                    print("[AppInitializer] App initialized. User is authenticated.")
                } else {
                    // This case might occur if activation was expected but didn't result in an authenticated state,
                    // though activateDeviceIfNeeded should throw if it fails to authenticate.
                    print("[AppInitializer] App initialized. User is NOT authenticated.")
                    // Potentially set a specific UserFacingAuthError if this state is unexpected after activation attempt.
                }
            } catch let error as UserFacingAuthError {
                print("[AppInitializer] Initialization failed with UserFacingAuthError: \(error.localizedDescription)")
                self.userFacingError = error
            } catch {
                print("[AppInitializer] Initialization failed with an unexpected error: \(error.localizedDescription)")
                self.userFacingError = .unknown(error)
            }
        }
    }
}

// Note: The main App struct (e.g., BulkTrackApp.swift) should observe 
// AppInitializer's userFacingError property and present an alert or other UI to the user.
