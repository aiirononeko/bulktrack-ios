import Foundation
import Combine
import Domain

#if os(iOS)
import UIKit
import BackgroundTasks

extension Notification.Name {
    static let backgroundTimerUpdate = Notification.Name("backgroundTimerUpdate")
}
#endif

/// バックグラウンドタイマー管理サービスの実装
@MainActor
public final class BackgroundTimerService: BackgroundTimerServiceProtocol {
    // MARK: - Properties
    private let appLifecycleSubject = PassthroughSubject<AppLifecycleEvent, Never>()
    private var activeTasks: [String: Any] = [:]
    private var cancellables = Set<AnyCancellable>()
    
    public var appLifecycleEvents: AnyPublisher<AppLifecycleEvent, Never> {
        appLifecycleSubject.eraseToAnyPublisher()
    }
    
    public var isBackgroundProcessingAvailable: Bool {
        #if os(iOS)
        return UIApplication.shared.backgroundRefreshStatus == .available
        #else
        return false
        #endif
    }
    
    // MARK: - Initialization
    public init() {
        setupAppLifecycleObservation()
        registerBackgroundTasks()
    }
    
    deinit {
        // cancellablesのクリーンアップはMainActorコンテキストで自動的に行われる
    }
}

// MARK: - Public Methods
public extension BackgroundTimerService {
    func startBackgroundTask(
        identifier: String,
        expirationHandler: @escaping () -> Void
    ) -> String? {
        #if os(iOS)
        let taskId = UIApplication.shared.beginBackgroundTask(withName: identifier) {
            // タスクの期限切れ時の処理
            expirationHandler()
            
            // タスクを終了
            if let storedTaskId = self.activeTasks[identifier] as? UIBackgroundTaskIdentifier {
                UIApplication.shared.endBackgroundTask(storedTaskId)
                self.activeTasks.removeValue(forKey: identifier)
            }
        }
        
        guard taskId != .invalid else {
            print("[BackgroundTimerService] Failed to start background task: \(identifier)")
            return nil
        }
        
        activeTasks[identifier] = taskId
        print("[BackgroundTimerService] Started background task: \(identifier)")
        return identifier
        #else
        print("[BackgroundTimerService] Background tasks not supported on this platform")
        return nil
        #endif
    }
    
    func endBackgroundTask(taskId: String) {
        #if os(iOS)
        guard let backgroundTaskId = activeTasks[taskId] as? UIBackgroundTaskIdentifier else {
            print("[BackgroundTimerService] No active task found for ID: \(taskId)")
            return
        }
        
        UIApplication.shared.endBackgroundTask(backgroundTaskId)
        activeTasks.removeValue(forKey: taskId)
        print("[BackgroundTimerService] Ended background task: \(taskId)")
        #else
        print("[BackgroundTimerService] Background tasks not supported on this platform")
        #endif
    }
    
    func checkBackgroundAppRefreshStatus() -> BackgroundAppRefreshStatus {
        #if os(iOS)
        switch UIApplication.shared.backgroundRefreshStatus {
        case .available:
            return .available
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        @unknown default:
            return .denied
        }
        #else
        return .restricted
        #endif
    }
    
    func requestBackgroundProcessingPermission() {
        #if os(iOS)
        // iOS設定アプリを開く
        if let settingsURL = URL(string: UIApplication.openSettingsURLString),
           UIApplication.shared.canOpenURL(settingsURL) {
            UIApplication.shared.open(settingsURL)
        }
        #endif
    }
}

// MARK: - Private Methods
private extension BackgroundTimerService {
    func setupAppLifecycleObservation() {
        #if os(iOS)
        // アプリがアクティブでなくなる時
        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                self?.appLifecycleSubject.send(.willResignActive)
            }
            .store(in: &cancellables)
        
        // アプリがアクティブになる時
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.appLifecycleSubject.send(.didBecomeActive)
            }
            .store(in: &cancellables)
        
        // アプリがバックグラウンドに移行する時
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                self?.appLifecycleSubject.send(.didEnterBackground)
            }
            .store(in: &cancellables)
        
        // アプリがフォアグラウンドに復帰する時
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                self?.appLifecycleSubject.send(.willEnterForeground)
            }
            .store(in: &cancellables)
        #endif
    }
    
    func registerBackgroundTasks() {
        #if os(iOS)
        // バックグラウンドタスクの登録
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.bulktrack.timer-sync",
            using: nil
        ) { task in
            self.handleBackgroundTimerSync(task: task as! BGProcessingTask)
        }
        #endif
    }
    
    #if os(iOS)
    func handleBackgroundTimerSync(task: BGProcessingTask) {
        // バックグラウンドでのタイマー同期処理
        task.expirationHandler = {
            print("[BackgroundTimerService] Background timer sync task expired")
            task.setTaskCompleted(success: false)
        }
        
        // 実際の同期処理はここで実行
        // GlobalTimerServiceと連携してタイマー状態を更新
        print("[BackgroundTimerService] Starting background timer sync")
        
        // タスク完了まで最大30秒間LiveActivityを更新
        Task { @MainActor in
            var updateCount = 0
            let maxUpdates = 6 // 5秒ごとに6回 = 30秒
            
            for _ in 0..<maxUpdates {
                updateCount += 1
                print("[BackgroundTimerService] Background update \(updateCount)/\(maxUpdates)")
                
                // GlobalTimerServiceに更新を通知
                NotificationCenter.default.post(name: .backgroundTimerUpdate, object: nil)
                
                // 5秒待機
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                
                // タスクが期限切れになった場合は終了
                if task.expirationHandler != nil {
                    break
                }
            }
            
            print("[BackgroundTimerService] Background timer sync completed after \(updateCount) updates")
            task.setTaskCompleted(success: true)
            
            // 次のバックグラウンドタスクをスケジュール
            self.scheduleBackgroundTimerSync()
        }
    }
    
    func scheduleBackgroundTimerSync() {
        let request = BGProcessingTaskRequest(identifier: "com.bulktrack.timer-sync")
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = false
        request.earliestBeginDate = Date(timeIntervalSinceNow: 30) // 30秒後
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("[BackgroundTimerService] Background timer sync scheduled")
        } catch {
            print("[BackgroundTimerService] Failed to schedule background timer sync: \(error)")
        }
    }
    #endif
}
