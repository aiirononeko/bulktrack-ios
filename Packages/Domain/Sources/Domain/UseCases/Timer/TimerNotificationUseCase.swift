import Foundation
import UserNotifications

/// タイマー通知管理のプロトコル
public protocol TimerNotificationUseCaseProtocol {
    /// タイマー完了時の通知
    func notifyTimerCompletion()
    
    /// バックグラウンド通知のスケジュール
    func scheduleBackgroundNotification(remainingTime: TimeInterval)
    
    /// スケジュールされた通知をキャンセル
    func cancelScheduledNotifications()
    
    /// 通知権限の確認・リクエスト
    func requestNotificationPermission() async -> Bool
}

/// タイマー通知管理UseCase
public final class TimerNotificationUseCase: TimerNotificationUseCaseProtocol {
    private let notificationCenter = UNUserNotificationCenter.current()
    private let notificationIdentifier = "BulkTrack.IntervalTimer"
    
    public init() {}
    
    public func notifyTimerCompletion() {
        // 音の再生
        playCompletionSound()
        
        // 振動
        triggerHapticFeedback()
        
        // フォアグラウンドでは音と振動のみ、バックグラウンドでは通知も送信される
    }
    
    public func scheduleBackgroundNotification(remainingTime: TimeInterval) {
        guard remainingTime > 0 else { return }
        
        cancelScheduledNotifications()
        
        let content = UNMutableNotificationContent()
        content.title = "インターバルタイマー"
        content.body = "セット間のインターバルが完了しました"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: remainingTime,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: notificationIdentifier,
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("タイマー通知のスケジュールに失敗: \(error)")
            }
        }
    }
    
    public func cancelScheduledNotifications() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [notificationIdentifier])
    }
    
    public func requestNotificationPermission() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            return granted
        } catch {
            print("通知権限のリクエストに失敗: \(error)")
            return false
        }
    }
}

// MARK: - Private Methods
private extension TimerNotificationUseCase {
    func playCompletionSound() {
        // システムサウンドの再生はSwift Packageでは利用不可のため、
        // 通知音やバックグラウンド通知のサウンドで代替
    }
    
    func triggerHapticFeedback() {
        #if os(iOS)
        // iOSでの振動（メインキューで実行）
        DispatchQueue.main.async {
            let impactGenerator = UIImpactFeedbackGenerator(style: .heavy)
            impactGenerator.impactOccurred()
            
            // 追加の振動パターン
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                impactGenerator.impactOccurred()
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                impactGenerator.impactOccurred()
            }
        }
        #endif
    }
}

// MARK: - UIKit Import for iOS
#if os(iOS)
import UIKit
#endif
