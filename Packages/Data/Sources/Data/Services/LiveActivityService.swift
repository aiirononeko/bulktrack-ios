import Foundation
import Domain

#if os(iOS)
@preconcurrency import ActivityKit
import UIKit


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
            print("[LiveActivityService] Live Activities not available - iOS 16.1+ required")
            throw LiveActivityError.notAvailable
        }
        
        print("[LiveActivityService] Starting timer activity...")
        print("[LiveActivityService] Timer State: \(timerState.status), Remaining: \(timerState.formattedRemainingTime)")
        print("[LiveActivityService] Exercise Name: \(exerciseName ?? "nil")")
        
        // 既存のアクティビティがあれば終了
        if isActivityActive {
            print("[LiveActivityService] Ending existing activity before starting new one")
            await endTimerActivity()
        }
        
        // Live Activitiesが利用可能かチェック
        let authInfo = ActivityAuthorizationInfo()
        print("[LiveActivityService] Activities enabled: \(authInfo.areActivitiesEnabled)")
        print("[LiveActivityService] Authorization status: \(authInfo.frequentPushesEnabled)")
        
        guard authInfo.areActivitiesEnabled else {
            print("[LiveActivityService] Live Activities are not enabled by user")
            throw LiveActivityError.notAuthorized
        }
        
        // アクティビティの属性とコンテンツ状態を作成
        let timerId = "timer-\(UUID().uuidString)"
        let attributes = TimerActivityAttributes(timerId: timerId)
        let activityData = timerState.toActivityData(exerciseName: exerciseName)
        let contentState = TimerActivityContentState(from: activityData)
        
        print("[LiveActivityService] Creating activity with ID: \(timerId)")
        print("[LiveActivityService] Content state: remaining=\(contentState.remainingTime), duration=\(contentState.duration), status=\(contentState.status)")
        
        do {
            // アクティビティを開始
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: contentState, staleDate: nil),
                pushType: nil  // プッシュ通知なしでテスト
            )
            
            currentActivity = activity
            currentExerciseName = exerciseName
            
            print("[LiveActivityService] Timer activity started successfully!")
            print("[LiveActivityService] Activity ID: \(timerId)")
            print("[LiveActivityService] Activity state: \(activity.activityState)")
            
        } catch {
            print("[LiveActivityService] Failed to start timer activity: \(error)")
            print("[LiveActivityService] Error type: \(type(of: error))")
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
        let activities = Activity<TimerActivityAttributes>.activities
        for activity in activities {
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
