import SwiftUI
import UIKit

/// ステータスバーエリアの背景色をナビゲーションバーと統一するためのView
struct StatusBarBackgroundView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Rectangle()
            .fill(backgroundColor)
            .frame(height: statusBarHeight)
            .frame(maxWidth: .infinity)
            .ignoresSafeArea(.all, edges: .top)
    }
    
    private var backgroundColor: Color {
        // ナビゲーションバーと同じ色を使用
        if colorScheme == .dark {
            return Color(UIColor(white: 0.06, alpha: 1.0))
        } else {
            return Color.white
        }
    }
    
    private var statusBarHeight: CGFloat {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return 0
        }
        return window.safeAreaInsets.top
    }
}
