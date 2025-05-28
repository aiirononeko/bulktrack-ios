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
                
                Text(context.state.status.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.state.displayExerciseName)
                        .font(.headline)
                        .lineLimit(1)
                    
                    
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    AnimatedTimerText(context: context)
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
                RealTimeProgressView(context: context)
                    .scaleEffect(y: 1.33) // Adjust for lock screen
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
        AnimatedTimerText(context: context)
            .font(.caption)
            .fontWeight(.semibold)
            .monospacedDigit()
    }
}

struct TimerExpandedTrailingView: View {
    let context: ActivityViewContext<TimerActivityAttributes>
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            AnimatedTimerText(context: context)
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
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                ScrollingTextView(text: context.state.displayExerciseName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
            }
            
            if context.state.duration > 0 {
                RealTimeProgressView(context: context)
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
        AnimatedTimerText(context: context)
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

// MARK: - Animated Timer Text Component
struct AnimatedTimerText: View {
    let context: ActivityViewContext<TimerActivityAttributes>
    @State private var currentTime = Date()
    
    private var timeString: String {
        // Use startedAt-based calculation for running timers
        if context.state.status == .running, let startedAt = context.state.startedAt {
            let elapsed = currentTime.timeIntervalSince(startedAt)
            let remaining = max(0, context.state.duration - elapsed)
            let minutes = Int(remaining) / 60
            let seconds = Int(remaining) % 60
            return String(format: "%02d:%02d", minutes, seconds)
        } else {
            return context.state.formattedRemainingTime
        }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(timeString.enumerated()), id: \.offset) { index, character in
                Text(String(character))
                    .id("timer-\(index)-\(character)")
                    .transition(.asymmetric(
                        insertion: .push(from: .top).combined(with: .opacity),
                        removal: .push(from: .bottom).combined(with: .opacity)
                    ))
                    .animation(.easeInOut(duration: 0.2), value: character)
            }
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            if context.state.status == .running {
                currentTime = Date()
            }
        }
    }
}

// MARK: - Real-time Progress View Component
struct RealTimeProgressView: View {
    let context: ActivityViewContext<TimerActivityAttributes>
    @State private var currentTime = Date()
    
    private var currentProgress: Double {
        // Use startedAt-based calculation for running timers
        if context.state.status == .running, let startedAt = context.state.startedAt {
            let elapsed = currentTime.timeIntervalSince(startedAt)
            let progress = min(max(elapsed / context.state.duration, 0.0), 1.0)
            return progress
        } else {
            return context.state.progress
        }
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color(context.state.status.color))
                .frame(width: 6, height: 6)
            
            ProgressView(value: currentProgress)
                .progressViewStyle(LinearProgressViewStyle(tint: Color(context.state.status.color)))
            
            Circle()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 6, height: 6)
        }
        .scaleEffect(y: 1.5)
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            if context.state.status == .running {
                currentTime = Date()
            }
        }
    }
}

// MARK: - Scrolling Text Component
struct ScrollingTextView: View {
    let text: String
    @State private var offset: CGFloat = 0
    @State private var textWidth: CGFloat = 0
    @State private var containerWidth: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            Text(text)
                .fixedSize(horizontal: true, vertical: false)
                .offset(x: offset)
                .onAppear {
                    containerWidth = geometry.size.width
                    measureTextWidth()
                    startScrollingIfNeeded()
                }
                .onChange(of: text) { _ in
                    measureTextWidth()
                    startScrollingIfNeeded()
                }
                .background(
                    Text(text)
                        .hidden()
                        .background(GeometryReader { textGeometry in
                            Color.clear.onAppear {
                                textWidth = textGeometry.size.width
                            }
                        })
                )
        }
        .clipped()
    }
    
    private func measureTextWidth() {
        DispatchQueue.main.async {
            if textWidth > containerWidth {
                startScrolling()
            } else {
                offset = 0
            }
        }
    }
    
    private func startScrollingIfNeeded() {
        if textWidth > containerWidth {
            startScrolling()
        }
    }
    
    private func startScrolling() {
        let scrollDistance = textWidth - containerWidth + 20
        
        withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: true)) {
            offset = -scrollDistance
        }
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
