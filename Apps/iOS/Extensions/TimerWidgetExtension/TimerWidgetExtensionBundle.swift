//
//  TimerWidgetExtensionBundle.swift
//  TimerWidgetExtension
//
//  Created by Ryota Katada on 2025/05/27.
//

import WidgetKit
import SwiftUI

@main
struct TimerWidgetExtensionBundle: WidgetBundle {
    var body: some Widget {
        // Live Activity Widget
        TimerWidgetExtensionLiveActivity()
        
        // Static Timer Widget (if needed in the future)
        // TimerWidgetExtension()
        
        // Control Widget for iOS 18+ (if needed in the future)
        // if #available(iOS 18.0, *) {
        //     TimerWidgetExtensionControl()
        // }
    }
}
