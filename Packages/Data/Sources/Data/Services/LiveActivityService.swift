import Foundation
import Domain

#if os(iOS)
@preconcurrency import ActivityKit
import UIKit

// MARK: - Forward Declaration for Widget Extension Types
// Widget Extensionで定義された型への前方宣言
// 実際の実装は Apps/iOS/Extensions/TimerWidgetExtension/TimerActivityAttributes.swift にあります

/// Timer Live Activity用の属性定義（前方宣言）
struct TimerActivityAttributes: ActivityAttributes {
    typealias ContentState = TimerActivityContentState
    let timerId: String
    
    init(timerId: String) {
        self.timerId = timerId
    }
}

/// Timer Live Activity用のContentState（前方宣言）
struct TimerActivityContentState: Codable, Hashable {
    let remainingTime: TimeInterval
    let duration: TimeInterval
    let status: TimerActivityStatus
    let exerciseName: String?
    
    init(remainingTime: TimeInterval, duration: TimeInterval, status: TimerActivityStatus, exerciseName: String? = nil) {
        self.remainingTime = remainingTime
        self.duration = duration
        self.status = status
        self.exerciseName = exerciseName
    }
    
    init(from activityData: TimerActivityData) {
        self.remainingTime = activityData.remainingTime
        self.duration = activityData.duration
        self.status = activityData.status
        self.exerciseName = activityData.exerciseName
    }
}

/// Live Activity（Dynamic Island）管理サービスの実装
@MainActor
public final class LiveActivityService: LiveActivityServiceProtocol {
    // MARK: - Private Properties
    private var currentActivity: Activity<TimerActivityAttributes>?
    private var currentExerciseName: String?
    
    // MARK: - Public Properties
    public var isActivityActive: Bool {
        guard #available(iOS 16.1, *) else { return false }
        return currentActivity?.activityState == .active
    }
    
    // MARK: - Initialization
    public init() {
        // 既存のアクティビティを確認
        if #available(iOS 16.1, *) {
            restoreExistingActivity()
        }
    }
    
    // MARK: - Public Methods
    
    public func startTimerActivity(timerState: TimerState, exerciseName: String?) async throws {
        guard #available(iOS 16.1, *) else {
            throw LiveActivityError.notAvailable
        }
        
        // 既存のアクティビティがあれば終了
        if isActivityActive {
            await endTimerActivity()
        }
        
        // Live Activitiesが利用可能かチェック
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("[LiveActivityService] Live Activities are not enabled")
            throw LiveActivityError.notAuthorized
        }
        
        // アクティビティの属性とコンテンツ状態を作成
        let attributes = TimerActivityAttributes(timerId: "timer-\(UUID().uuidString)")
        let activityData = timerState.toActivityData(exerciseName: exerciseName)
        let contentState = TimerActivityContentState(from: activityData)
        
        do {
            // アクティビティを開始
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: contentState, staleDate: nil),
                pushType: nil  // プッシュ通知なしでテスト
            )
            
            currentActivity = activity
            currentExerciseName = exerciseName
            
            print("[LiveActivityService] Timer activity started successfully with ID: \(attributes.timerId)")
            
        } catch {
            print("[LiveActivityService] Failed to start timer activity: \(error)")
            print("[LiveActivityService] Error details: \(error.localizedDescription)")
            throw LiveActivityError.failedToStart(error)
        }
    }
    
    public func updateTimerActivity(timerState: TimerState) async throws {
        guard #available(iOS 16.1, *) else {
            throw LiveActivityError.notAvailable
        }
        
        guard let activity = currentActivity else {
            print("[LiveActivityService] No active activity to update")
            throw LiveActivityError.noActiveActivity
        }
        
        let activityData = timerState.toActivityData(exerciseName: currentExerciseName)
        let contentState = TimerActivityContentState(from: activityData)
        let activityContent = ActivityContent(state: contentState, staleDate: nil)
        
        await activity.update(activityContent)
        print("[LiveActivityService] Timer activity updated - remaining: \(timerState.formattedRemainingTime)")
    }
    
    public func endTimerActivity() async {
        guard #available(iOS 16.1, *),
              let activity = currentActivity else { return }
        
        let finalData = TimerState.defaultTimer().toActivityData(exerciseName: currentExerciseName)
        let finalContentState = TimerActivityContentState(from: finalData)
        let finalContent = ActivityContent(state: finalContentState, staleDate: nil)
        
        await activity.end(
            finalContent,
            dismissalPolicy: .after(.now + 3) // 3秒後に自動で非表示
        )
        
        currentActivity = nil
        currentExerciseName = nil
        
        print("[LiveActivityService] Timer activity ended")
    }
    
    public func endAllActivities() async {
        guard #available(iOS 16.1, *) else { return }
        
        // 全てのタイマーアクティビティを終了
        for activity in Activity<TimerActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        
        currentActivity = nil
        currentExerciseName = nil
        
        print("[LiveActivityService] All timer activities ended")
    }
}

// MARK: - Private Methods
@available(iOS 16.1, *)
private extension LiveActivityService {
    func restoreExistingActivity() {
        // アプリ起動時に既存のアクティビティを復元
        if let existingActivity = Activity<TimerActivityAttributes>.activities.first {
            currentActivity = existingActivity
            print("[LiveActivityService] Restored existing timer activity")
        }
    }
}

#else
// Non-iOS platforms - stub implementation
@MainActor
public final class LiveActivityService: LiveActivityServiceProtocol {
    public var isActivityActive: Bool { false }
    
    public init() {}
    
    public func startTimerActivity(timerState: TimerState, exerciseName: String?) async throws {
        throw LiveActivityError.notAvailable
    }
    
    public func updateTimerActivity(timerState: TimerState) async throws {
        throw LiveActivityError.notAvailable
    }
    
    public func endTimerActivity() async {}
    
    public func endAllActivities() async {}
}
#endif

// MARK: - Live Activity Errors
public enum LiveActivityError: LocalizedError {
    case notAvailable
    case notAuthorized
    case noActiveActivity
    case failedToStart(Error)
    case failedToUpdate(Error)
    
    public var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "Live ActivitiesはiOS 16.1以降でのみ利用可能です。"
        case .notAuthorized:
            return "Live Activitiesが許可されていません。設定から有効にしてください。"
        case .noActiveActivity:
            return "アクティブなLive Activityがありません。"
        case .failedToStart(let error):
            return "Live Activityの開始に失敗しました: \(error.localizedDescription)"
        case .failedToUpdate(let error):
            return "Live Activityの更新に失敗しました: \(error.localizedDescription)"
        }
    }
}
