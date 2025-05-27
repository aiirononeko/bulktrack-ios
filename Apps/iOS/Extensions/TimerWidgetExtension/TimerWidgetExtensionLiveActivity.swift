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
