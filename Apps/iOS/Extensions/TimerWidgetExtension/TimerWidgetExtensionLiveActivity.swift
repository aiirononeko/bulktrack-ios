//
//  TimerWidgetExtensionLiveActivity.swift
//  TimerWidgetExtension
//
//  Created by Ryota Katada on 2025/05/27.
//

import ActivityKit
import WidgetKit
import SwiftUI
import Domain

// MARK: - Activity Attributes

/// Timer Live Activity用の属性定義
public struct TimerActivityAttributes: ActivityAttributes {
    public typealias ContentState = TimerActivityContentState
    
    /// タイマーID（一意識別子）
    public let timerId: String
    
    public init(timerId: String) {
        self.timerId = timerId
    }
}

/// Timer Live Activity用のContentState
/// DomainのTimerActivityDataをActivityKitのContentStateに適合させる
public struct TimerActivityContentState: Codable, Hashable {
    /// タイマーの残り時間（秒）
    public let remainingTime: TimeInterval
    /// タイマーの全体時間（秒）
    public let duration: TimeInterval
    /// タイマーの状態
    public let status: TimerActivityStatus
    /// 種目名（オプション）
    public let exerciseName: String?
    
    public init(remainingTime: TimeInterval, duration: TimeInterval, status: TimerActivityStatus, exerciseName: String? = nil) {
        self.remainingTime = remainingTime
        self.duration = duration
        self.status = status
        self.exerciseName = exerciseName
    }
    
    /// DomainのTimerActivityDataから変換
    public init(from activityData: TimerActivityData) {
        self.remainingTime = activityData.remainingTime
        self.duration = activityData.duration
        self.status = activityData.status
        self.exerciseName = activityData.exerciseName
    }
}

// MARK: - Helper Extensions for Widget Views
public extension TimerActivityContentState {
    /// 残り時間をフォーマットされた文字列で取得
    var formattedRemainingTime: String {
        let minutes = Int(remainingTime) / 60
        let seconds = Int(remainingTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    /// 進捗率を取得（0.0〜1.0）
    var progress: Double {
        guard duration > 0 else { return 0.0 }
        let elapsed = duration - remainingTime
        return min(max(elapsed / duration, 0.0), 1.0)
    }
    
    /// 表示用の種目名を取得
    var displayExerciseName: String {
        return exerciseName ?? "ワークアウト"
    }
}

struct TimerWidgetExtensionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerActivityAttributes.self) { context in
            // Lock screen/banner UI goes here
            TimerLockScreenView(context: context)
                .activityBackgroundTint(Color(.systemBackground))
                .activitySystemActionForegroundColor(Color.primary)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    TimerExpandedLeadingView(context: context)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    TimerExpandedTrailingView(context: context)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    TimerExpandedBottomView(context: context)
                }
            } compactLeading: {
                TimerCompactLeadingView(context: context)
            } compactTrailing: {
                TimerCompactTrailingView(context: context)
            } minimal: {
                TimerMinimalView(context: context)
            }
            .widgetURL(URL(string: "bulktrack://timer"))
            .keylineTint(Color.accentColor)
        }
    }
}

// MARK: - Lock Screen View
struct TimerLockScreenView: View {
    let context: ActivityViewContext<TimerActivityAttributes>
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: context.state.status.systemImageName)
                    .foregroundColor(Color(context.state.status.color))
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.state.displayExerciseName)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text(context.state.status.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(context.state.formattedRemainingTime)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .monospacedDigit()
                    
                    if context.state.duration > 0 {
                        Text("\(Int(context.state.duration / 60))分")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Progress bar
            if context.state.duration > 0 {
                ProgressView(value: context.state.progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: Color(context.state.status.color)))
                    .scaleEffect(y: 2)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Dynamic Island Views

struct TimerExpandedLeadingView: View {
    let context: ActivityViewContext<TimerActivityAttributes>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: context.state.status.systemImageName)
                .font(.title3)
                .foregroundColor(Color(context.state.status.color))
            
            Text(context.state.status.displayName)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct TimerExpandedTrailingView: View {
    let context: ActivityViewContext<TimerActivityAttributes>
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(context.state.formattedRemainingTime)
                .font(.title3)
                .fontWeight(.semibold)
                .monospacedDigit()
            
            if context.state.duration > 0 {
                Text("\(Int(context.state.duration / 60))分")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct TimerExpandedBottomView: View {
    let context: ActivityViewContext<TimerActivityAttributes>
    
    var body: some View {
        VStack(spacing: 8) {
            Text(context.state.displayExerciseName)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(1)
            
            if context.state.duration > 0 {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color(context.state.status.color))
                        .frame(width: 6, height: 6)
                    
                    ProgressView(value: context.state.progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: Color(context.state.status.color)))
                    
                    Circle()
                        .fill(Color.secondary.opacity(0.3))
                        .frame(width: 6, height: 6)
                }
                .scaleEffect(y: 1.5)
            }
        }
    }
}

struct TimerCompactLeadingView: View {
    let context: ActivityViewContext<TimerActivityAttributes>
    
    var body: some View {
        Image(systemName: context.state.status.systemImageName)
            .font(.caption)
            .foregroundColor(Color(context.state.status.color))
    }
}

struct TimerCompactTrailingView: View {
    let context: ActivityViewContext<TimerActivityAttributes>
    
    var body: some View {
        Text(context.state.formattedRemainingTime)
            .font(.caption)
            .fontWeight(.semibold)
            .monospacedDigit()
    }
}

struct TimerMinimalView: View {
    let context: ActivityViewContext<TimerActivityAttributes>
    
    var body: some View {
        Image(systemName: context.state.status.systemImageName)
            .font(.caption2)
            .foregroundColor(Color(context.state.status.color))
    }
}

// MARK: - Preview Extensions
extension TimerActivityAttributes {
    fileprivate static var preview: TimerActivityAttributes {
        TimerActivityAttributes(timerId: "preview-timer-001")
    }
}

extension TimerActivityContentState {
    fileprivate static var running: TimerActivityContentState {
        TimerActivityContentState(
            remainingTime: 45,
            duration: 60,
            status: .running,
            exerciseName: "ベンチプレス"
        )
    }
     
    fileprivate static var paused: TimerActivityContentState {
        TimerActivityContentState(
            remainingTime: 30,
            duration: 60,
            status: .paused,
            exerciseName: "スクワット"
        )
    }
    
    fileprivate static var completed: TimerActivityContentState {
        TimerActivityContentState(
            remainingTime: 0,
            duration: 60,
            status: .completed,
            exerciseName: "デッドリフト"
        )
    }
}

#Preview("Notification", as: .content, using: TimerActivityAttributes.preview) {
   TimerWidgetExtensionLiveActivity()
} contentStates: {
    TimerActivityContentState.running
    TimerActivityContentState.paused
    TimerActivityContentState.completed
}
